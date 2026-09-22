# =============================================================================
#  Junior SWAT Labs - Serverless Stack Smoke Test
#
#  Purpose: PROVE the intended lab stack actually deploys on the vlabs
#  subscription - because "allowed by policy" does not mean "has quota"
#  (App Service was allow-listed but had 0 compute quota).
#
#  Stands up one of each service the labs will rely on, all serverless /
#  consumption / managed (no dedicated-compute quota), all in an allowed region:
#    - Log Analytics + Application Insights   (observability)
#    - Container Registry (admin creds)       (image store)
#    - Container Apps env + app (public image)(app host + HTTP ingress)
#    - Cosmos DB (serverless)                 (data)
#    - Service Bus (Standard) + queue         (messaging/events)
#    - Key Vault                              (secrets)
#
#  If `terraform apply` succeeds and the app URL returns 200, the stack is
#  viable and we can design labs on it. Destroy immediately after.
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
  resource_provider_registrations = "none" # register the RPs once via az (see README)
  features {}
}

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  suffix = random_string.suffix.result
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-stack-smoke-rg"
  location = var.location
}

# ---- Observability ----------------------------------------------------------
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-law-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "appi" {
  name                = "${var.prefix}-appi-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
}

# ---- Image registry ---------------------------------------------------------
resource "azurerm_container_registry" "acr" {
  name                = "${var.prefix}acr${local.suffix}" # alphanumeric only
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true # Contributor can't create AcrPull role assignments; use admin creds
}

# ---- App host: Container Apps ------------------------------------------------
resource "azurerm_container_app_environment" "cae" {
  name                       = "${var.prefix}-cae-${local.suffix}"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}

resource "azurerm_container_app" "app" {
  name                         = "${var.prefix}-hello-${local.suffix}"
  container_app_environment_id = azurerm_container_app_environment.cae.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "hello"
      image  = "mcr.microsoft.com/k8se/quickstart:latest" # public hello image
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

# ---- Data: Cosmos DB (serverless) ------------------------------------------
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "${var.prefix}-cosmos-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }
}

# ---- Messaging: Service Bus -------------------------------------------------
resource "azurerm_servicebus_namespace" "sb" {
  name                = "${var.prefix}-sb-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "q" {
  name         = "smoke-queue"
  namespace_id = azurerm_servicebus_namespace.sb.id
}

# ---- Secrets: Key Vault -----------------------------------------------------
resource "azurerm_key_vault" "kv" {
  name                       = "${var.prefix}-kv-${local.suffix}"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
}
