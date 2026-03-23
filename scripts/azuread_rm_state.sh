#!/usr/bin/env bash
set -euo pipefail

TF_DIR="../Terraform"

remove_if_present() {
	local address="$1"
	if terraform -chdir="$TF_DIR" state list | grep -Fxq "$address"; then
		terraform -chdir="$TF_DIR" state rm "$address"
	else
		echo "Skipping (not in state): $address"
	fi
}

# Remove Azure AD resources from state (one-time bootstrap complete)
remove_if_present "azuread_application.tetris_ad"
remove_if_present "azuread_application_password.tetris"
remove_if_present "azuread_service_principal.tetris"
remove_if_present "azuread_application_federated_identity_credential.github_infra_branch"
remove_if_present "azuread_application_federated_identity_credential.github_app_branch"
remove_if_present "data.azuread_client_config.current"
remove_if_present "data.azurerm_storage_account.tfstate"

# Remove auth-related role assignments
remove_if_present "azurerm_role_assignment.tetris-contributor"
remove_if_present "azurerm_role_assignment.tetris_tfstate_blob_data"
remove_if_present "azurerm_role_assignment.tetris_contributor_app_rg"
remove_if_present "azurerm_role_assignment.tetris_uua_app_rg"
remove_if_present "azurerm_role_assignment.tetris_reader_tfstate_rg"
remove_if_present "azurerm_role_assignment.tetris_uua_tfstate_rg"