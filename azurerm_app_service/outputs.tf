output "id" {
  value = azurerm_app_service.app_service.id
}

output "name" {
  value = azurerm_app_service.app_service.name
}

output "subnet_id" {
  value = module.subnet.id
}

output "default_site_hostname" {
  value = azurerm_app_service.app_service.default_site_hostname
}

output "outbound_ip_addresses" {
  value = azurerm_app_service.app_service.outbound_ip_addresses
}

output "possible_outbound_ip_addresses" {
  value = azurerm_app_service.app_service.possible_outbound_ip_addresses
}
