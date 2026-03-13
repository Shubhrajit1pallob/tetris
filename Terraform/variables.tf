variable "backend-rg" {
  description = "The resource group for the tfstate backend configuration"
  default     = "terraform-rg01"
}

variable "backend-storage-account" {
  description = "The storage account for the tfstate backend configuration"
}

variable "backend-container" {
  description = "The container for the tfstate backend configuration"
  default     = "tfstate"
}

variable "backend-key" {
  description = "The key for the tfstate backend configuration"
  default     = "terraform.tfstate"
}

variable "region" {
  description = "The region that is common for all resources"
  default     = "westcentralus"
}