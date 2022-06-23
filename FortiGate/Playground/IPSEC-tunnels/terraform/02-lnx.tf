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

resource "azurerm_virtual_machine" "lnxvm" {
  name                         = "${var.PREFIX}-LNX-VM"
  location                     = azurerm_resource_group.resourcegroup.location
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  network_interface_ids        = [azurerm_network_interface.lnxifc1.id, azurerm_network_interface.lnxifc2.id]
  primary_network_interface_id = azurerm_network_interface.lnxifc1.id
  vm_size                      = var.lnx_vmsize

  identity {
    type = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.PREFIX}-LNX-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }

  os_profile {
    computer_name  = "${var.PREFIX}-LNX-A"
    admin_username = var.USERNAME
    admin_password = var.PASSWORD
    custom_data    = data.template_file.lnx_custom_data.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = var.fortinet_tags
}

data "template_file" "lnx_custom_data" {
  template = file("${path.module}/customdata-lnx.tpl")

  vars = {}
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
