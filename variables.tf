variable "region" {
  type = string
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
    condition     = var.naming.department_code != null || var.naming.department_code != ""
    error_message = "naming.department_code cannot be null or empty"
  }

  validation {
    condition     = var.naming.environment != null ? contains(["Development", "Quality Assurance", "Production", "Sandbox", "Testing", "UAT"], var.naming.environment) : false
    error_message = "naming.environment must be one of: Development | Quality Assurance | Production | Sandbox | Testing | UAT"
  }

  validation {
    condition     = var.naming.group != null || var.naming.group != ""
    error_message = "naming.group cannot be null or empty"
  }

  validation {
    condition     = var.naming.user_defined != null || var.naming.user_defined != ""
    error_message = "naming.user_defined cannot be null or empty"
  }
}

variable "oauth2_proxy_client_secret" {
  type      = string
  sensitive = true
}
