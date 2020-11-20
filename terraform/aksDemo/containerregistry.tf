
resource "azurerm_container_registry" "main" {
  name                     = var.container_registry_name
  resource_group_name      = var.resource_group_name
  location                 = var.azure_region
  sku                      = "Premium"
  admin_enabled            = false  
}