# Tetris Infrastructure Bootstrap Guide

This guide explains how to set up the Tetris project infrastructure from scratch, including GitHub Actions OIDC authentication and Terraform state management.

## Prerequisites

- Azure CLI (`az`) installed and configured
- Terraform >= 1.5.0
- GitHub repository with Actions enabled
- Admin or `User Access Administrator` role in the Azure subscription

## Architecture Overview

The setup uses **GitHub OIDC Federation** to authenticate Azure Actions without storing long-lived secrets:

```
GitHub Actions (infra/app branch)
         ↓ (OIDC token)
GitHub Token Service (token.actions.githubusercontent.com)
         ↓ (federated)
Azure AD Workload Identity
         ↓
Terraform → Azure Resources (AKS, Cosmos, ACR)
```

## Bootstrap Steps

### Step 1: Create Terraform Backend Storage

Backend storage is created **outside** the main Terraform stack to avoid state bootstrapping circular dependencies.

```bash
#!/bin/bash
# Create resource group
az group create --name terraform-rg01 --location westcentralus

# Create storage account (must have random suffix for global uniqueness)
RANDOM_SUFFIX=$(openssl rand -hex 4)
STORAGE_ACCOUNT="tetris${RANDOM_SUFFIX}"
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group terraform-rg01 \
  --location westcentralus \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# Create tfstate container
az storage container create \
  --name tfstate \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login

echo "Storage account created: $STORAGE_ACCOUNT"
```

**OR use the provided script:**
```bash
./scripts/azure_storage_account.sh create
```

Save the storage account name for Step 3 (used as `TFSTATE_STORAGE_ACCOUNT` secret).

### Step 2: Create Azure AD Application & Service Principal

```bash
# Create Azure AD application
APP_ID=$(az ad app create --display-name "tetris-application" --query appId -o tsv)

# Create service principal
SP_ID=$(az ad sp create --id "$APP_ID" --query id -o tsv)
SP_CLIENT_ID=$(az ad sp show --id "$SP_ID" --query appId -o tsv)

echo "Application ID: $APP_ID"
echo "Service Principal ID: $SP_ID"
echo "Client ID (for AZURE_CLIENT_ID secret): $SP_CLIENT_ID"
```

### Step 3: Create GitHub OIDC Federated Credentials

GitHub OIDC federation allows Actions to authenticate without secrets. Create one for each branch:

```bash
# For 'infra' branch (infrastructure deployments)
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters '{
    "name": "github-infra-branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:Shubhrajit1pallob/tetris:ref:refs/heads/infra",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# For 'app' branch (app deployments)
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters '{
    "name": "github-app-branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:Shubhrajit1pallob/tetris:ref:refs/heads/app",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### Step 4: Grant RBAC Permissions

Grant the service principal permissions needed for deployments:

```bash
# Get the service principal object ID
SP_OBJECT_ID=$(az ad sp show --id "$SP_CLIENT_ID" --query id -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Get resource group and storage account IDs
APP_RG="tetris-tetris-rg"  # Will be created by Terraform
TFSTATE_RG="terraform-rg01"
STORAGE_ACCOUNT="tetrisec788fda"  # From Step 1

APP_RG_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$APP_RG"
TFSTATE_RG_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$TFSTATE_RG"
STORAGE_SCOPE=$(az storage account show -g "$TFSTATE_RG" -n "$STORAGE_ACCOUNT" --query id -o tsv)

# Grant permissions
# App RG: manage all infra resources (AKS, Cosmos, ACR)
az role assignment create \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Contributor" \
  --scope "$APP_RG_SCOPE"

# Tfstate RG: read storage account metadata
az role assignment create \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Reader" \
  --scope "$TFSTATE_RG_SCOPE"

# Storage account: read/write tfstate blobs
az role assignment create \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "$STORAGE_SCOPE"
```

**OR use the provided script:**
```bash
./scripts/storage_access.sh
```

### Step 5: Configure GitHub Secrets

Set these secrets in your GitHub repository (Settings → Secrets and variables → Actions):

| Secret Name | Value |
|---|---|
| `AZURE_CLIENT_ID` | Service principal client ID from Step 2 |
| `AZURE_TENANT_ID` | `az account show --query tenantId -o tsv` |
| `AZURE_SUBSCRIPTION_ID` | `az account show --query id -o tsv` |
| `TFSTATE_RESOURCE_GROUP` | `terraform-rg01` |
| `TFSTATE_STORAGE_ACCOUNT` | Storage account name from Step 1 |
| `TFSTATE_CONTAINER` | `tfstate` |
| `ACR_NAME` | Will be created by Terraform (leave for now) |

### Step 6: Deploy Infrastructure

Now you can deploy the main infrastructure:

```bash
# Initialize Terraform
terraform -chdir=Terraform init \
  -backend-config="resource_group_name=terraform-rg01" \
  -backend-config="storage_account_name=tetrisec788fda" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=terraform.tfstate"

# Plan the deployment
terraform -chdir=Terraform plan \
  -var="tfstate_storage_account_name=tetrisec788fda" \
  -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)" \
  -out=tfplan

