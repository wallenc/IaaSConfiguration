resource "azurerm_virtual_network" "main" {
    name = var.azure_vnet
    address_space = var.azure_vnet_address_range
    resource_group_name = var.azure_vnet_resource_group
    location = "usgovvirginia"

    dns_servers = ["10.10.0.6", "8.8.8.8"]
}

resource "azurerm_subnet" "main" {
    name = var.subnet_name
    virtual_network_name = azurerm_virtual_network.main.name
    resource_group_name = azurerm_virtual_network.main.resource_group_name
    address_prefixes = var.subnet_address_range       
}
