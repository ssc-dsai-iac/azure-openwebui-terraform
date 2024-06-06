resource "azurerm_dns_txt_record" "openwebui" {
  count = var.dns != null ? 1 : 0

  name                = "asuid.${var.dns.record}"
  resource_group_name = var.dns.zone_resource_group_name
  zone_name           = var.dns.zone_name
  ttl                 = 300

  record {
    value = azurerm_container_app.openwebui.custom_domain_verification_id
  }
}

resource "azurerm_dns_cname_record" "openwebui" {
  count = var.dns != null ? 1 : 0

  name                = trimprefix(azurerm_dns_txt_record.openwebui[0].name, "asuid.")
  resource_group_name = var.dns.zone_resource_group_name
  zone_name           = var.dns.zone_name
  ttl                 = 300
  record              = "${azurerm_container_app.oauth_proxy.name}.${azurerm_container_app_environment.this.default_domain}"
}

output "openwebui_fqdn" {
  description = "The FQDN of the OpenWebUI instance."
  value       = var.dns != null ? "https://${azurerm_dns_cname_record.openwebui[0].fqdn}" : "https://$(CONTAINER_APP_NAME).$(CONTAINER_APP_ENV_DNS_SUFFIX)"
}

output "custom_dns_next_steps" {
  description = <<-EOD
    If this output is not null, the following steps need to be completed to bind a certificate an Azure Managed Certificate to the Container App for TLS.
    1. Go to the Azure Portal.
    2. Navigate to the ContainerApp resource whose name is the value of this output.
    3. Navigate to the `Custom domains`
    4. Click on `Add custom domain` to open a blade on the right side of the web page
    5. Select `Managed certificate` and enter the OpenWebUI FQDN in the `Domain` text box
    6. Click on `Validate`, then on `Add`
    7. Back on the `Custom domains` configuration page, click on `Bind` for the new `Custom domains` entry
    EOD
  value       = var.dns != null ? azurerm_container_app.oauth_proxy.name : null
}

# resource "time_sleep" "wait_for_dns" {
#   depends_on = [azurerm_dns_cname_record.openwebui]

#   create_duration = "5s"
# }

# NOTE: Requires manually binding the certificate on the ContainerApp due to bug in provider
# https://github.com/hashicorp/terraform-provider-azurerm/issues/25788
# resource "azurerm_container_app_custom_domain" "openwebui" {
#   # depends_on = [time_sleep.wait_for_dns]

#   name                     = trimsuffix(azurerm_dns_cname_record.openwebui.fqdn, ".")
#   container_app_id         = azurerm_container_app.oauth_proxy.id
#   certificate_binding_type = "SniEnabled"

#   lifecycle {
#     // When using an Azure created Managed Certificate these values must be added to ignore_changes to prevent resource recreation.
#     # ignore_changes = [certificate_binding_type, container_app_environment_certificate_id]
#   }
# }