# Apply resources
terraform -chdir=Terraform apply tfplan
```

### Step 7: Push & Verify CI/CD

```bash
# Commit changes
git add Terraform/ .github/
git commit -m "Infra: bootstrap AKS, Cosmos, ACR"

# Push to infra branch
git push origin infra

# Monitor GitHub Actions workflow (infra-ci)
# Should complete with plan > apply
```

## After Bootstrap: Managing the Stack

Once bootstrapped:

- **Azure AD resources** (app, service principal, OIDC credentials):
  - Created once, managed **outside** Terraform
  - Reason: Avoids ABAC role assignment restrictions in CI/CD identity
  
- **Infrastructure resources** (AKS, Cosmos, ACR):
  - Managed by Terraform normally
  - Deployed via GitHub Actions on push to `infra` branch
  
- **State file**:
  - Stored in `terraform-rg01/tetrisec788fda/tfstate/terraform.tfstate`
  - Locked via Blob Storage lease

## Troubleshooting

### OIDC Token Exchange Fails
**Error**: `AADSTS700213: No matching federated identity record found`

**Solution**: Verify federated credentials match branch names:
```bash
az ad app federated-credential list --id <app-id>
# Check that 'subject' matches exactly:
#   repo:Shubhrajit1pallob/tetris:ref:refs/heads/infra
```

### Storage Account Access Denied (403)
**Error**: `Microsoft.Storage/storageAccounts/read` or `roleAssignments/read`

**Solution**: Ensure service principal has enough permissions:
```bash
az role assignment list --assignee-object-id $SP_OBJECT_ID --all
# Should show: Contributor, Reader, Storage Blob Data Contributor
```

### State Locking Issues
**Error**: Terraform plan/apply hangs or times out

**Solution**: Release lock manually:
```bash
# Connect to storage account and delete lock blob
az storage blob delete --container-name tfstate \
  --name terraform.tfstate.lock \
  --account-name tetrisec788fda
```

## Security Best Practices

✅ **Do:**
- Use OIDC federation (no long-lived secrets stored)
- Use separate RBAC for backend access vs. app resources
- Enable Azure Policy (`azure_policy_enabled = true` in AKS)
- Restrict network access (future: private clusters, private endpoints)
- Regularly audit role assignments

❌ **Don't:**
- Store Azure credentials in git
- Use `admin_enabled = true` on ACR (use managed identity instead)
- Deploy with overly broad permissions (principle of least privilege)
- Reuse credentials across projects

## References

- [GitHub Actions: Azure Login with OIDC](https://learn.microsoft.com/entra/workload-id/workload-identity-federation)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Kubernetes Service Security](https://learn.microsoft.com/azure/aks/concepts-security)
