##############################################################################################################
#
# FortiManager - a standalone FortiManager VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

resource "azurerm_network_security_group" "fmgnsg" {
  name                = "${var.prefix}-FMG-NSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_network_security_rule" "fmgnsgallowallout" {
  name                        = "AllowAllOutbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fmgnsg.name
  priority                    = 105
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fmgnsgallowsshin" {
  name                        = "AllowSSHInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fmgnsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fmgnsgallowhttpin" {
  name                        = "AllowHTTPInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fmgnsg.name
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fmgnsgallowhttpsin" {
  name                        = "AllowHTTPSInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fmgnsg.name
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fmgnsgallowdevregin" {
  name                        = "AllowDevRegInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fmgnsg.name
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "514"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_public_ip" "fmgpip" {
  name                = "${var.prefix}-FMG-PIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s-%s", lower(var.prefix), "fmg", random_string.random.result)
}

resource "azurerm_network_interface" "fmgifc" {
  name                 = "${var.prefix}-FMG-IFC"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fmg_ipaddress_a["1"]
    public_ip_address_id          = azurerm_public_ip.fmgpip.id
  }
}

resource "azurerm_network_interface_security_group_association" "fmgnsg" {
  network_interface_id      = azurerm_network_interface.fmgifc.id
  network_security_group_id = azurerm_network_security_group.fmgnsg.id
}

resource "azurerm_linux_virtual_machine" "fmgvm" {
  name                  = "${var.prefix}-FMG-VM"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.fmgifc.id]
  size                  = var.fmg_vmsize

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "fortinet"
    offer     = "fortinet-fortimanager"
    sku       = var.FMG_IMAGE_SKU
    version   = var.FMG_VERSION
  }

  plan {
    publisher = "fortinet"
    product   = "fortinet-fortimanager"
    name      = var.FMG_IMAGE_SKU
  }

  os_disk {
    name                 = "${var.prefix}-FMG-OSDISK"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  custom_data = base64encode(templatefile("${path.module}/customdata.tpl", {
    fmg_vm_name           = "${var.prefix}-FMG"
    fmg_license_file      = var.FMG_BYOL_LICENSE_FILE
    fmg_license_fortiflex = var.FMG_BYOL_FORTIFLEX_LICENSE_TOKEN
    fmg_username          = var.username
    fmg_ssh_public_key    = var.FMG_SSH_PUBLIC_KEY_FILE
    fmg_ipaddr            = var.fmg_ipaddress_a["1"]
    fmg_mask              = var.subnetmask["1"]
    fmg_gw                = var.gateway_ipaddress["1"]
    vnet_network          = var.vnet
  }))

  tags = {
    publisher = "Fortinet",
    template  = "FortiManager-Terraform",
    provider  = "6EB3B02F-50E5-4A3E-8CB8-2E1292583FMG"
  }
}

data "azurerm_public_ip" "fmgpip" {
  name                = azurerm_public_ip.fmgpip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

output "fmg_public_ip_address" {
  value = data.azurerm_public_ip.fmgpip.ip_address
}
