output "app_url" {
  description = "The deployed test app."
  value       = "https://${azurerm_container_app.app.ingress[0].fqdn}"
}

output "resource_group" {
  value = azurerm_resource_group.rg.name
}
