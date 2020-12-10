resource "azurerm_resource_group" "rg" {
  name     = "AKS-DEMO-RG"
  location = "usgovvirginia"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "demoAKS"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "demoaks1"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_B2ms"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
    max_pods = 15
  }

  network_profile {
      network_plugin = "azure"
      load_balancer_sku = "Basic"
  }

  identity {
    type = "SystemAssigned"
  }

    addon_profile {
        oms_agent {
          enabled                    = true        
          log_analytics_workspace_id = azurerm_log_analytics_workspace.loga.id
        }
        kube_dashboard {
              enabled = false        
        }        
    }       
    
  tags = {
    Environment = "Production"
  }   
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw
}

output "k8s_identity" {
  value = azurerm_kubernetes_cluster.aks.identity
}

# resource "azurerm_monitor_metric_alert" "main" {
#   name                = "mytest-jsappinsights2"
#   resource_group_name =  "ANSIBLE-RG"
#   scopes              =  ["/subscriptions/d8abb5fd-9d00-48fd-862a-0f778306cce7/resourceGroups/ANSIBLE-RG/providers/microsoft.insights/webtests/mytest-jsappinsights"]
#   description         = "Alert rule for availability test myTest2"
#   frequency           = "PT5M"
#   severity            = 1
#   window_size         = "PT5M"

#   criteria {
#     metric_namespace = "microsoft.insights/webtests"
#     metric_name      = "availabilityResults/count"
#     aggregation      = "Count"
#     operator         = "GreaterThan"
#     threshold        = 2
#   }

#   action {
#     action_group_id = "/subscriptions/d8abb5fd-9d00-48fd-862a-0f778306cce7/resourceGroups/EAST-PROD-RG/providers/microsoft.insights/actiongroups/ImportantPPL"
#   }
# }