output "app_url" {
  description = "Open this in a browser to see the hello-world page."
  value       = "https://${azurerm_linux_web_app.app.default_hostname}"
}

output "app_name" {
  description = "Name of the deployed web app."
  value       = azurerm_linux_web_app.app.name
}

output "resource_group" {
  description = "Resource group holding all lab resources."
  value       = azurerm_resource_group.rg.name
}
