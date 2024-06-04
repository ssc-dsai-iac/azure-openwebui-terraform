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

  oauth_proxy = {
    config = {
      azure_tenant_id = "d05bc194-94bf-4ad6-ae2e-1db0f2e38f5e"
      client_id = "def7e653-d2f6-4067-91e4-f89a1eb61328"
      client_secret = var.oauth2_proxy_client_secret
      oidc_issuer_url = "https://login.microsoftonline.com/d05bc194-94bf-4ad6-ae2e-1db0f2e38f5e/v2.0"
    }
    container = {
      # image = "docker.io/justmbert/oauth2-proxy:rebuild"
    }
  }

  openwebui = {

  }

  ollama = {
    config = {}
    container = {}
  }

  tags = local.tags
}
