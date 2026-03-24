#!/bin/bash
set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

RESOURCE_GROUP_NAME="terraform-rg01"
RANDOM_SUFFIX=$(openssl rand -hex 4)
STORAGE_ACCOUNT_NAME="tetris${RANDOM_SUFFIX}"
LOCATION="westcentralus"
CONTAINER_NAME="tfstate"

create_resources() {
    echo -e "${BLUE}Creating resource group: $RESOURCE_GROUP_NAME in $LOCATION${NC}"
    
    az group create \
    --name "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION"

    echo -e "${BLUE}Creating storage account: $STORAGE_ACCOUNT_NAME in $LOCATION${NC}"

    az storage account create \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false

    echo -e "${BLUE}Creating container: $CONTAINER_NAME in storage account: $STORAGE_ACCOUNT_NAME${NC}"

    az storage container create \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --auth-mode login
    # This block is not needed as terraform can use the OICD authentication to access the storage account

    # access_key=$(az storage account keys list \
    #   --resource-group "$RESOURCE_GROUP_NAME" \
    #   --account-name "$STORAGE_ACCOUNT_NAME" \
    #   --query "[0].value" -o tsv)
    # echo "ARM_ACCESS_KEY=$access_key" >> .env


    echo -e "${BLUE}Assigning Storage Blob Data Contributor role...${NC}"

    USER_ID=$(az ad signed-in-user show --query id -o tsv)

    STORAGE_ACCOUNT_ID=$(az storage account show \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query id -o tsv)

    az role assignment create \
    --role "Storage Blob Data Contributor" \
    --assignee "$USER_ID" \
    --scope "$STORAGE_ACCOUNT_ID"
}

destroy_resources() {
    echo -e "${BLUE}Destroying resource group: $RESOURCE_GROUP_NAME${NC}"
    
    az group delete \
    --name "$RESOURCE_GROUP_NAME" \
    --yes \
    --no-wait
}



main() {
    if [[ $# -eq 0 ]]; then
        echo -e "${YELLOW}Usage: $0 [create|destroy]${NC}"
        echo -e "${YELLOW}  create  - Create Azure resources (resource group, storage account, container)${NC}"
        echo -e "${YELLOW}  destroy - Destroy Azure resources${NC}"
        exit 1
    fi

    case "$1" in
        create)
            create_resources
            echo -e "${GREEN}✓ Resources created successfully${NC}"
            ;;
        destroy)
            destroy_resources
            echo -e "${GREEN}✓ Resources destroyed successfully${NC}"
            ;;
        *)
            echo -e "${RED}Error: Invalid option '$1'${NC}"
            echo -e "${YELLOW}Usage: $0 [create|destroy]${NC}"
            exit 1
            ;;
    esac
}

main "$@"