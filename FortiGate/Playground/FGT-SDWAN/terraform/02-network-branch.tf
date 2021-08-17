##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template
#
# https://github.com/terraform-providers/terraform-provider-azurerm/issues/2605
#
##############################################################################################################

##############################################################################################################
# BRANCH 1
##############################################################################################################
resource "azurerm_virtual_network" "vnetbranch1" {
  name                = "${var.PREFIX}-VNET-BRANCH1"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  address_space       = ["${var.vnetbranch1}"]
}

resource "azurerm_subnet" "subnet1branch1" {
  name                 = "${var.PREFIX}-BRANCH1-SUBNET1"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnetbranch1.name
  address_prefix       = var.subnetbranch1["1"]
  lifecycle {
    ignore_changes = ["route_table_id"]
  }
}

resource "azurerm_subnet" "subnet2branch1" {
  name                 = "${var.PREFIX}-BRANCH1-SUBNET2"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnetbranch1.name
  address_prefix       = var.subnetbranch1["2"]
  lifecycle {
    ignore_changes = ["route_table_id"]
  }
}

resource "azurerm_subnet" "subnet3branch1" {
  name                 = "${var.PREFIX}-BRANCH1-SUBNET3"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnetbranch1.name
  address_prefix       = var.subnetbranch1["3"]
  lifecycle {
    ignore_changes = ["route_table_id"]
  }
}

resource "azurerm_subnet" "subnet4branch1" {
  name                 = "${var.PREFIX}-BRANCH1-SUBNET4"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnetbranch1.name
  address_prefix       = var.subnetbranch1["4"]
  lifecycle {
    ignore_changes = ["route_table_id"]
  }
}

resource "azurerm_subnet" "subnet5branch1" {
  name                 = "${var.PREFIX}-BRANCH1-SUBNET5"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnetbranch1.name
  address_prefix       = var.subnetbranch1["5"]
  lifecycle {
    ignore_changes = ["route_table_id"]
  }
}

resource "azurerm_subnet_route_table_association" "branch1rt" {
  subnet_id      = azurerm_subnet.subnet4branch1.id
  route_table_id = azurerm_route_table.branch1route.id
}

resource "azurerm_route_table" "branch1route" {
  name                = "${var.PREFIX}-RT-BRANCH1"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name

  route {
    name                   = "VirtualNetwork"
    address_prefix         = var.vnetbranch1
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.fgt_ipaddress_branch1["3"]
  }
  route {
    name           = "Subnet"
    address_prefix = var.subnetbranch1["4"]
    next_hop_type  = "VnetLocal"
  }
  route {
    name                   = "Default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.fgt_ipaddress_branch1["3"]
  }
}

resource "azurerm_subnet_route_table_association" "branch1rt2" {
  subnet_id      = azurerm_subnet.subnet5branch1.id
  route_table_id = azurerm_route_table.branch1route2.id
}

resource "azurerm_route_table" "branch1route2" {
  name                = "${var.PREFIX}-RT2-BRANCH1"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name

  route {
    name                   = "VirtualNetwork"
    address_prefix         = var.vnetbranch1
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.fgt_ipaddress_branch1["3"]
  }
  route {
    name           = "Subnet"
    address_prefix = var.subnetbranch1["5"]
    next_hop_type  = "VnetLocal"
  }
  route {
    name                   = "Default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.fgt_ipaddress_branch1["3"]
  }
}

##############################################################################################################
# BRANCH 2
##############################################################################################################
resource "azurerm_virtual_network" "vnetbranch2" {
  name                = "${var.PREFIX}-VNET-BRANCH2"
  address_space       = ["${var.vnetbranch2}"]
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_subnet" "subnet1branch2" {
  name                 = "${var.PREFIX}-BRANCH2-SUBNET1"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnetbranch2.name
  address_prefix       = var.subnetbranch2["1"]
  lifecycle {
    ignore_changes = ["route_table_id"]
  }
}

resource "azurerm_subnet" "subnet2branch2" {
  name                 = "${var.PREFIX}-BRANCH2-SUBNET2"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnetbranch2.name
  address_prefix       = var.subnetbranch2["2"]
  lifecycle {
    ignore_changes = ["route_table_id"]
  }
}

resource "azurerm_subnet" "subnet3branch2" {
  name                 = "${var.PREFIX}-BRANCH2-SUBNET3"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnetbranch2.name
  address_prefix       = var.subnetbranch2["3"]
  lifecycle {
    ignore_changes = ["route_table_id"]
  }
}

resource "azurerm_subnet" "subnet4branch2" {
  name                 = "${var.PREFIX}-BRANCH2-SUBNET4"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnetbranch2.name
  address_prefix       = var.subnetbranch2["4"]
  lifecycle {
    ignore_changes = ["route_table_id"]
  }
}

resource "azurerm_subnet" "subnet5branch2" {
  name                 = "${var.PREFIX}-BRANCH2-SUBNET5"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnetbranch2.name
  address_prefix       = var.subnetbranch2["5"]
  lifecycle {
    ignore_changes = ["route_table_id"]
  }
}

resource "azurerm_subnet_route_table_association" "branch2rt" {
  subnet_id      = azurerm_subnet.subnet4branch2.id
  route_table_id = azurerm_route_table.branch2route.id
}

resource "azurerm_route_table" "branch2route" {
  name                = "${var.PREFIX}-RT-BRANCH2"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name

  route {
    name                   = "VirtualNetwork"
    address_prefix         = var.vnetbranch2
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.fgt_ipaddress_branch2["3"]
  }
  route {
    name           = "Subnet"
    address_prefix = var.subnetbranch2["4"]
    next_hop_type  = "VnetLocal"
  }
  route {
    name                   = "Default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.fgt_ipaddress_branch2["3"]
  }
}

resource "azurerm_subnet_route_table_association" "branch2rt2" {
  subnet_id      = azurerm_subnet.subnet5branch2.id
  route_table_id = azurerm_route_table.branch2route.id
}

resource "azurerm_route_table" "branch2route2" {
  name                = "${var.PREFIX}-RT2-BRANCH2"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name

  route {
    name                   = "VirtualNetwork"
    address_prefix         = var.vnetbranch2
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.fgt_ipaddress_branch2["3"]
  }
  route {
    name           = "Subnet"
    address_prefix = var.subnetbranch2["5"]
    next_hop_type  = "VnetLocal"
  }
  route {
    name                   = "Default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.fgt_ipaddress_branch2["3"]
  }
}