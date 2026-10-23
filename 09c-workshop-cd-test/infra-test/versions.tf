terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  # State lives in an Azure storage account that the pipeline creates (job cdtest:state).
  # The pipeline passes resource group, account, container and key with -backend-config.
  backend "azurerm" {}
}

# Credentials come from the environment, set by the pipeline - never from a .tf file:
#   OIDC:     ARM_USE_OIDC=true, ARM_OIDC_TOKEN (GitLab ID token), ARM_CLIENT_ID, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
#   fallback: ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
provider "azurerm" {
  features {}
  resource_provider_registrations = "none" # the lab role cannot register providers
}
