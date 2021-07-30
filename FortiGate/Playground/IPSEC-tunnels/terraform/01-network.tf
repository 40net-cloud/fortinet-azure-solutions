##############################################################################################################
#
# FortiTester VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
#
# Deployment of the virtual network
#
##############################################################################################################

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.PREFIX}-VNET"
  address_space       = [var.vnet]
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_subnet" "subnet1" {
  name                 = "${var.PREFIX}-SUBNET-MGMT"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet["1"]]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "${var.PREFIX}-SUBNET-PORT1"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet["2"]]
}

resource "azurerm_subnet" "subnet3" {
  name                 = "${var.PREFIX}-SUBNET-PORT2"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet["3"]]
}

resource "azurerm_route_table" "ipsecroute" {
  name                = "${var.PREFIX}-RT-SPOKE1"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name

  route {
    name                   = "IPSEC"
    address_prefix         = "10.1.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.lnx_ipaddress["2"]
  }
}

resource "azurerm_subnet_route_table_association" "subnet2rt" {
  subnet_id      = azurerm_subnet.subnet2.id
  route_table_id = azurerm_route_table.ipsecroute.id

  lifecycle {
    ignore_changes = [route_table_id]
  }
}
