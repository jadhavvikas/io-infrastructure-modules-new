provider "azurerm" {
  version = "=1.44.0"
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "azurerm" {}
}

resource "azurerm_subnet" "subnet" {
  name                 = var.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefix       = var.address_prefix

  dynamic "delegation" {
    for_each = var.delegation == null ? [] : ["delegation"]
    content {
      name = var.delegation.name

      service_delegation {
        name    = var.delegation.service_delegation.name
        actions = var.delegation.service_delegation.actions
      }
    }
  }

  service_endpoints = var.service_endpoints
}
