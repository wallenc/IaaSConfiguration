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
      subscription_id = "d8abb5fd-9d00-48fd-862a-0f778306cce7"
      tenant_id = "8a09f2d7-8415-4296-92b2-80bb4666c5fc"
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