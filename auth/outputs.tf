data "azurerm_client_config" "current" {}

output "azure_client_id" {
  description = "Set as GitHub secret: AZURE_CLIENT_ID"
  value       = azuread_application.tetris_ad.client_id
}

output "azure_tenant_id" {
  description = "Set as GitHub secret: AZURE_TENANT_ID"
  value       = data.azurerm_client_config.current.tenant_id
}

output "azure_subscription_id" {
  description = "Set as GitHub secret: AZURE_SUBSCRIPTION_ID"
  value       = data.azurerm_client_config.current.subscription_id
}

output "service_principal_object_id" {
  description = "Service principal object ID used for RBAC assignments"
  value       = azuread_service_principal.tetris.object_id
}

output "github_actions_auth_secrets" {
  description = "Copy these values into GitHub Actions repository secrets"
  value = {
    AZURE_CLIENT_ID       = azuread_application.tetris_ad.client_id
    AZURE_TENANT_ID       = data.azurerm_client_config.current.tenant_id
    AZURE_SUBSCRIPTION_ID = data.azurerm_client_config.current.subscription_id
  }
}