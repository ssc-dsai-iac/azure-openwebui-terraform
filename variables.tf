variable "region" {
  description = <<-EOD
    The Azure region in which all resources in this example should be provisioned.
    Supported regions: Canada Central, Canada East
    EOD
  type        = string
  default     = "Canada Central"
  nullable    = false

  validation {
    condition     = contains(["Canada Central", "Canada East"], var.region)
    error_message = "var.region must be one of: ${format("%v", ["Canada Central", "Canada East"])}"
  }
}

variable "naming" {
  description = <<-EOD
    Values that define the names of resources using the following pattern: <departmentCode><environment><region><deviceType>-<group>-<userDefined><descriptor>-<suffix>
    Note: deviceType, descriptor, and suffix are set by the module.
    EOD
  type = object({
    department_code = optional(string, "Sc")
    environment     = string
    group           = string
    user_defined    = string
  })
  nullable = false

  validation {
    condition     = var.naming.department_code != ""
    error_message = "naming.department_code cannot be empty"
  }

  validation {
    condition     = var.naming.environment != null ? contains(["Development", "Quality Assurance", "Production", "Sandbox", "Testing", "UAT"], var.naming.environment) : false
    error_message = "naming.environment must be one of: ${format("%v", ["Development", "Quality Assurance", "Production", "Sandbox", "Testing", "UAT"])}"
  }

  validation {
    condition     = var.naming.group != null && var.naming.group != ""
    error_message = "naming.group cannot be null or empty"
  }

  validation {
    condition     = var.naming.user_defined != null && var.naming.user_defined != ""
    error_message = "naming.user_defined cannot be null or empty"
  }
}

variable "tags" {
  description = "Azure resource tags that will be added to all resources."
  type        = map(string)

  nullable = false

  default = {}
}

variable "resource_group_name" {
  description = "The name of the Resource Group in which to deploy resources."
  type        = string

  validation {
    condition     = var.resource_group_name != null && var.resource_group_name != ""
    error_message = "resource_group_name cannot be null or empty"
  }
}

variable "environment" {
  description = "Configurations for the Container App Environment."
  type = object({
    internal_load_balancer_enabled              = optional(bool, null)
    dapr_application_insights_connection_string = optional(string)
    log_analytics_workspace_id                  = optional(string)
    subnet_id                                   = optional(string)
    zone_redundancy_enabled                     = optional(bool, null)

    workload_profiles = optional(list(object({
      name          = string
      type          = string
      maximum_count = optional(number, 1)
      minimum_count = optional(number, 1)
    })), [])
  })

  default = {}

  validation {
    condition     = var.environment.dapr_application_insights_connection_string != ""
    error_message = "environment.dapr_application_insights_connection_string cannot be an empty string"
  }

  validation {
    condition     = var.environment.log_analytics_workspace_id != ""
    error_message = "environment.log_analytics_workspace_id cannot be an empty string"
  }

  validation {
    condition     = var.environment.subnet_id != ""
    error_message = "environment.subnet_id cannot be an empty string"
  }

  validation {
    condition     = (var.environment.internal_load_balancer_enabled != null && var.environment.subnet_id != null && var.environment.subnet_id != "") || var.environment.internal_load_balancer_enabled == null
    error_message = "environment.internal_load_balancer_enabled can only be set if environment.subnet_id is set"
  }

  validation {
    condition     = (var.environment.zone_redundancy_enabled != null && var.environment.subnet_id != null && var.environment.subnet_id != "") || var.environment.zone_redundancy_enabled == null
    error_message = "environment.zone_redundancy_enabled can only be set if environment.subnet_id is set"
  }

  validation {
    condition     = alltrue([for wp in var.environment.workload_profiles : wp.name != null && wp.name != ""])
    error_message = "names of environment.workload_profiles cannot be null or empty"
  }

  validation {
    condition     = alltrue([for wp in var.environment.workload_profiles : wp.type != null && wp.type != "" ? contains(["Consumption", "D4", "D8", "D16", "D32", "E4", "E8", "E16", "E32"], wp.type) : false])
    error_message = "types of environment.workload_profiles cannot be null or empty and must be one of ${format("%v", ["Consumption", "D4", "D8", "D16", "D32", "E4", "E8", "E16", "E32"])}"
  }

  validation {
    condition     = alltrue([for wp in var.environment.workload_profiles : wp.maximum_count != null ? wp.maximum_count >= 0 && wp.maximum_count <= 20 : false])
    error_message = "maximum_count of environment.workload_profiles cannot be null and must be between 0 and 20 (inclusive)"
  }

  validation {
    condition     = alltrue([for wp in var.environment.workload_profiles : wp.maximum_count != null ? wp.maximum_count >= 0 && wp.maximum_count <= 20 : false])
    error_message = "minimum_counts of environment.workload_profiles cannot be null and must be between 0 and 20 (inclusive)"
  }

  validation {
    condition     = alltrue([for wp in var.environment.workload_profiles : wp.minimum_count <= wp.maximum_count])
    error_message = "minimum_counts must be smaller or equal to their respective maximum_count for each environment.workload_profiles"
  }
}

