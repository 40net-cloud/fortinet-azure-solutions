##############################################################################################################
#
# FortiWeb a standalone FortiWeb VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

resource "azurerm_network_security_group" "fwbnsg" {
  name                = "${var.prefix}-FWB-NSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_network_security_rule" "fwbnsgallowallout" {
  name                        = "AllowAllOutbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fwbnsg.name
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fwbnsgallowallin" {
  name                        = "AllowAllInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fwbnsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_public_ip" "fwbpip" {
  name                = "${var.prefix}-FWB-PIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s", lower(var.prefix), "lb-pip")
}

resource "azurerm_network_interface" "fwbifcext" {
  name                          = "${var.prefix}-FWB-Nic1-EXT"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = var.FWB_ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fwb_ipaddress["1"]
    public_ip_address_id          = azurerm_public_ip.fwbpip.id
  }
}

resource "azurerm_network_interface_security_group_association" "fwbifcextnsg" {
  network_interface_id      = azurerm_network_interface.fwbifcext.id
  network_security_group_id = azurerm_network_security_group.fwbnsg.id
}

resource "azurerm_network_interface" "fwbifcint" {
  name                 = "${var.prefix}-FWB-Nic2-INT"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fwb_ipaddress["2"]
  }
}

resource "azurerm_network_interface_security_group_association" "fwbifcintnsg" {
  network_interface_id      = azurerm_network_interface.fwbifcint.id
  network_security_group_id = azurerm_network_security_group.fwbnsg.id
}

resource "azurerm_linux_virtual_machine" "fwbvm" {
  name                  = "${var.prefix}-FWB"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.fwbifcext.id, azurerm_network_interface.fwbifcint.id]
  size                  = var.fwb_vmsize

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "fortinet"
    offer     = "fortinet_fortiweb-vm_v5"
    sku       = var.FWB_IMAGE_SKU
    version   = var.FWB_VERSION
  }

  plan {
    publisher = "fortinet"
    product   = "fortinet_fortiweb-vm_v5"
    name      = var.FWB_IMAGE_SKU
  }

  os_disk {
    name                 = "${var.prefix}-FWB-OSDISK"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  custom_data = base64encode(templatefile("${path.module}/customdata.tpl", {
    fwb_vm_name           = "${var.prefix}-FWB"
    fwb_license_file      = var.FWB_BYOL_LICENSE_FILE
    fwb_license_fortiflex = var.FWB_BYOL_FORTIFLEX_LICENSE_TOKEN
#    fwb_username          = var.username
#    fwb_ssh_public_key    = var.FWB_SSH_PUBLIC_KEY_FILE
#    fwb_external_ipaddr   = var.fwb_ipaddress["1"]
#    fwb_external_mask     = var.subnetmask["1"]
#    fwb_external_gw       = var.gateway_ipaddress["1"]
#    fwb_internal_ipaddr   = var.fwb_ipaddress["2"]
#    fwb_internal_mask     = var.subnetmask["2"]
#    fwb_internal_gw       = var.gateway_ipaddress["2"]
#    vnet_network          = var.vnet
  }))

  boot_diagnostics {
  }

  tags = var.fortinet_tags
}

resource "azurerm_managed_disk" "fwbvm-datadisk" {
  name                 = "${var.prefix}-FWB-DATADISK"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 180
}

resource "azurerm_virtual_machine_data_disk_attachment" "fwbvm-datadisk-attach" {
  managed_disk_id    = azurerm_managed_disk.fwbvm-datadisk.id
  virtual_machine_id = azurerm_linux_virtual_machine.fwbvm.id
  lun                = 0
  caching            = "ReadWrite"
}

data "azurerm_public_ip" "fwbpip" {
  name                = azurerm_public_ip.fwbpip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
  depends_on          = [azurerm_linux_virtual_machine.fwbvm]
}

output "fwb_public_ip_address" {
  value = data.azurerm_public_ip.fwbpip.ip_address
}
