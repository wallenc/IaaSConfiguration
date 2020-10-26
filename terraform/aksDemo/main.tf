provider "azurerm" {
  version = "=2.32.0"
  features {}  
  skip_provider_registration = "true"  
}

terraform {
    backend "azurerm" {
      
    }
}

data "azurerm_subscription" "primary" {
}

data "azurerm_client_config" "example" {
}