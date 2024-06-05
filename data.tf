data "azurerm_client_config" "current" {}

data "azuread_users" "canchat_admins" {
  user_principal_names = [
    "justin.bertrand@ssc-spc.gc.ca",
    "pascal.beaulne2@ssc-spc.gc.ca",
  ]
}
