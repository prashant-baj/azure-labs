output "app_url" {
  description = "Container App URL - open it / curl it; a 200 means the app host works."
  value       = "https://${azurerm_container_app.app.ingress[0].fqdn}"
}

output "acr_login_server" {
  description = "Container Registry login server (docker push target)."
  value       = azurerm_container_registry.acr.login_server
}

output "cosmos_endpoint" {
  description = "Cosmos DB (serverless) endpoint."
  value       = azurerm_cosmosdb_account.cosmos.endpoint
}

output "servicebus_namespace" {
  description = "Service Bus namespace."
  value       = azurerm_servicebus_namespace.sb.name
}

output "key_vault_uri" {
  description = "Key Vault URI."
  value       = azurerm_key_vault.kv.vault_uri
}

output "app_insights_connection_string" {
  description = "Application Insights connection string."
  value       = azurerm_application_insights.appi.connection_string
  sensitive   = true
}

output "stack_ok" {
  description = "If you can read this after apply, every service in the stack deployed."
  value       = "All services created in ${azurerm_resource_group.rg.name} (${var.location}). Run 'terraform destroy' to clean up."
}
