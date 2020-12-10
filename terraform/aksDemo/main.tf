provider "azurerm" {
  version = "=2.32.0"
  features {}  
  skip_provider_registration = "true"  
}

terraform {
    backend "local" {
        path = "../State/aksDemo.tfstate"
  }
}

