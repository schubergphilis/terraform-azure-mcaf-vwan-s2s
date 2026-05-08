# terraform-azure-mcaf-vwan-s2s
Terraform module to create a VPN Gateway, Site and Connection in an existing Azure Virtual WAN.

## VPN Connection rate limit
VPN connection throughput can be limited by setting 'ratelimit_enabled' to true. This sets the maximum throughput to the default setting of 10Mbps which is customizable by setting 'bandwidth_mbps' (this value is only effective when ratelimit_enabled is set to true). Example that enables rate limit with a maximum throughput of 20Mbps:

```hcl
    bandwidth_mbps    = 20
    ratelimit_enabled = true
```
## VPN Gateway NAT Rules

NAT rules translate IP addresses on VPN tunnels to resolve overlapping address spaces. Define rules via `vpn_gateway_nat_rules` and attach them to VPN links using `ingress_nat_rule_names` / `egress_nat_rule_names`.

### Modes

- **IngressSnat** -- translates the source IP of packets arriving from the remote site.
- **EgressSnat** -- translates the source IP of packets leaving toward the remote site.

### Types

| Type | Mapping | Direction | Notes |
|------|---------|-----------|-------|
| **Static** (default) | 1:1 fixed address mapping | Bidirectional | Subnets must be equal size |
| **Dynamic** | Many:1 (NAPT) via port translation | Unidirectional (initiated from internal side only) | External mapping max /26 |

### Multiple mappings per rule

Each rule supports one or more `internal_mappings` and `external_mappings` entries, allowing multiple prefixes to be translated under a single rule.

```hcl
vpn_gateway_nat_rules = {
  # Static 1:1
  siteb-nginx = {
    name             = "nat-rule-siteb-nginx"
    vpn_gateway_name = "hub"
    mode             = "IngressSnat"
    internal_mappings = [{ address_space = "192.168.1.4/32" }]
    external_mappings = [{ address_space = "172.16.111.4/32" }]
  }

  # Multiple prefixes in one rule
  multi-prefix = {
    name             = "nat-rule-multi"
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

  # Dynamic many:1 NAPT
  dynamic-napt = {
    name             = "nat-rule-dynamic"
    vpn_gateway_name = "hub"
    mode             = "IngressSnat"
    type             = "Dynamic"
    internal_mappings = [{ address_space = "192.168.20.0/24" }]
    external_mappings = [{ address_space = "172.16.20.0/26" }]
  }

  # Static port mapping (port 8080 -> 443, Static type only, individual ports)
  static-port = {
    name             = "nat-rule-static-port"
    vpn_gateway_name = "hub"
    mode             = "IngressSnat"
    internal_mappings = [{ address_space = "192.168.1.10/32", port_range = "8080" }]
    external_mappings = [{ address_space = "172.16.111.10/32", port_range = "443" }]
  }
}
```

