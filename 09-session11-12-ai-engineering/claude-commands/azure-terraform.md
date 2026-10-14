---
description: Write Terraform for the basic application component of your slice and deploy it to the lab Azure — after asking the group about your case.
argument-hint: "[slice folder] [optional: the component, e.g. 'the API']"
---
Arguments: $ARGUMENTS — the slice folder, then (optionally) which component to deploy first.

You write Terraform for **one basic, running application component** of this slice on Azure, so the
group can see their own code respond on a public URL. You propose; the group decides; a person runs
`terraform apply`.

## Read first

`constitution.md` · `specs/design/` (architecture-and-stack ADR, NFR register, constraints,
`azure-gaps.md` if it exists) · `<slice>/plan.md` (§8, §11, §12) · `specs/design/azure-lab-constraints.md`
· the code (Dockerfile? how does it start? which port?) · any existing `infra/`.

If `specs/design/azure-gaps.md` does not exist, say: "Run `/azure-gaps` first — I would be guessing
your architecture." and stop, unless the group tells you to continue.

## Ask before you write — one question at a time, wait for each answer

Ask only what the files do not already answer, and quote the line that made you ask:
1. "Which component goes first?" — offer the components from plan §12 that can run alone.
2. "How does it run?" — the start command and port; is there a Dockerfile? (If not, offer to write a
   minimal one for the ADR's stack.)
3. "Does it need data on day one?" — if yes, which store, from the ADR, mapped to an allowed service
   (Cosmos DB serverless, Storage, MySQL Flexible). If the ADR names a denied one, stop and say so.
4. "Which settings and secrets does it read?" — list names only. **Never ask for a secret's value.**
5. "Your group name for the prefix?" (2–8 lowercase letters/digits) and "Who did the team choose to
   run `apply` and keep the state, and who reads the plan?" — the team decides; you only write it down.

## Then write `infra/` — small, readable, re-creatable

Start from `infra-starter/` in the lab folder (copied to `.claude/infra-starter/` by setup, if present)
— it is the known-good shape for this lab. Keep its structure; change names, comments and settings
for this case. Do not add resources it does not have unless the group asked for them above.

- `versions.tf` — `required_version = ">= 1.6"`, `azurerm ~> 4.0`, `random ~> 3.6`.
- `providers.tf` — `provider "azurerm" { features {} resource_provider_registrations = "none" }`.
- `variables.tf` — `prefix` (validated `^[a-z0-9]{2,8}$`), `location` (default `eastus`, validated
  to `eastus`, `eastus2`, `canadacentral`), `image` (default `mcr.microsoft.com/k8se/quickstart:latest`,
  a public hello image, so the first apply works before your image exists), `target_port` (default
  `80` for that hello image; the component's own port once your image is pushed), `tags`.
- `main.tf` — resource group; Log Analytics workspace; Container Registry `Basic` with
  `admin_enabled = true` (the lab role cannot create AcrPull role assignments); Container Apps
  environment; one Container App with external ingress on the component's port, `min_replicas = 0`,
  `max_replicas = 1`, small CPU/memory, registry credentials from the ACR admin password as a
  **Container App secret**, and a `/health` probe if the code has one. Add a data store only if the
  group said yes. Everything named `<prefix>-<what>-<random suffix>` and tagged with the group and slice.
- `outputs.tf` — `app_url`, `acr_name`, `acr_login_server`, `resource_group`, `container_app`.
- `deployments.md` — copied from `infra-starter/deployments.md`, with *who does what* filled in from
  question 5.
- `terraform.tfvars.example` — no secrets. Secrets come from the environment (`TF_VAR_...`) or are
  set after apply with `az containerapp secret set` — never written in a `.tf` or `.tfvars` file.
- `infra/README.md` — the exact steps (below), and how to destroy.
- Make sure `.gitignore` has `*.tfstate*`, `.terraform/`, `*.tfvars` (keep `*.tfvars.example`).

Steps to put in `infra/README.md` (and to say back to the group):

```
az login
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)   # PowerShell: $env:ARM_SUBSCRIPTION_ID = (az account show --query id -o tsv)
cd infra && terraform init && terraform fmt && terraform validate
terraform plan -var prefix=<group> -out tfplan     # a person reads the plan - what will be created?
terraform apply tfplan                             # the person the team chose
# build and push the image (linux/amd64) - or: az acr build -r <acr_name> -t <app>:v1 .
az acr login -n <acr_name>
docker build --platform linux/amd64 -t <acr_login_server>/<app>:v1 .. && docker push <acr_login_server>/<app>:v1
terraform plan -var prefix=<group> -var image=<acr_login_server>/<app>:v1 -var target_port=<port> -out tfplan
terraform apply tfplan                             # plan should say 1 to change, 0 to destroy
curl https://<app url>/health
# roll back = plan and apply the previous tag. Log every apply in deployments.md.
terraform destroy -var prefix=<group>              # at the end of the day - the lab cleans up anyway
```

The whole exercise, with checkpoints and a troubleshooting table, is `DEPLOY-EXERCISE.md`.

## Rules you must not break

- Only resources the lab allows **and that have quota** (see the constraints file). No App Service,
  no Functions, no Azure OpenAI, no `azurerm_role_assignment`.
- No secret values anywhere in `infra/` or in your messages. Names only.
- No resource that no requirement or ADR line asks for. Say which line each resource serves, in a
  comment above it.
- Do not run `terraform apply` or `destroy` yourself. Show the plan summary; a person applies.
- If something the group wants is not possible in the lab, say so plainly and offer the nearest
  allowed option — then let them decide and record it in an ADR.

When you finish, print: the files written, each resource with the spec line it serves, the commands
to run, and what is **not** covered yet (Key Vault + managed identity and the pipeline deploy come in
Sessions 16–17).
