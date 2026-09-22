# Lab 01 · Hello-World Web App with Terraform

Deploy a live web page to Azure using **Terraform** — no portal clicking. You'll run the
Terraform workflow (`init → plan → apply → destroy`) against a small configuration and get
a public URL at the end. Terraform even uploads the page content itself.

**Time:** ~15 minutes · **Cost:** a few cents of storage, torn down at the end.

> **Why a static website (and not an App Service or VM)?** The lab subscription has **zero
> dedicated-compute quota** — Basic App Service plans and B-series VMs both come back with
> `quota 0`. Azure Storage static hosting needs no compute quota, so it deploys reliably for
> everyone. See [`../../lab-constraints.md`](../../lab-constraints.md).

## What you'll build

```
Resource Group
  └── Storage Account
        ├── Static website feature (creates the "$web" container, served over HTTPS)
        └── index.html  ◀── uploaded by Terraform
```

Everything lives in **eastus** and uses only resource types the lab policy allows.

## Learning goals

- The core Terraform loop: `init`, `plan`, `apply`, `destroy`.
- How providers, resources, variables and outputs fit together.
- Using Terraform to deploy **content** (an HTML file), not just infrastructure.
- How Terraform authenticates to Azure through your `az` CLI session.

## Prerequisites

- Ran **`prereqs-check`** (Terraform, Azure CLI installed).
- Ran **`00-access-check`** and signed in — i.e. `az login` is done and the lab
  subscription is active. Start the lab environment in vlabs first if it was recycled.

## Files

| File | Purpose |
|------|---------|
| `main.tf` | Provider + resources (resource group, storage account, static-website, the HTML blob). |
| `variables.tf` | Inputs (`prefix`, `location`) with defaults and validation. |
| `outputs.tf` | Prints the website URL after apply. |
| `terraform.tfvars.example` | Optional: copy to `terraform.tfvars` to override defaults. |
| `.terraform.lock.hcl` | Pins provider versions so everyone gets the same ones. |

## Steps

### 0. Register the Storage resource provider (once per lab session)

A freshly-provisioned lab subscription hasn't registered the `Microsoft.Storage` resource
provider yet, so the first deployment would fail with `MissingSubscriptionRegistration`.
Register it once (your Contributor role allows this):

```bash
az provider register --namespace Microsoft.Storage --wait
```

`--wait` blocks (~1 minute) until it reports `Registered`. You only do this once per lab
session — but because the environment is recycled every ~4 hours into a **new** subscription,
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

```bash
terraform init
```

Terraform downloads the AzureRM and random providers (recorded in `.terraform.lock.hcl`).

### 3. Preview the plan

```bash
terraform plan
```

It should show **4 to add** (resource group, storage account, static-website setting, the
HTML blob) and **0 to change / 0 to destroy**. `plan` only previews — nothing is created yet.

### 4. Apply

```bash
terraform apply
```

Type `yes`. After ~30–60 seconds you'll see outputs, including:

```
website_url = "https://swatwebxxxxxx.z13.web.core.windows.net/"
```

### 5. Verify

Open `website_url` in a browser — you'll see the hello-world page. Or from the CLI:

```bash
curl -I $(terraform output -raw website_url)     # expect HTTP/... 200
```

### 6. Clean up

```bash
terraform destroy
```

Type `yes`. (Even if you skip it, the 4-hour vlabs cleanup removes everything — but always
destroy your own resources when you're done.)

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `MissingSubscriptionRegistration ... 'Microsoft.Storage'` | You skipped Step 0. Run `az provider register --namespace Microsoft.Storage --wait`, then `terraform apply` again. |
| `Error: building account: could not... subscription ID` | You didn't set `ARM_SUBSCRIPTION_ID` (Step 1), or you're not logged in — re-run `az login`. |
| `SubscriptionNotFound` / auth errors | The lab environment was recycled. Restart it in vlabs, re-run `az login`, re-set `ARM_SUBSCRIPTION_ID`. |
| `RequestDisallowedByPolicy` | You changed `location` to a disallowed region. Use `eastus`, `eastus2`, or `canadacentral`. |
| Storage account name error | The name must be globally unique; re-run `terraform apply` and the random suffix regenerates. |
| Page shows the 404 doc | The blob may still be uploading — wait a few seconds and refresh. |

## Try next (optional)

- Edit the HTML in `main.tf` (the `source_content`) and re-`apply` — Terraform detects just
  the blob change and re-uploads it.
- Add a second page (another `azurerm_storage_blob`, e.g. `about.html`) and browse to it.
- Point `error_404_document` at a custom `404.html` you also upload.
