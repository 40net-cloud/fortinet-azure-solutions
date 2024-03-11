##############################################################################################################
#
# FortiAnalyzer VM
# Active / Passive deployment
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

resource "azurerm_availability_set" "fazavset" {
  name                = "${var.PREFIX}-faz-availabilityset"
  location            = var.LOCATION
  managed             = true
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_network_security_group" "faznsg" {
  name                = "${var.PREFIX}-faz-nsg"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_network_security_rule" "faznsgallowallout" {
  name                        = "AllowAllOutbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.faznsg.name
  priority                    = 105
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "faznsgallowsshin" {
  name                        = "AllowSSHInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.faznsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "faznsgallowhttpin" {
  name                        = "AllowHTTPInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.faznsg.name
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "faznsgallowhttpsin" {
  name                        = "AllowHTTPSInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.faznsg.name
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "faznsgallowdevregin" {
  name                        = "AllowDevRegInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.faznsg.name
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "514"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_public_ip" "fazpip" {
  name                = "${var.PREFIX}-faz-vip"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "-vip")
}

resource "azurerm_public_ip" "fazpip2" {
  name                = "${var.PREFIX}-faz-a-mgmt-pip"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "fazpip3" {
  name                = "${var.PREFIX}-faz-b-mgmt-pip"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "fazaifc" {
  name                 = "${var.PREFIX}-faz-a-nic1"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.faz_ipaddress_a["1"]
    public_ip_address_id          = azurerm_public_ip.fazpip2.id
    primary                       = true
  }
  ip_configuration {
    name                          = "faz-vip"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.faz_ipaddress_a["2"]
    public_ip_address_id          = azurerm_public_ip.fazpip.id
  }
}

resource "azurerm_network_interface_security_group_association" "fazansg" {
  network_interface_id      = azurerm_network_interface.fazaifc.id
  network_security_group_id = azurerm_network_security_group.faznsg.id
}

resource "azurerm_network_interface" "fazbifc" {
  name                 = "${var.PREFIX}-faz-b-nic1"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.faz_ipaddress_b["1"]
    public_ip_address_id          = azurerm_public_ip.fazpip3.id
    primary                       = true
  }
  ip_configuration {
    name                          = "faz-vip"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.faz_ipaddress_b["2"]
  }
}

resource "azurerm_network_interface_security_group_association" "fazbnsg" {
  network_interface_id      = azurerm_network_interface.fazbifc.id
  network_security_group_id = azurerm_network_security_group.faznsg.id
}

resource "azurerm_linux_virtual_machine" "faza" {
  name                  = "${var.PREFIX}-faz-a"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.fazaifc.id]
  size                  = var.faz_vmsize
  availability_set_id   = azurerm_availability_set.fazavset.id

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "fortinet"
    offer     = "fortinet-fortianalyzer"
    sku       = var.FAZ_IMAGE_SKU
    version   = var.FAZ_VERSION
  }

  plan {
    publisher = "fortinet"
    product   = "fortinet-fortianalyzer"
    name      = var.FAZ_IMAGE_SKU
  }

  os_disk {
    name                 = "${var.PREFIX}-faz-a-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                  = var.USERNAME
  admin_password                  = var.PASSWORD
  disable_password_authentication = false
  custom_data = base64encode(templatefile("${path.module}/customdata.tftpl", {
    faz_vm_name           = "${var.PREFIX}-faz-a"
    faz_username          = var.USERNAME
    faz_password          = var.PASSWORD
    faz_ssh_public_key    = var.FAZ_SSH_PUBLIC_KEY_FILE
    faz_license_file      = var.FAZ_BYOL_LICENSE_FILE_A
    faz_license_fortiflex = var.FAZ_BYOL_FORTIFLEX_LICENSE_TOKEN_A
    faz_serial_number     = var.FAZ_BYOL_SERIAL_NUMBER_B
    faz_ipaddress_b       = var.faz_ipaddress_b["1"]
    faz_vip               = data.azurerm_public_ip.fazpip.ip_address
    faz_role              = "primary"
  }))

  boot_diagnostics {
  }

  tags = var.fortinet_tags
}

resource "azurerm_managed_disk" "faz-a-datadisk" {
  name                 = "${var.PREFIX}-faz-a-datadisk"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 50
}

resource "azurerm_virtual_machine_data_disk_attachment" "faz-a-datadisk-attach" {
  managed_disk_id    = azurerm_managed_disk.faz-a-datadisk.id
  virtual_machine_id = azurerm_linux_virtual_machine.faza.id
  lun                = 0
  caching            = "ReadWrite"
}

resource "azurerm_linux_virtual_machine" "fazb" {
  name                  = "${var.PREFIX}-faz-b"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.fazbifc.id]
  size                  = var.faz_vmsize
  availability_set_id   = azurerm_availability_set.fazavset.id

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "fortinet"
    offer     = "fortinet-fortianalyzer"
    sku       = var.FAZ_IMAGE_SKU
    version   = var.FAZ_VERSION
  }

  plan {
    publisher = "fortinet"
    product   = "fortinet-fortianalyzer"
    name      = var.FAZ_IMAGE_SKU
  }

  os_disk {
    name                 = "${var.PREFIX}-faz-b-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                  = var.USERNAME
  admin_password                  = var.PASSWORD
  disable_password_authentication = false
  custom_data = base64encode(templatefile("${path.module}/customdata.tftpl", {
    faz_vm_name           = "${var.PREFIX}-faz-b"
    faz_username          = var.USERNAME
    faz_password          = var.PASSWORD
    faz_license_file      = var.FAZ_BYOL_LICENSE_FILE_B
    faz_license_fortiflex = var.FAZ_BYOL_FORTIFLEX_LICENSE_TOKEN_B
    faz_serial_number     = var.FAZ_BYOL_SERIAL_NUMBER_A
    faz_ssh_public_key    = var.FAZ_SSH_PUBLIC_KEY_FILE
    faz_ipaddress_b       = var.faz_ipaddress_a["1"]
    faz_vip               = data.azurerm_public_ip.fazpip.ip_address
    faz_role              = "secondary"
  }))

  boot_diagnostics {
  }

  tags = var.fortinet_tags
}

resource "azurerm_managed_disk" "faz-b-datadisk" {
  name                 = "${var.PREFIX}-faz-b-datadisk"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 50
}

resource "azurerm_virtual_machine_data_disk_attachment" "faz-b-datadisk-attach" {
  managed_disk_id    = azurerm_managed_disk.faz-b-datadisk.id
  virtual_machine_id = azurerm_linux_virtual_machine.fazb.id
  lun                = 0
  caching            = "ReadWrite"
}

data "azurerm_public_ip" "fazpip" {
  name                = azurerm_public_ip.fazpip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

output "faz_public_ip" {
  value = data.azurerm_public_ip.fazpip.ip_address
}

data "azurerm_public_ip" "fazpip2" {
  name                = azurerm_public_ip.fazpip2.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

output "faz_a_mgmt_public_ip" {
  value = data.azurerm_public_ip.fazpip2.ip_address
}

data "azurerm_public_ip" "fazpip3" {
  name                = azurerm_public_ip.fazpip3.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

output "faz_b_mgmt_public_ip" {
  value = data.azurerm_public_ip.fazpip3.ip_address
}
