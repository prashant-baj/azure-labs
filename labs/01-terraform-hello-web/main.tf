# =============================================================================
#  Junior SWAT Labs - 01 - Hello-World Web App with Terraform
#  Deploys an Azure App Service (Linux) running a hello-world container.
#  Stays inside the vlabs policy: region eastus, no VMs, allowed resource types.
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
  # exceed lab permissions). Instead register the one we need once, up front:
  #   az provider register --namespace Microsoft.Web --wait
  # (see README Step 0).
  resource_provider_registrations = "none"

  # Auth comes from your `az login` session. The subscription id is read from
  # the ARM_SUBSCRIPTION_ID environment variable (see the README).
  features {}
}

# A short random suffix keeps the globally-unique web app name collision-free.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-hello-web-rg"
  location = var.location
}

resource "azurerm_service_plan" "plan" {
  name                = "${var.prefix}-hello-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = var.plan_sku
}

resource "azurerm_linux_web_app" "app" {
  name                = "${var.prefix}-hello-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.plan.location
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = true

  site_config {
    always_on = true

    # Run a ready-made hello-world web container from Microsoft Container
    # Registry (public, no login needed).
    application_stack {
      docker_image_name   = "azuredocs/aci-helloworld:latest"
      docker_registry_url = "https://mcr.microsoft.com"
    }
  }

  app_settings = {
    # The hello-world container listens on port 80.
    WEBSITES_PORT = "80"
  }
}
