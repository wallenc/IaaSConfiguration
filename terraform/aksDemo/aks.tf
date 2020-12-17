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

output "client_key" {
    value = azurerm_kubernetes_cluster.main.kube_config.0.client_key
}

output "cluster_ca_certificate" {
    value = azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate
}

output "cluster_username" {
    value = azurerm_kubernetes_cluster.main.kube_config.0.username
}

output "cluster_password" {
    value = azurerm_kubernetes_cluster.main.kube_config.0.password
}

output "host" {
    value = azurerm_kubernetes_cluster.main.kube_config.0.host
}

output "identity_resource_id" {
    value = azurerm_user_assigned_identity.main.id
}

output "identity_client_id" {
    value = azurerm_user_assigned_identity.main.client_id
}