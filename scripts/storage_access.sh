#!/usr/bin/env bash
set -euo pipefail

AZURE_CLIENT_ID="961a32e7-d4ad-4cd5-a2db-2c35b48ab825"
AZURE_SUBSCRIPTION_ID="de9e61cc-b888-49f7-985a-0f8e65ce6e3d"
TFSTATE_RESOURCE_GROUP="terraform-rg01"
TFSTATE_STORAGE_ACCOUNT="tetrisec788fda"

az account set --subscription "$AZURE_SUBSCRIPTION_ID"

SP_OBJECT_ID=$(az ad sp show --id "$AZURE_CLIENT_ID" --query id -o tsv)
RG_SCOPE="/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$TFSTATE_RESOURCE_GROUP"
STORAGE_SCOPE=$(az storage account show -g "$TFSTATE_RESOURCE_GROUP" -n "$TFSTATE_STORAGE_ACCOUNT" --query id -o tsv)

ensure_role() {
  local role="$1" scope="$2"
  if ! az role assignment list --assignee-object-id "$SP_OBJECT_ID" --scope "$scope" --role "$role" --query "[0].id" -o tsv | grep -q .; then
    az role assignment create --assignee-object-id "$SP_OBJECT_ID" --assignee-principal-type ServicePrincipal --role "$role" --scope "$scope"
  fi
}

ensure_role "Reader" "$RG_SCOPE"
ensure_role "User Access Administrator" "$RG_SCOPE"
ensure_role "Storage Blob Data Contributor" "$STORAGE_SCOPE"