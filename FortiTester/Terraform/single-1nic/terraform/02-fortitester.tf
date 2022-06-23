##############################################################################################################
#
# FortiTester VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

##############################################################################################################
# FortiGate custom VHD image
##############################################################################################################

resource "azurerm_image" "osdiskvhd" {
  name                = "${var.PREFIX}-FTS-IMAGE"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = var.FTSOSDISKVHDURI
    caching  = "ReadWrite"
  }
}

##############################################################################################################

resource "azurerm_network_security_group" "ftsnsg" {
  name                = "${var.PREFIX}-FTS-NSG"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_network_security_rule" "ftsnsgallowallout" {
  name                        = "AllowAllOutbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.ftsnsg.name
  priority                    = 105
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "ftsnsgallowsshin" {
  name                        = "AllowSSHInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.ftsnsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "ftsnsgallowhttpin" {
  name                        = "AllowHTTPInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.ftsnsg.name
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "ftsnsgallowhttpsin" {
  name                        = "AllowHTTPSInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.ftsnsg.name
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_public_ip" "ftspip" {
  name                = "${var.PREFIX}-FTS-PIP"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Basic"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "fts-pip")
}


resource "azurerm_network_interface" "ftsifc1" {
  name                          = "${var.PREFIX}-FTS-MGMT"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fts_ipaddress["1"]
    public_ip_address_id          = azurerm_public_ip.ftspip.id
  }
}

resource "azurerm_network_interface" "ftsifc2" {
  name                          = "${var.PREFIX}-FTS-PORT1"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fts_ipaddress["2"]
  }
}

resource "azurerm_network_interface" "ftsifc3" {
  name                          = "${var.PREFIX}-FTS-PORT2"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet3.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fts_ipaddress["3"]
  }
}

resource "azurerm_network_interface_security_group_association" "ftsnsg" {
  network_interface_id      = azurerm_network_interface.ftsifc1.id
  network_security_group_id = azurerm_network_security_group.ftsnsg.id
}

resource "azurerm_virtual_machine" "ftsvm" {
  name                         = "${var.PREFIX}-FTS-VM"
  location                     = azurerm_resource_group.resourcegroup.location
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  network_interface_ids        = [azurerm_network_interface.ftsifc1.id, azurerm_network_interface.ftsifc2.id, azurerm_network_interface.ftsifc3.id]
  primary_network_interface_id = azurerm_network_interface.ftsifc1.id
  vm_size                      = var.fts_vmsize

  identity {
    type = "SystemAssigned"
  }

  storage_image_reference {
    id = azurerm_image.osdiskvhd.id
  }

  #  storage_image_reference {
  #    publisher = "fortinet"
  #    offer     = "fortinet-fortitester"
  #    sku       = var.FTS_IMAGE_SKU
  #    version   = var.FTS_VERSION
  #  }

  #  plan {
  #    publisher = "fortinet"
  #    product   = "fortinet-fortitester"
  #    name      = var.FTS_IMAGE_SKU
  #  }

  storage_os_disk {
    name              = "${var.PREFIX}-FTS-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }

  storage_data_disk {
    name              = "${var.PREFIX}-FTS-DATADISK"
    managed_disk_type = "StandardSSD_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "100"
  }

  os_profile {
    computer_name  = "${var.PREFIX}-FTS-A"
    admin_username = var.USERNAME
    admin_password = var.PASSWORD
    custom_data    = data.template_file.fts_custom_data.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = var.fortinet_tags
}

data "template_file" "fts_custom_data" {
  template = file("${path.module}/customdata-fts.tpl")

  vars = {
    fts_vm_name        = "${var.PREFIX}-FTS-A"
    fts_license_file   = var.FTS_BYOL_LICENSE_FILE
    fts_username       = var.USERNAME
    fts_ssh_public_key = var.FTS_SSH_PUBLIC_KEY_FILE
    fts_ipaddr         = var.fts_ipaddress["1"]
    fts_mask           = var.subnetmask["1"]
    fts_gw             = var.gateway_ipaddress["1"]
    vnet_network       = var.vnet
  }
}

data "azurerm_public_ip" "ftspip" {
  name                = azurerm_public_ip.ftspip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

output "fts_public_ip_address" {
  value = data.azurerm_public_ip.ftspip.ip_address
}
