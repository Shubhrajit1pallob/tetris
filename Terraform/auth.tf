data "azuread_client_config" "current" {}
data "azurerm_client_config" "current" {

}

resource "azuread_application_federated_identity_credential" "github_infra_branch" {
  application_id = azuread_application.tetris_ad.id
  display_name   = "github-infra-branch"
  description    = "OIDC trust for GitHub Actions Infra branch"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:Shubhrajit1pallob/tetris:ref:refs/heads/infra"
}
resource "azuread_application_federated_identity_credential" "github_app_branch" {
  application_id = azuread_application.tetris_ad.id
  display_name   = "github-app-branch"
  description    = "OIDC trust for GitHub Actions App branch"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:Shubhrajit1pallob/tetris:ref:refs/heads/app"
}


resource "azuread_application" "tetris_ad" {
  display_name = "tetris-application"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_application_password" "tetris" {
  application_id = azuread_application.tetris_ad.id
  display_name   = "tetris-terraform-secret"
}

resource "azuread_service_principal" "tetris" {
  client_id = azuread_application.tetris_ad.client_id
}

resource "azurerm_role_assignment" "tetris-contributor" {
  scope                = azurerm_resource_group.tetris-project.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.tetris.object_id
}

data "azurerm_storage_account" "tfstate" {
  name                = var.tfstate_storage_account_name
  resource_group_name = var.tfstate_resource_group_name
}

resource "azurerm_role_assignment" "tetris_tfstate_blob_data" {
  scope                = data.azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.tetris.object_id
}