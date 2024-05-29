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
      name   = "anything-llm"
      image  = var.openwebui.container.image
      cpu    = var.openwebui.container.cpu
      memory = var.openwebui.container.memory

      # command = [
      #   "/bin/bash",
      #   "-c",
      #   <<-EOC
      #   set -x -e
      #   sleep 3
      #   echo "AWS_REGION: $AWS_REGION"
      #   echo "SERVER_PORT: $SERVER_PORT"
      #   echo "NODE_ENV: $NODE_ENV"
      #   echo "STORAGE_DIR: $STORAGE_DIR"
      #   {
      #     cd /app/server/ &&
      #       npx prisma generate --schema=./prisma/schema.prisma &&
      #       npx prisma migrate deploy --schema=./prisma/schema.prisma &&
      #       node /app/server/index.js
      #     echo "Server process exited with status $?"
      #   } &
      #   {
      #     node /app/collector/index.js
      #     echo "Collector process exited with status $?"
      #   } &
      #   wait -n
      #   exit $?
      #   EOC
      #   ,
      # ]

      # liveness_probe {
      #   path = "/v1/api/health"
      #   port = 3001
      #   # termination_grace_period_seconds = 15
      #   transport = "HTTP"
      # }

      # readiness_probe {
      #   path      = "/v1/api/health"
      #   port      = 3001
      #   transport = "HTTP"
      # }

      # env {
      #   name = "NODE_ENV"
      #   value = "production"
      # }

      # env {
      #   name  = "SERVER_PORT"
      #   value = 3001
      # }
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
