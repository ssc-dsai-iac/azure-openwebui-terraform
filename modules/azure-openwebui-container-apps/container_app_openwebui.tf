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
    external_enabled           = false
    target_port                = 8080

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

  secret {
    name  = "database-url"
    value = "postgresql://${azurerm_postgresql_flexible_server.this.administrator_login}:${azurerm_postgresql_flexible_server.this.administrator_password}@${azurerm_postgresql_flexible_server.this.fqdn}:5432/${azurerm_postgresql_flexible_server_database.openwebui.name}?sslmode=require"
  }

  secret {
    name  = "openai-api-key"
    value = random_password.litellm_master_key.result
  }

  tags = local.tags

  template {
    container {
      name   = "openwebui"
      image  = var.openwebui.container.image
      cpu    = var.openwebui.container.cpu
      memory = var.openwebui.container.memory

      env {
        name  = "CUSTOM_NAME"
        value = "CANChatUI"
      }

      env {
        name  = "DEFAULT_USER_ROLE"
        value = "user"
      }

      env {
        name        = "DATABASE_URL"
        secret_name = "database-url"
      }

      env {
        name  = "DEFAULT_MODELS"
        value = "gemma:2b"
      }

      env {
        name  = "ENV"
        value = "dev"
      }

      env {
        name  = "ENABLE_COMMUNITY_SHARING"
        value = "false"
      }

      env {
        name  = "ENABLE_MODEL_FILTER"
        value = false
      }

      env {
        name  = "GLOBAL_LOG_LEVEL"
        value = "INFO"
      }

      env {
        name  = "OLLAMA_BASE_URLS"
        value = "http://${azurerm_container_app.ollama.name}"
      }

      env {
        name  = "OPENAI_API_BASE_URL"
        value = "http://${azurerm_container_app.litellm.name}"
      }

      env {
        name        = "OPENAI_API_KEY"
        secret_name = "openai-api-key"
      }

      env {
        name  = "WEBUI_AUTH_TRUSTED_EMAIL_HEADER"
        value = "X-Forwarded-Email"
      }

      # Image Generation
      env {
        name  = "ENABLE_IMAGE_GENERATION"
        value = true
      }

      env {
        name  = "IMAGE_GENERATION_ENGINE"
        value = "openai"
      }

      env {
        name        = "IMAGES_OPENAI_API_KEY"
        secret_name = "openai-api-key"
      }

      env {
        name  = "IMAGES_OPENAI_API_BASE_URL"
        value = "http://${azurerm_container_app.litellm.name}"
      }

      liveness_probe {
        path      = "/health"
        port      = 8080
        transport = "HTTP"
      }

      readiness_probe {
        path      = "/health"
        port      = 8080
        transport = "HTTP"
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
