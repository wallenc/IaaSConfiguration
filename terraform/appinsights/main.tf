provider "azurerm" {
  version = "=2.32.0"
  features {}
}

terraform {
    backend "azurerm" {      
      resource_group_name   = "appinsights-RG"
      storage_account_name  = "cwterraformstate"
      container_name        = "tfstate"
      key                   = "appinsights.terraform.tfstate"
      environment           = "usgovernment"      
  }
}

data "azurerm_subscription" "primary" {
}

data "azurerm_client_config" "example" {
}