variable "database" {
  description = "Configures the PostgreSQL database which backs OpenWebUI."
  type = object({
    ad_admins = optional(list(object({
      tenant_id      = string
      object_id      = string
      principal_name = string
      principal_type = string
    })), [])
    firewall_rules = optional(list(object({
      name             = optional(string, "")
      start_ip_address = string
      end_ip_address   = string
    })), [])
    sku_name   = optional(string, "B_Standard_B1ms")
    storage_mb = optional(number, 32768)
    tenant_id  = optional(string, null)
    version    = optional(number, 16)
    zone       = optional(number, 1)
  })

  default = {}

  validation {
    condition     = alltrue([for admin in var.database.ad_admins : admin.principal_type != null ? contains(["Group", "ServicePrincipal", "User"], admin.principal_type) : false])
    error_message = "database.ad_admins.principal_type must be one of ${format("%v", ["Group", "ServicePrincipal", "User"])}"
  }

  validation {
    condition     = alltrue([for admin in var.database.ad_admins : admin.tenant_id != null && admin.tenant_id != ""])
    error_message = "database.ad_admins.tenant_id cannot be null or empty"
  }

  validation {
    condition     = alltrue([for admin in var.database.ad_admins : admin.object_id != null && admin.object_id != ""])
    error_message = "database.ad_admins.object_id cannot be null or empty"
  }

  validation {
    condition     = alltrue([for admin in var.database.ad_admins : admin.principal_name != null && admin.principal_name != ""])
    error_message = "database.ad_admins.principal_name cannot be null or empty"
  }

  validation {
    condition     = alltrue([for rule in var.database.firewall_rules : rule.start_ip_address != null && rule.start_ip_address != ""])
    error_message = "database.firewall_rules.start_ip_address cannot be null or empty."
  }

  validation {
    condition     = alltrue([for rule in var.database.firewall_rules : rule.end_ip_address != null && rule.end_ip_address != ""])
    error_message = "database.firewall_rules.end_ip_address cannot be null or empty."
  }

  validation {
    condition     = contains(range(11, 16 + 1), var.database.version)
    error_message = "database.version must be one of ${format("%v", range(11, 16 + 1))}"
  }
}

variable "dns" {
  description = "Custom DNS configurations."
  type = object({
    zone_name                = string
    zone_resource_group_name = string
    record                   = string
  })

  default = null
}

