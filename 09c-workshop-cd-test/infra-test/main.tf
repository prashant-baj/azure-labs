# The smallest useful test deployment: one resource group, one storage account serving one
# static page. No compute, nothing to pay for by the hour, ready in about a minute.
# The page names the commit and pipeline that deployed it - that is the whole test.

data "azurerm_client_config" "current" {}

locals {
  # Storage account names are global across Azure: add 8 characters unique to this subscription.
  suffix = substr(sha1("${data.azurerm_client_config.current.subscription_id}-${var.prefix}"), 0, 8)
  tags = {
    purpose    = "cd-test"
    managed_by = "gitlab-ci"
    project    = var.project
    commit     = var.commit
  }
}

resource "azurerm_resource_group" "test" {
  name     = "rg-${var.prefix}-cdtest"
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "site" {
  name                            = "st${var.prefix}${local.suffix}" # 3-24 lowercase letters and digits
  resource_group_name             = azurerm_resource_group.test.name
  location                        = azurerm_resource_group.test.location
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false # the static website still works; containers stay private
  tags                            = local.tags
}

resource "azurerm_storage_account_static_website" "site" {
  storage_account_id = azurerm_storage_account.site.id
  index_document     = "index.html"
  error_404_document = "index.html"
}

resource "azurerm_storage_blob" "index" {
  name                 = "index.html"
  storage_container_id = "${azurerm_storage_account.site.id}/blobServices/default/containers/$web" # made by the static website
  type                 = "Block"
  content_type         = "text/html; charset=utf-8"
  source_content = templatefile("${path.module}/site/index.html.tftpl", {
    project      = var.project
    commit       = var.commit
    message      = var.message
    pipeline_url = var.pipeline_url
  })
  depends_on = [azurerm_storage_account_static_website.site]
}
