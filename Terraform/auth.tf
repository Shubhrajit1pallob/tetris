# ╔════════════════════════════════════════════════════════════════════════════════╗
# ║ BOOTSTRAP: Azure AD & GitHub OIDC Authentication Setup                          ║
# ╚════════════════════════════════════════════════════════════════════════════════╝
#
# IMPORTANT: These resources are BOOTSTRAPPED ONE-TIME ONLY and managed OUTSIDE
# this Terraform stack. This separation prevents permission escalation issues and
# simplifies CI/CD deployments.
#
# ┌─ FIRST-TIME SETUP (run locally with admin credentials) ──────────────────────┐
# │                                                                               │
# │ 1. Uncomment all resources below                                             │
# │                                                                               │
# │ 2. Apply ONLY auth resources using targeted apply:                           │
# │    $ terraform -chdir=Terraform apply \                                     │
# │        -target=azuread_application.tetris_ad \                              │
# │        -target=azuread_service_principal.tetris \                           │
# │        -target=azuread_application_federated_identity_credential.* \         │
# │        -target=azurerm_role_assignment.tetris_*                             │
# │                                                                               │
# │ 3. After successful apply, grant additional RBAC manually (or use script):   │
# │    $ ./scripts/storage_access.sh                                            │
# │                                                                               │
# │ 4. Run state removal to detach from Terraform:                              │
# │    $ ./scripts/azuread_rm_state.sh                                          │
# │                                                                               │
# │ 5. Comment out all resources below again (keep commented for CI/CD)         │
# │                                                                               │
# │ 6. Now run full 'terraform apply' for infra resources (AKS, Cosmos, ACR)    │
# │                                                                               │
# └───────────────────────────────────────────────────────────────────────────────┘
#
# ┌─ KEY ARTIFACTS CREATED ────────────────────────────────────────────────────────┐
# │                                                                               │
# │ After bootstrap, these exist in Azure (NOT managed by Terraform):            │
# │  • Azure AD Application (tetris-application)                                 │
# │  • Service Principal (client_id: from AZURE_CLIENT_ID secret)               │
# │  • Federated Identity Credentials (GitHub OIDC trust for app & infra branches)
# │  • Role assignments granting SP access to app RG and tfstate storage        │
# │                                                                               │
# │ GitHub Actions environment needs these secrets set:                          │
# │  • AZURE_CLIENT_ID       <- Application/service principal client ID         │
# │  • AZURE_TENANT_ID       <- Organization tenant ID                          │
# │  • AZURE_SUBSCRIPTION_ID <- Subscription to deploy into                     │
# │  • TFSTATE_RESOURCE_GROUP <- (default: terraform-rg01)                      │
# │  • TFSTATE_STORAGE_ACCOUNT <- (default: tetrisec788fda)                     │
# │  • TFSTATE_CONTAINER     <- (default: tfstate)                              │
# │                                                                               │
# └───────────────────────────────────────────────────────────────────────────────┘
#
# IMPORTANT: If remanaging auth resources, uncomment and use 'terraform import'
# to bind existing Azure resources back to this config. See commented resources
# below for import commands.

# locals {
#   tfstate_rg_scope      = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.tfstate_resource_group_name}"
#   tfstate_storage_scope = "${local.tfstate_rg_scope}/providers/Microsoft.Storage/storageAccounts/${var.tfstate_storage_account_name}"
# }
#
# data "azuread_client_config" "current" {}
# data "azurerm_client_config" "current" {}
#
# data "azurerm_storage_account" "tfstate" {
#   name                = var.tfstate_storage_account_name
#   resource_group_name = var.tfstate_resource_group_name
# }
#
# resource "azuread_application_federated_identity_credential" "github_infra_branch" {
#   application_id = azuread_application.tetris_ad.id
#   display_name   = "github-infra-branch"
#   description    = "OIDC trust for GitHub Actions Infra branch"
#   audiences      = ["api://AzureADTokenExchange"]
#   issuer         = "https://token.actions.githubusercontent.com"
#   subject        = "repo:Shubhrajit1pallob/tetris:ref:refs/heads/infra"
# }
#
# resource "azuread_application_federated_identity_credential" "github_app_branch" {
#   application_id = azuread_application.tetris_ad.id
#   display_name   = "github-app-branch"
#   description    = "OIDC trust for GitHub Actions App branch"
#   audiences      = ["api://AzureADTokenExchange"]
#   issuer         = "https://token.actions.githubusercontent.com"
#   subject        = "repo:Shubhrajit1pallob/tetris:ref:refs/heads/app"
# }
#
# resource "azuread_application" "tetris_ad" {
#   display_name = "tetris-application"
#   owners       = [data.azuread_client_config.current.object_id]
# }
#
# resource "azuread_application_password" "tetris" {
#   application_id = azuread_application.tetris_ad.id
#   display_name   = "tetris-terraform-secret"
# }
#
# resource "azuread_service_principal" "tetris" {
#   client_id = azuread_application.tetris_ad.client_id
# }
#
# resource "azurerm_role_assignment" "tetris-contributor" {
#   scope                = azurerm_resource_group.tetris-project.id
#   role_definition_name = "Contributor"
#   principal_id         = azuread_service_principal.tetris.object_id
# }
#
# resource "azurerm_role_assignment" "tetris_tfstate_blob_data" {
#   scope                = local.tfstate_storage_scope
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azuread_service_principal.tetris.object_id
# }
#
# resource "azurerm_role_assignment" "tetris_contributor_app_rg" {
#   scope                = azurerm_resource_group.tetris-project.id
#   role_definition_name = "Contributor"
#   principal_id         = azuread_service_principal.tetris.object_id
# }
#
# resource "azurerm_role_assignment" "tetris_uua_app_rg" {
#   scope                = azurerm_resource_group.tetris-project.id
#   role_definition_name = "User Access Administrator"
#   principal_id         = azuread_service_principal.tetris.object_id
# }
#
# resource "azurerm_role_assignment" "tetris_reader_tfstate_rg" {
#   scope                = local.tfstate_rg_scope
#   role_definition_name = "Reader"
#   principal_id         = azuread_service_principal.tetris.object_id
# }
#
# resource "azurerm_role_assignment" "tetris_uua_tfstate_rg" {
#   scope                = local.tfstate_rg_scope
#   role_definition_name = "User Access Administrator"
#   principal_id         = azuread_service_principal.tetris.object_id
# }