resource "azurerm_application_gateway" "main" {
  name                = var.app_gateway_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_port {
    name = "feport"
    port = 80
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "feip"
    public_ip_address_id = azurerm_public_ip.appgw_public_ip.id
  }

  backend_address_pool {
    name = "beap"
  }

  backend_http_settings {
    name                  = "be-htst"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = "httplistn"
    frontend_ip_configuration_name = "feip"
    frontend_port_name             = "feport"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rqrt"
    rule_type                  = "Basic"
    http_listener_name         = "httplistn"
    backend_address_pool_name  = "beap"
    backend_http_settings_name = "be-htst"
  }

  depends_on = [
      azurerm_virtual_network.main, 
      azurerm_public_ip.appgw_public_ip
      ]
}