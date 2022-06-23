##############################################################################################################
#
# Fortinet FortiGate Terraform deployment
#
##############################################################################################################

resource "azurerm_public_ip" "fgtpip" {
  name                = "${var.PREFIX}-FGT-PIP"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroupa.name
  allocation_method   = "Static"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "a-fgt-pip")
}

resource "azurerm_network_interface" "fgtifcext" {
  name                          = "${var.PREFIX}-VM-FGT-IFC-EXT"
  location                      = azurerm_resource_group.resourcegroupa.location
  resource_group_name           = azurerm_resource_group.resourcegroupa.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_external_ipaddress["a"]
    public_ip_address_id          = azurerm_public_ip.fgtpip.id
  }
}

resource "azurerm_network_interface" "fgtifcint" {
  name                          = "${var.PREFIX}-VM-FGT-IFC-INT"
  location                      = azurerm_resource_group.resourcegroupa.location
  resource_group_name           = azurerm_resource_group.resourcegroupa.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_internal_ipaddress["a"]
  }
}

resource "azurerm_virtual_machine" "fgtvm" {
  name                         = "${var.PREFIX}-VM-FGT"
  location                     = azurerm_resource_group.resourcegroupa.location
  resource_group_name          = azurerm_resource_group.resourcegroupa.name
  network_interface_ids        = ["${azurerm_network_interface.fgtifcext.id}", "${azurerm_network_interface.fgtifcint.id}"]
  primary_network_interface_id = azurerm_network_interface.fgtifcext.id
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
    name              = "${var.PREFIX}-VM-FGT-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.PREFIX}-VM-FGT"
    admin_username = var.USERNAME
    admin_password = var.PASSWORD
    custom_data    = data.template_file.fgt_custom_data.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = var.TAGS

  #  boot_diagnostics {
  #    enabled     = "${var.BOOT_DIAGNOSTICS}"
  #    storage_uri = "${var.BOOT_DIAGNOSTICS == "true" ? join(",", azurerm_storage_account.sadiaga.*.primary_blob_endpoint) : "" }"
  #  }
}

data "template_file" "fgt_custom_data" {
  template = file("${path.module}/customdata.tpl")

  vars = {
    prefix              = "${var.PREFIX}"
    fgt_vm_name         = "${var.PREFIX}-VM-FGT"
    fgt_license_file    = "${var.FGT_LICENSE_FILE}"
    fgt_username        = "${var.USERNAME}"
    fgt_ssh_public_key  = "${var.FGT_SSH_PUBLIC_KEY_FILE}"
    fgt_external_ipaddr = "${var.fgt_external_ipaddress["a"]}"
    fgt_external_mask   = "${var.fgt_external_subnetmask["a"]}"
    fgt_external_gw     = "${var.fgt_external_gateway["a"]}"
    fgt_internal_ipaddr = "${var.fgt_internal_ipaddress["a"]}"
    fgt_internal_mask   = "${var.fgt_internal_subnetmask["a"]}"
    fgt_internal_gw     = "${var.fgt_internal_gateway["a"]}"
    fgt_protected_net_a = "${var.subnet_protected["a"]}"
    fgt_protected_net_b = "${var.subnet_protected["b"]}"
    vnet_network        = "${var.vnet["a"]}"
  }
}

output "fgt_private_ip_address" {
  value = azurerm_network_interface.fgtifcext.private_ip_address
}

data "azurerm_public_ip" "fgtpip" {
  name                = azurerm_public_ip.fgtpip.name
  resource_group_name = azurerm_resource_group.resourcegroupa.name
}

output "fgt_public_ip_address" {
  value = data.azurerm_public_ip.fgtpip.ip_address
}
