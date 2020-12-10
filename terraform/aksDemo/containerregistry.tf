
resource "azurerm_container_registry" "main" {
  name                     = var.container_registry_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.azure_region
  sku                      = "Premium"
  admin_enabled            = false  
}