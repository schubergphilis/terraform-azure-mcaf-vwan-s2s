resource "azurerm_resource_group" "this" {
  count    = var.create_new_resource_group ? 1 : 0
  name     = var.resource_group.name
  location = var.resource_group.location
  tags = merge(
    try(var.tags),
    tomap({
      "Resource Type" = "Resource Group"
    })
  )
}

resource "azurerm_vpn_gateway" "this" {
  for_each = var.vpn_gateways

  name                = each.value.name
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  virtual_hub_id      = var.virtual_wan_properties.virtual_hub_id

  routing_preference = try(each.value.routing_preference, null)
  scale_unit         = try(each.value.scale_unit, null)

  tags = merge(
    try(var.tags),
    tomap({
      "Resource Type" = "VPN Gateway"
    })
  )
}



resource "azurerm_vpn_site" "this" {
  for_each            = var.vpn_sites != null ? var.vpn_sites : {}
  name                = each.value.name
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name

  virtual_wan_id = var.virtual_wan_properties.virtual_wan_id
  address_cidrs  = each.value.address_cidrs

  dynamic "link" {
    for_each = each.value.links != null && length(each.value.links) > 0 ? each.value.links : []
    content {
      name          = link.value.name
      ip_address    = link.value.ip_address
      provider_name = link.value.provider_name
      speed_in_mbps = link.value.speed_in_mbps

      dynamic "bgp" {
        for_each = link.value.bgp_settings != null ? [link.value.bgp_settings] : []
        content {
          asn             = bgp.value.asn
          peering_address = bgp.value.bgp_peering_address
        }
      }
    }
  }

  tags = merge(
    try(var.tags),
    tomap({
      "Resource Type" = "VPN Site"
    })
  )
}

resource "azurerm_vpn_gateway_connection" "this" {
  for_each = var.vpn_site_connections != null && length(var.vpn_site_connections) > 0 ? var.vpn_site_connections : {}

  name                      = each.value.name
  vpn_gateway_id            = azurerm_vpn_gateway.this[each.value.vpn_gateway_name].id
  remote_vpn_site_id        = azurerm_vpn_site.this[each.value.remote_vpn_site_name].id
  internet_security_enabled = try(each.value.internet_security_enabled, null)

  dynamic "vpn_link" {
    for_each = each.value.vpn_links != null && length(each.value.vpn_links) > 0 ? each.value.vpn_links : []

    content {
      name                                  = vpn_link.value.name
      vpn_site_link_id                      = azurerm_vpn_site.this[var.vpn_sites[each.key].name].link[vpn_link.value.name].id
      bandwidth_mbps                        = try(vpn_link.value.bandwidth_mbps, null)
      bgp_enabled                           = try(vpn_link.value.bgp_enabled, null)
      connection_mode                       = try(vpn_link.value.connection_mode, null)
      protocol                              = try(vpn_link.value.protocol, null)
      ratelimit_enabled                     = try(vpn_link.value.ratelimit_enabled, null)
      route_weight                          = try(vpn_link.value.route_weight, null)
      shared_key                            = try(vpn_link.value.shared_key, null)
      local_azure_ip_address_enabled        = try(vpn_link.value.local_azure_ip_address_enabled, null)
      policy_based_traffic_selector_enabled = try(vpn_link.value.policy_based_traffic_selector_enabled, null)

      dynamic "ipsec_policy" {
        for_each = vpn_link.value.ipsec_policy != null ? [vpn_link.value.ipsec_policy] : []

        content {
          dh_group                 = ipsec_policy.value.dh_group
          ike_encryption_algorithm = ipsec_policy.value.ike_encryption_algorithm
          ike_integrity_algorithm  = ipsec_policy.value.ike_integrity_algorithm
          encryption_algorithm     = ipsec_policy.value.encryption_algorithm
          integrity_algorithm      = ipsec_policy.value.integrity_algorithm
          pfs_group                = ipsec_policy.value.pfs_group
          sa_data_size_kb          = ipsec_policy.value.sa_data_size_kb
          sa_lifetime_sec          = ipsec_policy.value.sa_lifetime_sec
        }
      }

      dynamic "custom_bgp_address" {
        for_each = vpn_link.value.custom_bgp_address != null ? [vpn_link.value.custom_bgp_address] : []

        content {
          ip_address          = custom_bgp_address.value.ip_address
          ip_configuration_id = custom_bgp_address.value.ip_configuration_id
        }
      }
    }
  }
}
