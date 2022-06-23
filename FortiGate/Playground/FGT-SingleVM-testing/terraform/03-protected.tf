##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

resource "azurerm_public_ip" "lnxapip" {
  name                = "${var.PREFIX}-LNX-PIP-A"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroupa.name
  allocation_method   = "Static"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "lnx-pip-a")
}

resource "azurerm_network_interface" "lnxaifc" {
  name                          = "${var.PREFIX}-VM-LNX-IFC-A"
  location                      = azurerm_resource_group.resourcegroupa.location
  resource_group_name           = azurerm_resource_group.resourcegroupa.name
  enable_ip_forwarding          = false
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet3.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.protected_srv_ipaddress["a"]
    public_ip_address_id          = azurerm_public_ip.lnxapip.id
  }
}

resource "azurerm_virtual_machine" "lnxavm" {
  name                  = "${var.PREFIX}-VM-LNX-A"
  location              = azurerm_resource_group.resourcegroupa.location
  resource_group_name   = azurerm_resource_group.resourcegroupa.name
  network_interface_ids = ["${azurerm_network_interface.lnxaifc.id}"]
  vm_size               = var.lnx_vmsize

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.PREFIX}-VM-LNX-OSDISK-A"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.PREFIX}-VM-LNX-A"
    admin_username = var.USERNAME
    admin_password = var.PASSWORD
    custom_data    = data.template_file.lnx_a_custom_data.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = var.TAGS
}

data "template_file" "lnx_a_custom_data" {
  template = file("${path.module}/customdata-lnx.tpl")

  vars = {
  }
}

data "azurerm_public_ip" "lnxapip" {
  name                = azurerm_public_ip.lnxapip.name
  resource_group_name = azurerm_resource_group.resourcegroupa.name
}

output "lnx_a_public_ip_address" {
  value = data.azurerm_public_ip.lnxapip.ip_address
}

output "lnx_a_private_ip_address" {
  value = azurerm_network_interface.lnxaifc.private_ip_address
}

resource "azurerm_public_ip" "lnxbpip" {
  name                = "${var.PREFIX}-LNX-PIP-B"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroupa.name
  allocation_method   = "Static"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "b-lnx-pip")
}

resource "azurerm_network_interface" "lnxbifc" {
  name                          = "${var.PREFIX}-VM-LNX-IFC-B"
  location                      = azurerm_resource_group.resourcegroupa.location
  resource_group_name           = azurerm_resource_group.resourcegroupa.name
  enable_ip_forwarding          = false
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet4.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.protected_srv_ipaddress["b"]
    public_ip_address_id          = azurerm_public_ip.lnxbpip.id
  }
}

resource "azurerm_virtual_machine" "lnxbvm" {
  name                  = "${var.PREFIX}-VM-LNX-B"
  location              = azurerm_resource_group.resourcegroupa.location
  resource_group_name   = azurerm_resource_group.resourcegroupa.name
  network_interface_ids = ["${azurerm_network_interface.lnxbifc.id}"]
  vm_size               = var.lnx_vmsize

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.PREFIX}-VM-LNX-OSDISK-B"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.PREFIX}-VM-LNX-B"
    admin_username = var.USERNAME
    admin_password = var.PASSWORD
    custom_data    = data.template_file.lnx_a_custom_data.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = var.TAGS
}

data "template_file" "lnx_b_custom_data" {
  template = file("${path.module}/customdata-lnx.tpl")

  vars = {
  }
}

data "azurerm_public_ip" "lnxbpip" {
  name                = azurerm_public_ip.lnxbpip.name
  resource_group_name = azurerm_resource_group.resourcegroupa.name
}

output "lnx_b_public_ip_address" {
  value = data.azurerm_public_ip.lnxbpip.ip_address
}

output "lnx_b_private_ip_address" {
  value = azurerm_network_interface.lnxbifc.private_ip_address
}