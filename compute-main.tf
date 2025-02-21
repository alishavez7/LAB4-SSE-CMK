

locals {
  nic_name = "nic-${local.vm_name}"
  vm_name  = "vm-${var.application_name}-${var.environment_name}"
}

resource "azurerm_network_interface" "nic" {
  name                = local.nic_name
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet-app.id
    private_ip_address_allocation = "Dynamic"
  }

}


resource "azurerm_linux_virtual_machine" "vm" {
  name                            = local.vm_name
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = var.region
  size                            = "Standard_DS1_v2"
  admin_username                  = "adminuser"
  admin_password                  = "Password1234"
  disable_password_authentication = "false"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]
  os_disk {
    name                   = "${local.vm_name}-osdisk"
    caching                = "ReadWrite"
    storage_account_type   = "Standard_LRS"
    disk_encryption_set_id = azurerm_disk_encryption_set.disk_encryption_set.id
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  availability_set_id = azurerm_availability_set.avset_name.id

}

resource "azurerm_availability_set" "avset_name" {
  name                         = "avset-${var.application_name}-${var.environment_name}"
  location                     = var.region
  resource_group_name          = azurerm_resource_group.rg.name
  platform_update_domain_count = 5
  platform_fault_domain_count  = 3
  managed                      = true

}

resource "azurerm_managed_disk" "disk1" {
  name                   = "${local.vm_name}-disk1"
  location               = var.region
  resource_group_name    = azurerm_resource_group.rg.name
  storage_account_type   = "Standard_LRS"
  create_option          = "Empty"
  disk_size_gb           = 32
  disk_encryption_set_id = azurerm_disk_encryption_set.disk_encryption_set.id

}

resource "azurerm_virtual_machine_data_disk_attachment" "disk1_attach" {
  managed_disk_id    = azurerm_managed_disk.disk1.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  lun                = 0
  caching            = "None"
}

# This resource block defines an Azure Disk Encryption Set.
# 
# Arguments:
# - name: The name of the Disk Encryption Set, which is a combination of the application name and environment name.
# - resource_group_name: The name of the resource group where the Disk Encryption Set will be created.
# - location: The Azure region where the Disk Encryption Set will be created.
# - key_vault_key_id: The ID of the Key Vault key to be used for encryption.
#
# The identity block specifies that the Disk Encryption Set will use a system-assigned managed identity.
resource "azurerm_disk_encryption_set" "disk_encryption_set" {
  name                = "des-${var.application_name}-${var.environment_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region
  key_vault_key_id    = azurerm_key_vault_key.key.id

  identity {
    type = "SystemAssigned"
  }

}




