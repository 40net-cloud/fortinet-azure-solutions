##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

resource "azurerm_virtual_network" "vneta" {
  name                = "${var.PREFIX}-A-VNET"
  address_space       = ["${var.vnet["a"]}"]
  location            = azurerm_resource_group.resourcegroupa.location
  resource_group_name = azurerm_resource_group.resourcegroupa.name
}

resource "azurerm_subnet" "subneta1" {
  name                 = "${var.PREFIX}-A-SUBNET-FGT-EXTERNAL"
  resource_group_name  = azurerm_resource_group.resourcegroupa.name
  virtual_network_name = azurerm_virtual_network.vneta.name
  address_prefix       = var.subnet_fgt_external["a"]
}

resource "azurerm_subnet" "subneta2" {
  name                 = "${var.PREFIX}-A-SUBNET-FGT-INTERNAL"
  resource_group_name  = azurerm_resource_group.resourcegroupa.name
  virtual_network_name = azurerm_virtual_network.vneta.name
  address_prefix       = var.subnet_fgt_internal["a"]
}

resource "azurerm_subnet" "subneta3" {
  name                 = "${var.PREFIX}-A-SUBNET-PROTECTED"
  resource_group_name  = azurerm_resource_group.resourcegroupa.name
  virtual_network_name = azurerm_virtual_network.vneta.name
  address_prefix       = var.subnet_protected["a"]
}

resource "azurerm_subnet_route_table_association" "subneta3rt" {
  subnet_id      = azurerm_subnet.subneta3.id
  route_table_id = azurerm_route_table.protectedaroute.id
}

resource "azurerm_route_table" "protectedaroute" {
  name                = "${var.PREFIX}-A-RT-PROTECTED"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroupa.name

  route {
    name                   = "${var.PREFIX}-A-ProtectedToInternet"
    address_prefix         = var.subnet_protected["b"]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.fgt_internal_ipaddress["a"]
  }
}

resource "azurerm_network_security_group" "fgtansg" {
  name                = "${var.PREFIX}-A-NSG"
  location            = azurerm_resource_group.resourcegroupa.location
  resource_group_name = azurerm_resource_group.resourcegroupa.name
}

resource "azurerm_network_security_rule" "fgtansgrule1" {
  name                        = "AllOutbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.resourcegroupa.name
  network_security_group_name = azurerm_network_security_group.fgtansg.name
}

resource "azurerm_network_security_rule" "fgtansgrule2" {
  name                        = "AllInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.resourcegroupa.name
  network_security_group_name = azurerm_network_security_group.fgtansg.name
}

resource "azurerm_subnet_network_security_group_association" "fgtansgassociation1" {
  subnet_id                 = azurerm_subnet.subneta1.id
  network_security_group_id = azurerm_network_security_group.fgtansg.id
}

resource "azurerm_subnet_network_security_group_association" "fgtansgassociation2" {
  subnet_id                 = azurerm_subnet.subneta2.id
  network_security_group_id = azurerm_network_security_group.fgtansg.id
}
