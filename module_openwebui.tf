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

  openwebui = {

  }
}
