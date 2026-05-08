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

  vpn_sites            = {}
  vpn_site_connections = {}
}

# Test: invalid mode is rejected
run "invalid_nat_rule_mode" {
  command = plan

  variables {
    vpn_gateway_nat_rules = {
      bad-rule = {
        name             = "nat-rule-bad"
        vpn_gateway_name = "hub"
        mode             = "InvalidMode"
        internal_mappings = [{ address_space = "192.168.1.0/24" }]
        external_mappings = [{ address_space = "172.16.111.0/24" }]
      }
    }
  }

  expect_failures = [
    var.vpn_gateway_nat_rules,
  ]
}

# Test: invalid type is rejected
run "invalid_nat_rule_type" {
  command = plan

  variables {
    vpn_gateway_nat_rules = {
      bad-rule = {
        name             = "nat-rule-bad"
        vpn_gateway_name = "hub"
        mode             = "IngressSnat"
        type             = "InvalidType"
        internal_mappings = [{ address_space = "192.168.1.0/24" }]
        external_mappings = [{ address_space = "172.16.111.0/24" }]
      }
    }
  }

  expect_failures = [
    var.vpn_gateway_nat_rules,
  ]
}

# Test: empty mappings are rejected
run "empty_nat_rule_mappings" {
  command = plan

  variables {
    vpn_gateway_nat_rules = {
      bad-rule = {
        name              = "nat-rule-bad"
        vpn_gateway_name  = "hub"
        mode              = "IngressSnat"
        internal_mappings = []
        external_mappings = [{ address_space = "172.16.111.0/24" }]
      }
    }
  }

  expect_failures = [
    var.vpn_gateway_nat_rules,
  ]
}

# Test: multiple mappings per rule are accepted
run "multiple_mappings_per_rule" {
  command = plan

  variables {
    vpn_gateway_nat_rules = {
      multi-rule = {
        name             = "nat-rule-multi"
        vpn_gateway_name = "hub"
        mode             = "IngressSnat"
        internal_mappings = [
          { address_space = "192.168.1.0/24" },
          { address_space = "192.168.2.0/25" },
        ]
        external_mappings = [
          { address_space = "172.16.1.0/24" },
          { address_space = "172.16.2.0/25" },
        ]
      }
    }
  }

  assert {
    condition     = length(azurerm_vpn_gateway_nat_rule.this) == 1
    error_message = "Expected exactly one NAT rule with multiple mappings"
  }
}
