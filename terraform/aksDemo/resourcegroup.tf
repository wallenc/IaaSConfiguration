resource "azurerm_resource_group" "rg" {
  name     = "DEMO-AKS-RG"
  location = var.azure_region
}