##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.PREFIX}-VNET"
  address_space       = [var.vnet]
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_subnet" "subnet1a" {
  name                 = "${var.PREFIX}-SUBNET-FGT-EXTERNAL-A"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = [var.subnet_fgt_external["a"]]
}

resource "azurerm_subnet" "subnet2a" {
  name                 = "${var.PREFIX}-SUBNET-FGT-INTERNAL-A"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = [var.subnet_fgt_internal["a"]]
}

resource "azurerm_subnet" "subnet1b" {
  name                 = "${var.PREFIX}-SUBNET-FGT-EXTERNAL-B"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = [var.subnet_fgt_external["b"]]
}

resource "azurerm_subnet" "subnet2b" {
  name                 = "${var.PREFIX}-SUBNET-FGT-INTERNAL-B"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = [var.subnet_fgt_internal["b"]]
}

resource "azurerm_network_security_group" "fgtnsg" {
  name                = "${var.PREFIX}-NSG"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
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
  resource_group_name         = azurerm_resource_group.resourcegroup.name
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
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fgtnsg.name
}

resource "azurerm_subnet_network_security_group_association" "fgtnsgassociation1" {
  subnet_id                 = azurerm_subnet.subnet1a.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_subnet_network_security_group_association" "fgtnsgassociation2" {
  subnet_id                 = azurerm_subnet.subnet2a.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_subnet_network_security_group_association" "fgtnsgassociation3" {
  subnet_id                 = azurerm_subnet.subnet1b.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_subnet_network_security_group_association" "fgtnsgassociation4" {
  subnet_id                 = azurerm_subnet.subnet2b.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_route_table" "subnet2arouter" {
  name                = "${local.fgt_a_prefix}-RT"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name

  route {
    name                   = "toB"
    address_prefix         = var.subnet_fgt_internal["b"]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${cidrhost(var.subnet_fgt_internal["a"], 4)}"
  }
}

resource "azurerm_subnet_route_table_association" "subnet2art" {
  subnet_id      = azurerm_subnet.subnet2a.id
  route_table_id = azurerm_route_table.subnet2arouter.id

  lifecycle {
    ignore_changes = [route_table_id]
  }
}

resource "azurerm_route_table" "subnet2brouter" {
  name                = "${local.fgt_b_prefix}-RT"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name

  route {
    name                   = "toB"
    address_prefix         = var.subnet_fgt_internal["a"]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${cidrhost(var.subnet_fgt_internal["b"], 4)}"
  }
}

resource "azurerm_subnet_route_table_association" "subnet2brt" {
  subnet_id      = azurerm_subnet.subnet2b.id
  route_table_id = azurerm_route_table.subnet2brouter.id

  lifecycle {
    ignore_changes = [route_table_id]
  }
}
