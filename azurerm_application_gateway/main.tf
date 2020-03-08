provider "azurerm" {
  version = "=1.44"
}

terraform {
  backend "azurerm" {}
}

data "azurerm_key_vault_secret" "certificate_secret" {
  name         = var.custom_domains.certificate_name
  key_vault_id = var.custom_domains.keyvault_id
}

module "subnet" {
  source = "git::git@github.com:pagopa/io-infrastructure-modules-new.git//azurerm_subnet?ref=v0.0.33"

  global_prefix     = var.global_prefix
  environment       = var.environment
  environment_short = var.environment_short
  region            = var.region

  name                 = "ag${var.name}"
  resource_group_name  = var.virtual_network_info.resource_group_name
  virtual_network_name = var.virtual_network_info.name
  address_prefix       = var.virtual_network_info.subnet_address_prefix

  service_endpoints = [
    "Microsoft.Web"
  ]
}

resource "azurerm_application_gateway" "application_gateway" {
  name                = local.resource_name
  resource_group_name = var.resource_group_name
  location            = var.region

  sku {
    name     = var.sku.name
    tier     = var.sku.tier
    capacity = var.sku.capacity
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.custom_domains.identity_id]
  }

  gateway_ip_configuration {
    name      = local.gateway_ip_configuration_name
    subnet_id = module.subnet.id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = var.public_ip_info.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = var.frontend_port
  }

  ssl_certificate {
    name                = "sslcertificate"
    key_vault_secret_id = trimsuffix(data.azurerm_key_vault_secret.certificate_secret.id, "${data.azurerm_key_vault_secret.certificate_secret.version}")
  }

  dynamic "http_listener" {
    for_each = var.services
    iterator = service

    content {
      name                           = "httplistener-${service.value.name}"
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_port_name             = local.frontend_port_name
      protocol                       = service.value.http_listener.protocol
      host_name                      = service.value.http_listener.host_name
      ssl_certificate_name           = "sslcertificate"
      require_sni                    = true
    }
  }

  dynamic "backend_address_pool" {
    for_each = var.services
    iterator = service

    content {
      name         = "backendaddresspool-${service.value.name}"
      ip_addresses = service.value.backend_address_pool.ip_addresses
      fqdns        = service.value.backend_address_pool.fqdns
    }
  }

  dynamic "probe" {
    for_each = var.services
    iterator = service

    content {
      name                = "probe-${service.value.name}"
      host                = service.value.probe.host
      protocol            = service.value.probe.protocol
      path                = service.value.probe.path
      interval            = service.value.probe.interval
      timeout             = service.value.probe.timeout
      unhealthy_threshold = service.value.probe.unhealthy_threshold
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.services
    iterator = service

    content {
      name                  = "backendhttpsettings-${service.value.name}"
      protocol              = service.value.backend_http_settings.protocol
      port                  = service.value.backend_http_settings.port
      path                  = service.value.backend_http_settings.path
      cookie_based_affinity = service.value.backend_http_settings.cookie_based_affinity
      request_timeout       = service.value.backend_http_settings.request_timeout
      probe_name            = "probe-${service.value.name}"
      host_name             = service.value.backend_http_settings.host_name
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.services
    iterator = service

    content {
      name                       = "requestroutingrule-${service.value.name}"
      http_listener_name         = "httplistener-${service.value.name}"
      backend_address_pool_name  = "backendaddresspool-${service.value.name}"
      backend_http_settings_name = "backendhttpsettings-${service.value.name}"
      rule_type                  = "Basic"
    }
  }
}

resource "azurerm_dns_a_record" "dns_a_record" {
  for_each = { for service in var.services : service.name => service.a_record_name }

  name                = each.value
  zone_name           = var.custom_domains.zone_name
  resource_group_name = var.custom_domains.zone_resource_group_name
  ttl                 = 300
  records = [
    var.public_ip_info.ip
  ]
}