variable "web_app_slot_count" {
  type        = number
  description = "Number of slots (0 or 1)"
  default     = 0
  # tfvars contains web_app_slot_count = 1
}
provider "azurerm" {
  features {
    key_vault {
      purge_soft_deleted_certificates_on_destroy = true
      recover_soft_deleted_certificates          = true
    }
  }
  subscription_id = "f7b47845-d5bc-4233-bd62-1d9c2832b014"
}
data "azurerm_client_config" "current" {}
data "azurerm_resource_group" "main"{
name = "poc-spoke"
}
data "azurerm_windows_web_app" "example"{
name = "apppoc"
resource_group_name = data.azurerm_resource_group.main.name
}
resource "azurerm_key_vault" "example" {
  name                = "stagkeyvault"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    certificate_permissions = [
      "Create",
      "Delete",
      "DeleteIssuers",
      "Get",
      "GetIssuers",
      "Import",
      "List",
      "ListIssuers",
      "ManageContacts",
      "ManageIssuers",
      "SetIssuers",
      "Update",
    ]

    key_permissions = [
      "Backup",
      "Create",
      "Decrypt",
      "Delete",
      "Encrypt",
      "Get",
      "Import",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Sign",
      "UnwrapKey",
      "Update",
      "Verify",
      "WrapKey",
    ]

    secret_permissions = [
      "Backup",
      "Delete",
      "Get",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Set",
    ]
  }
}

resource "azurerm_key_vault_certificate" "example" {
  name         = "imported-cert"
  key_vault_id = azurerm_key_vault.example.id

  certificate {
    contents = filebase64("jahkeyvault-mynewCertificate-20241024.pfx")
    password = ""
  }
}
resource "azurerm_windows_web_app_slot" "example" {
  name           = "stag-slot"
  app_service_id = data.azurerm_windows_web_app.example.id
  site_config {}
}
resource "azurerm_app_service_custom_hostname_binding" "example" {
  count               = var.web_app_slot_count
  hostname            = "stag-staging.rdc.nl"
  app_service_name    = data.azurerm_windows_web_app.example.name
  resource_group_name = data.azurerm_resource_group.main.name
  ssl_state           = "SniEnabled"
  thumbprint          = azurerm_key_vault_certificate.example.thumbprint

  depends_on = [azurerm_windows_web_app_slot.example]
}

