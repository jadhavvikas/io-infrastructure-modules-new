variable "global_prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "environment_short" {
  type = string
}

variable "region" {
  type = string
}

variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "public_ip_allocation_method" {
  type = string
}

variable "public_ip_sku" {
  type = string
}

variable "type" {
  type        = string
  description = "The type of the Virtual Network Gateway."
}

variable "vpn_type" {
  type        = string
  description = "The routing type of the Virtual Network Gateway."
  default     = "RouteBased"
}

variable "active_active" {
  type        = bool
  description = "If true, an active-active Virtual Network Gateway will be created."
  default     = false
}

variable "enable_bgp" {
  type        = bool
  description = "If true, BGP (Border Gateway Protocol) will be enabled for this Virtual Network Gateway"
  default     = false
}

variable "sku" {
  type        = string
  description = "Configuration of the size and capacity of the virtual network gateway"
}

variable "default_local_network_gateway_id" {
  type        = string
  description = "The ID of the local network gateway through which outbound Internet traffic from the virtual network in which the gateway is created will be routed"
  default     = null
}

variable "generation" {
  type        = string
  description = "The Generation of the Virtual Network gateway"
  default     = null
}

variable "ip_configurations" {
  type = list(object({
    name                          = string
    private_ip_address_allocation = string
  }))
}

variable "vpn_client_configurations" {
  type = list(object({
    address_space = list(string)
    root_certificates = list(object({
      name             = string
      public_cert_data = string
    }))
    revoked_certificates = list(object({
      name       = string
      thumbprint = string
    }))
    radius_server_address = string
    radius_server_secret  = string
    vpn_client_protocols  = list(string)
  }))
  default = []
}

variable "subnet_id" {
  type        = string
  description = "The id of the subnet where to place the vpn gateway."
  default     = null
}

# Local network gateway
variable "gateway_address" {
  type        = string
  description = "The IP address of the gateway to which to connect."
}

variable "gateway_address_space" {
  type        = list(string)
  description = "The list of string CIDRs representing the address spaces the gateway exposes."
}

variable "bgp_settings" {
  type        = list(object({
    asn                 = string
    bgp_peering_address = string
    peer_weight         = string
  }))
  default     = []
}

## Virtual Network Gateway Connection

variable "connection_type" {
  type        = string
  description = "The type of connection. Valid options are IPsec (Site-to-Site), ExpressRoute (ExpressRoute), and Vnet2Vnet (VNet-to-VNet)."
}

variable "shared_key" {
  type        = string
  description = "The shared IPSec key. A key must be provided if a Site-to-Site or VNet-to-VNet connection is created whereas ExpressRoute connections do not need a shared key."
  default     = null
}



locals {
  resource_name                           = "${var.global_prefix}-${var.environment_short}-vnetgw-${var.name}"
  virtual_network_local_gateway_name      = "${var.global_prefix}-${var.environment_short}-vnetgw-l-${var.name}"
  virtual_network_gateway_connection_name = "${var.global_prefix}-${var.environment_short}-cn-${var.name}"
}
