resource "azurerm_storage_container" "automation_runbook_container" {
  name                  = var.automation_runbook_container_name
  storage_account_name  = var.automation_runbook_storage_account
  container_access_type = "private"
  depends_on = [
    azurerm_storage_account.automation_storage
  ]
}

resource "azurerm_storage_blob" "demorgdevops_automationrunbooks_Assert-DeletionLock" {
  name = "Assert-DeletionLock.ps1"
  storage_account_name = var.automation_runbook_storage_account
  storage_container_name = azurerm_storage_container.automation_runbook_container.name
  source = "${path.module}\\..\\..\\Assets\\Runbooks\\Assert-DeletionLock.ps1"
  type = "Block"
  depends_on = [
    azurerm_storage_container.automation_runbook_container
  ]
}

resource "azurerm_storage_blob" "demorgdevops_automationrunbooks_Azure-GeneralHelper" {
  name = "Azure-GeneralHelper.zip"
  storage_account_name = var.automation_runbook_storage_account
  storage_container_name = azurerm_storage_container.automation_runbook_container.name
  source = "${path.module}\\..\\..\\Assets\\bin\\Azure-GeneralHelper.zip"
  type = "Block"
  depends_on = [
    azurerm_storage_container.automation_runbook_container
  ]
}