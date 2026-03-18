output "acr_name" {
  description = "Azure Container Registry name for CI login"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "Azure Container Registry login server used for docker tag/push"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_id" {
  description = "Azure Container Registry resource ID for role assignments"
  value       = azurerm_container_registry.acr.id
}


output "app-password" {
  value     = azuread_application_password.tetris.value
  sensitive = true
}

output "client-id" {
  value = azuread_application.tetris_ad.client_id
}

output "tenant-id" {
  value = data.azuread_client_config.current.tenant_id
}

output "subscription-id" {
  value = data.azurerm_client_config.current.subscription_id
}

output "service_principal_id" {
  value = azuread_service_principal.tetris.object_id
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.tetris.name
}

output "aks_resource_group" {
  description = "Resource group hosting AKS"
  value       = azurerm_resource_group.tetris-project.name
}

output "cosmos_endpoint" {
  description = "Cosmos DB endpoint for score API"
  value       = azurerm_cosmosdb_account.tetris.endpoint
}

output "cosmos_database_name" {
  description = "Cosmos SQL database name"
  value       = azurerm_cosmosdb_sql_database.tetris.name
}

output "cosmos_container_name" {
  description = "Cosmos SQL container name"
  value       = azurerm_cosmosdb_sql_container.scores.name
}