variable "litellm" {
  description = "Configurations for the CanChat Container App."
  type = object({
    config = object({
      general_settings = optional(any, {})
      litellm_settings = optional(any, {})
      model_list = list(
        object({
          model_name     = string
          litellm_params = optional(any, {})
          model_info     = optional(any, {})
        })
      )
    })

    container = optional(object({
      image  = optional(string, "ghcr.io/berriai/litellm:main-v1.40.12")
      cpu    = optional(number, 1)
      memory = optional(string, "2Gi")
    }), {})

    environment_variables = optional(list(object({
      name         = string
      value        = string
      is_sensitive = bool
    })), [])

    identities = optional(object({
      enable_system_assigned_identity = optional(bool, false)
      user_managed_identity_ids       = optional(list(string), [])
    }), {})

    registries = optional(list(object({
      server               = string
      identity_resource_id = string
    })), [])

    replicas = optional(object({
      max = optional(number, 1)
      min = optional(number, 1)
    }), {})

    workload_profile_name = optional(string, "Consumption")
  })

  # Config validation
  validation {
    condition     = var.litellm.config != null
    error_message = "litellm.config cannot be null"
  }

  validation {
    condition     = var.litellm.config.model_list != null
    error_message = "litellm.config.model_list cannot be null"
  }

  validation {
    condition     = var.litellm.config.model_list != null ? length(var.litellm.config.model_list) > 0 : false
    error_message = "litellm.config.model_list requires at least one model"
  }

  validation {
    condition     = var.litellm.config.model_list != null ? alltrue([for model in var.litellm.config.model_list : model.model_name != null && model.model_name != ""]) : false
    error_message = "litellm.config.model_list.model_name cannot be null or empty"
  }

  # container validation
  validation {
    condition     = var.litellm.container.image != null && var.litellm.container.image != ""
    error_message = "container.image cannot be null or empty"
  }

  # regitries validation
  validation {
    condition     = alltrue([for r in var.litellm.registries : r.server != null && r.server != ""])
    error_message = "server entries in litellm.registries cannot be null or empty"
  }

  validation {
    condition     = alltrue([for r in var.litellm.registries : r.identity_resource_id != null && r.identity_resource_id != ""])
    error_message = "identity_resource_id entries in litellm.registries cannot be null or empty"
  }

  # replicas validation
  validation {
    condition     = var.litellm.replicas.max >= 1 && var.litellm.replicas.max <= 300
    error_message = "litellm.replicas.max must be between 1 and 300 (inclusive)"
  }

  validation {
    condition     = var.litellm.replicas.min >= 0 && var.litellm.replicas.min <= 300
    error_message = "litellm.replicas.max must be between 0 and 300 (inclusive)"
  }

  validation {
    condition     = var.litellm.replicas.max >= var.litellm.replicas.min
    error_message = "var.litellm.replicas.max must be larger or equal to var.litellm.replicas.min"
  }

  # workload_profile_name validation
  validation {
    condition     = var.litellm.workload_profile_name != ""
    error_message = "litellm.workload_profile_name cannot be empty"
  }
}

variable "oauth_proxy" {
  description = "Configurations for the oauth-proxy Container App."
  type = object({
    config = object({
      azure_tenant_id      = string
      client_id            = string
      client_secret        = string
      cookie_name          = optional(string, "__Secure-OpenWebUI")
      oidc_issuer_url      = string
      reverse_proxy        = optional(bool, true)
      skip_provider_button = optional(bool, true)
    })

    container = optional(object({
      image  = optional(string, "quay.io/oauth2-proxy/oauth2-proxy:v7.6.0")
      cpu    = optional(number, 0.5)
      memory = optional(string, "1Gi")
    }), {})

    identities = optional(object({
      enable_system_assigned_identity = optional(bool, false)
      user_managed_identity_ids       = optional(list(string), [])
    }), {})

    registries = optional(list(object({
      server               = string
      identity_resource_id = string
    })), [])

    replicas = optional(object({
      max = optional(number, 1)
      min = optional(number, 1)
    }), {})

    workload_profile_name = optional(string, "Consumption")
  })

  # Config validation
  # TODO:


  # container validation
  validation {
    condition     = var.oauth_proxy.container.image != ""
    error_message = "container.image cannot be null or empty"
  }

  # regitries validation
  validation {
    condition     = alltrue([for r in var.oauth_proxy.registries : r.server != null && r.server != ""])
    error_message = "server entries in oauth_proxy.registries cannot be null or empty"
  }

  validation {
    condition     = alltrue([for r in var.oauth_proxy.registries : r.identity_resource_id != null && r.identity_resource_id != ""])
    error_message = "identity_resource_id entries in oauth_proxy.registries cannot be null or empty"
  }

  # replicas validation
  validation {
    condition     = var.oauth_proxy.replicas.max >= 1 && var.oauth_proxy.replicas.max <= 300
    error_message = "oauth_proxy.replicas.max must be between 1 and 300 (inclusive)"
  }

  validation {
    condition     = var.oauth_proxy.replicas.min >= 0 && var.oauth_proxy.replicas.min <= 300
    error_message = "oauth_proxy.replicas.max must be between 0 and 300 (inclusive)"
  }

  validation {
    condition     = var.oauth_proxy.replicas.max >= var.oauth_proxy.replicas.min
    error_message = "var.oauth_proxy.replicas.max must be larger or equal to var.oauth_proxy.replicas.min"
  }

  # workload_profile_name validation
  validation {
    condition     = var.oauth_proxy.workload_profile_name != ""
    error_message = "oauth_proxy.workload_profile_name cannot be empty"
  }
}

