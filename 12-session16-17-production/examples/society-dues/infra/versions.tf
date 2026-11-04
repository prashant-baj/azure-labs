terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# The subscription comes from the environment, never from a file:
#   bash:        export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
#   PowerShell:  $env:ARM_SUBSCRIPTION_ID = (az account show --query id -o tsv)
provider "azurerm" {
  features {}
  resource_provider_registrations = "none" # the lab role registers providers once with `az provider register`
}
