##############################################################################################################
#
# FortiGate Active/Passive High Available FortiGate pair with Azure Route Server
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
  name                 = "${var.prefix}-SUBNET-FGT-EXTERNAL"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet["1"]]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "${var.prefix}-SUBNET-FGT-INTERNAL"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet["2"]]
}

resource "azurerm_subnet" "subnet3" {
  name                 = "${var.prefix}-SUBNET-FGT-HASYNC"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet["3"]]
}

resource "azurerm_subnet" "subnet4" {
  name                 = "${var.prefix}-SUBNET-FGT-MGMT"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet["4"]]
}

resource "azurerm_subnet" "subnet5" {
  name                 = "${var.prefix}-SUBNET-PROTECTED-A"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet["5"]]
}

resource "azurerm_subnet" "subnet6" {
  name                 = "RouteServerSubnet"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet["6"]]
}

resource "azurerm_public_ip" "arspip" {
  name                = "${var.prefix}-ARS-PIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s", lower(var.prefix), "ars-pip")
}

resource "azurerm_route_server" "routeserver" {
  name                             = "${var.prefix}-ARS"
  resource_group_name              = azurerm_resource_group.resourcegroup.name
  location                         = azurerm_resource_group.resourcegroup.location
  sku                              = "Standard"
  subnet_id                        = azurerm_subnet.subnet6.id
  public_ip_address_id             = azurerm_public_ip.arspip.id
  branch_to_branch_traffic_enabled = false
}


resource "azurerm_subnet_route_table_association" "subnet1rt" {
  subnet_id      = azurerm_subnet.subnet1.id
  route_table_id = azurerm_route_table.rtfgt.id
}

resource "azurerm_subnet_route_table_association" "subnet2rt" {
  subnet_id      = azurerm_subnet.subnet2.id
  route_table_id = azurerm_route_table.rtfgt.id
}

resource "azurerm_subnet_route_table_association" "subnet3rt" {
  subnet_id      = azurerm_subnet.subnet3.id
  route_table_id = azurerm_route_table.rtfgt.id
}

resource "azurerm_subnet_route_table_association" "subnet4rt" {
  subnet_id      = azurerm_subnet.subnet4.id
  route_table_id = azurerm_route_table.rtfgt.id
}

resource "azurerm_route_table" "rtfgt" {
  name                = "${var.prefix}-RT-FGT"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  route {
    name                   = "Default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "Internet"
  }

}