variable "openwebui" {
  description = "Configurations for the Open WebUI Container App."
  type = object({
    # https://docs.openwebui.com/getting-started/env-configuration
    config = optional(object({

    }), {})

    container = optional(object({
      image  = optional(string, "ghcr.io/open-webui/open-webui:0.3.5")
      cpu    = optional(number, 1)
      memory = optional(string, "2Gi")
    }), {})

    identities = optional(object({
      enable_system_assigned_identity = optional(bool, false)
      user_managed_identity_ids       = optional(list(string), [])
    }), {})

    registries = optional(list(object({
      server               = string
      identity_resource_id = string
    })), [])

    replicas = optional(object({
      max = optional(number, 1)
      min = optional(number, 1)
    }), {})

    workload_profile_name = optional(string, "Consumption")
  })

  # Config validation


  # container validation
  validation {
    condition     = var.openwebui.container.image != ""
    error_message = "container.image cannot be null or empty"
  }

  # regitries validation
  validation {
    condition     = alltrue([for r in var.openwebui.registries : r.server != null && r.server != ""])
    error_message = "server entries in openwebui.registries cannot be null or empty"
  }

  validation {
    condition     = alltrue([for r in var.openwebui.registries : r.identity_resource_id != null && r.identity_resource_id != ""])
    error_message = "identity_resource_id entries in openwebui.registries cannot be null or empty"
  }

  # replicas validation
  validation {
    condition     = var.openwebui.replicas.max >= 1 && var.openwebui.replicas.max <= 300
    error_message = "openwebui.replicas.max must be between 1 and 300 (inclusive)"
  }

  validation {
    condition     = var.openwebui.replicas.min >= 0 && var.openwebui.replicas.min <= 300
    error_message = "openwebui.replicas.max must be between 0 and 300 (inclusive)"
  }

  validation {
    condition     = var.openwebui.replicas.max >= var.openwebui.replicas.min
    error_message = "var.openwebui.replicas.max must be larger or equal to var.openwebui.replicas.min"
  }

  # workload_profile_name validation
  validation {
    condition     = var.openwebui.workload_profile_name != ""
    error_message = "openwebui.workload_profile_name cannot be empty"
  }
}

variable "ollama" {
  description = "Configurations for the Ollama Container App."
  type = object({
    config = object({
      debug             = optional(number, 0)
      flash_attention   = optional(bool, false)
      host              = optional(string, "0.0.0.0:11434")
      keep_alive        = optional(string, "5m")
      llm_library       = optional(string, "")
      max_loaded_models = optional(number, 1)
      max_queue         = optional(number, 0)
      max_vram          = optional(number, 0)
      models            = optional(string, "")
      no_history        = optional(string, "") # Non-empty string will enable
      no_prune          = optional(string, "") # Non-empty string will enable
      num_parallel      = optional(number, 1)
      origins = optional(list(string), [
        "http://localhost",
        "http://127.0.0.1",
        "http://0.0.0.0",
        "https://localhost",
        "https://127.0.0.1",
        "https://0.0.0.0",
      ])
      runners_dir = optional(string, "")
      tmpdir      = optional(string, "")
    })

    container = object({
      image  = optional(string, "docker.io/ollama/ollama:0.1.39")
      cpu    = optional(number, 1)
      memory = optional(string, "2Gi")
    })

    identities = optional(object({
      enable_system_assigned_identity = optional(bool, false)
      user_managed_identity_ids       = optional(list(string), [])
    }), {})

    registries = optional(list(object({
      server               = string
      identity_resource_id = string
    })), [])

    replicas = optional(object({
      max = optional(number, 1)
      min = optional(number, 1)
    }), {})

    workload_profile_name = optional(string, "Consumption")
  })

  # Config validation
  validation {
    condition     = var.ollama.config != null
    error_message = "ollama.config cannot be null"
  }

  # TODO: create validation rules.

  # container validation
  validation {
    condition     = var.ollama.container.image != null && var.ollama.container.image != ""
    error_message = "container.image cannot be null or empty"
  }

  # registries validation
  validation {
    condition     = alltrue([for r in var.ollama.registries : r.server != null && r.server != ""])
    error_message = "server entries in ollama.registries cannot be null or empty"
  }

  validation {
    condition     = alltrue([for r in var.ollama.registries : r.identity_resource_id != null && r.identity_resource_id != ""])
    error_message = "identity_resource_id entries in ollama.registries cannot be null or empty"
  }

  # replicas validation
  validation {
    condition     = var.ollama.replicas.max >= 1 && var.ollama.replicas.max <= 300
    error_message = "ollama.replicas.max must be between 1 and 300 (inclusive)"
  }

  validation {
    condition     = var.ollama.replicas.min >= 0 && var.ollama.replicas.min <= 300
    error_message = "ollama.replicas.max must be between 0 and 300 (inclusive)"
  }

  validation {
    condition     = var.ollama.replicas.max >= var.ollama.replicas.min
    error_message = "var.ollama.replicas.max must be larger or equal to var.ollama.replicas.min"
  }

  # workload_profile_name validation
  validation {
    condition     = var.ollama.workload_profile_name != ""
    error_message = "ollama.workload_profile_name cannot be empty"
  }
}

