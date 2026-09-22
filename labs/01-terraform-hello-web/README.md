# Lab 01 · Hello-World Web App with Terraform

Deploy a running web app to Azure using **Terraform** — no portal clicking. You'll write
nothing from scratch here; you'll run the Terraform workflow (`init → plan → apply →
destroy`) against a small, ready-made configuration and see a live URL at the end.

**Time:** ~15–20 minutes · **Cost:** a Basic (B1) App Service plan, torn down at the end
(and by the lab's 4-hour auto-cleanup).

## What you'll build

```
Resource Group
  └── App Service Plan (Linux, B1)
        └── Linux Web App  ──runs──▶  hello-world container (mcr.microsoft.com/azuredocs/aci-helloworld)
```

Everything lives in **eastus** and uses only resource types the lab policy allows — no VMs,
so none of the VM size/capacity limits apply.

## Learning goals

- The core Terraform loop: `init`, `plan`, `apply`, `destroy`.
- How Terraform providers, resources, variables and outputs fit together.
- How Terraform authenticates to Azure through your `az` CLI session.
- Reading a `plan` before you apply, and cleaning up with `destroy`.

## Prerequisites

- Ran **`prereqs-check`** (Terraform, Azure CLI installed).
- Ran **`00-access-check`** and signed in — i.e. `az login` is done and the lab
  subscription is active. Start the lab environment in vlabs first if it was recycled.

## Files

| File | Purpose |
|------|---------|
| `main.tf` | Provider + the resources (resource group, plan, web app). |
| `variables.tf` | Inputs (`prefix`, `location`, `plan_sku`) with defaults and validation. |
| `outputs.tf` | Prints the app URL after apply. |
| `terraform.tfvars.example` | Optional: copy to `terraform.tfvars` to override defaults. |
| `.terraform.lock.hcl` | Pins provider versions so everyone gets the same ones. |

## Steps

### 0. Register the App Service resource provider (once per lab session)

A freshly-provisioned lab subscription hasn't registered the `Microsoft.Web` resource
provider yet, so the very first deployment would fail with `MissingSubscriptionRegistration`.
Register it once (your Contributor role allows this):

```bash
az provider register --namespace Microsoft.Web --wait
```

`--wait` blocks (~1 minute) until it reports `Registered`. You only do this once per lab
session -- but because the environment is recycled every ~4 hours into a **new** subscription,
you'll register again at the start of the next session.

### 1. Sign in and point Terraform at your subscription

Terraform reuses your `az login` session for auth, but the AzureRM provider needs to know
**which subscription** to use. Set it from your current login:

**PowerShell**
```powershell
az account show --query id -o tsv          # confirm you're logged in to the lab sub
$env:ARM_SUBSCRIPTION_ID = az account show --query id -o tsv
```

**bash / macOS / WSL**
```bash
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
```

### 2. Initialize

From this folder:

```bash
terraform init
```

Terraform downloads the AzureRM and random providers (recorded in `.terraform.lock.hcl`).

### 3. Preview the plan

```bash
terraform plan
```

Read the output: it should show **3 to add** (resource group, plan, web app) and **0 to
change / 0 to destroy**. Nothing is created yet — `plan` only previews.

### 4. Apply

```bash
terraform apply
```

Type `yes` when prompted. After ~1–2 minutes you'll see outputs, including:

```
app_url = "https://swat-hello-xxxxxx.azurewebsites.net"
```

### 5. Verify

Open `app_url` in a browser. The first request may take 20–60 seconds while the container
pulls and starts, then you'll see the hello-world page. You can also check from the CLI:

```bash
curl -I $(terraform output -raw app_url)     # expect HTTP/... 200
```

### 6. Clean up

```bash
terraform destroy
```

Type `yes`. This removes everything the lab created. (Even if you skip it, the 4-hour
vlabs cleanup will remove it — but always destroy your own resources when you're done.)

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Error: building account: could not... subscription ID` | You didn't set `ARM_SUBSCRIPTION_ID` (Step 1), or you're not logged in — re-run `az login`. |
| `SubscriptionNotFound` / auth errors | The lab environment was recycled. Restart it in vlabs, re-run `az login`, re-set `ARM_SUBSCRIPTION_ID`. |
| `RequestDisallowedByPolicy` | You changed `location` to a disallowed region. Use `eastus`, `eastus2`, or `canadacentral`. |
| Web page shows "Application Error" briefly | The container is still starting — wait ~1 minute and refresh. |
| `Name ... already taken` | Re-run `terraform apply` — the random suffix regenerates a unique name. |

## Try next (optional)

- Change `plan_sku` to `B2` in `terraform.tfvars`, run `terraform plan`, and see Terraform
  show an **in-place update** instead of a rebuild.
- Add a second app setting in `main.tf` and watch `plan` detect just that one change.
- Point `docker_image_name` at a different public image and re-apply.
