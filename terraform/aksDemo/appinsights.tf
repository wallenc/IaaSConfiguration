resource "azurerm_application_insights" "main" {
  name                = "myDemoAppinsights"
  location            = var.azure_region
  resource_group_name = var.resource_group_name
  application_type    = "java"  
}

resource "null_resource" "set_appinsights" {  
  provisioner "local-exec" {
    interpreter = ["Powershell", "-Command"]
    command = <<ps
     .'${path.module}\Assets\\Provisioners\\Set-AzAppInsights.ps1' `
      -AzureSubscriptionId "${var.azure_subscription_id}" `
      -AppInsightsWorkspaceName ${azurerm_application_insights.main.name} `
      -AppInsightsResourceGroupName ${var.resource_group_name} `
      -LogAnalyticsWorkspaceName ${azurerm_log_analytics_workspace.main.name} `
      -LogAnalyticsResourceGroupName ${azurerm_log_analytics_workspace.main.resource_group_name}
  ps
    }
    depends_on = [
      azurerm_application_insights.main,
      azurerm_log_analytics_workspace.main
  ]
}