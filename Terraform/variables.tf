# variable "backend-rg" {
#   description = "The resource group for the tfstate backend configuration"
#   default     = "terraform-rg01"
# }

# variable "backend-storage-account" {
#   description = "The storage account for the tfstate backend configuration"
# }

# variable "backend-container" {
#   description = "The container for the tfstate backend configuration"
#   default     = "tfstate"
# }

# variable "backend-key" {
#   description = "The key for the tfstate backend configuration"
#   default     = "terraform.tfstate"
# }

variable "region" {
  description = "The region that is common for all resources"
  default     = "westcentralus"
}

variable "project_name" {
  description = "Project slug used for naming resources"
  default     = "tetris"
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  default     = "tetris-aks"
}

variable "aks_dns_prefix" {
  description = "DNS prefix for AKS API endpoint"
  default     = "tetris-aks"
}

variable "aks_node_count" {
  description = "Node count for the AKS default node pool"
  type        = number
  default     = 1
}

variable "aks_node_vm_size" {
  description = "VM size for the AKS default node pool"
  default     = "Standard_B2s"
}

variable "cosmos_account_name" {
  description = "Globally unique Azure Cosmos DB account name"
  default     = "tetriscosmosdbacct01"
}

variable "cosmos_database_name" {
  description = "Cosmos SQL database name for score data"
  default     = "tetris"
}

variable "cosmos_container_name" {
  description = "Cosmos SQL container name for score data"
  default     = "scores"
}

variable "ssh_public_key" {
  description = "The SSH key for sshing into the instance."
}