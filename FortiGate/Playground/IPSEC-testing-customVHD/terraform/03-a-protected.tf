##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

resource "azurerm_public_ip" "lnxapip" {
  name                = "${var.prefix}-A-LNX-PIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroupa.name
  allocation_method   = "Static"
  domain_name_label   = format("%s-%s", lower(var.prefix), "a-lnx-pip")
}

resource "azurerm_network_interface" "lnxaifc" {
  name                          = "${var.prefix}-A-VM-LNX-IFC"
  location                      = azurerm_resource_group.resourcegroupa.location
  resource_group_name           = azurerm_resource_group.resourcegroupa.name
  ip_forwarding_enabled          = false
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subneta3.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.backend_srv_ipaddress["a"]
    public_ip_address_id          = azurerm_public_ip.lnxapip.id
  }
}

resource "azurerm_virtual_machine" "lnxavm" {
  name                  = "${var.prefix}-A-VM-LNX"
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
    name              = "${var.prefix}-A-VM-LNX-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}-A-VM-LNX"
    admin_username = var.username
    admin_password = var.password
    custom_data    = data.template_file.lnx_a_custom_data.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "IPSEC test"
    vendor      = "Fortinet"
  }
}

data "template_file" "lnx_a_custom_data" {
  template = file("${path.module}/customdata-lnx.tpl")

  vars {
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