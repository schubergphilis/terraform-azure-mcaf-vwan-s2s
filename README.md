# terraform-azure-mcaf-vwan-s2s
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
| [azurerm_vpn_site.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/vpn_site) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | The Resource Group to add the IP Groups to or create if create\_ipg\_resource\_group is true | <pre>object({<br>    name     = string<br>    location = string<br>  })</pre> | n/a | yes |
| <a name="input_virtual_wan_properties"></a> [virtual\_wan\_properties](#input\_virtual\_wan\_properties) | The Virtual WAN properties | <pre>object({<br>    virtual_wan_id = string<br>  })</pre> | n/a | yes |
| <a name="input_vpn_gateways"></a> [vpn\_gateways](#input\_vpn\_gateways) | The VPN Gateway to create | <pre>map(object({<br>    name               = string<br>    routing_preference = string<br>    scale_unit         = number<br>    virtual_hub_id     = string<br>    bgp_settings = optional(object({<br>      asn                            = number<br>      instance_0_bgp_peering_address = optional(string)<br>      instance_1_bgp_peering_address = optional(string)<br>      peer_weight                    = number<br>    }))<br>  }))</pre> | n/a | yes |
| <a name="input_vpn_site_connections"></a> [vpn\_site\_connections](#input\_vpn\_site\_connections) | n/a | <pre>map(object({<br>    name                                  = string<br>    vpn_gateway_name                      = string<br>    remote_vpn_site_name                  = string<br>    protocol                              = optional(string)<br>    ratelimit_enabled                     = optional(bool)<br>    route_weight                          = optional(number)<br>    shared_key                            = optional(string)<br>    local_azure_ip_address_enabled        = optional(bool)<br>    policy_based_traffic_selector_enabled = optional(bool)<br>    internet_security_enabled             = optional(bool)<br><br>    vpn_links = list(object({<br>      name = string<br>      # Index of the link on the vpn gateway<br>      vpn_site_link_number = number<br>      bandwidth_mbps       = optional(number)<br>      bgp_enabled          = optional(bool)<br>      connection_mode      = optional(string)<br><br>      ipsec_policy = optional(object({<br>        dh_group                 = string<br>        ike_encryption_algorithm = string<br>        ike_integrity_algorithm  = string<br>        encryption_algorithm     = string<br>        integrity_algorithm      = string<br>        pfs_group                = string<br>        sa_data_size_kb          = string<br>        sa_lifetime_sec          = string<br>      }))<br><br>      custom_bgp_address = optional(list(object({<br>        ip_address          = string<br>        ip_configuration_id = string<br>      })))<br>    }))<br>  }))</pre> | n/a | yes |
| <a name="input_vpn_sites"></a> [vpn\_sites](#input\_vpn\_sites) | The VPN Site to create | <pre>map(object({<br>    name          = string<br>    address_cidrs = optional(list(string))<br>    device_model  = optional(string)<br>    device_vendor = optional(string)<br>    links = list(object({<br>      name          = string<br>      ip_address    = optional(string)<br>      provider_name = optional(string)<br>      speed_in_mbps = optional(number)<br>      bgp_settings = optional(object({<br>        asn                 = number<br>        bgp_peering_address = string<br>      }))<br>    }))<br>  }))</pre> | n/a | yes |
| <a name="input_create_new_resource_group"></a> [create\_new\_resource\_group](#input\_create\_new\_resource\_group) | A flag to create a Resource Group for the IP Groups | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resource. | `map(string)` | `{}` | no |

## Outputs

No outputs
<!-- END_TF_DOCS -->