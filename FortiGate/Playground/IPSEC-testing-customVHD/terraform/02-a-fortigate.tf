###############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

resource "azurerm_public_ip" "fgtapip" {
  name                = "${var.PREFIX}-A-FGT-PIP"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroupa.name
  allocation_method   = "Static"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "a-fgt-pip")
}

resource "azurerm_network_interface" "fgtaifcext" {
  name                          = "${var.PREFIX}-A-VM-FGT-IFC-EXT"
  location                      = azurerm_resource_group.resourcegroupa.location
  resource_group_name           = azurerm_resource_group.resourcegroupa.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subneta1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_external_ipaddress["a"]
    public_ip_address_id          = azurerm_public_ip.fgtapip.id
  }
}

resource "azurerm_network_interface" "fgtaifcint" {
  name                          = "${var.PREFIX}-A-VM-FGT-IFC-INT"
  location                      = azurerm_resource_group.resourcegroupa.location
  resource_group_name           = azurerm_resource_group.resourcegroupa.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subneta2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_internal_ipaddress["a"]
  }
}

resource "azurerm_virtual_machine" "fgtavm" {
  name                         = "${var.PREFIX}-A-VM-FGT"
  location                     = azurerm_resource_group.resourcegroupa.location
  resource_group_name          = azurerm_resource_group.resourcegroupa.name
  network_interface_ids        = ["${azurerm_network_interface.fgtaifcext.id}", "${azurerm_network_interface.fgtaifcint.id}"]
  primary_network_interface_id = azurerm_network_interface.fgtaifcext.id
  vm_size                      = var.fgt_vmsize

  identity {
    type = "SystemAssigned"
  }

  storage_image_reference {
    id = azurerm_image.osdiskvhd.id
  }

  storage_os_disk {
    name              = "${var.PREFIX}-A-VM-FGT-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "${var.PREFIX}-A-VM-FGT"
    admin_username = var.USERNAME
    admin_password = var.PASSWORD
    custom_data    = data.template_file.fgt_a_custom_data.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "IPSEC-test"
    vendor      = "Fortinet"
  }
}

data "template_file" "fgt_a_custom_data" {
  template = file("${path.module}/customdata.tpl")

  vars {
    fgt_vm_name          = "${var.PREFIX}-A-VM-FGT"
    fgt_license_file     = var.FGT_LICENSE_FILE_A
    fgt_username         = var.USERNAME
    fgt_ssh_public_key   = var.FGT_SSH_PUBLIC_KEY_FILE
    fgt_external_ipaddr  = var.fgt_external_ipaddress["a"]
    fgt_external_mask    = var.fgt_external_subnetmask["a"]
    fgt_external_gw      = var.fgt_external_gateway["a"]
    fgt_internal_ipaddr  = var.fgt_internal_ipaddress["a"]
    fgt_internal_mask    = var.fgt_internal_subnetmask["a"]
    fgt_internal_gw      = var.fgt_internal_gateway["a"]
    fgt_protected_net    = var.subnet_protected["a"]
    vnet_network         = var.vnet["a"]
    remote_protected_net = var.subnet_protected["b"]
    remote_public_ip     = data.azurerm_public_ip.fgtbpip.ip_address
    ipsec_psk            = random_string.ipsec_psk.result
  }
}

output "fgt_a_private_ip_address" {
  value = azurerm_network_interface.fgtaifcext.private_ip_address
}

data "azurerm_public_ip" "fgtapip" {
  name                = azurerm_public_ip.fgtapip.name
  resource_group_name = azurerm_resource_group.resourcegroupa.name
}

output "fgt_a_public_ip_address" {
  value = data.azurerm_public_ip.fgtapip.ip_address
}

#data "external" "fgt_a_token" {
#  program = ["sh", "${path.module}/get-token.sh"]
#  query = {
#    fgt_public_ipaddress = "${data.azurerm_public_ip.fgtapip.ip_address}"
#    fgt_username = "${var.USERNAME}"
#    fgt_ssh_private_key = "${var.FGT_SSH_PRIVATE_KEY_FILE}"
#  }
#  depends_on = ["azurerm_virtual_machine.fgtavm"]
#}
# ssh -l azureuser -i output/ssh_key -oStrictHostKeyChecking=no 104.40.209.70 "exec api generate-key restapi" | grep "New API key" | sed -e "s/^.*New API key: //" > test2
#resource "null_resource" "export_rendered_template" {
#  provisioner "local-exec" {
#    command = "echo ${data.azurerm_public_ip.webpip.ip_address} > test.output"
#  }
#
#  depends_on = ["azurerm_virtual_machine.webvm"]
#}
