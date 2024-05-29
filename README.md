# azure-openwebui-terraform
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.6 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.100.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.100.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_openwebui"></a> [openwebui](#module\_openwebui) | ./modules/azure-openwebui-container-apps | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_container_app.debug](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app) | resource |
| [azurerm_log_analytics_workspace.openwebui](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_resource_group.anything_llm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_naming"></a> [naming](#input\_naming) | Values that define the names of resources using the following pattern: <departmentCode><environment><region><deviceType>-<group>-<userDefined><descriptor>-<suffix><br>Note: deviceType, descriptor, and suffix are set by the module. | <pre>object({<br>    department_code = optional(string, "Sc")<br>    environment     = string<br>    group           = string<br>    user_defined    = string<br>  })</pre> | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->