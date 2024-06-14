# azure-openwebui-terraform
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.6 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | ~> 2.48.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.106 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | 2.48.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.106.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_openwebui"></a> [openwebui](#module\_openwebui) | ./modules/azure-openwebui-container-apps | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_container_app.debug](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app) | resource |
| [azurerm_log_analytics_workspace.openwebui](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_resource_group.openwebui](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azuread_users.canchat_admins](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/users) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_dns_zone.dsai_dns](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/dns_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_naming"></a> [naming](#input\_naming) | Values that define the names of resources using the following pattern: <departmentCode><environment><region><deviceType>-<group>-<userDefined><descriptor>-<suffix><br>Note: deviceType, descriptor, and suffix are set by the module. | <pre>object({<br>    department_code = optional(string, "Sc")<br>    environment     = string<br>    group           = string<br>    user_defined    = string<br>  })</pre> | n/a | yes |
| <a name="input_oauth2_proxy_client_secret"></a> [oauth2\_proxy\_client\_secret](#input\_oauth2\_proxy\_client\_secret) | n/a | `string` | n/a | yes |
| <a name="input_open_ai_host"></a> [open\_ai\_host](#input\_open\_ai\_host) | n/a | `string` | n/a | yes |
| <a name="input_openai_api_key"></a> [openai\_api\_key](#input\_openai\_api\_key) | n/a | `string` | n/a | yes |
| <a name="input_openai_east_us_api_key"></a> [openai\_east\_us\_api\_key](#input\_openai\_east\_us\_api\_key) | n/a | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->