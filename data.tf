data "azurerm_client_config" "current" {}

data "azuread_users" "canchat_admins" {
  user_principal_names = [
    "justin.bertrand@ssc-spc.gc.ca",
    "pascal.beaulne2@ssc-spc.gc.ca",
  ]
}

data "azurerm_dns_zone" "dsai_dns" {
  name = "dsai-sdia.ssc-spc.cloud-nuage.canada.ca"
}
