resource "azurerm_virtual_network" "aks_vnet" {
    name = "AKS-DEMO-VNET"
    address_space = ["10.20.0.0/23"]
    resource_group_name = "AKS-DEMO-RG"
    location = "usgovvirginia"
}

resource "azurerm_subnet" "aks_subnet" {
    name = "S-3"
    virtual_network_name = azurerm_virtual_network.aks_vnet.name
    resource_group_name = azurerm_virtual_network.aks_vnet.resource_group_name
    address_prefixes = ["10.20.0.64/26"]        

    # delegation {
    #   name = "aciDelegation"
    #   service_delegation {
    #   name    = "Microsoft.ContainerInstance/containerGroups"
    #   actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    # }
  #}
}
