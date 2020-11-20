resource "azurerm_virtual_network" "main" {
    name = var.azure_vnet
    address_space = var.azure_vnet_address_range
    resource_group_name = var.azure_vnet_resource_group
    location = var.azure_region
}

resource "azurerm_subnet" "aks_subnet" {
    name = var.azure_subnet
    virtual_network_name = azurerm_virtual_network.main.name
    resource_group_name = azurerm_virtual_network.main.resource_group_name
    address_prefixes = var.subnet_address_range    
    depends_on = [
        azurerm_virtual_network.main
    ]   
}
