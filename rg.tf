resource "azurerm_resource_group" "openwebui" {
  name     = format(local.standardized_name_template, "", "", "rg")
  location = "Canada Central"

  tags = local.tags
}
