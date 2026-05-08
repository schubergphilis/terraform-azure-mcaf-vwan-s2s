terraform {
  required_version = ">= 1.8"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.5, < 5.0"
    }
  }
}

resource "azurerm_resource_group" "this" {
  name     = "example-nat-rules"
  location = "West Europe"
}

module "s2svpn" {
  source = "../.."

  create_new_resource_group = false
  resource_group = {
    name     = azurerm_resource_group.this.name
    location = azurerm_resource_group.this.location
  }

  virtual_wan_properties = {
    virtual_wan_id = "/subscriptions/00112233-4455-6677-8899-aabbccddeeff/resourceGroups/example-nat-rules/providers/Microsoft.Network/virtualWans/example-vwan"
  }

  vpn_gateways = {
    hub = {
      name               = "vpngw-hub"
      routing_preference = "Microsoft Network"
      scale_unit         = 1
      virtual_hub_id     = "/subscriptions/00112233-4455-6677-8899-aabbccddeeff/resourceGroups/example-nat-rules/providers/Microsoft.Network/virtualHubs/vhub-westeurope"
    }
  }

  # NAT rules for IP translation over the VPN tunnel.
  # IngressSnat: translates the SOURCE of incoming packets (from remote site).
  # EgressSnat: translates the SOURCE of outgoing packets (toward remote site).
  vpn_gateway_nat_rules = {
    # Translate remote site IP 192.168.1.4 to 10.96.111.4 when entering the hub
    siteb-nginx = {
      name             = "nat-rule-siteb-nginx"
      vpn_gateway_name = "hub"
      mode             = "IngressSnat"
      internal_mappings = [{ address_space = "192.168.1.4/32" }]
      external_mappings = [{ address_space = "172.16.111.4/32" }]
    }

    # Translate Azure spoke IP 10.96.2.4 to 10.96.222.4 when leaving the hub
    sitea-test = {
      name             = "nat-rule-sitea-test"
      vpn_gateway_name = "hub"
      mode             = "EgressSnat"
      internal_mappings = [{ address_space = "172.16.2.4/32" }]
      external_mappings = [{ address_space = "172.16.222.4/32" }]
    }

    # Example: multiple prefixes in a single NAT rule
    multi-prefix = {
      name             = "nat-rule-multi-prefix"
      vpn_gateway_name = "hub"
      mode             = "IngressSnat"
      internal_mappings = [
        { address_space = "192.168.10.0/24" },
        { address_space = "192.168.11.0/25" },
      ]
      external_mappings = [
        { address_space = "172.16.10.0/24" },
        { address_space = "172.16.11.0/25" },
      ]
    }

    # Example: Dynamic NAT (many:1 NAPT) - /24 mapped to /26
    dynamic-napt = {
      name             = "nat-rule-dynamic"
      vpn_gateway_name = "hub"
      mode             = "IngressSnat"
      type             = "Dynamic"
      internal_mappings = [{ address_space = "192.168.20.0/24" }]
      external_mappings = [{ address_space = "172.16.20.0/26" }]
    }

    # Example: Static NAT with port mapping (port 8080 -> port 443)
    # Port mappings only work with Static type, individual ports only (no ranges).
    static-port = {
      name             = "nat-rule-static-port"
      vpn_gateway_name = "hub"
      mode             = "IngressSnat"
      internal_mappings = [{ address_space = "192.168.1.10/32", port_range = "8080" }]
      external_mappings = [{ address_space = "172.16.111.10/32", port_range = "443" }]
    }
  }

  vpn_sites = {
    remote-site = {
      name = "vpnsite-remote"
      # Include both real and NAT-translated address ranges
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
        name                 = "link-conn-remote"
        vpn_site_link_number = 0
        shared_key           = "REPLACE_WITH_REAL_KEY"
        protocol             = "IKEv2"
        bgp_enabled          = false
        bandwidth_mbps       = 10

        # Attach NAT rules to this link
        ingress_nat_rule_names = ["siteb-nginx"]
        egress_nat_rule_names  = ["sitea-test"]
      }]
    }
  }
}
