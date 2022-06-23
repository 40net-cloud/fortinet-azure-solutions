##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

resource "azurerm_public_ip" "lnxbpip" {
  name                = "${var.PREFIX}-B-LNX-PIP"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroupb.name
  allocation_method   = "Static"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "b-lnx-pip")
}

resource "azurerm_network_interface" "lnxbifc" {
  name                          = "${var.PREFIX}-B-VM-LNX-IFC"
  location                      = azurerm_resource_group.resourcegroupb.location
  resource_group_name           = azurerm_resource_group.resourcegroupb.name
  enable_ip_forwarding          = false
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnetb3.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.backend_srv_ipaddress["b"]
    public_ip_address_id          = azurerm_public_ip.lnxbpip.id
  }
}

resource "azurerm_virtual_machine" "lnxbvm" {
  name                  = "${var.PREFIX}-B-VM-LNX"
  location              = azurerm_resource_group.resourcegroupb.location
  resource_group_name   = azurerm_resource_group.resourcegroupb.name
  network_interface_ids = ["${azurerm_network_interface.lnxbifc.id}"]
  vm_size               = "Standard_D4s_v3"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.PREFIX}-B-VM-LNX-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.PREFIX}-B-VM-LNX"
    admin_username = var.USERNAME
    admin_password = var.PASSWORD
    custom_data    = data.template_file.lnx_b_custom_data.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "IPSEC test"
    vendor      = "Fortinet"
  }
}

data "template_file" "lnx_b_custom_data" {
  template = file("${path.module}/customdata-lnx.tpl")

  vars {
  }
}

data "azurerm_public_ip" "lnxbpip" {
  name                = azurerm_public_ip.lnxbpip.name
  resource_group_name = azurerm_resource_group.resourcegroupb.name
}

output "lnx_b_public_ip_address" {
  value = data.azurerm_public_ip.lnxbpip.ip_address
}

output "lnx_b_private_ip_address" {
  value = azurerm_network_interface.lnxaifc.private_ip_address
}
