##############################################################################################################
#
# FortiWeb HA-Active-Active
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

resource "azurerm_network_security_group" "fwbnsg" {
  name                = "${var.PREFIX}-FWB-NSG"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_network_security_rule" "fwbnsgallowallout" {
  name                        = "AllowAllOutbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fwbnsg.name
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fwbnsgallowallin" {
  name                        = "AllowAllInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fwbnsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_public_ip" "elbpip" {
  name                = "${var.PREFIX}-FWB-PIP"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "lb-pip")
}

resource "azurerm_lb" "elb" {
  name                = "${var.PREFIX}-ExternalLoadBalancer"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "${var.PREFIX}-ELB-PIP"
    public_ip_address_id = azurerm_public_ip.elbpip.id
  }
}

resource "azurerm_lb_backend_address_pool" "elbbackend" {
  loadbalancer_id = azurerm_lb.elb.id
  name            = "BackEndPool"
}

resource "azurerm_lb_probe" "elbprobehttp" {
  loadbalancer_id     = azurerm_lb.elb.id
  name                = "lbprobehttp"
  port                = 80
  interval_in_seconds = 15
  number_of_probes    = 2
  protocol            = "Tcp"
}

resource "azurerm_lb_probe" "elbprobehttps" {
  loadbalancer_id     = azurerm_lb.elb.id
  name                = "lbprobehttps"
  port                = 443
  interval_in_seconds = 15
  number_of_probes    = 2
  protocol            = "Tcp"
}

resource "azurerm_lb_rule" "lbruletcphttp" {
  loadbalancer_id                = azurerm_lb.elb.id
  name                           = "PublicLBRule-FE1-http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "${var.PREFIX}-ELB-PIP"
  probe_id                       = azurerm_lb_probe.elbprobehttp.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.elbbackend.id]
  enable_floating_ip             = true
}

resource "azurerm_lb_rule" "lbruletcphttps" {
  loadbalancer_id                = azurerm_lb.elb.id
  name                           = "PublicLBRule-FE1-https"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "${var.PREFIX}-ELB-PIP"
  probe_id                       = azurerm_lb_probe.elbprobehttps.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.elbbackend.id]
  enable_floating_ip             = true
}


resource "azurerm_lb_nat_rule" "fwbamgmthttps" {
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  loadbalancer_id                = azurerm_lb.elb.id
  name                           = "${var.PREFIX}-FWB-A-Admin-HTTPS"
  protocol                       = "Tcp"
  frontend_port                  = 40030
  backend_port                   = 8443
  frontend_ip_configuration_name = "${var.PREFIX}-ELB-PIP"
}

resource "azurerm_lb_nat_rule" "fwbbmgmthttps" {
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  loadbalancer_id                = azurerm_lb.elb.id
  name                           = "${var.PREFIX}-FWB-B-Admin-HTTPS"
  protocol                       = "Tcp"
  frontend_port                  = 40031
  backend_port                   = 8443
  frontend_ip_configuration_name = "${var.PREFIX}-ELB-PIP"
}

resource "azurerm_lb_nat_rule" "fwbamgmtssh" {
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  loadbalancer_id                = azurerm_lb.elb.id
  name                           = "${var.PREFIX}-FWB-A-SSH"
  protocol                       = "Tcp"
  frontend_port                  = 50030
  backend_port                   = 22
  frontend_ip_configuration_name = "${var.PREFIX}-ELB-PIP"
}

resource "azurerm_lb_nat_rule" "fwbbmgmtssh" {
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  loadbalancer_id                = azurerm_lb.elb.id
  name                           = "${var.PREFIX}-FWB-B-SSH"
  protocol                       = "Tcp"
  frontend_port                  = 50031
  backend_port                   = 22
  frontend_ip_configuration_name = "${var.PREFIX}-ELB-PIP"
}


