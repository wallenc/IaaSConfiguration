resource "azurerm_kubernetes_cluster" "main" {
  name                = var.aks_cluster_name
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.aks_dns_prefix

  default_node_pool {
    name       = var.aks_node_pool_name
    node_count = var.aks_node_count
    vm_size    = var.aks_node_size
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  network_profile {
      network_plugin = "azure"
      load_balancer_sku = "Standard"
  }

  identity {
    type = "SystemAssigned"
  }

    addon_profile {
        oms_agent {
          enabled                    = true
          log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
        }
        kube_dashboard {
              enabled = false
        }
    }

  depends_on = [
    azurerm_virtual_network.main
  ]
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.main.kube_config.0.client_certificate
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.main.kube_config_raw
}

output "k8s_identity" {
  value = azurerm_kubernetes_cluster.main.identity
}