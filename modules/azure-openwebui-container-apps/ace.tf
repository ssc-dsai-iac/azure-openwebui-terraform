# ---------------------------------------------------------------------------------------------------------------------
# ContainerApp environment
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_container_app_environment" "this" {
  name                       = replace(format(local.standardized_name_template, "", "", "cae"), "_", "-")
  location                   = var.region
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.environment.log_analytics_workspace_id

  infrastructure_resource_group_name = var.environment.subnet_id != null && var.environment.subnet_id != "" ? format(local.standardized_name_template, "", "-Managed", "rg") : null

  dapr_application_insights_connection_string = var.environment.dapr_application_insights_connection_string

  infrastructure_subnet_id = var.environment.subnet_id

  internal_load_balancer_enabled = var.environment.internal_load_balancer_enabled
  zone_redundancy_enabled        = var.environment.zone_redundancy_enabled

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
    maximum_count         = 0
    minimum_count         = 0
  }

  dynamic "workload_profile" {
    for_each = [for wp in var.environment.workload_profiles : wp if wp.type != "Consumption"]

    content {
      name                  = workload_profile.value.name
      workload_profile_type = workload_profile.value.type
      maximum_count         = workload_profile.value.maximum_count
      minimum_count         = workload_profile.value.minimum_count
    }
  }

  tags = local.tags
}
