##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

resource "azurerm_public_ip" "lnxbpip" {
  name                = "${var.PREFIX}-LNX-B-PIP"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "-lnx-b-pip")
}

resource "azurerm_network_interface" "lnxbifc" {
  name                          = "${var.PREFIX}-LNX-B-IFC"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = false
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet2b.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lnxbpip.id
  }
}

resource "azurerm_linux_virtual_machine" "lnxbvm" {
  name                  = "${var.PREFIX}-LNX-B-VM"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.lnxbifc.id]
  size                  = var.lnx_vmsize

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    name                 = "${var.PREFIX}-LNX-B-OSDISK"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  computer_name                   = "${var.PREFIX}-LNX-B-VM"
  admin_username                  = var.USERNAME
  admin_password                  = var.PASSWORD
  disable_password_authentication = false
  custom_data                     = base64encode(templatefile("${path.module}/../templates/customdata-lnx.tftpl",{}))

  boot_diagnostics {
  }

  tags = var.TAGS

  depends_on = [azurerm_linux_virtual_machine.lnxavm]
}

data "azurerm_public_ip" "lnxbpip" {
  name                = azurerm_public_ip.lnxbpip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

output "lnx_b_public_ip_address" {
  value = data.azurerm_public_ip.lnxbpip.ip_address
}

output "lnx_b_private_ip_address" {
  value = azurerm_network_interface.lnxaifc.private_ip_address
}
