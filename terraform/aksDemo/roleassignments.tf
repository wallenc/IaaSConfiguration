resource "azurerm_user_assigned_identity" "main" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name = "appgwidentity" 
}

resource "azurerm_role_assignment" "ra1" {
  scope                = azurerm_subnet.aks_subnet.id
  role_definition_name = "Network Contributor"
  principal_id         = data.azurerm_kubernetes_cluster.main.identity[0].principal_id

  depends_on = [
      azurerm_virtual_network.main,
      azurerm_kubernetes_cluster.main
  ]
}

resource "azurerm_role_assignment" "ra3" {
  scope                = azurerm_application_gateway.main.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  depends_on           = [
        azurerm_user_assigned_identity.main, 
        azurerm_application_gateway.main
    ]
}

resource "azurerm_role_assignment" "ra4" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  depends_on           = [
      azurerm_user_assigned_identity.main, 
      azurerm_application_gateway.main
      ]
}