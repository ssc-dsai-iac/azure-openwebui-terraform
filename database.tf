resource "azurerm_postgresql_flexible_server" "this" {
  name                = lower(replace(format(local.standardized_name_template, "", "", "sqldb"), "_", "-"))
  resource_group_name = var.resource_group_name
  location            = var.region

  version = var.database.version

  administrator_login    = random_pet.postgresql_admin_username.id
  administrator_password = random_password.postgresql_admin_password.result

  public_network_access_enabled = true

  storage_mb = var.database.storage_mb
  sku_name   = var.database.sku_name

  tags = local.tags

  zone = var.database.zone

  authentication {
    active_directory_auth_enabled = true
    tenant_id                     = var.database.tenant_id
  }
}

resource "random_pet" "postgresql_admin_username" {
  separator = ""
}

resource "random_password" "postgresql_admin_password" {
  length  = 32
  special = false
}

resource "azurerm_postgresql_flexible_server_database" "openwebui" {
  name      = "openwebui"
  server_id = azurerm_postgresql_flexible_server.this.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Implements the `Allow public access from any Azure service within Azure to this server` on the Network tab in the Portal
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name             = "AllowAllAzureServicesAndResourcesWithinAzureIps"
  server_id        = azurerm_postgresql_flexible_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "rules" {
  for_each = { for index, rule in var.database.firewall_rules : "terraform_rule_${rule.name != "" ? rule.name : index}" => rule }

  name             = each.key
  server_id        = azurerm_postgresql_flexible_server.this.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

# AD Admins
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "admins" {
  for_each = { for index, admin in var.database.ad_admins : admin.principal_name => admin }

  server_name         = azurerm_postgresql_flexible_server.this.name
  resource_group_name = azurerm_postgresql_flexible_server.this.resource_group_name
  tenant_id           = each.value.tenant_id
  object_id           = each.value.object_id
  principal_name      = each.value.principal_name
  principal_type      = each.value.principal_type
}
