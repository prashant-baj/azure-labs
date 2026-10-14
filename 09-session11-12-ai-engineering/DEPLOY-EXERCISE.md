# Exercise · deploy your work in progress to Azure — Terraform, from the command line

**Session 12 · 45 minutes · the whole group, one laptop applies.** Your slice is half built. That is the
point: teams that deploy early find the surprises while they are still cheap.

By the end, your own component answers on a public URL in the lab subscription, every resource came
from `infra/` in your repository, and you have changed it and rolled it back once — all from the CLI.

> **The team decides who does what.** Write it at the top of `infra/deployments.md` before you start:
> who runs `apply` (and so keeps the state on their laptop for the day), who reads every plan before
> it is applied, who builds the image, who keeps the log. Swap roles between checkpoints if you like —
> but only the laptop with the state can apply.

## Before you start — 5 minutes, on the laptop that will apply

```bash
az login                                              # the lab account
az account show --query "{name:name, user:user.name}" -o table
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
terraform -version                                    # 1.6 or later
docker info > /dev/null && echo "docker ok"           # or plan to use az acr build (step 4b)
```
```powershell
az login
$env:ARM_SUBSCRIPTION_ID = (az account show --query id -o tsv)
terraform -version
docker info *> $null; if ($?) { "docker ok" }
```

First time on the subscription? Register the providers once (takes a minute, safe to repeat):
`az provider register -n Microsoft.App` · `-n Microsoft.OperationalInsights` · `-n Microsoft.ContainerRegistry`.

## Checkpoint 1 · `infra/` written, read and merged — 10 min

```text
/azure-terraform specs/001-…        # reads azure-gaps.md, asks about your component, writes infra/
```

No time, or the assistant's version looks odd? Copy `infra-starter/` into `infra/` and adapt it — it is
the known-good shape (`terraform validate` clean). Either way:

- [ ] Every resource has a comment naming the spec or ADR line it serves
- [ ] No secret value anywhere in `infra/` — names only
- [ ] `.gitignore` has `*.tfstate*`, `.terraform/`, `*.tfvars` (setup added them)
- [ ] `infra/deployments.md` exists, with *who does what* filled in
- [ ] Merged through the gate: `infra: first component (<component>)`

## Checkpoint 2 · a person reads the plan — 5 min

```bash
cd infra
terraform init
terraform fmt -check && terraform validate
terraform plan -var prefix=<group> -out tfplan
```

The plan reader answers these out loud **before** anyone types apply:

1. How many to add, change, destroy? (First time: about 6 to add, 0 to destroy.)
2. Which region? Anything outside `eastus`, `eastus2`, `canadacentral` will be refused.
3. Anything you do not recognise — or that no line of your spec asks for?
4. Any `role_assignment`, App Service, Function or Azure OpenAI? (The lab refuses them.)

## Checkpoint 3 · something is running on Azure — 8 min

```bash
terraform apply tfplan                                # Container Apps takes a few minutes the first time
terraform output app_url
curl -s $(terraform output -raw app_url)              # the public hello page
```
```powershell
Invoke-WebRequest (terraform output -raw app_url) -UseBasicParsing | Select-Object StatusCode
```

Log row 1 in `infra/deployments.md`.

## Checkpoint 4 · your own code on your own URL — 12 min

Your component needs a `Dockerfile` (ask the assistant for a minimal one for your ADR's stack — then read
it). Nothing runnable yet? Use `../sample-app/` for today and swap yours in later.

**4a — with Docker** (from the folder with the Dockerfile):

```bash
ACR=$(terraform -chdir=infra output -raw acr_name)
SERVER=$(terraform -chdir=infra output -raw acr_login_server)
az acr login -n $ACR
docker build --platform linux/amd64 -t $SERVER/<component>:v1 .
docker push $SERVER/<component>:v1
```

**4b — no Docker, or a proxy breaks the build:** build it in Azure instead —
`az acr build -r $ACR -t <component>:v1 .` (if the subscription says *tasks are not allowed*, use 4a).

Then point the app at it — **the plan should say 1 to change, 0 to destroy**:

```bash
cd infra
terraform plan -var prefix=<group> -var image=$SERVER/<component>:v1 -var target_port=<your port> -out tfplan
terraform apply tfplan
curl -s $(terraform output -raw app_url)/health        # your app, not the hello page
```

Log row 2.

## Checkpoint 5 · change it, then roll it back — 5 min

Build `:v2` with one visible change (a version string is enough; with the sample app, pass
`-var 'settings={APP_VERSION="v2"}'` instead). Plan, apply, check `/health`. Log row 3.

Now roll back: plan and apply again with `image=…:v1`. Log row 4. **That is your rollback** — the
previous tag, applied from code. No portal clicks, nothing to remember.

## Checkpoint 6 · record it and tidy up — 5 min

- [ ] `infra/deployments.md` has a row for every apply — date, what changed, tag, what the plan said, who, result
- [ ] Commit `infra/` and the log — **never** `terraform.tfstate`, `.terraform/` or `terraform.tfvars`
- [ ] `check-ai-engineering` — section 1b green
- [ ] Decide: `terraform destroy` now, or leave it for the demo? The lab is cleaned about every four
      hours anyway — which is fine: you can recreate everything from `infra/` in minutes. That is the point.

## When it goes wrong — read the error, not the traceback

| You see | It means | Do this |
|---|---|---|
| `RequestDisallowedByPolicy` (with a long Python traceback after it) | The lab policy refused a region or a resource type | Read the block **above** the traceback. Use `eastus` and an allowed service |
| `MissingSubscriptionRegistration` | A resource provider is not registered | `az provider register -n Microsoft.App` (or the namespace named) and wait a minute |
| `subscription ID could not be determined` | azurerm 4 needs it from the environment | Set `ARM_SUBSCRIPTION_ID` (see *Before you start*) |
| `AuthorizationFailed … roleAssignments/write` | Something tried to assign a role | Remove it — the lab uses ACR admin credentials instead |
| Registry name `already in use` | ACR names are global across Azure | `terraform apply -replace=random_string.suffix` for a new suffix, or change `prefix` |
| App URL times out or returns 404 | Wrong `target_port`, or the app listens on `127.0.0.1` | Use your app's real port; listen on `0.0.0.0` |
| `exec format error` in the logs | Image built for ARM (Apple silicon) | `docker build --platform linux/amd64 …` |
| Want the logs | — | `az containerapp logs show -n $(terraform output -raw container_app) -g $(terraform output -raw resource_group) --follow` |
| Plan wants to create everything again | The lab cleaned up overnight — your state remembers resources that are gone | Fine: apply and they come back. That is why everything is in code |
| `terraform init` cannot download providers | Network or proxy | Try another network; tell your facilitator the exact error |

## What this is not (yet)

No Key Vault, no managed identity, no pipeline deploy, no remote state, no monitoring dashboard — those
are layer 6 (Sessions 16–17). Today is: **your code, on Azure, from code, through the CLI — and the
team can do it again tomorrow.**
