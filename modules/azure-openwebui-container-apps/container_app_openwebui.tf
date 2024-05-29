locals {}

# ---------------------------------------------------------------------------------------------------------------------
# ContainerApp
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_container_app" "openwebui" {
  name                         = lower(replace(format(local.standardized_name_template, "", "", "ca"), "_", "-"))
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  workload_profile_name = var.openwebui.workload_profile_name

  dynamic "identity" {
    for_each = (var.openwebui.identities.enable_system_assigned_identity ||
      length(var.openwebui.identities.user_managed_identity_ids) > 0 ||
      length(var.openwebui.registries) > 0) ? [
      {
        system_assigned = var.openwebui.identities.enable_system_assigned_identity
        # Any identity used to access a registry must also be assigned to the App
        user_managed_identity_ids = toset(concat(var.openwebui.identities.user_managed_identity_ids, [for r in var.openwebui.registries : r.identity_resource_id]))
      }
    ] : []

    content {
      # type is expected to be one of "SystemAssigned", "UserAssigned", or "SystemAssigned, UserAssigned" which requires this triple ternary
      type = identity.value.system_assigned ? (length(identity.value.user_managed_identity_ids) > 0 ? "SystemAssigned, UserAssigned" : "SystemAssigned") : (length(identity.value.user_managed_identity_ids) > 0 ? "UserAssigned" : null)
      # type = "UserAssigned"
      identity_ids = identity.value.user_managed_identity_ids
    }
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 3001

    # Required but only applies if `revision_mode` is `Multiple`.
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  dynamic "registry" {
    for_each = var.openwebui.registries

    content {
      server   = registry.value.server
      identity = registry.value.identity_resource_id
    }
  }

  tags = local.tags

  template {
    container {
      name   = "openwebui"
      image  = var.openwebui.container.image
      cpu    = var.openwebui.container.cpu
      memory = var.openwebui.container.memory

      env {
        name  = "OLLAMA_BASE_URLS"
        value = ""
      }
    }

    max_replicas = var.openwebui.replicas.max
    min_replicas = var.openwebui.replicas.min
  }

  lifecycle {
    precondition {
      condition     = length([for wp in azurerm_container_app_environment.this.workload_profile : wp.name if wp.name == var.openwebui.workload_profile_name]) > 0
      error_message = "openwebui.workload_profile_name must be one of ${format("%v", [for wp in azurerm_container_app_environment.this.workload_profile : wp.name])}"
    }
  }
}
