#!/usr/bin/env bash
set -euo pipefail

SUB_ID="de9e61cc-b888-49f7-985a-0f8e65ce6e3d"
APP_RG="tetris-tetris-rg"
AZURE_CLIENT_ID="961a32e7-d4ad-4cd5-a2db-2c35b48ab825"

RG="tetris-tetris-rg"
ACCOUNT="tetriscosmosdbacct01"
DB="tetrisdb"
CONTAINER="scores"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

az account set --subscription "$SUB_ID"

SP_OBJECT_ID=$(az ad sp show --id "$AZURE_CLIENT_ID" --query id -o tsv)
APP_RG_SCOPE="/subscriptions/$SUB_ID/resourceGroups/$APP_RG"

if ! az role assignment list \
  --assignee-object-id "$SP_OBJECT_ID" \
  --scope "$APP_RG_SCOPE" \
  --role "User Access Administrator" \
  --query "[0].id" -o tsv | grep -q .; then
  az role assignment create \
    --assignee-object-id "$SP_OBJECT_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "User Access Administrator" \
    --scope "$APP_RG_SCOPE"
else
  echo "Role already present: User Access Administrator on $APP_RG_SCOPE"
fi

cd "$REPO_ROOT"
terraform -chdir=Terraform init -backend=false >/dev/null

import_if_missing() {
  local address="$1"
  local resource_id="$2"

  if terraform -chdir=Terraform state list | grep -Fxq "$address"; then
    echo "Already in state: $address"
  else
    terraform -chdir=Terraform import "$address" "$resource_id"
  fi
}

import_if_missing \
  "azurerm_cosmosdb_account.tetris" \
  "/subscriptions/$SUB_ID/resourceGroups/$RG/providers/Microsoft.DocumentDB/databaseAccounts/$ACCOUNT"

import_if_missing \
  "azurerm_cosmosdb_sql_database.tetris" \
  "/subscriptions/$SUB_ID/resourceGroups/$RG/providers/Microsoft.DocumentDB/databaseAccounts/$ACCOUNT/sqlDatabases/$DB"

import_if_missing \
  "azurerm_cosmosdb_sql_container.scores" \
  "/subscriptions/$SUB_ID/resourceGroups/$RG/providers/Microsoft.DocumentDB/databaseAccounts/$ACCOUNT/sqlDatabases/$DB/containers/$CONTAINER"