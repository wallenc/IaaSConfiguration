provider "azurerm" {
  version = "~> 2.24.0"
  features {}
}

terraform {
    backend "local" {
        path = "../State/AKS-DEMO-RG.tfstate"
    }
}

data "azurerm_subscription" "primary" {
}

data "azurerm_client_config" "example" {
}