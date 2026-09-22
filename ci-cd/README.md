# CI/CD · GitHub Actions → Azure Container Apps

Automate the pipeline: on every push to `main`, GitHub Actions builds your app image in
**ACR** and rolls your **Container App** to it. Authentication uses **OIDC** (workload
identity federation) — no passwords or client secrets stored in GitHub.

This folder is a **template**. `deploy.yml` goes into *your application repo*, not this one.

## The one thing that needs vlabs

On the lab subscription you are **Contributor**, which **cannot assign roles**
(`Microsoft.Authorization/roleAssignments/write` is denied — confirmed). A CI/CD service
principal needs a role to deploy, so **vlabs (the subscription Owner) must run one command**
to grant it. Everything else you do yourself.

With OIDC there is **no client secret** to hand around — only three IDs, none of them secret.

## Setup

### 1. Create the app registration + federated credential (you can do this)

```powershell
# create the app + service principal
$appId = az ad app create --display-name "gh-<yourteam>" --query appId -o tsv
az ad sp create --id $appId
$appId                        # note this — it's your AZURE_CLIENT_ID and the vlabs ask

# trust your app repo's main branch
@'
{
  "name": "gh-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:<owner>/<your-app-repo>:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}
'@ | Out-File -Encoding ascii fed-cred.json
az ad app federated-credential create --id $appId --parameters fed-cred.json
```

> The `subject` must match the repo **and** ref that runs the workflow. For deploys gated on
> a GitHub Environment use `repo:<owner>/<repo>:environment:<name>` instead of the `ref:` form.
> Lost your appId later? `az ad app list --display-name "gh-<yourteam>" --query "[].appId" -o tsv`.

### 2. Ask vlabs to grant the role (they must do this — you can't)

Send them your `appId`. They run, with their Owner rights:

```bash
az role assignment create --assignee <your-appId> --role Contributor \
  --scope /subscriptions/b4ff8670-4b0c-484f-8565-74df13f030a6
```

(Subscription scope is simplest; a specific resource-group scope works too if it exists.)

### 3. Add the three IDs as GitHub secrets

In your app repo → Settings → Secrets and variables → Actions → New repository secret:

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | your `$appId` |
| `AZURE_TENANT_ID` | `az account show --query tenantId -o tsv` |
| `AZURE_SUBSCRIPTION_ID` | `az account show --query id -o tsv` |

These are identifiers, not passwords — OIDC exchanges a short-lived token at run time.

### 4. Add the workflow

Copy `deploy.yml` into your app repo at `.github/workflows/deploy.yml`, fill in the `env:`
values (ACR name, resource group, container app name), commit, and push to `main`. The run
appears under the repo's **Actions** tab.

## What the workflow does

1. `azure/login` authenticates via OIDC (no secret).
2. `az acr build` builds your `Dockerfile` **inside ACR** (no Docker needed on the runner) and
   pushes it tagged with the commit SHA.
3. `az containerapp update` points the Container App at the new image — a new revision, so you
   can roll back to a previous revision from the portal or CLI.

## Fallback if no service principal is available

The **build + push** half needs no SP — ACR admin credentials work as plain secrets
(`ACR_USERNAME` / `ACR_PASSWORD` / `ACR_LOGIN_SERVER` from `az acr credential show`):

```yaml
      - uses: docker/login-action@v3
        with:
          registry: ${{ secrets.ACR_LOGIN_SERVER }}
          username: ${{ secrets.ACR_USERNAME }}
          password: ${{ secrets.ACR_PASSWORD }}
      - run: |
          docker build -t ${{ secrets.ACR_LOGIN_SERVER }}/myapp:${{ github.sha }} .
          docker push  ${{ secrets.ACR_LOGIN_SERVER }}/myapp:${{ github.sha }}
```

…but the **deploy** step still needs `az login` (the SP). Without one, CI builds and pushes the
image and the Container Apps deploy stays a manual `az containerapp update` from your own
signed-in session. That still teaches the pipeline; the SP is what makes it fully hands-off.
