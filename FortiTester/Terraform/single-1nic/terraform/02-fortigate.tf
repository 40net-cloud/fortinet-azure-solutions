##############################################################################################################
#
# FortiGate VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

resource "azurerm_network_security_group" "fgtnsg" {
  name                = "${var.prefix}-FGT-NSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_network_security_rule" "fgtnsgallowallout" {
  name                        = "AllowAllOutbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fgtnsg.name
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fgtnsgallowallin" {
  name                        = "AllowAllInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fgtnsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_public_ip" "fgtpip" {
  name                = "${var.prefix}-FGT-PIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s", lower(var.prefix), "fgt-pip")
}

resource "azurerm_network_interface" "fgtifcmgmt" {
  name                          = "${var.prefix}-FGT-VM-IFC-MGMT"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = var.ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress["1"]
    public_ip_address_id          = azurerm_public_ip.fgtpip.id
  }
}

resource "azurerm_network_interface_security_group_association" "fgtifcmgmtnsg" {
  network_interface_id      = azurerm_network_interface.fgtifcmgmt.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}


resource "azurerm_network_interface" "fgtifcext" {
  name                          = "${var.prefix}-FGT-VM-IFC-EXT"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = var.ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress["2a"]
    primary                       = true
  }

  ip_configuration {
    name                          = "ifconfig2"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress["2b"]
  }
}

resource "azurerm_network_interface_security_group_association" "fgtifcextnsg" {
  network_interface_id      = azurerm_network_interface.fgtifcext.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_network_interface" "fgtifcint" {
  name                          = "${var.prefix}-FGT-VM-IFC-INT"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = var.ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet3.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress["3"]
  }
}

resource "azurerm_network_interface_security_group_association" "fgtifcintnsg" {
  network_interface_id      = azurerm_network_interface.fgtifcint.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_virtual_machine" "fgtvm" {
  name                         = "${var.prefix}-FGT-VM"
  location                     = azurerm_resource_group.resourcegroup.location
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  network_interface_ids        = [azurerm_network_interface.fgtifcmgmt.id, azurerm_network_interface.fgtifcext.id, azurerm_network_interface.fgtifcint.id]
  primary_network_interface_id = azurerm_network_interface.fgtifcmgmt.id
  vm_size                      = var.fgt_vmsize

  identity {
    type = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "fortinet"
    offer     = "fortinet_fortigate-vm_v5"
    sku       = var.FGT_IMAGE_SKU
    version   = var.FGT_VERSION
  }

  plan {
    publisher = "fortinet"
    product   = "fortinet_fortigate-vm_v5"
    name      = var.FGT_IMAGE_SKU
  }

  storage_os_disk {
    name              = "${var.prefix}-FGT-VM-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}-FGT-VM"
    admin_username = var.username
    admin_password = var.password
    custom_data    = data.template_file.fgt_custom_data.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = var.fortinet_tags
}

data "template_file" "fgt_custom_data" {
  template = file("${path.module}/customdata-fgt.tpl")

  vars = {
    fgt_vm_name           = "${var.prefix}-FGT-VM"
    fgt_license_file      = var.FGT_BYOL_LICENSE_FILE
    fgt_license_fortiflex = var.FGT_BYOL_FORTIFLEX_LICENSE_TOKEN
    fgt_username          = var.username
    fgt_password          = var.password
    fgt_ssh_public_key    = var.FGT_SSH_PUBLIC_KEY_FILE
    fgt_mgmt_ipaddr       = var.fgt_ipaddress["1"]
    fgt_mgmt_mask         = var.subnetmask["1"]
    fgt_mgmt_gw           = var.gateway_ipaddress["1"]
    fgt_external_ipaddr   = var.fgt_ipaddress["2a"]
    fgt_external_ipaddr_2 = var.fgt_ipaddress["2b"]
    fgt_external_mask     = var.subnetmask["2"]
    fgt_external_gw       = var.gateway_ipaddress["2"]
    fgt_internal_ipaddr   = var.fgt_ipaddress["3"]
    fgt_internal_mask     = var.subnetmask["3"]
    fgt_internal_gw       = var.gateway_ipaddress["3"]
    vnet_network          = var.vnet
  }
}

data "azurerm_public_ip" "fgtpip" {
  name                = azurerm_public_ip.fgtpip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
  depends_on          = [azurerm_virtual_machine.fgtvm]
}
