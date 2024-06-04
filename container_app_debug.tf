resource "azurerm_container_app" "debug" {
  name                         = "debug"
  container_app_environment_id = module.openwebui.container_app_environment.id
  resource_group_name          = azurerm_resource_group.openwebui.name
  revision_mode                = "Single"

  workload_profile_name = "Consumption"

  template {
    container {
      name   = "debug"
      image  = "docker.io/library/alpine:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      command = [
        # keep the pod running infinitely.
        "tail",
        "-f",
        "/dev/null",
      ]
    }
  }

  tags = local.tags
}
