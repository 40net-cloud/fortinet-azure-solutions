###############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

##############################################################################################################
# BRANCH 1
##############################################################################################################
resource "azurerm_public_ip" "fgtbranch1pip1" {
  name                = "${var.PREFIX}-FGT-BRANCH1-PIP1"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "branch1-pip1")
}

resource "azurerm_public_ip" "fgtbranch1pip2" {
  name                = "${var.PREFIX}-FGT-BRANCH1-PIP2"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "branch1-pip2")
}

resource "azurerm_network_interface" "fgtbranch1ifcext" {
  name                          = "${var.PREFIX}-VM-FGT-BRANCH1-IFC-EXT"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = true
  network_security_group_id     = azurerm_network_security_group.fgtnsg.id

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1branch1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress_branch1["1"]
    public_ip_address_id          = azurerm_public_ip.fgtbranch1pip1.id
  }
}

resource "azurerm_network_interface" "fgtbranch1ifcext2" {
  name                          = "${var.PREFIX}-VM-FGT-BRANCH1-IFC-EXT-2"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = true
  network_security_group_id     = azurerm_network_security_group.fgtnsg.id

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1branch1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress_branch1["1"]
    public_ip_address_id          = azurerm_public_ip.fgtbranch1pip2.id
  }
}

resource "azurerm_network_interface" "fgtbranch1ifcint" {
  name                          = "${var.PREFIX}-FGT-BRANCH1-VM-FGT-IFC-INT"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = true
  network_security_group_id     = azurerm_network_security_group.fgtnsg.id


  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet2branch1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress_branch1["2"]
  }
}

resource "azurerm_virtual_machine" "fgtbranch1vm" {
  name                         = "${var.PREFIX}-BRANCH1-VM-FGT"
  location                     = azurerm_resource_group.resourcegroup.location
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  network_interface_ids        = ["${azurerm_network_interface.fgtbranch1ifcext.id}", "${azurerm_network_interface.fgtbranch1ifcext2.id}", "${azurerm_network_interface.fgtbranch1ifcint.id}"]
  primary_network_interface_id = azurerm_network_interface.fgtbranch1ifcext.id
  vm_size                      = var.fgt_vmsize

  identity {
    type = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "fortinet"
    offer     = "fortinet_fortigate-vm_v5"
    sku       = var.IMAGESKU
    version   = "latest"
  }

  plan {
    publisher = "fortinet"
    product   = "fortinet_fortigate-vm_v5"
    name      = var.IMAGESKU
  }

  storage_os_disk {
    name              = "${var.PREFIX}-BRANCH1-VM-FGT-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.PREFIX}-BRANCH1-VM-FGT"
    admin_username = var.USERNAME
    admin_password = var.PASSWORD
    custom_data    = data.template_file.fgt_a_custom_data.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "Quickstart-VNET-Peering"
    vendor      = "Fortinet"
  }
}

data "template_file" "fgt_branch1_custom_data" {
  template = file("${path.module}/customdata-branch.tpl")

  vars = {
    fgt_vm_name         = "${var.PREFIX}-A-VM-FGT"
    fgt_license_file    = "${var.FGT_LICENSE_FILE_A}"
    fgt_username        = "${var.USERNAME}"
    fgt_ssh_public_key  = "${var.FGT_SSH_PUBLIC_KEY_FILE}"
    fgt_external_ipaddr = "${var.fgt_ipaddress_a["1"]}"
    fgt_external_mask   = "${var.subnetmask["1"]}"
    fgt_external_gw     = "${var.gateway_ipaddress["1"]}"
    fgt_internal_ipaddr = "${var.fgt_ipaddress_a["2"]}"
    fgt_internal_mask   = "${var.subnetmask["2"]}"
    fgt_internal_gw     = "${var.gateway_ipaddress["2"]}"
    fgt_hasync_ipaddr   = "${var.fgt_ipaddress_a["3"]}"
    fgt_hasync_mask     = "${var.subnetmask["3"]}"
    fgt_hasync_gw       = "${var.gateway_ipaddress["3"]}"
    fgt_mgmt_ipaddr     = "${var.fgt_ipaddress_a["4"]}"
    fgt_mgmt_mask       = "${var.subnetmask["4"]}"
    fgt_mgmt_gw         = "${var.gateway_ipaddress["4"]}"
    fgt_ha_peerip       = "${var.fgt_ipaddress_b["3"]}"
    fgt_protected_net   = "${var.subnet["5"]}"
    vnet_network        = "${var.vnet}"
  }
}
