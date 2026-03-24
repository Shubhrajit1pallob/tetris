data "azuread_client_config" "current" {}

variable "application_display_name" {
  description = "Display name for the Azure AD application"
  type        = string
  default     = "tetris-application"
}

variable "github_repository" {
  description = "GitHub repository in owner/name format"
  type        = string
  default     = "Shubhrajit1pallob/tetris"
}

variable "infra_branch" {
  description = "Branch allowed to run infra workflow"
  type        = string
  default     = "infra"
}

variable "app_branch" {
  description = "Branch allowed to run app workflow"
  type        = string
  default     = "app"
}

resource "azuread_application" "tetris_ad" {
  display_name = var.application_display_name
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "tetris" {
  client_id = azuread_application.tetris_ad.client_id
}

resource "azuread_application_federated_identity_credential" "github_infra_branch" {
  application_id = azuread_application.tetris_ad.id
  display_name   = "github-infra-branch"
  description    = "OIDC trust for GitHub Actions infra branch"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repository}:ref:refs/heads/${var.infra_branch}"
}

resource "azuread_application_federated_identity_credential" "github_app_branch" {
  application_id = azuread_application.tetris_ad.id
  display_name   = "github-app-branch"
  description    = "OIDC trust for GitHub Actions app branch"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repository}:ref:refs/heads/${var.app_branch}"
}
