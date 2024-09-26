locals {
  qdrant_storage = {
    storage = {
      name         = "qdrant-storage"
      path         = "/qdrant/storage"
      env_variable = "QDRANT__STORAGE__STORAGE_PATH"
    },
    snapshots = {
      name         = "qdrant-snapshots"
      path         = "/qdrant/snapshots"
      env_variable = "QDRANT__STORAGE__SNAPSHOTS_PATH"
    },
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ContainerApp
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_container_app" "qdrant" {
  name                         = lower(replace(format(local.standardized_name_template, "", "-qdrant", "ca"), "_", "-"))
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  workload_profile_name = var.qdrant.workload_profile_name

  dynamic "identity" {
    for_each = (var.qdrant.identities.enable_system_assigned_identity ||
      length(var.qdrant.identities.user_managed_identity_ids) > 0 ||
      length(var.qdrant.registries) > 0) ? [
      {
        system_assigned = var.qdrant.identities.enable_system_assigned_identity
        # Any identity used to access a registry must also be assigned to the App
        user_managed_identity_ids = toset(concat(var.qdrant.identities.user_managed_identity_ids, [for r in var.qdrant.registries : r.identity_resource_id]))
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
    target_port                = 6333

    # Required but only applies if `revision_mode` is `Multiple`.
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  dynamic "registry" {
    for_each = var.qdrant.registries

    content {
      server   = registry.value.server
      identity = registry.value.identity_resource_id
    }
  }

  tags = local.tags

  template {
    container {
      name   = "qdrant"
      image  = var.qdrant.container.image
      cpu    = var.qdrant.container.cpu
      memory = var.qdrant.container.memory

      args = [
        # "--disable-telemetry",
      ]

      liveness_probe {
        path = "/livez"
        port = 6333
        # termination_grace_period_seconds = 15
        transport = "HTTP"
      }

      readiness_probe {
        path      = "/readyz"
        port      = 6333
        transport = "HTTP"
      }

      env {
        name  = "QDRANT__LOG_LEVEL"
        value = var.qdrant.config.log_level
      }

      env {
        name  = "QDRANT__SERVICE__MAX_REQUEST_SIZE_MB"
        value = var.qdrant.config.service.max_request_size_mb
      }

      env {
        name  = "QDRANT__STORAGE__TEMP_PATH"
        value = "/qdrant/snapshots_temp"
      }

      env {
        name  = "QDRANT__TELEMETRY_DISABLED"
        value = "true"
      }

      dynamic "env" {
        for_each = local.qdrant_storage

        content {
          name  = env.value.env_variable
          value = env.value.path
        }
      }

      volume_mounts {
        name = "temp-snapshots"
        path = "/qdrant/snapshots_temp"
      }

      dynamic "volume_mounts" {
        for_each = local.qdrant_storage

        content {
          name = volume_mounts.value.name
          path = volume_mounts.value.path
        }
      }
    }

    max_replicas = var.qdrant.replicas.max
    min_replicas = var.qdrant.replicas.min

    volume {
      name         = "temp-snapshots"
      storage_type = "EmptyDir"
    }

    dynamic "volume" {
      for_each = toset([for storage in azurerm_container_app_environment_storage.qdrant : storage.name])

      content {
        name         = volume.key
        storage_type = "AzureFile"
        storage_name = volume.key
      }
    }
  }

  lifecycle {
    precondition {
      condition     = length([for wp in azurerm_container_app_environment.this.workload_profile : wp.name if wp.name == var.qdrant.workload_profile_name]) > 0
      error_message = "qdrant.workload_profile_name must be one of ${format("%v", [for wp in azurerm_container_app_environment.this.workload_profile : wp.name])}"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------------------------------------------------

resource "random_id" "qdrant_storage_account" {
  byte_length = "32"
}

resource "azurerm_storage_account" "qdrant" {
  name = lower(format(
    local.globalresource_standardized_name_template,
    join("", [substr(random_id.qdrant_storage_account.hex, 0, 24 - (length(local.globalresource_standardized_name_template) + 1)), "stg"])
  ))
  location                 = var.region
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version = "TLS1_2"

  tags = merge(
    local.tags,
    { applicationName = "qdrant" },
  )
}

resource "azurerm_storage_share" "qdrant" {
  for_each             = local.qdrant_storage
  name                 = each.value.name
  storage_account_name = azurerm_storage_account.qdrant.name
  quota                = 1000
}

resource "azurerm_container_app_environment_storage" "qdrant" {
  for_each = local.qdrant_storage

  name                         = each.value.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  account_name                 = azurerm_storage_account.qdrant.name
  share_name                   = each.value.name
  access_key                   = azurerm_storage_account.qdrant.primary_access_key
  access_mode                  = "ReadWrite"
}