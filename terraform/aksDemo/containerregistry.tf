
resource "azurerm_container_registry" "acr" {
  name                     = var.container_registry_name
  resource_group_name      = var.aks_resource_group
  location                 = var.azure_region
  sku                      = "Premium"
  admin_enabled            = false
  georeplication_locations = ["USGov Virginia", "USGov Texas"]
}