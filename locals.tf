locals {
  tags = {
    configurationSource = "https://github.com/ssc-dsai-iac/azure-openwebui-terraform"
  }


  # The standardized naming convention template to be used for naming resources.
  # It can be used in the following manner:
  # format(local.standardized_name_template, <deviceType>, <userDefinedExtension>, <suffix>)
  standardized_name_template = "${var.naming.department_code}${lookup({
    "Development"       = "D",
    "Quality Assurance" = "Q",
    "Production"        = "P",
    "Sandbox"           = "S",
    "Testing"           = "T",
    "UAT"               = "U",
    }, var.naming.environment, "")}${lookup({
    "Canada Central" = "c",
    "Canada East"    = "d",
  }, var.region, "")}%s-${var.naming.group}-${var.naming.user_defined}%s-%s"

  # The standardized naming convention template to be used for naming global resource (i.e. storage accounts, key vaults, etc.).
  # Provides the following naming convention with the number of allocated characters (max 24):
  #   <dept-code:2><env:1><CSP-region:1><user-defined:max 12><random:min 5><suffix:3>
  # It can be used in the following manner:
  # lower(format(
  #   local.globalresource_standardized_name_template,
  #   join("", [substr(<randomString>, 0, 24 - (length(local.globalresource_standardized_name_template) + 1)), <suffix>])
  # ))
  globalresource_standardized_name_template = "${var.naming.department_code}${lookup({
    "Development"       = "D",
    "Quality Assurance" = "Q",
    "Production"        = "P",
    "Sandbox"           = "S",
    "Testing"           = "T",
    "UAT"               = "U",
    }, var.naming.environment, "")}${lookup({
    "Canada Central" = "c",
    "Canada East"    = "d",
  }, var.region, "")}${substr(replace(join("", [var.naming.group, var.naming.user_defined]), "_", ""), 0, 12)}%s"
}
