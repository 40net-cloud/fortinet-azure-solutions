##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template
#
# https://github.com/terraform-providers/terraform-provider-azurerm/issues/2605
#
##############################################################################################################

##############################################################################################################
# FMG
##############################################################################################################
resource "azurerm_virtual_network" "vnetfmg" {
  name                = "${var.PREFIX}-VNET-FMG"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  address_space       = ["${var.vnetfmg}"]
}

resource "azurerm_subnet" "subnet1fmg" {
  name                 = "${var.PREFIX}-FMG-SUBNET1"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnetfmg.name
  address_prefix       = var.subnetfmg["1"]
  lifecycle {
    ignore_changes = ["route_table_id"]
  }
}

resource "azurerm_subnet" "subnet2fmg" {
  name                 = "${var.PREFIX}-FMG-SUBNET2"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnetfmg.name
  address_prefix       = var.subnetfmg["2"]
  lifecycle {
    ignore_changes = ["route_table_id"]
  }
}
