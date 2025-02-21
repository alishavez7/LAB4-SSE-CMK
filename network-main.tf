# create Vnet and Subnet
locals {
  app_subnet_address_space = cidrsubnet(var.base_address_space, 2, 0)
  db_subnet_address_space  = cidrsubnet(var.base_address_space, 2, 1)
}

resource "azurerm_virtual_network" "Vnet" {
  name                = "vnet-${var.application_name}-${var.environment_name}"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.base_address_space]

}

resource "azurerm_subnet" "subnet-app" {
  name                 = "subnet-${var.application_name}-${var.environment_name}-app"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.Vnet.name
  address_prefixes     = [local.app_subnet_address_space]

}

resource "azurerm_subnet" "subnet-db" {
  name                 = "subnet-${var.application_name}-${var.environment_name}-db"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.Vnet.name
  address_prefixes     = [local.db_subnet_address_space]

}

resource "azurerm_network_security_group" "nsg-app" {
  name                = "nsg-app-${var.application_name}-${var.environment_name}"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name

}

resource "azurerm_subnet_network_security_group_association" "nsg-app-association" {
  network_security_group_id = azurerm_network_security_group.nsg-app.id
  subnet_id                 = azurerm_subnet.subnet-app.id
}

resource "azurerm_network_security_group" "nsg-db" {
  name                = "nsg-db-${var.application_name}-${var.environment_name}"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name

}

resource "azurerm_subnet_network_security_group_association" "nsg-db-association" {
  network_security_group_id = azurerm_network_security_group.nsg-db.id
  subnet_id                 = azurerm_subnet.subnet-db.id
}
