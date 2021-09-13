##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

resource "azurerm_virtual_network" "vnetb" {
  name                = "${var.PREFIX}-B-VNET"
  address_space       = ["${var.vnet["b"]}"]
  location            = azurerm_resource_group.resourcegroupb.location
  resource_group_name = azurerm_resource_group.resourcegroupb.name
}

resource "azurerm_subnet" "subnetb1" {
  name                 = "${var.PREFIX}-B-SUBNET-FGT-EXTERNAL"
  resource_group_name  = azurerm_resource_group.resourcegroupb.name
  virtual_network_name = azurerm_virtual_network.vnetb.name
  address_prefix       = var.subnet_fgt_external["b"]
}

resource "azurerm_subnet" "subnetb2" {
  name                 = "${var.PREFIX}-B-SUBNET-FGT-INTERNAL"
  resource_group_name  = azurerm_resource_group.resourcegroupb.name
  virtual_network_name = azurerm_virtual_network.vnetb.name
  address_prefix       = var.subnet_fgt_internal["b"]
}

resource "azurerm_subnet" "subnetb3" {
  name                 = "${var.PREFIX}-B-SUBNET-PROTECTED"
  resource_group_name  = azurerm_resource_group.resourcegroupb.name
  virtual_network_name = azurerm_virtual_network.vnetb.name
  address_prefix       = var.subnet_protected["b"]
}

resource "azurerm_subnet_route_table_association" "subnetb3rt" {
  subnet_id      = azurerm_subnet.subnetb3.id
  route_table_id = azurerm_route_table.protectedbroute.id
}

resource "azurerm_route_table" "protectedbroute" {
  name                = "${var.PREFIX}-B-RT-PROTECTED"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroupb.name

  route {
    name                   = "${var.PREFIX}-B-ProtectedToInternet"
    address_prefix         = var.subnet_protected["a"]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.fgt_internal_ipaddress["b"]
  }
}
