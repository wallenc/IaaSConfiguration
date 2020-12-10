resource "azurerm_storage_account" "automation_storage" {
  name                     = var.automation_runbook_storage_account
  resource_group_name      = var.automation_storage_account_resource_group
  location                 = var.azure_region
  account_tier             = "Standard"
  account_replication_type = "LRS"  
}

# sas output
data "azurerm_storage_account_sas" "demorgdevops" {
  connection_string = azurerm_storage_account.automation_storage.primary_connection_string
  https_only = true
  resource_types {
    service = false
    container = false
    object = true
  }
  services {
    blob = true
    queue = false
    table = false
    file = false
  }
  start = "2020-11-13"
  expiry = "2021-11-13"
  permissions {
    read = true
    write = false
    delete = false
    list = false
    add = false
    create = false
    update = false
    process = false
  }
  depends_on = [
      azurerm_storage_account.automation_storage
  ]
}