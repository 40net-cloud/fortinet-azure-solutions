##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.PREFIX}-VNET"
  address_space       = ["${var.vnet["a"]}"]
  location            = azurerm_resource_group.resourcegroupa.location
  resource_group_name = azurerm_resource_group.resourcegroupa.name
}

resource "azurerm_subnet" "subnet1" {
  name                 = "${var.PREFIX}-SUBNET-FGT-EXTERNAL"
  resource_group_name  = azurerm_resource_group.resourcegroupa.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = var.subnet_fgt_external["a"]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "${var.PREFIX}-SUBNET-FGT-INTERNAL"
  resource_group_name  = azurerm_resource_group.resourcegroupa.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = var.subnet_fgt_internal["a"]
}

resource "azurerm_subnet" "subnet3" {
  name                 = "${var.PREFIX}-SUBNET-PROTECTED-A"
  resource_group_name  = azurerm_resource_group.resourcegroupa.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = var.subnet_protected["a"]
}

resource "azurerm_subnet" "subnet4" {
  name                 = "${var.PREFIX}-SUBNET-PROTECTED-B"
  resource_group_name  = azurerm_resource_group.resourcegroupa.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = var.subnet_protected["b"]
}

resource "azurerm_subnet_route_table_association" "subnet3rt" {
  subnet_id      = azurerm_subnet.subnet3.id
  route_table_id = azurerm_route_table.protectedroutea.id
}

resource "azurerm_subnet_route_table_association" "subnet4rt" {
  subnet_id      = azurerm_subnet.subnet4.id
  route_table_id = azurerm_route_table.protectedrouteb.id
}

resource "azurerm_route_table" "protectedroutea" {
  name                = "${var.PREFIX}-RT-PROTECTED-A"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroupa.name

  route {
    name                   = "${var.PREFIX}-ProtectedAtoB"
    address_prefix         = var.subnet_protected["b"]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.fgt_internal_ipaddress["a"]
  }
}

resource "azurerm_route_table" "protectedrouteb" {
  name                = "${var.PREFIX}-RT-PROTECTED-B"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroupa.name

  route {
    name                   = "${var.PREFIX}-ProtectedBtoA"
    address_prefix         = var.subnet_protected["a"]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.fgt_internal_ipaddress["a"]
  }
}

resource "azurerm_network_security_group" "fgtnsg" {
  name                = "${var.PREFIX}-NSG"
  location            = azurerm_resource_group.resourcegroupa.location
  resource_group_name = azurerm_resource_group.resourcegroupa.name
}

resource "azurerm_network_security_rule" "fgtnsgrule1" {
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
  network_security_group_name = azurerm_network_security_group.fgtnsg.name
}

resource "azurerm_network_security_rule" "fgtnsgrule2" {
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
  network_security_group_name = azurerm_network_security_group.fgtnsg.name
}

resource "azurerm_subnet_network_security_group_association" "fgtnsgassociation1" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id

  depends_on = ["azurerm_network_interface.fgtifcext"]
}

resource "azurerm_subnet_network_security_group_association" "fgtnsgassociation2" {
  subnet_id                 = azurerm_subnet.subnet2.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id

  depends_on = ["azurerm_network_interface.fgtifcint"]
}
