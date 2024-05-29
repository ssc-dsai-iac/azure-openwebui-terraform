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

variable "anything_llm" {
  description = "Configurations for the Anything LLM Container App."
  type = object({
    # https://github.com/Mintplex-Labs/anything-llm/blob/master/server/.env.example
    config = optional(object({

    }), {})

    container = optional(object({
      image  = optional(string, "docker.io/mintplexlabs/anythingllm:master")
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
    condition     = var.anything_llm.container.image != ""
    error_message = "container.image cannot be null or empty"
  }

  # regitries validation
  validation {
    condition     = alltrue([for r in var.anything_llm.registries : r.server != null && r.server != ""])
    error_message = "server entries in anything_llm.registries cannot be null or empty"
  }

  validation {
    condition     = alltrue([for r in var.anything_llm.registries : r.identity_resource_id != null && r.identity_resource_id != ""])
    error_message = "identity_resource_id entries in anything_llm.registries cannot be null or empty"
  }

  # replicas validation
  validation {
    condition     = var.anything_llm.replicas.max >= 1 && var.anything_llm.replicas.max <= 300
    error_message = "anything_llm.replicas.max must be between 1 and 300 (inclusive)"
  }

  validation {
    condition     = var.anything_llm.replicas.min >= 0 && var.anything_llm.replicas.min <= 300
    error_message = "anything_llm.replicas.max must be between 0 and 300 (inclusive)"
  }

  validation {
    condition     = var.anything_llm.replicas.max >= var.anything_llm.replicas.min
    error_message = "var.anything_llm.replicas.max must be larger or equal to var.anything_llm.replicas.min"
  }

  # workload_profile_name validation
  validation {
    condition     = var.anything_llm.workload_profile_name != ""
    error_message = "anything_llm.workload_profile_name cannot be empty"
  }
}
