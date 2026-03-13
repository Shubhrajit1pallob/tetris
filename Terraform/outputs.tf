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