resource "azurerm_network_interface" "fwbaifcext" {
  name                          = "${var.PREFIX}-FWB-A-Nic1-EXT"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.FWB_ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fwb_ipaddress_a["1"]
  }
}

resource "azurerm_network_interface_security_group_association" "fwbaifcextnsg" {
  network_interface_id      = azurerm_network_interface.fwbaifcext.id
  network_security_group_id = azurerm_network_security_group.fwbnsg.id
}

resource "azurerm_network_interface_backend_address_pool_association" "fwbaifcext2elbbackendpool" {
  network_interface_id    = azurerm_network_interface.fwbaifcext.id
  ip_configuration_name   = "interface1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.elbbackend.id
}

resource "azurerm_network_interface_nat_rule_association" "fwbamgmthttpsvm" {
  network_interface_id  = azurerm_network_interface.fwbaifcext.id
  ip_configuration_name = "interface1"
  nat_rule_id           = azurerm_lb_nat_rule.fwbamgmthttps.id
}

resource "azurerm_network_interface_nat_rule_association" "fwbamgmtsshvm" {
  network_interface_id  = azurerm_network_interface.fwbaifcext.id
  ip_configuration_name = "interface1"
  nat_rule_id           = azurerm_lb_nat_rule.fwbamgmtssh.id
}

resource "azurerm_network_interface" "fwbaifcint" {
  name                 = "${var.PREFIX}-FWB-A-Nic2-INT"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fwb_ipaddress_a["2"]
  }
}

resource "azurerm_network_interface_security_group_association" "fwbaifcintnsg" {
  network_interface_id      = azurerm_network_interface.fwbaifcint.id
  network_security_group_id = azurerm_network_security_group.fwbnsg.id
}

resource "azurerm_linux_virtual_machine" "fwbavm" {
  name                  = "${var.PREFIX}-FWB-A"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.fwbaifcext.id, azurerm_network_interface.fwbaifcint.id]
  size                  = var.fwb_vmsize

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "fortinet"
    offer     = "fortinet_fortiweb-vm_v5"
    sku       = var.FWB_IMAGE_SKU
    version   = var.FWB_VERSION
  }

  plan {
    publisher = "fortinet"
    product   = "fortinet_fortiweb-vm_v5"
    name      = var.FWB_IMAGE_SKU
  }

  os_disk {
    name                 = "${var.PREFIX}-FWB-A-OSDISK"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                  = var.USERNAME
  admin_password                  = var.PASSWORD
  disable_password_authentication = false
  custom_data = base64encode(templatefile("${path.module}/customdata.tpl", {
    fwb_vm_name           = "${var.PREFIX}-FWB-A"
    fwb_license_file      = var.FWB_BYOL_LICENSE_FILE_A
    fwb_license_fortiflex = var.FWB_BYOL_FORTIFLEX_LICENSE_TOKEN_A
	fwb_ha_group_name	  = "${var.PREFIX}"
	ha_loadblancer_name	  =	"${var.PREFIX}-ExternalLoadBalancer"
	fwb_ha_instanceId	  = 1
	fwb_ha_priority		  = 1
	fwb_ha_localip        = var.fwb_ipaddress_a["2"]
	fwb_ha_peerip         = var.fwb_ipaddress_b["2"]		
  }))

  boot_diagnostics {
  }

  tags = var.fortinet_tags
}

resource "azurerm_managed_disk" "fwbavm-datadisk" {
  name                 = "${var.PREFIX}-FWB-A-DATADISK"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 180
}

resource "azurerm_virtual_machine_data_disk_attachment" "fwbavm-datadisk-attach" {
  managed_disk_id    = azurerm_managed_disk.fwbavm-datadisk.id
  virtual_machine_id = azurerm_linux_virtual_machine.fwbavm.id
  lun                = 0
  caching            = "ReadWrite"
}

resource "azurerm_network_interface" "fwbbifcext" {
  name                          = "${var.PREFIX}-FWB-B-Nic1-EXT"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.FWB_ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fwb_ipaddress_b["1"]
  }
}

