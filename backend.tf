terraform {
  backend "azurerm" {
    resource_group_name  = "ScSc-DSAI-Terraform-rg"
    storage_account_name = "scsccsadsaiterraformdls1"
    container_name       = "tfstate-openwebui"
    key                  = "container-app.sandbox.tfstate"
    use_azuread_auth     = true
  }
}
