resource "azurerm_log_analytics_workspace" "main" {    
    name                =  var.log_analytics_name
    location            = "usgovvirginia"
    resource_group_name =  var.log_analytics_resource_group
    sku                 = "PerGB2018"
}

resource "azurerm_log_analytics_solution" "container_insights" {
    solution_name         = "ContainerInsights"
    location              = azurerm_log_analytics_workspace.main.location
    resource_group_name   = azurerm_log_analytics_workspace.main.resource_group_name
    workspace_resource_id = azurerm_log_analytics_workspace.main.id
    workspace_name        = azurerm_log_analytics_workspace.main.name

    plan {
        publisher = "Microsoft"
        product   = "OMSGallery/ContainerInsights"
    }
}