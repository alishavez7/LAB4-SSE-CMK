resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.application_name}-${var.environment_name}"
  location = var.region
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

data "azurerm_client_config" "config" {

}

resource "azurerm_key_vault" "keyvault" {
  name                        = "kv-${var.application_name}-${var.environment_name}-${random_string.suffix.result}"
  location                    = var.region
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.config.tenant_id
  sku_name                    = "standard"
  enable_rbac_authorization   = "true"
  enabled_for_disk_encryption = "true"
  purge_protection_enabled    = true

}

resource "azurerm_key_vault_key" "key" {
  name         = "key-${var.application_name}-${var.environment_name}-${random_string.suffix.result}"
  key_vault_id = azurerm_key_vault.keyvault.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "wrapKey", "unwrapKey", "verify"]

}
data "azurerm_subscription" "sub" {
}

data "azurerm_client_config" "user" {
}

resource "azurerm_role_assignment" "example" {
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "key vault administrator"
  principal_id         = data.azurerm_client_config.user.object_id
}

resource "azurerm_role_assignment" "example-disk" {
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Crypto User"
  principal_id         = azurerm_disk_encryption_set.disk_encryption_set.identity[0].principal_id
}


/*

resource "azurerm_log_analytics_workspace" "la" {
  name                = ""
  location            = ""
  resource_group_name = ""
  sku                 = ""
}

*/

resource "azurerm_log_analytics_workspace" "la" {
  name                = "la-test"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"

}


data "azurerm_log_analytics_workspace" "la" {
  name                = "la-test"
  resource_group_name = "rg-devops-prod"
}

resource "azurerm_monitor_diagnostic_setting" "diag-settings" {
  name                       = "kv-${var.application_name}-${var.environment_name}-${random_string.suffix.result}-diag"
  target_resource_id         = azurerm_key_vault.keyvault.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.la.id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
  }
}


