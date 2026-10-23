output "site_url" {
  description = "The test page - the pipeline checks it shows this commit."
  value       = azurerm_storage_account.site.primary_web_endpoint
}

output "resource_group" {
  value = azurerm_resource_group.test.name
}

output "storage_account" {
  value = azurerm_storage_account.site.name
}
