locals {}

# ---------------------------------------------------------------------------------------------------------------------
# ContainerApp
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_container_app" "oauth_proxy" {
  name                         = lower(replace(format(local.standardized_name_template, "", "-oauth", "ca"), "_", "-"))
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  workload_profile_name = var.oauth_proxy.workload_profile_name

  dynamic "identity" {
    for_each = (var.oauth_proxy.identities.enable_system_assigned_identity ||
      length(var.oauth_proxy.identities.user_managed_identity_ids) > 0 ||
      length(var.oauth_proxy.registries) > 0) ? [
      {
        system_assigned = var.oauth_proxy.identities.enable_system_assigned_identity
        # Any identity used to access a registry must also be assigned to the App
        user_managed_identity_ids = toset(concat(var.oauth_proxy.identities.user_managed_identity_ids, [for r in var.oauth_proxy.registries : r.identity_resource_id]))
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
    target_port                = 4180

    # Required but only applies if `revision_mode` is `Multiple`.
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  dynamic "registry" {
    for_each = var.oauth_proxy.registries

    content {
      server   = registry.value.server
      identity = registry.value.identity_resource_id
    }
  }

  secret {
    name  = "oauth-proxy-client-secret"
    value = var.oauth_proxy.config.client_secret
  }

  secret {
    name  = "oauth-proxy-cookie-secret"
    value = random_password.oauth_proxy_cookie_secret.result
  }

  tags = local.tags

  template {
    container {
      name   = "oauth-proxy"
      image  = var.oauth_proxy.container.image
      cpu    = var.oauth_proxy.container.cpu
      memory = var.oauth_proxy.container.memory

      env {
        name  = "OAUTH2_PROXY_AZURE_TENANT"
        value = var.oauth_proxy.config.azure_tenant_id
      }

      env {
        name  = "OAUTH2_PROXY_CLIENT_ID"
        value = var.oauth_proxy.config.client_id
      }

      env {
        name        = "OAUTH2_PROXY_CLIENT_SECRET"
        secret_name = "oauth-proxy-client-secret"
      }

      env {
        name  = "OAUTH2_PROXY_COOKIE_NAME"
        value = var.oauth_proxy.config.cookie_name
      }

      env {
        name  = "OAUTH2_PROXY_COOKIE_SAMESITE"
        value = "none"
      }

      env {
        name        = "OAUTH2_PROXY_COOKIE_SECRET"
        secret_name = "oauth-proxy-cookie-secret"
      }

      env {
        name  = "OAUTH2_PROXY_EMAIL_DOMAINS"
        value = "ssc-spc.gc.ca"
      }

      env {
        name  = "OAUTH2_PROXY_ERRORS_TO_INFO_LOG"
        value = true
      }

      env {
        name  = "OAUTH2_PROXY_HTTP_ADDRESS"
        value = var.oauth_proxy.config.http_address
      }

      env {
        name  = "OAUTH2_PROXY_OIDC_ISSUER_URL"
        value = var.oauth_proxy.config.oidc_issuer_url
      }

      env {
        name  = "OAUTH2_PROXY_PASS_HOST_HEADER"
        value = false
      }

      env {
        name  = "OAUTH2_PROXY_PROVIDER"
        value = var.oauth_proxy.config.provider
      }

      env {
        name  = "OAUTH2_PROXY_REDIRECT_URL"
        value = var.oauth_proxy.config.redirect_url
      }

      env {
        name  = "OAUTH2_PROXY_REVERSE_PROXY"
        value = true
      }

      env {
        name  = "OAUTH2_PROXY_SESSION_COOKIE_MINIMAL"
        value = true
      }

      env {
        name  = "OAUTH2_PROXY_SKIP_PROVIDER_BUTTON"
        value = var.oauth_proxy.config.skip_provider_button
      }

      env {
        name  = "OAUTH2_PROXY_UPSTREAMS"
        value = "http://${azurerm_container_app.openwebui.name}"
        # value = "https://${azurerm_container_app.ollama.name}"
        # value = "static://222"
        # value = "http://${lower(replace(format(local.standardized_name_template, "", "", "ca"), "_", "-"))}"
        # value = "http://scsc-dsai-openwebui-ca/"
      }

      liveness_probe {
        path      = "/ping"
        port      = 4180
        transport = "HTTP"
      }
    }

    max_replicas = var.oauth_proxy.replicas.max
    min_replicas = var.oauth_proxy.replicas.min
  }



  lifecycle {
    precondition {
      condition     = length([for wp in azurerm_container_app_environment.this.workload_profile : wp.name if wp.name == var.oauth_proxy.workload_profile_name]) > 0
      error_message = "oauth_proxy.workload_profile_name must be one of ${format("%v", [for wp in azurerm_container_app_environment.this.workload_profile : wp.name])}"
    }
  }
}

resource "random_password" "oauth_proxy_cookie_secret" {
  length           = 32
  override_special = "-_"
}
