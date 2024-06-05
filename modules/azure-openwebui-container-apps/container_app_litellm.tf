# ---------------------------------------------------------------------------------------------------------------------
# ContainerApp
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_container_app" "litellm" {
  name                         = lower(replace(format(local.standardized_name_template, "", "-litellm", "ca"), "_", "-"))
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  workload_profile_name = var.litellm.workload_profile_name

  dynamic "identity" {
    for_each = (var.litellm.identities.enable_system_assigned_identity ||
      length(var.litellm.identities.user_managed_identity_ids) > 0 ||
      length(var.litellm.registries) > 0) ? [
      {
        system_assigned = var.litellm.identities.enable_system_assigned_identity
        # Any identity used to access a registry must also be assigned to the App
        user_managed_identity_ids = toset(concat(var.litellm.identities.user_managed_identity_ids, [for r in var.litellm.registries : r.identity_resource_id]))
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
    target_port                = 4000

    # Required but only applies if `revision_mode` is `Multiple`.
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  dynamic "registry" {
    for_each = var.litellm.registries

    content {
      server   = registry.value.server
      identity = registry.value.identity_resource_id
    }
  }

  secret {
    name = "master-key"
    value = random_password.litellm_master_key.result
  }

  tags = local.tags

  dynamic "secret" {
    for_each = [for secret in var.litellm.environment_variables : secret if secret.is_sensitive]

    content {
      name  = lower(replace(secret.value.name, "_", "-"))
      value = secret.value.value
    }
  }

  template {
    container {
      name   = "litellm"
      image  = var.litellm.container.image
      cpu    = var.litellm.container.cpu
      memory = var.litellm.container.memory

      args = [
        "--config",
        "/litellm_config/${azurerm_storage_share_file.litellm_config.name}",
      ]

      # This env is in place to ensure that the proxy is restarted if the config changes.
      env {
        name  = "__LITELLM_CONFIG_MD5"
        value = md5(local_file.litellm_config.content)
      }

      env {
        name = "LITELLM_MASTER_KEY"
        secret_name = "master-key"
      }

      dynamic "env" {
        for_each = [for env in var.litellm.environment_variables : env if env.is_sensitive]

        content {
          name        = env.value.name
          secret_name = lower(replace(env.value.name, "_", "-"))
        }
      }

      dynamic "env" {
        for_each = [for env in var.litellm.environment_variables : env if !env.is_sensitive]

        content {
          name  = env.value.name
          value = env.value.value
        }
      }

      liveness_probe {
        path = "/health/liveliness"
        port = 4000
        # termination_grace_period_seconds = 15
        transport = "HTTP"
      }

      readiness_probe {
        path      = "/health/readiness"
        port      = 4000
        transport = "HTTP"
      }

      volume_mounts {
        name = "litellm-config"
        path = "/litellm_config"
      }
    }

    max_replicas = var.litellm.replicas.max
    min_replicas = var.litellm.replicas.min

    volume {
      name         = "litellm-config"
      storage_name = azurerm_container_app_environment_storage.litellm.name
      storage_type = "AzureFile"
    }
  }

  lifecycle {
    precondition {
      condition     = length([for wp in azurerm_container_app_environment.this.workload_profile : wp.name if wp.name == var.litellm.workload_profile_name]) > 0
      error_message = "litellm.workload_profile_name must be one of ${format("%v", [for wp in azurerm_container_app_environment.this.workload_profile : wp.name])}"
    }
  }
}

resource "local_file" "litellm_config" {
  filename = "${path.module}/generated_configs/litellm_config.json"
  content  = jsonencode(var.litellm.config)
}

resource "random_password" "litellm_master_key" {
  length  = 32
  special = false
}

# ---------------------------------------------------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------------------------------------------------

resource "random_id" "litellm_storage_account" {
  byte_length = "32"
}

resource "azurerm_storage_account" "litellm" {
  name = lower(format(
    local.globalresource_standardized_name_template,
    join("", [substr(random_id.litellm_storage_account.hex, 0, 24 - (length(local.globalresource_standardized_name_template) + 1)), "stg"])
  ))
  location                 = var.region
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version = "TLS1_2"

  tags = merge(
    local.tags,
    { applicationName = "litellm" },
  )
}

# resource "azurerm_role_assignment" "litellm_storage_account_contributor" {
#   role_definition_name  = "Storage Account Contributor"
#   scope = azurerm_storage_account.litellm
#   principal_id = data.azurerm_client_config.current.object_id
# }

resource "azurerm_storage_share" "litellm_config" {
  name                 = "litellm-config"
  storage_account_name = azurerm_storage_account.litellm.name
  quota                = 1000
}

resource "azurerm_storage_share_file" "litellm_config" {
  name             = "litellm_config.json"
  storage_share_id = azurerm_storage_share.litellm_config.id
  source           = local_file.litellm_config.filename
  content_md5      = md5(local_file.litellm_config.content)
}

resource "azurerm_container_app_environment_storage" "litellm" {
  name                         = "litellm-config"
  container_app_environment_id = azurerm_container_app_environment.this.id
  account_name                 = azurerm_storage_account.litellm.name
  share_name                   = azurerm_storage_share.litellm_config.name
  access_key                   = azurerm_storage_account.litellm.primary_access_key
  access_mode                  = "ReadOnly"
}