See [`examples/nat-rules`](examples/nat-rules) for a complete example.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_vpn_gateway.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/vpn_gateway) | resource |
| [azurerm_vpn_gateway_connection.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/vpn_gateway_connection) | resource |
| [azurerm_vpn_gateway_nat_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/vpn_gateway_nat_rule) | resource |
| [azurerm_vpn_site.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/vpn_site) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | The Resource Group to add the IP Groups to or create if create\_ipg\_resource\_group is true | <pre>object({<br>    name     = string<br>    location = string<br>  })</pre> | n/a | yes |
| <a name="input_virtual_wan_properties"></a> [virtual\_wan\_properties](#input\_virtual\_wan\_properties) | The Virtual WAN properties | <pre>object({<br>    virtual_wan_id = string<br>  })</pre> | n/a | yes |
| <a name="input_vpn_gateways"></a> [vpn\_gateways](#input\_vpn\_gateways) | The VPN Gateway to create | <pre>map(object({<br>    name               = string<br>    routing_preference = string<br>    scale_unit         = number<br>    virtual_hub_id     = string<br>    bgp_settings = optional(object({<br>      asn                            = number<br>      instance_0_bgp_peering_address = optional(string)<br>      instance_1_bgp_peering_address = optional(string)<br>      peer_weight                    = number<br>    }))<br>  }))</pre> | n/a | yes |
| <a name="input_vpn_site_connections"></a> [vpn\_site\_connections](#input\_vpn\_site\_connections) | n/a | <pre>map(object({<br>    name                      = string<br>    vpn_gateway_name          = string<br>    remote_vpn_site_name      = string<br>    internet_security_enabled = optional(bool)<br><br>    vpn_links = list(object({<br>      name = string<br>      # Index of the link on the vpn gateway<br>      vpn_site_link_number                  = number<br>      bandwidth_mbps                        = optional(number)<br>      bgp_enabled                           = optional(bool)<br>      route_weight                          = optional(number)<br>      ratelimit_enabled                     = optional(bool)<br>      protocol                              = optional(string)<br>      shared_key                            = optional(string)<br>      connection_mode                       = optional(string)<br>      local_azure_ip_address_enabled        = optional(bool)<br>      policy_based_traffic_selector_enabled = optional(bool)<br><br>      ipsec_policy = optional(object({<br>        dh_group                 = string<br>        ike_encryption_algorithm = string<br>        ike_integrity_algorithm  = string<br>        encryption_algorithm     = string<br>        integrity_algorithm      = string<br>        pfs_group                = string<br>        sa_data_size_kb          = string<br>        sa_lifetime_sec          = string<br>      }))<br><br>      custom_bgp_address = optional(list(object({<br>        ip_address          = string<br>        ip_configuration_id = string<br>      })))<br><br>      ingress_nat_rule_names = optional(list(string), [])<br>      egress_nat_rule_names  = optional(list(string), [])<br>    }))<br>  }))</pre> | n/a | yes |
| <a name="input_vpn_sites"></a> [vpn\_sites](#input\_vpn\_sites) | The VPN Site to create | <pre>map(object({<br>    name          = string<br>    address_cidrs = optional(list(string))<br>    device_model  = optional(string, null)<br>    device_vendor = optional(string, null)<br>    links = list(object({<br>      name          = string<br>      ip_address    = optional(string)<br>      provider_name = optional(string)<br>      speed_in_mbps = optional(number)<br>      bgp_settings = optional(object({<br>        asn                 = number<br>        bgp_peering_address = string<br>      }))<br>    }))<br>  }))</pre> | n/a | yes |
| <a name="input_create_new_resource_group"></a> [create\_new\_resource\_group](#input\_create\_new\_resource\_group) | A flag to create a Resource Group for the IP Groups | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resource. | `map(string)` | `{}` | no |
| <a name="input_vpn_gateway_nat_rules"></a> [vpn\_gateway\_nat\_rules](#input\_vpn\_gateway\_nat\_rules) | VPN Gateway NAT rules for IP translation over S2S VPN connections.<br><br>- vpn\_gateway\_name: the map key in var.vpn\_gateways.<br>- mode: "IngressSnat" (translate source of incoming packets) or "EgressSnat" (translate source of outgoing packets).<br>- type: "Static" (1:1 fixed mapping, bidirectional) or "Dynamic" (many:1 NAPT, unidirectional from internal side only, max /26 external).<br>- internal\_mappings / external\_mappings: one or more address translation entries per rule.<br>  Each entry has an address\_space (CIDR) and an optional port\_range (Static type only, individual port).<br><br>Static NAT example (1:1):<br>  internal\_mappings = [{ address\_space = "10.0.1.0/24" }]<br>  external\_mappings = [{ address\_space = "192.168.1.0/24" }]<br><br>Dynamic NAT example (many:1 NAPT, /24 to /26):<br>  internal\_mappings = [{ address\_space = "10.0.1.0/24" }]<br>  external\_mappings = [{ address\_space = "192.168.1.0/26" }]<br><br>Multiple prefixes per rule:<br>  internal\_mappings = [<br>    { address\_space = "10.0.1.0/24" },<br>    { address\_space = "10.0.2.0/25" },<br>  ]<br>  external\_mappings = [<br>    { address\_space = "192.168.1.0/24" },<br>    { address\_space = "192.168.2.0/25" },<br>  ] | <pre>map(object({<br>    name             = string<br>    vpn_gateway_name = string<br>    mode             = string<br>    type             = optional(string, "Static")<br><br>    internal_mappings = list(object({<br>      address_space = string<br>      port_range    = optional(string)<br>    }))<br><br>    external_mappings = list(object({<br>      address_space = string<br>      port_range    = optional(string)<br>    }))<br>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vpn_gateway_bgp_settings"></a> [vpn\_gateway\_bgp\_settings](#output\_vpn\_gateway\_bgp\_settings) | Map of VPN Gateway BGP settings |
| <a name="output_vpn_gateway_connection_ids"></a> [vpn\_gateway\_connection\_ids](#output\_vpn\_gateway\_connection\_ids) | Map of VPN Gateway Connection IDs |
| <a name="output_vpn_gateway_ids"></a> [vpn\_gateway\_ids](#output\_vpn\_gateway\_ids) | Map of VPN Gateway IDs |
| <a name="output_vpn_gateway_nat_rule_ids"></a> [vpn\_gateway\_nat\_rule\_ids](#output\_vpn\_gateway\_nat\_rule\_ids) | Map of VPN Gateway NAT rule IDs |
| <a name="output_vpn_site_ids"></a> [vpn\_site\_ids](#output\_vpn\_site\_ids) | Map of VPN Site IDs |
<!-- END_TF_DOCS -->