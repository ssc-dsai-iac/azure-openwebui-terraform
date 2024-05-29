resource "azurerm_resource_group" "anything_llm" {
  name     = format(local.standardized_name_template, "", "", "rg")
  location = "Canada Central"
}
