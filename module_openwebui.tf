locals {
  litellm_azure_api_key_env_var_name = "AZURE_API_KEY"
  litellm_params_azure_openai = {
    api_key     = "os.environ/${local.litellm_azure_api_key_env_var_name}"
    api_base    = var.open_ai_host
    # max_retries = 3
    # timeout     = 5
  }

  canchat_db_admins = [for admin in data.azuread_users.canchat_admins.users :
    {
      tenant_id      = data.azurerm_client_config.current.tenant_id
      object_id      = admin.object_id
      principal_name = admin.user_principal_name
      principal_type = "User"
    }
  ]
}

module "openwebui" {
  source = "./modules/azure-openwebui-container-apps"

  resource_group_name = azurerm_resource_group.openwebui.name

  naming = var.naming

  # Container App Environment Configurations
  environment = {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.openwebui.id
    # workload_profiles = [{
    #   name = "test"
    #   type = "D4"
    # }]
  }

  database = {
    ad_admins      = local.canchat_db_admins
    firewall_rules = []
    tenant_id      = data.azurerm_client_config.current.tenant_id
  }

  dns = {
    zone_name                = data.azurerm_dns_zone.dsai_dns.name
    zone_resource_group_name = data.azurerm_dns_zone.dsai_dns.resource_group_name
    record                   = "openwebui.sandbox"
  }

  litellm = {
    config = {
      litellm_settings = {
        set_verbose = true
      }
      model_list = [
        {
          model_name = "gpt-35-turbo"
          litellm_params = merge(
            { model = "azure/chatgpt35" },
            local.litellm_params_azure_openai,
          )
        },
        {
          model_name = "gpt-4"
          litellm_params = merge(
            { model = "azure/chatgpt4" },
            local.litellm_params_azure_openai,
          )
        },
        {
          model_name = "dall-e-3"
          litellm_params = {
            model       = "azure/Dall3"
            api_key     = "os.environ/AZURE_EAST_US_API_KEY"
            api_base    = "https://scsccps-dsai-lab-dev-eastus-oai.openai.azure.com/"
            api_version = "2023-07-01-preview"
            base_model  = "dall-e-2" # Trick to prevent cost-tracking error.
          }
          model_info = {
            mode = "image_generation"
          }
        },
        {
          model_name = "dall-e-2"
          litellm_params = {
            model       = "azure/Dall2"
            api_key     = "os.environ/AZURE_EAST_US_API_KEY"
            api_base    = "https://scsccps-dsai-lab-dev-eastus-oai.openai.azure.com/"
            api_version = "2023-07-01-preview"
            base_model  = "dall-e-2" # Trick to prevent cost-tracking error.
          }
          model_info = {
            mode = "image_generation"
          }
        },
      ]
    }

    container = {
      cpu    = 0.25
      memory = "0.5Gi"
    }

    environment_variables = [
      {
        name         = local.litellm_azure_api_key_env_var_name
        value        = var.openai_api_key
        is_sensitive = true
      },
      {
        name         = "AZURE_EAST_US_API_KEY"
        value        = var.openai_east_us_api_key
        is_sensitive = true
      },
    ]

    replicas = {
      min = 1
    }
  }

  oauth_proxy = {
    config = {
      azure_tenant_id = "d05bc194-94bf-4ad6-ae2e-1db0f2e38f5e"
      client_id       = "def7e653-d2f6-4067-91e4-f89a1eb61328"
      client_secret   = var.oauth2_proxy_client_secret
      oidc_issuer_url = "https://login.microsoftonline.com/d05bc194-94bf-4ad6-ae2e-1db0f2e38f5e/v2.0"
    }
    container = {
      # image = "docker.io/justmbert/oauth2-proxy:rebuild"
    }
  }

  openwebui = {

  }

  ollama = {
    config    = {}
    container = {}
  }

  tags = local.tags
}
