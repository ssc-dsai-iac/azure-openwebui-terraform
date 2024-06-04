# ---------------------------------------------------------------------------------------------------------------------
# ContainerApp
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_container_app" "ollama" {
  name                         = lower(replace(format(local.standardized_name_template, "", "-ollama", "ca"), "_", "-"))
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  workload_profile_name = var.ollama.workload_profile_name

  dynamic "identity" {
    for_each = (var.ollama.identities.enable_system_assigned_identity ||
      length(var.ollama.identities.user_managed_identity_ids) > 0 ||
      length(var.ollama.registries) > 0) ? [
      {
        system_assigned = var.ollama.identities.enable_system_assigned_identity
        # Any identity used to access a registry must also be assigned to the App
        user_managed_identity_ids = toset(concat(var.ollama.identities.user_managed_identity_ids, [for r in var.ollama.registries : r.identity_resource_id]))
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
    target_port                = 11434

    # Required but only applies if `revision_mode` is `Multiple`.
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  dynamic "registry" {
    for_each = var.ollama.registries

    content {
      server   = registry.value.server
      identity = registry.value.identity_resource_id
    }
  }

  tags = local.tags

  template {
    container {
      name   = "ollama"
      image  = var.ollama.container.image
      cpu    = var.ollama.container.cpu
      memory = var.ollama.container.memory

      command = [

      ]

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

      # Configs: https://github.com/ollama/ollama/blob/9db0996ed458e64ee6814d3c276bd5cb57c208ca/envconfig/config.go#L48
      env {
        name  = "OLLAMA_DEBUG"
        value = var.ollama.config.debug
      }

      env {
        name  = "OLLAMA_FLASH_ATTENTION"
        value = var.ollama.config.flash_attention
      }

      env {
        name  = "OLLAMA_HOST"
        value = var.ollama.config.host
      }

      env {
        name  = "OLLAMA_KEEP_ALIVE"
        value = var.ollama.config.keep_alive
      }

      env {
        name  = "OLLAMA_LLM_LIBRARY"
        value = var.ollama.config.llm_library
      }

      env {
        name  = "OLLAMA_MAX_LOADED_MODELS"
        value = var.ollama.config.max_loaded_models
      }

      env {
        name  = "OLLAMA_MAX_QUEUE"
        value = var.ollama.config.max_queue
      }

      env {
        name  = "OLLAMA_MAX_VRAM"
        value = var.ollama.config.max_vram
      }

      env {
        name  = "OLLAMA_MODELS"
        value = var.ollama.config.models
      }

      env {
        name  = "OLLAMA_NOHISTORY"
        value = var.ollama.config.no_history
      }

      env {
        name  = "OLLAMA_NOPRUNE"
        value = var.ollama.config.no_prune
      }

      env {
        name  = "OLLAMA_NUM_PARALLEL"
        value = var.ollama.config.num_parallel
      }

      env {
        name  = "OLLAMA_ORIGINS"
        value = join(",", var.ollama.config.origins)
      }

      env {
        name  = "OLLAMA_RUNNERS_DIR"
        value = var.ollama.config.runners_dir
      }

      env {
        name  = "OLLAMA_TMPDIR"
        value = var.ollama.config.tmpdir
      }
    }

    max_replicas = var.ollama.replicas.max
    min_replicas = var.ollama.replicas.min
  }

  lifecycle {
    precondition {
      condition     = length([for wp in azurerm_container_app_environment.this.workload_profile : wp.name if wp.name == var.ollama.workload_profile_name]) > 0
      error_message = "ollama.workload_profile_name must be one of ${format("%v", [for wp in azurerm_container_app_environment.this.workload_profile : wp.name])}"
    }
  }
}
