data "azurerm_kubernetes_cluster" "main" {
    name = var.aks_cluster_name
    resource_group_name = azurerm_resource_group.rg.name

    depends_on = [
        azurerm_kubernetes_cluster.main
    ]
}