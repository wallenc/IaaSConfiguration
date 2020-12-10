resource "azurerm_application_insights" "main" {
  name                = "myDemoAppinsights"
  location            = "USGov Virginia"
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "java"  
}

resource "null_resource" "set_appinsights" {
  depends_on = [
    azurerm_application_insights.main
  ]
  provisioner "local-exec" {
    interpreter = ["Powershell", "-Command"]
    command = <<ps
     .'${path.module}\Assets\\Provisioners\\Set-AzAppInsights.ps1' `
      -AzureSubscriptionId "${var.subscription_id}" `
      -AppInsightsWorkspaceName ${azurerm_application_insights.main.name} `
      -AppInsightsResourceGroupName ${azurerm_resource_group.rg.name} `
      -LogAnalyticsWorkspaceName ${azurerm_log_analytics_workspace.main.name} `
      -LogAnalyticsResourceGroupName ${azurerm_log_analytics_workspace.main.resource_group_name}
  ps
    }
}

output "instrumentation_key" {
  value = azurerm_application_insights.main.instrumentation_key
}

output "app_id" {
  value = azurerm_application_insights.main.app_id
}