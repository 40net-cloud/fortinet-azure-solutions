##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.PREFIX}-vnet"
  address_space       = [var.vnet]
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_subnet" "subnet1a" {
  name                 = "${var.PREFIX}-subnet-fgt-external-a"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = [var.subnet_fgt_external["a"]]
}

resource "azurerm_subnet" "subnet2a" {
  name                 = "${var.PREFIX}-subnet-fgt-internal-a"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = [var.subnet_fgt_internal["a"]]
}

resource "azurerm_subnet" "subnet3a" {
  name                 = "${var.PREFIX}-subnet-protected-a"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = [var.subnet_protected["a"]]
}

resource "azurerm_subnet" "subnet1b" {
  name                 = "${var.PREFIX}-subnet-fgt-external-b"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = [var.subnet_fgt_external["b"]]
}

resource "azurerm_subnet" "subnet2b" {
  name                 = "${var.PREFIX}-subnet-fgt-internal-b"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = [var.subnet_fgt_internal["b"]]
}

resource "azurerm_subnet" "subnet3b" {
  name                 = "${var.PREFIX}-subnet-protected-b"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = [var.subnet_protected["b"]]
}

resource "azurerm_network_security_group" "fgtnsg" {
  name                = "${var.PREFIX}-nsg"
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

resource "azurerm_route_table" "subnet3arouter" {
  name                = "${var.PREFIX}-rt-protected-a"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name

  route {
    name                   = "subnet3b"
    address_prefix         = var.subnet_protected["b"]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = module.ilb-a.azurerm_lb_frontend_ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "subnet3art" {
  subnet_id      = azurerm_subnet.subnet3a.id
  route_table_id = azurerm_route_table.subnet3arouter.id

  lifecycle {
    ignore_changes = [route_table_id]
  }
}

resource "azurerm_route_table" "subnet3brouter" {
  name                = "${var.PREFIX}-rt-protected-b"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name

  route {
    name                   = "subnet3a"
    address_prefix         = var.subnet_protected["a"]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = module.ilb-b.azurerm_lb_frontend_ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "subnet3brt" {
  subnet_id      = azurerm_subnet.subnet3b.id
  route_table_id = azurerm_route_table.subnet3brouter.id

  lifecycle {
    ignore_changes = [route_table_id]
  }
}