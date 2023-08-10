##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

resource "azurerm_public_ip" "lnxapip" {
  count               = var.lnx_count
  name                = "${var.PREFIX}-LNX-A-${count.index}-PIP"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  domain_name_label   = format("%s-%s-%s", lower(var.PREFIX), "a-lnx-pip", count.index)
}

resource "azurerm_network_interface" "lnxaifc" {
  count                         = var.lnx_count
  name                          = "${var.PREFIX}-LNX-A-${count.index}-IFC"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = false
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet3a.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lnxapip[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "lnxavm" {
  count                 = var.lnx_count
  name                  = "${var.PREFIX}-LNX-A-${count.index}-VM"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.lnxaifc[count.index].id]
  size                  = var.lnx_vmsize

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.USERNAME
    public_key = file(var.FGT_SSH_PUBLIC_KEY_FILE)
  }

  os_disk {
    name                 = "${var.PREFIX}-LNX-A-${count.index}-OSDISK"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  computer_name                   = "${var.PREFIX}-LNX-A-${count.index}-VM"
  admin_username                  = var.USERNAME
  admin_password                  = var.PASSWORD
  disable_password_authentication = false
  custom_data                     = base64encode(templatefile("${path.module}/../templates/customdata-lnx.tftpl", {}))

  boot_diagnostics {
  }

  tags = var.TAGS
}

data "azurerm_public_ip" "lnxapip" {
  count               = var.lnx_count
  name                = azurerm_public_ip.lnxapip[count.index].name
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

output "lnx_a_public_ip_address" {
  value = data.azurerm_public_ip.lnxapip.*.ip_address
}

output "lnx_a_private_ip_address" {
  value = azurerm_network_interface.lnxaifc.*.private_ip_address
}