resource "azurerm_network_interface_security_group_association" "fwbbifcextnsg" {
  network_interface_id      = azurerm_network_interface.fwbbifcext.id
  network_security_group_id = azurerm_network_security_group.fwbnsg.id
}

resource "azurerm_network_interface_backend_address_pool_association" "fwbbifcext2elbbackendpool" {
  network_interface_id    = azurerm_network_interface.fwbbifcext.id
  ip_configuration_name   = "interface1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.elbbackend.id
}

resource "azurerm_network_interface_nat_rule_association" "fwbbmgmthttpsvm" {
  network_interface_id  = azurerm_network_interface.fwbbifcext.id
  ip_configuration_name = "interface1"
  nat_rule_id           = azurerm_lb_nat_rule.fwbbmgmthttps.id
}

resource "azurerm_network_interface_nat_rule_association" "fwbbmgmtsshvm" {
  network_interface_id  = azurerm_network_interface.fwbbifcext.id
  ip_configuration_name = "interface1"
  nat_rule_id           = azurerm_lb_nat_rule.fwbbmgmtssh.id
}

resource "azurerm_network_interface" "fwbbifcint" {
  name                 = "${var.PREFIX}-FWB-B-Nic2-INT"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fwb_ipaddress_b["2"]
  }
}

resource "azurerm_network_interface_security_group_association" "fwbbifcintnsg" {
  network_interface_id      = azurerm_network_interface.fwbbifcint.id
  network_security_group_id = azurerm_network_security_group.fwbnsg.id
}

resource "azurerm_linux_virtual_machine" "fwbbvm" {
  name                  = "${var.PREFIX}-FWB-B"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.fwbbifcext.id, azurerm_network_interface.fwbbifcint.id]
  size                  = var.fwb_vmsize

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "fortinet"
    offer     = "fortinet_fortiweb-vm_v5"
    sku       = var.FWB_IMAGE_SKU
    version   = var.FWB_VERSION
  }

  plan {
    publisher = "fortinet"
    product   = "fortinet_fortiweb-vm_v5"
    name      = var.FWB_IMAGE_SKU
  }

  os_disk {
    name                 = "${var.PREFIX}-FWB-B-OSDISK"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                  = var.USERNAME
  admin_password                  = var.PASSWORD
  disable_password_authentication = false
  custom_data = base64encode(templatefile("${path.module}/customdata.tpl", {
    fwb_vm_name           = "${var.PREFIX}-FWB-B"
    fwb_license_file      = var.FWB_BYOL_LICENSE_FILE_B
    fwb_license_fortiflex = var.FWB_BYOL_FORTIFLEX_LICENSE_TOKEN_B
	fwb_ha_group_name	  = "${var.PREFIX}"
	ha_loadblancer_name	  =	"${var.PREFIX}-ExternalLoadBalancer"
	fwb_ha_instanceId	  = 2
	fwb_ha_priority		  = 2
	fwb_ha_localip       = var.fwb_ipaddress_b["2"]
	fwb_ha_peerip        = var.fwb_ipaddress_a["2"]		
  }))

  boot_diagnostics {
  }

  tags = var.fortinet_tags
}

resource "azurerm_managed_disk" "fwbbvm-datadisk" {
  name                 = "${var.PREFIX}-FWB-B-DATADISK"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 180
}

resource "azurerm_virtual_machine_data_disk_attachment" "fwbbvm-datadisk-attach" {
  managed_disk_id    = azurerm_managed_disk.fwbbvm-datadisk.id
  virtual_machine_id = azurerm_linux_virtual_machine.fwbbvm.id
  lun                = 0
  caching            = "ReadWrite"
}




data "azurerm_public_ip" "elbpip" {
  name                = azurerm_public_ip.elbpip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
  depends_on          = [azurerm_lb.elb]
}

output "elb_public_ip_address" {
  value = data.azurerm_public_ip.elbpip.ip_address
}
