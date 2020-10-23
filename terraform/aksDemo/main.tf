provider "azurerm" {
  version = "=2.32.0"
  features {}
  # environment = "usgovernment"
  skip_provider_registration = "true"  
}

terraform {
    backend "azurerm" {      
      resource_group_name  = "demoAKS-RG"
      storage_account_name = "cwterraformstate"
      container_name       = "tfstate"
      key                  = "demo.terraform.tfstate"
      environment = "usgovernment"
  }
}

# terraform {
#     backend "local" {
#         path = "../State/aksDemo.tfstate"
#     }
# }

resource "azurerm_storage_account" "storage" {
  name                     = "cwterraformstate"
  resource_group_name      = "demoAKS-RG"
  location                 = "usgovvirginia"
  account_tier             = "Standard"
  account_replication_type = "RAGRS"
}

data "azurerm_subscription" "primary" {
}

data "azurerm_client_config" "example" {
}