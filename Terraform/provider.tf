terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = var.backend-rg
    storage_account_name = var.backend-storage-account
    container_name       = var.backend-container
    key                  = var.backend-key
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
}