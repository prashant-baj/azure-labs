# =============================================================================
#  Junior SWAT Labs - 01 - Hello-World Web App with Terraform
#  Deploys a static website on Azure Storage and publishes an index.html page.
#  Chosen because the lab subscription has zero dedicated-compute quota
#  (App Service / VM), whereas Storage static hosting needs no compute quota.
#  Stays inside the vlabs policy: region eastus, allowed resource types, no VMs.
# =============================================================================

terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  # Don't let Terraform bulk-register every resource provider (slow, and it may
  # exceed lab permissions). Register the one we need once, up front:
  #   az provider register --namespace Microsoft.Storage --wait
  # (see README Step 0).
  resource_provider_registrations = "none"

  # Auth comes from your `az login` session; subscription id from
  # the ARM_SUBSCRIPTION_ID environment variable (see the README).
  features {}
}

# A short random suffix keeps the globally-unique storage account name unique.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-hello-web-rg"
  location = var.location
}

# Storage account to host the site.
resource "azurerm_storage_account" "web" {
  name                     = "${var.prefix}web${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Turn on the "static website" feature. This creates the special "$web"
# container that is served over HTTP(S).
resource "azurerm_storage_account_static_website" "web" {
  storage_account_id = azurerm_storage_account.web.id
  index_document     = "index.html"
  error_404_document = "index.html"
}

# The hello-world page itself, uploaded by Terraform into the "$web" container.
resource "azurerm_storage_blob" "index" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.web.name
  storage_container_name = "$web" # the container the static-website feature creates
  type                   = "Block"
  content_type           = "text/html"
  depends_on             = [azurerm_storage_account_static_website.web]

  source_content = <<-HTML
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Hello from Terraform</title>
        <style>
          body { font-family: system-ui, sans-serif; background:#0f172a; color:#e2e8f0;
                 display:grid; place-items:center; height:100vh; margin:0; text-align:center; }
          h1 { font-size: 2.5rem; margin: 0 0 .5rem; }
          p  { color:#94a3b8; }
          code { color:#7dd3fc; }
        </style>
      </head>
      <body>
        <div>
          <h1>Hello, world! 👋</h1>
          <p>This page was deployed to Azure Storage with <code>terraform apply</code>.</p>
        </div>
      </body>
    </html>
  HTML
}
