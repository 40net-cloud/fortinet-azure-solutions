##############################################################################################################
#
# Fortinet FortiGate Terraform deployment
# Azure Virtual WAN NVA deployment
#
##############################################################################################################
# Main
##############################################################################################################
resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.PREFIX}-rg"
  location = var.LOCATION

  tags = var.tags
}

##############################################################################################################
#
# Spoke VNET
#
##############################################################################################################

resource "azurerm_virtual_network" "spoke1" {
  name                = "${var.PREFIX}-spoke1-vnet"
  address_space       = [var.vnet["spoke1"]]
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  tags = var.tags
}

resource "azurerm_subnet" "spoke1subnet1" {
  name                 = "Subnet1"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.spoke1.name
  address_prefixes     = [var.spoke_subnet["spoke1"]]
}

resource "azurerm_virtual_network" "spoke2" {
  name                = "${var.PREFIX}-spoke2-vnet"
  address_space       = [var.vnet["spoke2"]]
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  tags = var.tags
}

resource "azurerm_subnet" "spoke2subnet1" {
  name                 = "Subnet1"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.spoke2.name
  address_prefixes     = [var.spoke_subnet["spoke2"]]
}

##############################################################################################################
#
# Spoke VM
#
##############################################################################################################
resource "azurerm_network_interface" "spoke1lnxifc" {
  name                          = "${var.PREFIX}-spoke1-lnx-ifc"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = false
  enable_accelerated_networking = false

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.spoke1subnet1.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "spoke1lnxvm" {
  name                  = "${var.PREFIX}-spoke1-lnx"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.spoke1lnxifc.id]
  size                  = var.lnx_vmsize

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    name                 = "${var.PREFIX}-spoke1-lnx-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  computer_name                   = "${var.PREFIX}-spoke1-lnx"
  admin_username                  = var.USERNAME
  admin_password                  = var.PASSWORD
  disable_password_authentication = false
  custom_data                     = base64encode(templatefile("${path.module}/vm-customdata.tftpl", {}))

  boot_diagnostics {
  }

  tags = var.tags
}

resource "azurerm_network_interface" "spoke2lnxifc" {
  name                          = "${var.PREFIX}-spoke2-lnx-ifc"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = false
  enable_accelerated_networking = false

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.spoke2subnet1.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "spoke2lnxvm" {
  name                  = "${var.PREFIX}-spoke2-lnx"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.spoke2lnxifc.id]
  size                  = var.lnx_vmsize

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    name                 = "${var.PREFIX}-spoke2-lnx-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  computer_name                   = "${var.PREFIX}-spoke2-lnx"
  admin_username                  = var.USERNAME
  admin_password                  = var.PASSWORD
  disable_password_authentication = false
  custom_data                     = base64encode(templatefile("${path.module}/vm-customdata.tftpl", {}))

  boot_diagnostics {
  }

  tags = var.tags
}

##############################################################################################################
#
# Virtual WAN
#
##############################################################################################################

resource "azurerm_virtual_wan" "vwan" {
  name                = "${var.PREFIX}-virtualwan"
  resource_group_name = azurerm_resource_group.resourcegroup.name
  location            = azurerm_resource_group.resourcegroup.location

  tags = var.tags
}

resource "azurerm_virtual_hub" "vhub" {
  name                = "${var.PREFIX}-virtualwan-hub"
  resource_group_name = azurerm_resource_group.resourcegroup.name
  location            = azurerm_resource_group.resourcegroup.location
  virtual_wan_id      = azurerm_virtual_wan.vwan.id
  address_prefix      = var.vnet_vhub

  tags = var.tags
}

resource "azurerm_virtual_hub_connection" "spoke1" {
  name                      = "${var.PREFIX}-spoke1"
  virtual_hub_id            = azurerm_virtual_hub.vhub.id
  remote_virtual_network_id = azurerm_virtual_network.spoke1.id
}

resource "azurerm_virtual_hub_connection" "spoke2" {
  name                      = "${var.PREFIX}-spoke2"
  virtual_hub_id            = azurerm_virtual_hub.vhub.id
  remote_virtual_network_id = azurerm_virtual_network.spoke2.id
}

##############################################################################################################
#
# FortiGate
#
##############################################################################################################
module "fgt_nva" {
  source = "./modules/fortigate"

  prefix                  = var.PREFIX
  name                    = "${var.PREFIX}-vwan-fgt"
  location                = azurerm_resource_group.resourcegroup.location
  resource_group_name     = azurerm_resource_group.resourcegroup.name
  username                = var.USERNAME
  password                = var.PASSWORD
  sku                     = var.fgt_sku
  scaleunit               = var.fgt_scaleunit
  mpversion               = var.fgt_version
  asn                     = var.fgt_asn
  tags                    = var.tags
  fmg_host                = var.fmg_host
  fmg_serial              = var.fmg_serial
  vhub_id                 = azurerm_virtual_hub.vhub.id
  vhub_virtual_router_ip1 = azurerm_virtual_hub.vhub.virtual_router_ips[0]
  vhub_virtual_router_ip2 = azurerm_virtual_hub.vhub.virtual_router_ips[1]
  vhub_virtual_router_asn = azurerm_virtual_hub.vhub.virtual_router_asn
  license_file_byol       = var.fgt_license_file_byol
  license_token_fortiflex = var.fgt_license_token_fortiflex
  customdata              = var.fgt_customdata
}
