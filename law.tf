resource "azurerm_log_analytics_workspace" "openwebui" {
  name                = format(local.standardized_name_template, "CLP", "", "law")
  location            = azurerm_resource_group.openwebui.location
  resource_group_name = azurerm_resource_group.openwebui.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
