#######################################################${var.prefix}#######################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

##############################################################################################################
# External Load Balancer
##############################################################################################################
module "elb-a" {
  source                       = "Azure/loadbalancer/azurerm"
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  location                     = azurerm_resource_group.resourcegroup.location
  name                         = "${local.fgt_a_prefix}-elb"
  type                         = "public"
  lb_floating_ip_enabled       = false
  lb_probe_interval            = 5
  lb_probe_unhealthy_threshold = 2
  lb_sku                       = "Standard"
  pip_name                     = "${local.fgt_a_prefix}-elb-pip"
  pip_sku                      = "Standard"

  remote_port = {
    mgmthttps = ["Tcp", "443"]
    mgmtssh   = ["Tcp", "22"]
  }
  lb_port = {
    http       = ["80", "Tcp", "80"]
    ipsec-ike  = ["500", "Udp", "500"]
    ipsec-natt = ["4500", "Udp", "4500"]
  }
  lb_probe = {
    lbprobe = ["Tcp", "8008", ""]
  }
  depends_on = [azurerm_resource_group.resourcegroup]
}

##############################################################################################################
# Internal Load Balancer
##############################################################################################################
module "ilb-a" {
  source                       = "Azure/loadbalancer/azurerm"
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  location                     = azurerm_resource_group.resourcegroup.location
  name                         = "${local.fgt_a_prefix}-ilb"
  type                         = "private"
  lb_floating_ip_enabled       = true
  lb_probe_interval            = 5
  lb_probe_unhealthy_threshold = 2
  lb_sku                       = "Standard"
  frontend_subnet_id           = azurerm_subnet.subnet2a.id

  lb_port = {
    haports = ["0", "All", "0"]
  }
  lb_probe = {
    lbprobe = ["Tcp", "8008", ""]
  }
  depends_on = [azurerm_resource_group.resourcegroup]
}

resource "azurerm_network_interface_backend_address_pool_association" "fgtaifcext2elbbackendpool" {
  network_interface_id    = azurerm_network_interface.fgtaifcext.id
  ip_configuration_name   = "interface1"
  backend_address_pool_id = module.elb-a.azurerm_lb_backend_address_pool_id
}

resource "azurerm_network_interface_backend_address_pool_association" "fgtaifcint2ilbbackendpool" {
  network_interface_id    = azurerm_network_interface.fgtaifcint.id
  ip_configuration_name   = "interface1"
  backend_address_pool_id = module.ilb-a.azurerm_lb_backend_address_pool_id
}

resource "azurerm_network_interface_nat_rule_association" "fgtanatrulemgmthttps" {
  network_interface_id  = azurerm_network_interface.fgtaifcext.id
  ip_configuration_name = azurerm_network_interface.fgtaifcext.ip_configuration[0].name
  nat_rule_id           = module.elb-a.azurerm_lb_nat_rule_ids[0]
}

resource "azurerm_network_interface_nat_rule_association" "fgtanatrulemgmtssh" {
  network_interface_id  = azurerm_network_interface.fgtaifcext.id
  ip_configuration_name = azurerm_network_interface.fgtaifcext.ip_configuration[0].name
  nat_rule_id           = module.elb-a.azurerm_lb_nat_rule_ids[1]
}

resource "azurerm_network_interface" "fgtaifcext" {
  name                           = "${local.fgt_a_prefix}-ifc-ext"
  location                       = azurerm_resource_group.resourcegroup.location
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = var.ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1a.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.fgt_a_private_ip_address_ext
    primary                       = true
  }
}

resource "azurerm_network_interface" "fgtaifcint" {
  name                           = "${local.fgt_a_prefix}-ifc-int"
  location                       = azurerm_resource_group.resourcegroup.location
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = var.ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet2a.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.fgt_a_private_ip_address_int
  }
}

resource "azurerm_linux_virtual_machine" "fgtavm" {
  name                  = local.fgt_a_vm_name
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.fgtaifcext.id, azurerm_network_interface.fgtaifcint.id]
  size                  = var.fgt_a_vmsize

  identity {
    type = "SystemAssigned"
  }

  #  source_image_id = data.azurerm_shared_image_version.fortigate.id
  source_image_reference {
    publisher = "fortinet"
    offer     = "fortinet_fortigate-vm_v5"
    sku       = var.FGT_IMAGE_SKU
    version   = var.FGT_VERSION
  }

  plan {
    publisher = "fortinet"
    product   = "fortinet_fortigate-vm_v5"
    name      = var.FGT_IMAGE_SKU
  }

  os_disk {
    name                 = "${local.fgt_a_vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  custom_data = base64encode(templatefile("${path.module}/../templates/customdata-fgt.tftpl", {
    fgt_vm_name              = "${local.fgt_a_vm_name}"
    fgt_license_file         = var.FGT_BYOL_LICENSE_FILE_A
    fgt_license_fortiflex    = var.FGT_BYOL_FORTIFLEX_LICENSE_TOKEN_A
    fgt_username             = var.username
    fgt_password             = var.password
    fgt_cpumask              = var.fgt_a_cpumask
    fgt_ssh_public_key       = var.FGT_SSH_PUBLIC_KEY_FILE
    fgt_external_network     = var.subnet_fgt_external["a"]
    fgt_external_ipaddress   = local.fgt_a_private_ip_address_ext
    fgt_external_ipcount     = "${local.fgt_external_ipcount}"
    fgt_external_mask        = "${cidrnetmask(var.subnet_fgt_external["a"])}"
    fgt_external_gateway     = "${cidrhost(var.subnet_fgt_external["a"], 1)}"
    fgt_internal_ipaddress   = local.fgt_a_private_ip_address_int
    fgt_internal_mask        = "${cidrnetmask(var.subnet_fgt_internal["a"])}"
    fgt_internal_gateway     = "${cidrhost(var.subnet_fgt_internal["a"], 1)}"
    fgt_protected_network    = var.subnet_protected["a"]
    vnet_network             = var.vnet
    remote_protected_network = var.subnet_protected["b"]
    remote_public_ip         = module.elb-b.azurerm_public_ip_address[0]
    ipsec_psk                = random_string.ipsec_psk.result
  }))

  boot_diagnostics {
  }

  tags = var.TAGS

  depends_on = [ azurerm_network_interface_nat_rule_association.fgtanatrulemgmthttps, azurerm_network_interface_nat_rule_association.fgtanatrulemgmtssh, azurerm_network_interface_backend_address_pool_association.fgtaifcext2elbbackendpool, azurerm_network_interface_backend_address_pool_association.fgtaifcint2ilbbackendpool ]
  lifecycle {
    ignore_changes = [custom_data]
  }
}

output "fgt_a_private_ip_address" {
  value = azurerm_network_interface.fgtaifcext.private_ip_address
}

output "fgt_a_public_ip_address" {
  value = module.elb-a.azurerm_public_ip_address
}
