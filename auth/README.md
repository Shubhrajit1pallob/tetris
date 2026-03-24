# Authentication Stack (Separate Terraform State)

This folder contains the dedicated Terraform stack for Azure AD / identity bootstrap.

## Why this stack is separate

- Keeps identity resources isolated from infra resources
- Reduces accidental changes to auth principals/credentials
- Uses a dedicated state file (`auth.tfstate`)

## State backend

Backend is configured via [backend.conf](backend.conf):

- same storage account/container as infra
- separate key: `auth.tfstate`

## Usage

From repository root:

```bash
terraform -chdir=auth init -backend-config=backend.conf
terraform -chdir=auth plan -var-file=terraform.tfvars.example
terraform -chdir=auth apply
```

## Optional variable overrides

Use [terraform.tfvars.example](terraform.tfvars.example) as a template:

```bash
cp auth/terraform.tfvars.example auth/terraform.tfvars
terraform -chdir=auth plan -var-file=terraform.tfvars
terraform -chdir=auth apply -var-file=terraform.tfvars
```

## Recommended workflow

1. Apply `auth` stack first
2. Capture outputs/secrets required by CI/CD
3. Apply infra stack in [Terraform](../Terraform) separately

## Notes

- `provider.tf` defines providers + backend stanza
- `auth.tf` is the place for Azure AD app/SP/OIDC resources
- Keep principal permissions least-privileged and review role assignments regularly