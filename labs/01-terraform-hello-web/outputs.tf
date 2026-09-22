output "website_url" {
  description = "Open this in a browser to see the hello-world page."
  value       = azurerm_storage_account.web.primary_web_endpoint
}

output "storage_account" {
  description = "Name of the storage account hosting the site."
  value       = azurerm_storage_account.web.name
}

output "resource_group" {
  description = "Resource group holding all lab resources."
  value       = azurerm_resource_group.rg.name
}
