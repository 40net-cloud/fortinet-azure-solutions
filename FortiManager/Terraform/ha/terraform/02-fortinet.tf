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

resource "azurerm_public_ip" "fmgapip" {
  name                = "${var.prefix}-FMG-A-PIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s-%s", lower(var.prefix), "fmg-a", random_string.random.result)
}

resource "azurerm_public_ip" "fmgbpip" {
  name                = "${var.prefix}-FMG-B-PIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s-%s", lower(var.prefix), "fmg-b", random_string.random.result)
}

resource "azurerm_network_interface" "fmgaifc" {
  name                 = "${var.prefix}-FMG-A-IFC"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fmg_a_ipaddress["1"]
    public_ip_address_id          = azurerm_public_ip.fmgapip.id
  }
}

resource "azurerm_network_interface" "fmgbifc" {
  name                 = "${var.prefix}-FMG-B-IFC"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fmg_b_ipaddress["1"]
    public_ip_address_id          = azurerm_public_ip.fmgbpip.id
  }
}

resource "azurerm_network_interface_security_group_association" "fmgansg" {
  network_interface_id      = azurerm_network_interface.fmgaifc.id
  network_security_group_id = azurerm_network_security_group.fmgnsg.id
}

resource "azurerm_network_interface_security_group_association" "fmgbnsg" {
  network_interface_id      = azurerm_network_interface.fmgbifc.id
  network_security_group_id = azurerm_network_security_group.fmgnsg.id
}

resource "azurerm_managed_disk" "fmgavm-datadisk" {
  name                 = "${var.prefix}-FMG-A-DATADISK"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 50
}

resource "azurerm_virtual_machine_data_disk_attachment" "fmgavm-datadisk-attach" {
  managed_disk_id    = azurerm_managed_disk.fmgavm-datadisk.id
  virtual_machine_id = azurerm_linux_virtual_machine.fmgavm.id
  lun                = 0
  caching            = "ReadWrite"
}

resource "azurerm_managed_disk" "fmgbvm-datadisk" {
  name                 = "${var.prefix}-FMG-B-DATADISK"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 50
}

resource "azurerm_virtual_machine_data_disk_attachment" "fmgbvm-datadisk-attach" {
  managed_disk_id    = azurerm_managed_disk.fmgbvm-datadisk.id
  virtual_machine_id = azurerm_linux_virtual_machine.fmgbvm.id
  lun                = 0
  caching            = "ReadWrite"
}

resource "azurerm_linux_virtual_machine" "fmgavm" {
  name                  = "${var.prefix}-FMG-A"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.fmgaifc.id]
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
    name                 = "${var.prefix}-FMG-A-OSDISK"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  custom_data = base64encode(templatefile("${path.module}/customdata.tpl", {
    fmg_vm_name           = "${var.prefix}-FMG-A"
    fmg_license_file      = var.FMG_A_BYOL_LICENSE_FILE
    fmg_license_fortiflex = var.FMG_A_BYOL_FORTIFLEX_LICENSE_TOKEN
    fmg_username          = var.username
    fmg_ssh_public_key    = var.FMG_SSH_PUBLIC_KEY_FILE
    fmg_ipaddress         = var.fmg_a_ipaddress["1"]
    fmg_mask              = var.subnetmask["1"]
    fmg_gw                = var.gateway_ipaddress["1"]
    fmg_peer_ipaddress    = var.fmg_b_ipaddress["1"]
    fmg_peer_serialnumber = var.FMG_B_BYOL_SERIAL_NUMBER
    fmg_password          = random_string.random.result
    fmg_ha_mode           = "primary"
    vnet_network          = var.vnet
  }))

  // Serial console using managed storage account
  boot_diagnostics {
  }

  tags = var.fortinet_tags
}

resource "azurerm_linux_virtual_machine" "fmgbvm" {
  name                  = "${var.prefix}-FMG-B"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.fmgbifc.id]
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
    name                 = "${var.prefix}-FMG-B-OSDISK"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  custom_data = base64encode(templatefile("${path.module}/customdata.tpl", {
    fmg_vm_name           = "${var.prefix}-FMG-B"
    fmg_license_file      = var.FMG_B_BYOL_LICENSE_FILE
    fmg_license_fortiflex = var.FMG_B_BYOL_FORTIFLEX_LICENSE_TOKEN
    fmg_username          = var.username
    fmg_ssh_public_key    = var.FMG_SSH_PUBLIC_KEY_FILE
    fmg_ipaddress         = var.fmg_b_ipaddress["1"]
    fmg_mask              = var.subnetmask["1"]
    fmg_gw                = var.gateway_ipaddress["1"]
    fmg_peer_ipaddress    = var.fmg_a_ipaddress["1"]
    fmg_peer_serialnumber = var.FMG_A_BYOL_SERIAL_NUMBER
    fmg_password          = random_string.random.result
    fmg_ha_mode           = "secondary"
    vnet_network          = var.vnet
  }))

  // Serial console using managed storage account
  boot_diagnostics {
  }

  tags = var.fortinet_tags
}


data "azurerm_public_ip" "fmgapip" {
  name                = azurerm_public_ip.fmgapip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

data "azurerm_public_ip" "fmgbpip" {
  name                = azurerm_public_ip.fmgbpip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

output "fmg_a_public_ip_address" {
  value = data.azurerm_public_ip.fmgapip.ip_address
}

output "fmg_b_public_ip_address" {
  value = data.azurerm_public_ip.fmgbpip.ip_address
}

output "fmg_a_cloudinit" {
  value = templatefile("${path.module}/customdata.tpl", {
    fmg_vm_name           = "${var.prefix}-FMG-A"
    fmg_license_file      = var.FMG_A_BYOL_LICENSE_FILE
    fmg_license_fortiflex = var.FMG_A_BYOL_FORTIFLEX_LICENSE_TOKEN
    fmg_username          = var.username
    fmg_ssh_public_key    = var.FMG_SSH_PUBLIC_KEY_FILE
    fmg_ipaddress         = var.fmg_a_ipaddress["1"]
    fmg_mask              = var.subnetmask["1"]
    fmg_gw                = var.gateway_ipaddress["1"]
    fmg_peer_ipaddress    = var.fmg_b_ipaddress["1"]
    fmg_peer_serialnumber = var.FMG_B_BYOL_SERIAL_NUMBER
    fmg_password          = random_string.random.result
    fmg_ha_mode           = "primary"
    vnet_network          = var.vnet
  })
}

output "fmg_b_cloudinit" {
  value = templatefile("${path.module}/customdata.tpl", {
    fmg_vm_name           = "${var.prefix}-FMG-B"
    fmg_license_file      = var.FMG_B_BYOL_LICENSE_FILE
    fmg_license_fortiflex = var.FMG_B_BYOL_FORTIFLEX_LICENSE_TOKEN
    fmg_username          = var.username
    fmg_ssh_public_key    = var.FMG_SSH_PUBLIC_KEY_FILE
    fmg_ipaddress         = var.fmg_b_ipaddress["1"]
    fmg_mask              = var.subnetmask["1"]
    fmg_gw                = var.gateway_ipaddress["1"]
    fmg_peer_ipaddress    = var.fmg_a_ipaddress["1"]
    fmg_peer_serialnumber = var.FMG_A_BYOL_SERIAL_NUMBER
    fmg_password          = random_string.random.result
    fmg_ha_mode           = "secondary"
    vnet_network          = var.vnet
  })
}
