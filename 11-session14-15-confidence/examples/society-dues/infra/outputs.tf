output "app_url" {
  description = "Open it, or: curl <app_url>/health"
  value       = "https://${azurerm_container_app.app.ingress[0].fqdn}"
}

output "acr_name" {
  description = "For az acr login / az acr build."
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "Prefix for your image tag: <acr_login_server>/<app>:<tag>"
  value       = azurerm_container_registry.acr.login_server
}

output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "container_app" {
  value = azurerm_container_app.app.name
}
