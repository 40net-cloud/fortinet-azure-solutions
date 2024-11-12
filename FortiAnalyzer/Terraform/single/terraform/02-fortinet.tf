##############################################################################################################
#
# FortiAnalyzer VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

resource "azurerm_network_security_group" "faznsg" {
  name                = "${var.prefix}-faz-nsg"
  location            = var.location
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
  name                = "${var.prefix}-faz-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s", lower(var.prefix), "faz-pip")
}


resource "azurerm_network_interface" "fazifc" {
  name                 = "${var.prefix}-faz-nic1"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.faz_ipaddress_a["1"]
    public_ip_address_id          = azurerm_public_ip.fazpip.id
    primary                       = true
  }
}

resource "azurerm_network_interface_security_group_association" "faznsg" {
  network_interface_id      = azurerm_network_interface.fazifc.id
  network_security_group_id = azurerm_network_security_group.faznsg.id
}

resource "azurerm_linux_virtual_machine" "faz" {
  name                  = "${var.prefix}-faz"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.fazifc.id]
  size                  = var.faz_vmsize

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
    name                 = "${var.prefix}-faz-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  custom_data = base64encode(templatefile("${path.module}/customdata.tftpl", {
    faz_vm_name           = "${var.prefix}-faz"
    faz_username          = var.username
    faz_license_file      = var.FAZ_BYOL_LICENSE_FILE
    faz_license_fortiflex = var.FAZ_BYOL_FORTIFLEX_LICENSE_TOKEN
    faz_ssh_public_key    = var.FAZ_SSH_PUBLIC_KEY_FILE
    faz_ipaddress_b       = var.faz_ipaddress_b["1"]
    faz_vip               = data.azurerm_public_ip.fazpip.ip_address
    faz_role              = "primary"
  }))

  boot_diagnostics {
  }

  tags = var.fortinet_tags
}

data "azurerm_public_ip" "fazpip" {
  name                = azurerm_public_ip.fazpip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

output "faz_public_ip_address" {
  value = data.azurerm_public_ip.fazpip.ip_address
}
