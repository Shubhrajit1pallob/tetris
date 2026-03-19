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