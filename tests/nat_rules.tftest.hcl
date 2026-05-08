mock_provider "azurerm" {}

variables {
  create_new_resource_group = false

  resource_group = {
    name     = "rg-test"
    location = "westeurope"
  }

  virtual_wan_properties = {
    virtual_wan_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualWans/vwan-test"
  }

  vpn_gateways = {
    hub = {
      name               = "vpngw-hub"
      routing_preference = "Microsoft Network"
      scale_unit         = 1
      virtual_hub_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualHubs/vhub-test"
    }
  }

  vpn_gateway_nat_rules = {
    ingress-rule = {
      name             = "nat-rule-ingress"
      vpn_gateway_name = "hub"
      mode             = "IngressSnat"
      internal_mappings = [{ address_space = "192.168.1.4/32" }]
      external_mappings = [{ address_space = "172.16.111.4/32" }]
    }
  }

  vpn_sites = {
    remote-site = {
      name          = "vpnsite-remote"
      address_cidrs = ["192.168.1.0/24", "172.16.111.0/24"]
      links = [{
        name       = "link-remote"
        ip_address = "203.0.113.1"
      }]
    }
  }

  vpn_site_connections = {
    hub-to-remote = {
      name                 = "conn-hub-to-remote"
      vpn_gateway_name     = "hub"
      remote_vpn_site_name = "remote-site"
      vpn_links = [{
        name                   = "link-conn-remote"
        vpn_site_link_number   = 0
        shared_key             = "test-key"
        protocol               = "IKEv2"
        bgp_enabled            = false
        bandwidth_mbps         = 10
        ingress_nat_rule_names = ["ingress-rule"]
      }]
    }
  }
}

# Test: NAT rule is created with correct attributes
run "nat_rule_ingress_created" {
  command = plan

  assert {
    condition     = length(azurerm_vpn_gateway_nat_rule.this) == 1
    error_message = "Expected exactly one NAT rule"
  }

  assert {
    condition     = azurerm_vpn_gateway_nat_rule.this["ingress-rule"].name == "nat-rule-ingress"
    error_message = "NAT rule name mismatch"
  }

  assert {
    condition     = azurerm_vpn_gateway_nat_rule.this["ingress-rule"].mode == "IngressSnat"
    error_message = "NAT rule mode should be IngressSnat"
  }

  assert {
    condition     = azurerm_vpn_gateway_nat_rule.this["ingress-rule"].type == "Static"
    error_message = "NAT rule type should default to Static"
  }
}
