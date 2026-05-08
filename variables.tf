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
  })
}

variable "vpn_gateways" {
  description = "The VPN Gateway to create"
  type = map(object({
    name               = string
    routing_preference = string
    scale_unit         = number
    virtual_hub_id     = string
    bgp_settings = optional(object({
      asn                            = number
      instance_0_bgp_peering_address = optional(string)
      instance_1_bgp_peering_address = optional(string)
      peer_weight                    = number
    }))
  }))
}

variable "vpn_sites" {
  description = "The VPN Site to create"
  type = map(object({
    name          = string
    address_cidrs = optional(list(string))
    device_model  = optional(string, null)
    device_vendor = optional(string, null)
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
    name                      = string
    vpn_gateway_name          = string
    remote_vpn_site_name      = string
    internet_security_enabled = optional(bool)

    vpn_links = list(object({
      name = string
      # Index of the link on the vpn gateway
      vpn_site_link_number                  = number
      bandwidth_mbps                        = optional(number)
      bgp_enabled                           = optional(bool)
      route_weight                          = optional(number)
      ratelimit_enabled                     = optional(bool)
      protocol                              = optional(string)
      shared_key                            = optional(string)
      connection_mode                       = optional(string)
      local_azure_ip_address_enabled        = optional(bool)
      policy_based_traffic_selector_enabled = optional(bool)

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

      ingress_nat_rule_names = optional(list(string), [])
      egress_nat_rule_names  = optional(list(string), [])
    }))
  }))
}

variable "vpn_gateway_nat_rules" {
  type = map(object({
    name             = string
    vpn_gateway_name = string
    mode             = string
    type             = optional(string, "Static")

    internal_mappings = list(object({
      address_space = string
      port_range    = optional(string)
    }))

    external_mappings = list(object({
      address_space = string
      port_range    = optional(string)
    }))
  }))
  default     = {}
  description = <<-EOT
    VPN Gateway NAT rules for IP translation over S2S VPN connections.

    - vpn_gateway_name: the map key in var.vpn_gateways.
    - mode: "IngressSnat" (translate source of incoming packets) or "EgressSnat" (translate source of outgoing packets).
    - type: "Static" (1:1 fixed mapping, bidirectional) or "Dynamic" (many:1 NAPT, unidirectional from internal side only, max /26 external).
    - internal_mappings / external_mappings: one or more address translation entries per rule.
      Each entry has an address_space (CIDR) and an optional port_range (Static type only, individual port).

    Static NAT example (1:1):
      internal_mappings = [{ address_space = "10.0.1.0/24" }]
      external_mappings = [{ address_space = "192.168.1.0/24" }]

    Dynamic NAT example (many:1 NAPT, /24 to /26):
      internal_mappings = [{ address_space = "10.0.1.0/24" }]
      external_mappings = [{ address_space = "192.168.1.0/26" }]

    Multiple prefixes per rule:
      internal_mappings = [
        { address_space = "10.0.1.0/24" },
        { address_space = "10.0.2.0/25" },
      ]
      external_mappings = [
        { address_space = "192.168.1.0/24" },
        { address_space = "192.168.2.0/25" },
      ]
  EOT

  validation {
    condition     = alltrue([for k, v in var.vpn_gateway_nat_rules : contains(["IngressSnat", "EgressSnat"], v.mode)])
    error_message = "mode must be 'IngressSnat' or 'EgressSnat'."
  }

  validation {
    condition     = alltrue([for k, v in var.vpn_gateway_nat_rules : contains(["Static", "Dynamic"], v.type)])
    error_message = "type must be 'Static' or 'Dynamic'."
  }

  validation {
    condition     = alltrue([for k, v in var.vpn_gateway_nat_rules : length(v.internal_mappings) > 0 && length(v.external_mappings) > 0])
    error_message = "Each NAT rule must have at least one internal_mapping and one external_mapping."
  }
}
