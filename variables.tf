variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "create_new_resource_group" {
  description = "A flag to create a Resource Group for the IP Groups"
  type        = bool
  default     = true
}

variable "resource_group" {
  description = "The Resource Group to add the IP Groups to or create if create_ipg_resource_group is true"
  type = object({
    name     = string
    location = string
  })
}

variable "virtual_wan_properties" {
  description = "The Virtual WAN properties"
  type = object({
    virtual_wan_id = string
    virtual_hub_id = string
  })
}

variable "vpn_gateways" {
  description = "The VPN Gateway to create"
  type = map(object({
    name               = string
    routing_preference = string
    scale_unit         = number
  }))
}

variable "vpn_sites" {
  description = "The VPN Site to create"
  type = map(object({
    name          = string
    address_cidrs = optional(list(string))
    device_model  = optional(string)
    device_vendor = optional(string)
    links = list(object({
      name          = string
      ip_address    = optional(string)
      provider_name = optional(string)
      speed_in_mbps = optional(number)
      bgp_settings = optional(object({
        asn                 = number
        bgp_peering_address = string
      }))
    }))
  }))
}

variable "vpn_site_connections" {
  type = map(object({
    name                                  = string
    vpn_gateway_name                      = string
    remote_vpn_site_name                  = string
    protocol                              = optional(string)
    ratelimit_enabled                     = optional(bool)
    route_weight                          = optional(number)
    shared_key                            = optional(string)
    local_azure_ip_address_enabled        = optional(bool)
    policy_based_traffic_selector_enabled = optional(bool)
    internet_security_enabled             = optional(bool)

    vpn_links = list(object({
      name = string
      # Index of the link on the vpn gateway
      vpn_site_link_number = number
      bandwidth_mbps       = optional(number)
      bgp_enabled          = optional(bool)
      connection_mode      = optional(string)

      ipsec_policy = optional(object({
        dh_group                 = string
        ike_encryption_algorithm = string
        ike_integrity_algorithm  = string
        encryption_algorithm     = string
        integrity_algorithm      = string
        pfs_group                = string
        sa_data_size_kb          = string
        sa_lifetime_sec          = string
      }))

      custom_bgp_address = optional(list(object({
        ip_address          = string
        ip_configuration_id = string
      })))
    }))
  }))
}
