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
  name     = "example-resource-group"
  location = "West Europe"
  tags = {
    "Environment"   = "Development"
    "Project"       = "ExampleProject"
    "Resource Type" = "Resource Group"
  }
}

module "s2svpn" {
  source = "../.."

  create_new_resource_group = false
  resource_group = {
    name     = azurerm_resource_group.this.name
    location = azurerm_resource_group.this.location
  }

  virtual_wan_properties = {
    virtual_wan_id = "/subscriptions/00112233-4455-6677-8899-aabbccddeeff/resourceGroups/example-resource-group/providers/Microsoft.Network/virtualWans/example-vwan"
  }
  vpn_gateways = {
    "example-vpn-gateway" = {
      name               = "example-vpn-gateway"
      routing_preference = "Microsoft Network"
      scale_unit         = 1
      virtual_hub_id     = "/subscriptions/00112233-4455-6677-8899-aabbccddeeff/resourceGroups/example-resource-group/providers/Microsoft.Network/virtualHubs/example-vhub"
      # bgp_settings = {
      #   asn                            = 65515
      #   peer_weight                    = 0
      #   instance_0_bgp_peering_address = "169.254.0.1"
      #   instance_1_bgp_peering_address = "169.254.0.2"
      # }
    }
  }
  vpn_sites = {
    "example-site" = {
      name          = "example-site"
      address_cidrs = ["172.1.1.0/24"]
      links = [
        {
          name          = "example-link"
          ip_address    = "123.45.67.89"
          provider_name = "KPN"
          speed_in_mbps = 100
          # bgp_settings = {
          #   asn                 = 65001
          #   bgp_peering_address = "10.1.2.3"
          # }
        }
      ]
    }
  }
  vpn_site_connections = {
    "example-connection" = {
      name                      = "example-connection"
      vpn_gateway_name          = "example-vpn-gateway"
      remote_vpn_site_name      = "example-site"
      internet_security_enabled = true

      vpn_links = [
        {
          name                 = "example-link"
          vpn_site_link_number = 0

          bgp_enabled                           = false
          shared_key                            = "EXAMPLE_PRE_SHARED_KEY"
          connection_mode                       = "Default"
          protocol                              = "IKEv2"
          route_weight                          = 100
          local_azure_ip_address_enabled        = false
          policy_based_traffic_selector_enabled = false
          # Enable rate limit with a maximum throughput of 100Mbps:
          ratelimit_enabled = true
          bandwidth_mbps    = 100

          ipsec_policy = {
            dh_group                 = "DHGroup14"
            ike_encryption_algorithm = "AES256"
            ike_integrity_algorithm  = "SHA256"
            encryption_algorithm     = "AES256"
            integrity_algorithm      = "SHA256"
            pfs_group                = "PFS14"
            sa_data_size_kb          = "102400000"
            sa_lifetime_sec          = "3600"
          }

          # custom_bgp_address = [
          #   {
          #     ip_address          = "169.254.26.1"
          #     ip_configuration_id = "Instance0"
          #   },
          #   {
          #     ip_address         = "169.254.26.2"
          #     ip_configuration_id = "Instance1"
          #   }
          # ]
        }
      ]
    }
  }
}
