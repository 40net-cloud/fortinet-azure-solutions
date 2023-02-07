##############################################################################################################
#
# Linux VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

resource "azurerm_network_security_group" "lnxnsg" {
  name                = "${var.PREFIX}-LNX-NSG"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_network_security_rule" "lnxnsgallowallout" {
  name                        = "AllowAllOutbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.lnxnsg.name
  priority                    = 105
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "lnxnsgallowsshin" {
  name                        = "AllowSSHInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.lnxnsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "lnxnsgallowhttpin" {
  name                        = "AllowHTTPInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.lnxnsg.name
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "lnxnsgallowhttpsin" {
  name                        = "AllowHTTPSInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.lnxnsg.name
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_public_ip" "lnxpip" {
  name                = "${var.PREFIX}-LNX-PIP"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Basic"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "lnx-pip")
}

resource "azurerm_network_interface" "lnxifc1" {
  name                          = "${var.PREFIX}-LNX-MGMT"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.lnx_ipaddress["1"]
    public_ip_address_id          = azurerm_public_ip.lnxpip.id
  }
}

resource "azurerm_network_interface" "lnxifc2" {
  name                          = "${var.PREFIX}-LNX-PORT1"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.lnx_ipaddress["2"]
  }
}

resource "azurerm_network_interface_security_group_association" "lnxnsg" {
  network_interface_id      = azurerm_network_interface.lnxifc1.id
  network_security_group_id = azurerm_network_security_group.lnxnsg.id
}

resource "azurerm_linux_virtual_machine" "lnxvm" {
  name                  = "${var.PREFIX}-LNX-VM"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.lnxifc1.id, azurerm_network_interface.lnxifc2.id]
  size                  = var.lnx_vmsize

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    name                 = "${var.PREFIX}-LNX-OSDISK"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  admin_username                  = var.USERNAME
  admin_password                  = var.PASSWORD
  disable_password_authentication = false
  custom_data                     = base64encode(templatefile("${path.module}/../templates/customdata-lnx.tftpl", {}))

#  admin_ssh_key {
#    username   = var.USERNAME
#    public_key = file(var.FGT_SSH_PUBLIC_KEY_FILE)
#  }

  tags = var.fortinet_tags
}

resource "azurerm_public_ip" "lnx2pip" {
  name                = "${var.PREFIX}-LNX2-PIP"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Basic"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "lnx2-pip")
}

resource "azurerm_network_interface" "lnx2ifc1" {
  name                          = "${var.PREFIX}-LNX2-MGMT"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.lnx2_ipaddress["1"]
    public_ip_address_id          = azurerm_public_ip.lnx2pip.id
  }
}

resource "azurerm_network_interface" "lnx2ifc2" {
  name                          = "${var.PREFIX}-LNX2-PORT1"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet3.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.lnx2_ipaddress["2"]
  }
}

resource "azurerm_network_interface_security_group_association" "lnx2nsg" {
  network_interface_id      = azurerm_network_interface.lnx2ifc1.id
  network_security_group_id = azurerm_network_security_group.lnxnsg.id
}

resource "azurerm_linux_virtual_machine" "lnx2vm" {
  name                  = "${var.PREFIX}-LNX2-VM"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.lnx2ifc1.id, azurerm_network_interface.lnx2ifc2.id]
  size                  = var.lnx2_vmsize

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    name                 = "${var.PREFIX}-LNX2-OSDISK"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  admin_username                  = var.USERNAME
  admin_password                  = var.PASSWORD
  disable_password_authentication = false
  custom_data                     = base64encode(templatefile("${path.module}/../templates/customdata-lnx2.tftpl", {}))

#  admin_ssh_key {
#    username   = var.USERNAME
#    public_key = file(var.FGT_SSH_PUBLIC_KEY_FILE)
#  }

  tags = var.fortinet_tags
}

data "azurerm_public_ip" "lnxpip" {
  name                = azurerm_public_ip.lnxpip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

output "lnx_public_ip_address" {
  value = data.azurerm_public_ip.lnxpip.ip_address
}

output "lnx_a_private_ip_address" {
  value = azurerm_network_interface.lnxifc1.private_ip_address
}

data "azurerm_public_ip" "lnx2pip" {
  name                = azurerm_public_ip.lnx2pip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

output "lnx2_public_ip_address" {
  value = data.azurerm_public_ip.lnx2pip.ip_address
}

output "lnx2_a_private_ip_address" {
  value = azurerm_network_interface.lnx2ifc1.private_ip_address
}
