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