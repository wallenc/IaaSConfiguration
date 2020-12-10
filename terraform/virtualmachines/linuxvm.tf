

resource "azurerm_public_ip" "main" {
  name                = "${var.azurevm_name}-publicip"
  resource_group_name = var.resource_group_name
  location            = var.azure_region
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.azurevm_name}-nic"
  location            = var.azure_region
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "primaryconfig"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = var.azurevm_name
  location              = var.azure_region
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_B2ms"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
   delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
   delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "81-ci-gen2"
    version   = "8.1.2020042524"
  }
  storage_os_disk {
    name              = "${var.azurevm_name}-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = var.azurevm_name
    admin_username = "xadmin"
    admin_password = "Password1234!"
    custom_data = file("..\\Assets\\cloud-init\\cloud-init-rhel.yml")
  }
  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys {
        key_data = file("..\\Assets\\SSHKeys\\LinuxPublicKey.pub")
        path = "/home/xadmin/.ssh/authorized_keys"
    }
  }  
}