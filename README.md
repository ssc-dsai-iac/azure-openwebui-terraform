# azure-openwebui-terraform
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.6 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.106 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.5 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.106 |
| <a name="provider_local"></a> [local](#provider\_local) | ~> 2.5 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.6.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_container_app.litellm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app) | resource |
| [azurerm_container_app.oauth_proxy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app) | resource |
| [azurerm_container_app.ollama](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app) | resource |
| [azurerm_container_app.openwebui](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app) | resource |
| [azurerm_container_app.qdrant](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app) | resource |
| [azurerm_container_app_environment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment) | resource |
| [azurerm_container_app_environment_storage.litellm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment_storage) | resource |
| [azurerm_container_app_environment_storage.qdrant](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment_storage) | resource |
| [azurerm_dns_cname_record.openwebui](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_txt_record.openwebui](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_txt_record) | resource |
| [azurerm_postgresql_flexible_server.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server) | resource |
| [azurerm_postgresql_flexible_server_active_directory_administrator.admins](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_active_directory_administrator) | resource |
| [azurerm_postgresql_flexible_server_database.openwebui](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_database) | resource |
| [azurerm_postgresql_flexible_server_firewall_rule.allow_azure_services](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_firewall_rule) | resource |
| [azurerm_postgresql_flexible_server_firewall_rule.rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_firewall_rule) | resource |
| [azurerm_storage_account.litellm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_account.qdrant](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_share.litellm_config](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share) | resource |
| [azurerm_storage_share.qdrant](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share) | resource |
| [azurerm_storage_share_file.litellm_config](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share_file) | resource |
| [local_file.litellm_config](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_id.litellm_storage_account](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_id.qdrant_storage_account](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_password.litellm_master_key](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.oauth_proxy_cookie_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.postgresql_admin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_pet.postgresql_admin_username](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_database"></a> [database](#input\_database) | Configures the PostgreSQL database which backs OpenWebUI. | <pre>object({<br>    ad_admins = optional(list(object({<br>      tenant_id      = string<br>      object_id      = string<br>      principal_name = string<br>      principal_type = string<br>    })), [])<br>    firewall_rules = optional(list(object({<br>      name             = optional(string, "")<br>      start_ip_address = string<br>      end_ip_address   = string<br>    })), [])<br>    sku_name   = optional(string, "B_Standard_B1ms")<br>    storage_mb = optional(number, 32768)<br>    tenant_id  = optional(string, null)<br>    version    = optional(number, 16)<br>    zone       = optional(number, 1)<br>  })</pre> | `{}` | no |
| <a name="input_dns"></a> [dns](#input\_dns) | Custom DNS configurations. | <pre>object({<br>    zone_name                = string<br>    zone_resource_group_name = string<br>    record                   = string<br>  })</pre> | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Configurations for the Container App Environment. | <pre>object({<br>    internal_load_balancer_enabled              = optional(bool, null)<br>    dapr_application_insights_connection_string = optional(string)<br>    log_analytics_workspace_id                  = optional(string)<br>    subnet_id                                   = optional(string)<br>    zone_redundancy_enabled                     = optional(bool, null)<br><br>    workload_profiles = optional(list(object({<br>      name          = string<br>      type          = string<br>      maximum_count = optional(number, 1)<br>      minimum_count = optional(number, 1)<br>    })), [])<br>  })</pre> | `{}` | no |
| <a name="input_litellm"></a> [litellm](#input\_litellm) | Configurations for the CanChat Container App. | <pre>object({<br>    config = object({<br>      general_settings = optional(any, {})<br>      litellm_settings = optional(any, {})<br>      model_list = list(<br>        object({<br>          model_name     = string<br>          litellm_params = optional(any, {})<br>          model_info     = optional(any, {})<br>        })<br>      )<br>    })<br><br>    container = optional(object({<br>      image  = optional(string, "ghcr.io/berriai/litellm:main-v1.40.12")<br>      cpu    = optional(number, 1)<br>      memory = optional(string, "2Gi")<br>    }), {})<br><br>    environment_variables = optional(list(object({<br>      name         = string<br>      value        = string<br>      is_sensitive = bool<br>    })), [])<br><br>    identities = optional(object({<br>      enable_system_assigned_identity = optional(bool, false)<br>      user_managed_identity_ids       = optional(list(string), [])<br>    }), {})<br><br>    registries = optional(list(object({<br>      server               = string<br>      identity_resource_id = string<br>    })), [])<br><br>    replicas = optional(object({<br>      max = optional(number, 1)<br>      min = optional(number, 1)<br>    }), {})<br><br>    workload_profile_name = optional(string, "Consumption")<br>  })</pre> | n/a | yes |
| <a name="input_naming"></a> [naming](#input\_naming) | Values that define the names of resources using the following pattern: <departmentCode><environment><region><deviceType>-<group>-<userDefined><descriptor>-<suffix><br>Note: deviceType, descriptor, and suffix are set by the module. | <pre>object({<br>    department_code = optional(string, "Sc")<br>    environment     = string<br>    group           = string<br>    user_defined    = string<br>  })</pre> | n/a | yes |
| <a name="input_oauth_proxy"></a> [oauth\_proxy](#input\_oauth\_proxy) | Configurations for the oauth-proxy Container App. | <pre>object({<br>    config = object({<br>      azure_tenant_id      = string<br>      client_id            = string<br>      client_secret        = string<br>      cookie_name          = optional(string, "__Secure-OpenWebUI")<br>      oidc_issuer_url      = string<br>      reverse_proxy        = optional(bool, true)<br>      skip_provider_button = optional(bool, true)<br>    })<br><br>    container = optional(object({<br>      image  = optional(string, "quay.io/oauth2-proxy/oauth2-proxy:v7.6.0")<br>      cpu    = optional(number, 0.5)<br>      memory = optional(string, "1Gi")<br>    }), {})<br><br>    identities = optional(object({<br>      enable_system_assigned_identity = optional(bool, false)<br>      user_managed_identity_ids       = optional(list(string), [])<br>    }), {})<br><br>    registries = optional(list(object({<br>      server               = string<br>      identity_resource_id = string<br>    })), [])<br><br>    replicas = optional(object({<br>      max = optional(number, 1)<br>      min = optional(number, 1)<br>    }), {})<br><br>    workload_profile_name = optional(string, "Consumption")<br>  })</pre> | n/a | yes |
| <a name="input_ollama"></a> [ollama](#input\_ollama) | Configurations for the Ollama Container App. | <pre>object({<br>    config = object({<br>      debug             = optional(number, 0)<br>      flash_attention   = optional(bool, false)<br>      host              = optional(string, "0.0.0.0:11434")<br>      keep_alive        = optional(string, "5m")<br>      llm_library       = optional(string, "")<br>      max_loaded_models = optional(number, 1)<br>      max_queue         = optional(number, 0)<br>      max_vram          = optional(number, 0)<br>      models            = optional(string, "")<br>      no_history        = optional(string, "") # Non-empty string will enable<br>      no_prune          = optional(string, "") # Non-empty string will enable<br>      num_parallel      = optional(number, 1)<br>      origins = optional(list(string), [<br>        "http://localhost",<br>        "http://127.0.0.1",<br>        "http://0.0.0.0",<br>        "https://localhost",<br>        "https://127.0.0.1",<br>        "https://0.0.0.0",<br>      ])<br>      runners_dir = optional(string, "")<br>      tmpdir      = optional(string, "")<br>    })<br><br>    container = object({<br>      image  = optional(string, "docker.io/ollama/ollama:0.1.39")<br>      cpu    = optional(number, 1)<br>      memory = optional(string, "2Gi")<br>    })<br><br>    identities = optional(object({<br>      enable_system_assigned_identity = optional(bool, false)<br>      user_managed_identity_ids       = optional(list(string), [])<br>    }), {})<br><br>    registries = optional(list(object({<br>      server               = string<br>      identity_resource_id = string<br>    })), [])<br><br>    replicas = optional(object({<br>      max = optional(number, 1)<br>      min = optional(number, 1)<br>    }), {})<br><br>    workload_profile_name = optional(string, "Consumption")<br>  })</pre> | n/a | yes |
| <a name="input_openwebui"></a> [openwebui](#input\_openwebui) | Configurations for the Open WebUI Container App. | <pre>object({<br>    # https://docs.openwebui.com/getting-started/env-configuration<br>    config = optional(object({<br><br>    }), {})<br><br>    container = optional(object({<br>      image  = optional(string, "ghcr.io/open-webui/open-webui:0.3.5")<br>      cpu    = optional(number, 1)<br>      memory = optional(string, "2Gi")<br>    }), {})<br><br>    identities = optional(object({<br>      enable_system_assigned_identity = optional(bool, false)<br>      user_managed_identity_ids       = optional(list(string), [])<br>    }), {})<br><br>    registries = optional(list(object({<br>      server               = string<br>      identity_resource_id = string<br>    })), [])<br><br>    replicas = optional(object({<br>      max = optional(number, 1)<br>      min = optional(number, 1)<br>    }), {})<br><br>    workload_profile_name = optional(string, "Consumption")<br>  })</pre> | n/a | yes |
| <a name="input_qdrant"></a> [qdrant](#input\_qdrant) | Configurations for the qdrant Container App. | <pre>object({<br>    config = optional(object({<br>      log_level = optional(string, "INFO")<br>      service = optional(object({<br>        max_request_size_mb = optional(number, 32)<br>      }), {})<br>    }), {})<br><br>    container = optional(object({<br>      image  = optional(string, "docker.io/qdrant/qdrant:v1.11.3-unprivileged")<br>      cpu    = optional(number, 1)<br>      memory = optional(string, "2Gi")<br>    }), {})<br><br>    identities = optional(object({<br>      enable_system_assigned_identity = optional(bool, false)<br>      user_managed_identity_ids       = optional(list(string), [])<br>    }), {})<br><br>    registries = optional(list(object({<br>      server               = string<br>      identity_resource_id = string<br>    })), [])<br><br>    replicas = optional(object({<br>      max = optional(number, 1)<br>      min = optional(number, 1)<br>    }), {})<br><br>    workload_profile_name = optional(string, "Consumption")<br>  })</pre> | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The Azure region in which all resources in this example should be provisioned.<br>Supported regions: Canada Central, Canada East | `string` | `"Canada Central"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the Resource Group in which to deploy resources. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Azure resource tags that will be added to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_container_app_environment"></a> [container\_app\_environment](#output\_container\_app\_environment) | The ContainerApp Environment object which hosts the Containers. |
| <a name="output_custom_dns_next_steps"></a> [custom\_dns\_next\_steps](#output\_custom\_dns\_next\_steps) | If this output is not null, the following steps need to be completed to bind a certificate an Azure Managed Certificate to the Container App for TLS.<br>1. Go to the Azure Portal.<br>2. Navigate to the ContainerApp resource whose name is the value of this output.<br>3. Navigate to the `Custom domains`<br>4. Click on `Add custom domain` to open a blade on the right side of the web page<br>5. Select `Managed certificate` and enter the OpenWebUI FQDN in the `Domain` text box<br>6. Click on `Validate`, then on `Add`<br>7. Back on the `Custom domains` configuration page, click on `Bind` for the new `Custom domains` entry |
| <a name="output_openwebui_fqdn"></a> [openwebui\_fqdn](#output\_openwebui\_fqdn) | The FQDN of the OpenWebUI instance. |
<!-- END_TF_DOCS -->