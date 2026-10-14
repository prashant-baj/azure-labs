# One running component on Azure Container Apps - the stack the lab smoke test proved.
# Each resource says which line of your spec or ADR it serves: replace the TODOs with yours.

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

locals {
  name = "${var.prefix}-${var.app_name}"
  tags = { group = var.prefix, component = var.app_name, layer = "L3-working" }
}

# Holds everything for this component - delete the group and it is all gone.
resource "azurerm_resource_group" "rg" {
  name     = "${local.name}-rg"
  location = var.location
  tags     = local.tags
}

# Logs for the app (TODO: your NFR or operability line, e.g. "NFR-00x - we can see failures").
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "${local.name}-logs-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

# Where your image lives (TODO: your architecture-and-stack ADR line).
# admin_enabled: the lab role cannot create the AcrPull role assignment, so the app uses admin credentials.
resource "azurerm_container_registry" "acr" {
  name                = "${var.prefix}acr${random_string.suffix.result}" # letters and digits only
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
  tags                = local.tags
}

resource "azurerm_container_app_environment" "env" {
  name                       = "${local.name}-env"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  tags                       = local.tags
}

# The component itself (TODO: the plan section 12 line that names this component).
resource "azurerm_container_app" "app" {
  name                         = local.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  tags                         = local.tags

  # The registry password is a Container App secret - never in a file you commit.
  secret {
    name  = "acr-password"
    value = azurerm_container_registry.acr.admin_password
  }

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = var.app_name
      image  = var.image
      cpu    = 0.25
      memory = "0.5Gi"

      dynamic "env" {
        for_each = var.settings
        content {
          name  = env.key
          value = env.value
        }
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = var.target_port
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
