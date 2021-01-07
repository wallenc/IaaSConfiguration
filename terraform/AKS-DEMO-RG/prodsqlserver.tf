# provider "azurerm" {
#   version = "=2.0.0"
#   features {}
# }

# resource azurerm_resource_group "ResourceGroup" {
#   name     = "AKS-DEMO-RG"
#   location = "usgovvirginia"
# }

# resource azurerm_sql_server "prodsqlserver" {
#   name                         = "prodsqlserver"
#   location                     = "usgovvirginia"
#   resource_group_name          = azurerm_resource_group.ResourceGroup.name
#   version                      = "12.0"
#   administrator_login_password = "P$teelers32"
#   administrator_login          = "xadmin"
# }

# resource azurerm_sql_database "test_proddb" {
#   name                = "test_proddb"
#   location            = azurerm_sql_server.prodsqlserver.location
#   resource_group_name = azurerm_resource_group.ResourceGroup.name
#   server_name         = azurerm_sql_server.prodsqlserver.name
# }

# resource "null_resource" "prodsqlserver_setTde" {
#   depends_on = [
#     "azurerm_sql_server.prodsqlserver",
#     "azurerm_sql_database.test_proddb"
#   ]
#   provisioner "local-exec" {
#     interpreter = ["PowerShell", "-Command"]    
#     command = <<ps
#      .'${path.module}\\..\..\Assets\\Provisioners\\Set-AzSqlDatabaseTDE.ps1' `
#      -ResourceGroupName ${azurerm_resource_group.ResourceGroup.name} `
#      -AzSqlServerName ${azurerm_sql_server.prodsqlserver.name} `
#      -AzSqlDatabaseName ${azurerm_sql_database.test_proddb.name} `
#      -State 'Enabled'
#   ps
#   }
# }