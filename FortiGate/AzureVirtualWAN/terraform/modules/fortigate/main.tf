##############################################################################################################
#
# FortiGate
#
##############################################################################################################
locals {
  vars = {
    fgt_vm_name             = var.name
    fgt_username            = var.username
    fgt_password            = var.password
    fgt_asn                 = var.asn
    vhub_virtual_router_ip1 = var.vhub_virtual_router_ip1
    vhub_virtual_router_ip2 = var.vhub_virtual_router_ip2
    vhub_virtual_router_asn = var.vhub_virtual_router_asn
    fmg_host                = var.fmg_host
    fmg_serial              = var.fmg_serial
    fgt_license_file        = var.license_file_byol
    fgt_license_fortiflex   = var.license_token_fortiflex
    fgt_customdata          = var.customdata
  }
  fgt_customdata = templatefile("${path.module}/fgt-customdata.tftpl", local.vars)
}

resource "azurerm_managed_application" "fgtinvhub" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  kind                        = "MarketPlace"
  managed_resource_group_name = "${var.resource_group_name}-mrg"

  parameter_values = jsonencode({
    adminUsername = {
      value = var.username
    },
    adminPassword = {
      value = var.password
    },
    fortiGateNamePrefix = {
      value = var.prefix
    },
    vwandeploymentSKU = {
      value = "${var.deployment_type}-${var.sku}"
    }
    fortiGateImageVersion = {
      value = "7.4.4"
    },
    hubId = {
      value = var.vhub_id
    },
    fortiGateASN = {
      value = tostring(var.asn)
    },
    scaleUnit = {
      value = var.scaleunit
    },
    hubRouters = {
      value = [var.vhub_virtual_router_ip1, var.vhub_virtual_router_ip2]
    },
    hubASN = {
      value = tostring(var.vhub_virtual_router_asn)
    },
    internetInboundCheck = {
      value = false
    },
    location = {
      value = var.location
    }
  })
  plan {
    name      = "fortigate-managedvwan"
    product   = "fortigate_vwan_nva"
    publisher = "fortinet"
    version   = "7.4.410240925"
  }

  tags = var.tags
}

#resource "azapi_resource" "fgtinvhub" {
#  type      = "Microsoft.Network/networkVirtualAppliances@2023-05-01"
#  name      = var.name
#  parent_id = var.resourcegroup_id
#
#  location = var.location
#  body = jsonencode({
#    properties = {
#      nvaSku = {
#        vendor             = var.sku
#        bundledScaleUnit   = var.scaleunit
#        marketPlaceVersion = var.mpversion
#      },
#      virtualHub = {
#        id = var.vhub_id
#      },
#      cloudInitConfiguration = local.fgt_customdata
#      virtualApplianceAsn    = tonumber(var.asn)
#    }
#  })
#
#  tags = var.tags
#
#  response_export_values = ["name", "properties.additionalNics", "properties.addressPrefix", "properties.cloudInitConfiguration", "properties.virtualApplianceNics"]
#}
