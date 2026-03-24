# Tetris Game | DevOps Deployment Journey

This repository tracks a staged DevOps journey using a web-based Tetris game.

The current README documents only what is completed right now. New sections will be added as each stage is implemented.

## Current Progress

- [x] Game application setup and local run instructions
- [x] Networking & Cloud (Azure infrastructure)
- [x] CI/CD + Security
- [x] IaC & Containerization
- [x] Kubernetes manifests and infrastructure
- [ ] Deploy Tetris App to AKS Cluster
- [ ] Observability & GitOps

## Stage Completed: Game Application Setup

The game source lives in [tetris-master](tetris-master).

Key app paths:

- Main entry page: [tetris-master/index.html](tetris-master/index.html)
- Source code: [tetris-master/src](tetris-master/src)
- Static/build assets: [tetris-master/public](tetris-master/public)
- Node scripts and dependencies: [tetris-master/package.json](tetris-master/package.json)

## Run Locally

From the [tetris-master](tetris-master) folder:

1. Install dependencies

	npm install

2. Start local server

	npm start

3. Open in browser

	http://localhost:8080

The start script uses http-server with cache disabled for local development.

## Repository Structure (Current)

- [tetris-master](tetris-master): web game code, assets, and Dockerfile
- [score-api](score-api): FastAPI backend for leaderboard/score management
- [Terraform](Terraform): Azure infrastructure as code (AKS, ACR, Cosmos DB, etc.)
- [k8s](k8s): Kubernetes deployment manifests (deployments, services, ingress, HPA)
- [.github/workflows](.github/workflows): CI/CD pipelines for app and infrastructure
- [scripts](scripts): Operational automation scripts

## Stage 2: Containerization

Both frontend and backend applications are containerized and pushed to Azure Container Registry (ACR).

### Frontend (Tetris Game)

- Dockerfile: [tetris-master/Dockerfile](tetris-master/Dockerfile)
- Build: Node.js app build → Nginx multi-stage with Chainguard base image (security hardening)
- Docker ignore: [tetris-master/.dockerignore](tetris-master/.dockerignore)
- Registry: Azure Container Registry (ACR)

### Backend (Score API)

- Dockerfile: [score-api/Dockerfile](score-api/Dockerfile)
- Runtime: Python 3.12 FastAPI with uvicorn on port 8000
- Database: Azure Cosmos DB (serverless, SQL API)

## Stage 3: Infrastructure as Code (IaC)

Complete Azure infrastructure defined in Terraform in [Terraform/](Terraform/):

### Core Resources

- **Resource Group**: [rg.tf](Terraform/rg.tf)
- **Azure Kubernetes Service (AKS)**: [aks.tf](Terraform/aks.tf) with system node pool, Log Analytics integration, and Azure Policy
- **Azure Container Registry (ACR)**: [container.tf](Terraform/container.tf)
- **Cosmos DB**: [cosmos.tf](Terraform/cosmos.tf) serverless account for score persistence
- **Azure AD Integration**: [auth/auth.tf](auth/auth.tf) - dedicated auth stack for service principal and GitHub OIDC federation
- **Backend State**: [backend.conf](Terraform/backend.conf) - Azure remote state management
- **Variables & Outputs**: [variables.tf](Terraform/variables.tf), [outputs.tf](Terraform/outputs.tf)

Initialize with:

```bash
cd Terraform
terraform init -backend-config=backend.conf
terraform plan -var-file=score-api.auto.tfvars
terraform apply
```

See [BOOTSTRAP.md](BOOTSTRAP.md) for detailed setup steps including GitHub OIDC federation.

## Stage 4: Kubernetes

Production-ready Kubernetes manifests in [k8s/](k8s/):

### Application Deployment

- **Namespace**: [score-api-namespace.yaml](k8s/score-api-namespace.yaml) - isolated `score-api` namespace
- **Deployment**: [score-api-deployment.yaml](k8s/score-api-deployment.yaml) - 2+ replicas with liveness/readiness probes
- **Service**: [score-api-service.yaml](k8s/score-api-service.yaml) - ClusterIP service (port 80→8000)
- **Horizontal Pod Autoscaler (HPA)**: [score-api-hpa.yaml](k8s/score-api-hpa.yaml) - scales 2–6 replicas based on CPU (70% threshold)
- **ConfigMap**: [score-api-configmap.yaml](k8s/score-api-configmap.yaml) - configuration management
- **Secret (template)**: [score-api-secret.example.yaml](k8s/score-api-secret.example.yaml)

### Traffic Management

- **Ingress**: [score-api-ingress.yaml](k8s/score-api-ingress.yaml) - Nginx ingress controller with domain-based routing

Deploy to AKS:

```bash
kubectl apply -f k8s/
```

## Stage 4.5: Deploy Tetris App to AKS Cluster

Execute the deployment of the containerized Tetris frontend and Score API backend to your AKS cluster.

### Prerequisites

