resource "azurerm_log_analytics_workspace" "loga" {    
    name                = "PROD-LOGA-WS1"
    location            = "usgovvirginia"
    resource_group_name = "LOG-ANALYTICS-RG"
    sku                 = "PerGB2018"
}

resource "azurerm_log_analytics_solution" "logas" {
    solution_name         = "ContainerInsights"
    location              = azurerm_log_analytics_workspace.loga.location
    resource_group_name   = azurerm_log_analytics_workspace.loga.resource_group_name
    workspace_resource_id = azurerm_log_analytics_workspace.loga.id
    workspace_name        = azurerm_log_analytics_workspace.loga.name

    plan {
        publisher = "Microsoft"
        product   = "OMSGallery/ContainerInsights"
    }
}