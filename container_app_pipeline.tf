locals {}

# ---------------------------------------------------------------------------------------------------------------------
# ContainerApp
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_container_app" "pipeline" {
  name                         = lower(replace(format(local.standardized_name_template, "", "-pipelines", "ca"), "_", "-"))
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  workload_profile_name = var.pipeline.workload_profile_name

  dynamic "identity" {
    for_each = (var.pipeline.identities.enable_system_assigned_identity ||
      length(var.pipeline.identities.user_managed_identity_ids) > 0 ||
      length([for r in var.pipeline.registries : r if can(r.identity_resource_id) && r.identity_resource_id != ""]) > 0) ? [
      {
        system_assigned = var.pipeline.identities.enable_system_assigned_identity
        # Any identity used to access a registry must also be assigned to the App
        user_managed_identity_ids = toset(concat(
          var.pipeline.identities.user_managed_identity_ids,
          [for r in var.pipeline.registries : r.identity_resource_id if can(r.identity_resource_id) && r.identity_resource_id != ""]
        ))
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
    target_port                = 9099

    # Required but only applies if `revision_mode` is `Multiple`.
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  dynamic "registry" {
    for_each = [for registry in var.pipeline.registries : registry if registry.identity_resource_id != null && registry.identity_resource_id != ""]

    content {
      server   = registry.value.server
      identity = registry.value.identity_resource_id
    }
  }

  dynamic "registry" {
    for_each = [for registry in var.pipeline.registries : registry if registry.identity_resource_id == null || registry.identity_resource_id == ""]

    content {
      server               = registry.value.server
      username             = registry.value.username
      password_secret_name = registry.value.password_secret_name
    }
  }

  dynamic "secret" {
    for_each = [for secret in var.pipeline.environment_variables : secret if secret.is_sensitive]

    content {
      name  = lower(replace(secret.value.name, "_", "-"))
      value = secret.value.value
    }
  }

  tags = local.tags

  template {
    container {
      name   = "pipeline"
      image  = var.pipeline.container.image
      cpu    = var.pipeline.container.cpu
      memory = var.pipeline.container.memory

      dynamic "env" {
        for_each = [for env in var.pipeline.environment_variables : env if env.is_sensitive]

        content {
          name        = env.value.name
          secret_name = lower(replace(env.value.name, "_", "-"))
        }
      }

      dynamic "env" {
        for_each = [for env in var.pipeline.environment_variables : env if !env.is_sensitive]

        content {
          name  = env.value.name
          value = env.value.value
        }
      }


      #   liveness_probe {
      #     path      = "/health"
      #     port      = 9099
      #     transport = "HTTP"
      #   }

      #   readiness_probe {
      #     path      = "/health"
      #     port      = 9099
      #     transport = "HTTP"
      #   }
      
      volume_mounts {
        name = "model-cache"
        path = "/model-cache"
      }
    }

    max_replicas = var.pipeline.replicas.max
    min_replicas = var.pipeline.replicas.min

    volume {
      name         = "model-cache"
      storage_name = azurerm_container_app_environment_storage.pipeline.name
      storage_type = "AzureFile"
    }

  }

  lifecycle {
    precondition {
      condition     = length([for wp in azurerm_container_app_environment.this.workload_profile : wp.name if wp.name == var.pipeline.workload_profile_name]) > 0
      error_message = "pipeline.workload_profile_name must be one of ${format("%v", [for wp in azurerm_container_app_environment.this.workload_profile : wp.name])}"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------------------------------------------------

resource "random_id" "pipeline_storage_account" {
  byte_length = "32"
}

resource "azurerm_storage_account" "pipeline" {
  name = lower(format(
    local.globalresource_standardized_name_template,
    join("", [substr(random_id.pipeline_storage_account.hex, 0, 24 - (length(local.globalresource_standardized_name_template) + 1)), "stg"])
  ))
  location                 = var.region
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version = "TLS1_2"

  tags = merge(
    local.tags,
    { applicationName = "pipeline" },
  )
}

resource "azurerm_storage_share" "pipeline" {
  name                 = "model-cache"
  storage_account_name = azurerm_storage_account.pipeline.name
  quota                = 1000
}

resource "azurerm_container_app_environment_storage" "pipeline" {
  name                         = "model-cache"
  container_app_environment_id = azurerm_container_app_environment.this.id
  account_name                 = azurerm_storage_account.pipeline.name
  share_name                   = azurerm_storage_share.pipeline.name
  access_key                   = azurerm_storage_account.pipeline.primary_access_key
  access_mode                  = "ReadWrite"
}