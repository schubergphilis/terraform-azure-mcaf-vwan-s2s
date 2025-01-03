resource "azurerm_resource_group" "this" {
  count    = 1
  name     = "example-resource-group"
  location = "West Europe"
  tags = {
    "Environment"   = "Development"
    "Project"       = "ExampleProject"
    "Resource Type" = "Resource Group"
  }
}

resource "azurerm_vpn_site" "this" {
  for_each            = {
    site1 = {
      name = "example-vpn-site1"
      address_cidrs = ["10.0.0.0/24"]
      links = [
        {
          name = "link1"
          ip_address = "192.168.1.1"
          provider_name = "Provider1"
          speed_in_mbps = 100
          bgp_settings = {
            asn = 65001
            bgp_peering_address = "192.168.1.2"
          }
        }
      ]
    }
    site2 = {
      name = "example-vpn-site2"
      address_cidrs = ["10.1.0.0/24"]
      links = [
        {
          name = "link2"
          ip_address = "192.168.2.1"
          provider_name = "Provider2"
          speed_in_mbps = 200
          bgp_settings = {
            asn = 65002
            bgp_peering_address = "192.168.2.2"
          }
        }
      ]
    }
  }
  name                = each.value.name
  location            = "West Europe"
  resource_group_name = "example-resource-group"
  virtual_wan_id      = "/subscriptions/your-subscription-id/resourceGroups/example-resource-group/providers/Microsoft.Network/virtualWans/example-virtual-wan"
  address_cidrs       = each.value.address_cidrs

  dynamic "link" {
    for_each = each.value.links
    content {
      name          = link.value.name
      ip_address    = link.value.ip_address
      provider_name = link.value.provider_name
      speed_in_mbps = link.value.speed_in_mbps

      dynamic "bgp" {
        for_each = [link.value.bgp_settings]
        content {
          asn             = bgp.value.asn
          peering_address = bgp.value.bgp_peering_address
        }
      }
    }
  }

  tags = {
    "Environment"   = "Development"
    "Project"       = "ExampleProject"
    "Resource Type" = "VPN Site"
  }
}

resource "azurerm_vpn_gateway_connection" "this" {
  for_each = {
    connection1 = {
      vpn_gateway_name = "example-vpn-gateway1"
      vpn_site_name = "example-vpn-site1"
      internet_security_enabled = true
      vpn_links = [
        {
          name = "link1"
          bandwidth_mbps = 100
          bgp_enabled = true
          connection_mode = "Default"
          protocol = "IKEv2"
          ratelimit_enabled = false
          route_weight = 10
          shared_key = "example-shared-key"
          local_azure_ip_address_enabled = true
          policy_based_traffic_selector_enabled = false
          ipsec_policy = {
            dh_group = "DHGroup14"
            ike_encryption_algorithm = "AES256"
            ike_integrity_algorithm = "SHA256"
            encryption_algorithm = "AES256"
            integrity_algorithm = "SHA256"
            pfs_group = "PFS2"
            sa_data_size_kb = 102400000
            sa_lifetime_sec = 3600
          }
          custom_bgp_address = {
            ip_address = "192.168.1.3"
            ip_configuration_id = "/subscriptions/your-subscription-id/resourceGroups/example-resource-group/providers/Microsoft.Network/virtualNetworkGateways/example-vpn-gateway1/ipConfigurations/ipconfig1"
          }
        }
      ]
    }
  }

  name                      = "${each.value.vpn_gateway_name}-${each.value.vpn_site_name}"
  vpn_gateway_id            = "/subscriptions/your-subscription-id/resourceGroups/example-resource-group/providers/Microsoft.Network/vpnGateways/${each.value.vpn_gateway_name}"
  remote_vpn_site_id        = azurerm_vpn_site.this[each.value.vpn_site_name].id
  internet_security_enabled = each.value.internet_security_enabled

  dynamic "vpn_link" {
    for_each = each.value.vpn_links
    content {
      name                                  = vpn_link.value.name
      vpn_site_link_id                      = azurerm_vpn_site.this[each.value.vpn_site_name].link[vpn_link.value.name].id
      bandwidth_mbps                        = vpn_link.value.bandwidth_mbps
      bgp_enabled                           = vpn_link.value.bgp_enabled
      connection_mode                       = vpn_link.value.connection_mode
      protocol                              = vpn_link.value.protocol
      ratelimit_enabled                     = vpn_link.value.ratelimit_enabled
      route_weight                          = vpn_link.value.route_weight
      shared_key                            = vpn_link.value.shared_key
      local_azure_ip_address_enabled        = vpn_link.value.local_azure_ip_address_enabled
      policy_based_traffic_selector_enabled = vpn_link.value.policy_based_traffic_selector_enabled

      dynamic "ipsec_policy" {
        for_each = [vpn_link.value.ipsec_policy]
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
        for_each = [vpn_link.value.custom_bgp_address]
        content {
          ip_address          = custom_bgp_address.value.ip_address
          ip_configuration_id = custom_bgp_address.value.ip_configuration_id
        }
      }
    }
  }
}