variable "qdrant" {
  description = "Configurations for the qdrant Container App."
  type = object({
    config = optional(object({
      log_level = optional(string, "INFO")
      service = optional(object({
        max_request_size_mb = optional(number, 32)
      }), {})
    }), {})

    container = optional(object({
      image  = optional(string, "docker.io/qdrant/qdrant:v1.11.3-unprivileged")
      cpu    = optional(number, 1)
      memory = optional(string, "2Gi")
    }), {})

    identities = optional(object({
      enable_system_assigned_identity = optional(bool, false)
      user_managed_identity_ids       = optional(list(string), [])
    }), {})

    registries = optional(list(object({
      server               = string
      identity_resource_id = string
    })), [])

    replicas = optional(object({
      max = optional(number, 1)
      min = optional(number, 1)
    }), {})

    workload_profile_name = optional(string, "Consumption")
  })

  # Config validation
  validation {
    condition     = var.qdrant.config != null
    error_message = "qdrant.config cannot be null"
  }

  validation {
    condition     = var.qdrant.config.log_level != null ? contains(["ERROR", "WARN", "INFO", "DEBUG", "TRACE"], var.qdrant.config.log_level) : false
    error_message = "qdrant.config.log_level must not be null and must be one of ${format("%v", ["ERROR", "WARN", "INFO", "DEBUG", "TRACE"])}"
  }

  validation {
    condition     = var.qdrant.config.service.max_request_size_mb > 0
    error_message = "qdrant.config.service.max_request_size_mb must be larger than 0"
  }

  # container validation
  validation {
    condition     = var.qdrant.container.image != ""
    error_message = "container.image cannot be null or empty"
  }

  # regitries validation
  validation {
    condition     = alltrue([for r in var.qdrant.registries : r.server != null && r.server != ""])
    error_message = "server entries in qdrant.registries cannot be null or empty"
  }

  validation {
    condition     = alltrue([for r in var.qdrant.registries : r.identity_resource_id != null && r.identity_resource_id != ""])
    error_message = "identity_resource_id entries in qdrant.registries cannot be null or empty"
  }

  # replicas validation
  validation {
    condition     = var.qdrant.replicas.max >= 1 && var.qdrant.replicas.max <= 300
    error_message = "qdrant.replicas.max must be between 1 and 300 (inclusive)"
  }

  validation {
    condition     = var.qdrant.replicas.min >= 0 && var.qdrant.replicas.min <= 300
    error_message = "qdrant.replicas.max must be between 0 and 300 (inclusive)"
  }

  validation {
    condition     = var.qdrant.replicas.max >= var.qdrant.replicas.min
    error_message = "var.qdrant.replicas.max must be larger or equal to var.qdrant.replicas.min"
  }

  # workload_profile_name validation
  validation {
    condition     = var.qdrant.workload_profile_name != ""
    error_message = "qdrant.workload_profile_name cannot be empty"
  }
}