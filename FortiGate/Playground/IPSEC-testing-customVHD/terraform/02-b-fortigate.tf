##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

resource "azurerm_public_ip" "fgtbpip" {
  name                = "${var.PREFIX}-B-FGT-PIP"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroupb.name
  allocation_method   = "Static"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "b-fgt-pip")
}

resource "azurerm_network_interface" "fgtbifcext" {
  name                          = "${var.PREFIX}-B-VM-FGT-IFC-EXT"
  location                      = azurerm_resource_group.resourcegroupb.location
  resource_group_name           = azurerm_resource_group.resourcegroupb.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnetb1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_external_ipaddress["b"]
    public_ip_address_id          = azurerm_public_ip.fgtbpip.id
  }
}

resource "azurerm_network_interface" "fgtbifcint" {
  name                          = "${var.PREFIX}-B-VM-FGT-IFC-INT"
  location                      = azurerm_resource_group.resourcegroupb.location
  resource_group_name           = azurerm_resource_group.resourcegroupb.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnetb2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_internal_ipaddress["b"]
  }
}

resource "azurerm_virtual_machine" "fgtbvm" {
  name                         = "${var.PREFIX}-B-VM-FGT"
  location                     = azurerm_resource_group.resourcegroupb.location
  resource_group_name          = azurerm_resource_group.resourcegroupb.name
  network_interface_ids        = ["${azurerm_network_interface.fgtbifcext.id}", "${azurerm_network_interface.fgtbifcint.id}"]
  primary_network_interface_id = azurerm_network_interface.fgtbifcext.id
  vm_size                      = var.fgt_vmsize

  identity {
    type = "SystemAssigned"
  }

  storage_image_reference {
    id = azurerm_image.osdiskvhd.id
  }

  storage_os_disk {
    name              = "${var.PREFIX}-B-VM-FGT-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.PREFIX}-B-VM-FGT"
    admin_username = var.USERNAME
    admin_password = var.PASSWORD
    custom_data    = data.template_file.fgt_b_custom_data.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "IPSEC-test"
    vendor      = "Fortinet"
  }
}

data "template_file" "fgt_b_custom_data" {
  template = file("${path.module}/customdata.tpl")

  vars {
    fgt_vm_name          = "${var.PREFIX}-B-VM-FGT"
    fgt_license_file     = var.FGT_LICENSE_FILE_B
    fgt_username         = var.USERNAME
    fgt_ssh_public_key   = var.FGT_SSH_PUBLIC_KEY_FILE
    fgt_external_ipaddr  = var.fgt_external_ipaddress["b"]
    fgt_external_mask    = var.fgt_external_subnetmask["b"]
    fgt_external_gw      = var.fgt_external_gateway["b"]
    fgt_internal_ipaddr  = var.fgt_internal_ipaddress["b"]
    fgt_internal_mask    = var.fgt_internal_subnetmask["b"]
    fgt_internal_gw      = var.fgt_internal_gateway["b"]
    fgt_protected_net    = var.subnet_protected["b"]
    vnet_network         = var.vnet["b"]
    remote_protected_net = var.subnet_protected["a"]
    remote_public_ip     = data.azurerm_public_ip.fgtapip.ip_address
    ipsec_psk            = random_string.ipsec_psk.result
  }
}

output "fgt_b_private_ip_address" {
  value = azurerm_network_interface.fgtbifcext.private_ip_address
}

data "azurerm_public_ip" "fgtbpip" {
  name                = azurerm_public_ip.fgtbpip.name
  resource_group_name = azurerm_resource_group.resourcegroupb.name
}

output "fgt_b_public_ip_address" {
  value = data.azurerm_public_ip.fgtbpip.ip_address
}