terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.106"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }

    random = {
      source = "hashicorp/random"
      version = "~> 3.6.2"
    }
  }
  required_version = ">= 1.2.6"
}