- AKS cluster running (provisioned via [Stage 3: IaC](Terraform/))
- Container images built and pushed to ACR
- `kubectl` configured to access the AKS cluster
- Kubernetes manifests in [k8s/](k8s/) directory

### Deployment Steps

1. **Deploy Score API backend** to the `score-api` namespace:

```bash
kubectl apply -f k8s/score-api-namespace.yaml
kubectl apply -f k8s/score-api-configmap.yaml
kubectl apply -f k8s/score-api-secret.example.yaml  # Configure with actual secrets
kubectl apply -f k8s/score-api-deployment.yaml
kubectl apply -f k8s/score-api-service.yaml
kubectl apply -f k8s/score-api-hpa.yaml
```

2. **Set up Ingress** for domain-based routing:

```bash
kubectl apply -f k8s/score-api-ingress.yaml
```

3. **Verify deployment**:

```bash
kubectl get pods -n score-api
kubectl get svc -n score-api
kubectl get ingress -n score-api
```

4. **Configure Tetris frontend** to use the new Score API endpoint:

   Set `window.TETRIS_API_BASE_URL` to point to your AKS ingress domain. See [Score API Endpoint Configuration](#score-api-endpoint-configuration).

5. **Monitor** via Log Analytics:

   Logs are automatically forwarded to the Log Analytics workspace provisioned in [aks.tf](Terraform/aks.tf).

### Validation

- Score API pods are in `Running` state
- Ingress has an assigned external IP
- Tetris frontend can reach the backend API
- Pod autoscaler is responding to load (HPA status)

## Stage 6: CI/CD + Security

Automated pipelines in [.github/workflows/](.github/workflows/) with integrated security scanning.

### Application CI Pipeline

- File: [.github/workflows/app-ci.yml](.github/workflows/app-ci.yml)
- Triggers: Push to `app` branch, pull requests
- Steps:
  - npm dependency audit (SCA)
  - Docker image build
  - **Trivy container vulnerability scan** (CRITICAL/HIGH failures block push)
  - SARIF report upload (GitHub Security tab)
  - Push to ACR on success

### Infrastructure CI Pipeline

- File: [.github/workflows/infra-ci.yml](.github/workflows/infra-ci.yml)
- Triggers: Push to `infra` branch
- Steps:
  - **Terraform Trivy SAST scan** (infrastructure code security)
  - **Checkov policy validation** (IaC best practices, 25+ checks)
  - Terraform plan and conditional apply
  - State management via Azure backend

### GitHub OIDC Federation

Secure CI/CD authentication via:

- [auth/auth.tf](auth/auth.tf) - GitHub OIDC provider and Azure AD app in dedicated auth state
- No stored secrets in GitHub; uses ambient identity

## Stage 7: Observability & GitOps

Monitoring, logging, and GitOps-based deployments.

### Logging

- **Log Analytics Workspace**: Provisioned in [aks.tf](Terraform/aks.tf)
- **OMS Agent**: Enabled on AKS nodes for container logs
- **Kubernetes Audit Logs**: Sent to Log Analytics for compliance tracking

### Operational Scripts

Automation helpers in [scripts/](scripts/):

- [aks_ACRPull_role_assign.sh](scripts/aks_ACRPull_role_assign.sh) - Manage AKS→ACR pull permissions
- [azure_storage_account.sh](scripts/azure_storage_account.sh) - Terraform backend storage setup
- [storage_access.sh](scripts/storage_access.sh) - Storage access configuration
- [azuread_rm_state.sh](scripts/azuread_rm_state.sh) - Azure AD resource cleanup

## Documentation

- [BOOTSTRAP.md](BOOTSTRAP.md) - Comprehensive bootstrap guide with GitHub OIDC federation steps
- [Readme.md](Readme.md) - This file, tracks all stages and provides quick-start references

## Credits and Attribution

This project builds on existing open-source work and extends it with staged DevOps improvements.

### Original Game Source

- Base Tetris implementation: [ytiurin/tetris](https://github.com/ytiurin/tetris)
- Original author: Eugene Tiurin
- License: MIT
- License file in this repository: [tetris-master/LICENSE](tetris-master/LICENSE)

### My Contributions

The following work is added by me in this repository as part of the DevOps journey:

- Repository-level documentation and stage tracking in [Readme.md](Readme.md)
- Upcoming infrastructure, deployment, and operations work under [Terraform](Terraform) and [k8s](k8s)
- Any CI/CD, security, and observability additions introduced in future stages

### Attribution Practice Used Here

- Keep the original license and copyright notice intact
- Explicitly mention the upstream repository and author
- Clearly separate inherited code from newly added work

## Score API Endpoint Configuration

The game now supports configuring the score backend endpoint at runtime.

- Default behavior keeps using the legacy score API URL.
- To point the game to the new backend, define `window.TETRIS_API_BASE_URL` before loading `all.js`.

Example:

```html
<script>
  window.TETRIS_API_BASE_URL = "https://<your-api-host>";
</script>
<script async defer src="./public/all.js"></script>
```

The game will call:

- `POST /api/scores`
- `GET /api/scores`
