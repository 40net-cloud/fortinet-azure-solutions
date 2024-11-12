##############################################################################################################
#
# FortiGate VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
#
# Deployment of the virtual network
#
##############################################################################################################

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-VNET"
  address_space       = [var.vnet]
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_subnet" "subnet1" {
  name                 = "${var.prefix}-SUBNET-MGMT"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet["1"]]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "${var.prefix}-SUBNET-PORT1"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet["2"]]
}

resource "azurerm_subnet" "subnet3" {
  name                 = "${var.prefix}-SUBNET-PORT2"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet["3"]]
}

resource "azurerm_route_table" "subnet2router" {
  name                = "${var.prefix}-RT-EXT"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  route {
    name                   = "underlay"
    address_prefix         = "10.1.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.lnx_ipaddress["2"]
  }
  route {
    name                   = "internal"
    address_prefix         = "172.16.138.0/24"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.fgt_ipaddress["2"]
  }
}

resource "azurerm_subnet_route_table_association" "subnet2rt" {
  subnet_id      = azurerm_subnet.subnet2.id
  route_table_id = azurerm_route_table.subnet2router.id

  lifecycle {
    ignore_changes = [route_table_id]
  }
}

resource "azurerm_route_table" "subnet3router" {
  name                = "${var.prefix}-RT-INT"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  route {
    name                   = "underlay"
    address_prefix         = "10.1.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.fgt_ipaddress["3"]
  }
  route {
    name                   = "overlay"
    address_prefix         = "10.2.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.fgt_ipaddress["3"]
  }
}

resource "azurerm_subnet_route_table_association" "subnet3rt" {
  subnet_id      = azurerm_subnet.subnet3.id
  route_table_id = azurerm_route_table.subnet3router.id

  lifecycle {
    ignore_changes = [route_table_id]
  }
}
