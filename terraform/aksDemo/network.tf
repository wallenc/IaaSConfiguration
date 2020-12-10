resource "azurerm_virtual_network" "main" {
    name = var.azure_vnet
    address_space = var.azure_vnet_address_range
    resource_group_name = azurerm_resource_group.rg.name
    location = var.azure_region
}

resource "azurerm_subnet" "aks_subnet" {
    name = var.aks_subnet
    virtual_network_name = azurerm_virtual_network.main.name
    resource_group_name = azurerm_virtual_network.main.resource_group_name
    address_prefixes = var.aks_subnet_address_range    
    depends_on = [
        azurerm_virtual_network.main
    ]   
}

resource "azurerm_subnet" "appgw_subnet" {
    name = var.appgw_subnet
    virtual_network_name = azurerm_virtual_network.main.name
    resource_group_name = azurerm_virtual_network.main.resource_group_name
    address_prefixes = var.appgw_subnet_address_range    
    depends_on = [
        azurerm_virtual_network.main
    ]   
}

resource "azurerm_public_ip" "appgw_public_ip" {
  name                         = "aks-appgw-public-ip"
  location                     = var.azure_region
  resource_group_name          = azurerm_virtual_network.main.resource_group_name
  allocation_method            = "Static"
  sku                          = "Standard"
}