##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

resource "azurerm_public_ip" "fgtbpip" {
  name                = "${local.fgt_b_prefix}-pip"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "b-fgt-pip")
  sku                 = "Standard"
}

##############################################################################################################
# Internal Load Balancer
##############################################################################################################
module "ilb-b" {
  source                       = "Azure/loadbalancer/azurerm"
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  location                     = azurerm_resource_group.resourcegroup.location
  name                         = "${local.fgt_b_prefix}-ilb"
  type                         = "private"
  lb_floating_ip_enabled       = true
  lb_probe_interval            = 5
  lb_probe_unhealthy_threshold = 2
  lb_sku                       = "Standard"
  frontend_subnet_id           = azurerm_subnet.subnet2b.id

  lb_port = {
    haports = ["0", "All", "0"]
  }
  lb_probe = {
    lbprobe = ["Tcp", "8008", ""]
  }
  depends_on = [azurerm_resource_group.resourcegroup]
}

resource "azurerm_network_interface_backend_address_pool_association" "fgtbifcint2ilbbackendpool" {
  network_interface_id    = azurerm_network_interface.fgtbifcint.id
  ip_configuration_name   = "interface1"
  backend_address_pool_id = module.ilb-b.azurerm_lb_backend_address_pool_id
}

resource "azurerm_network_interface" "fgtbifcext" {
  name                           = "${local.fgt_b_prefix}-ifc-ext"
  location                       = azurerm_resource_group.resourcegroup.location
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = var.ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1b.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.fgt_b_private_ip_address_ext
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.fgtbpip.id
  }
}

resource "azurerm_network_interface" "fgtbifcint" {
  name                           = "${local.fgt_b_prefix}-ifc-int"
  location                       = azurerm_resource_group.resourcegroup.location
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = var.ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet2b.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.fgt_b_private_ip_address_int
  }
}

resource "azurerm_linux_virtual_machine" "fgtbvm" {
  name                  = local.fgt_b_vm_name
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.fgtbifcext.id, azurerm_network_interface.fgtbifcint.id]
  size                  = var.fgt_b_vmsize

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
    name                 = "${local.fgt_b_vm_name}-OSDISK"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  admin_username                  = var.USERNAME
  admin_password                  = var.PASSWORD
  disable_password_authentication = false
  custom_data = base64encode(templatefile("${path.module}/../templates/customdata-fgt.tftpl", {
    fgt_csp                  = "Azure"
    fgt_vm_name              = "${local.fgt_b_vm_name}"
    fgt_license_file         = var.FGT_BYOL_LICENSE_FILE_B
    fgt_license_fortiflex    = var.FGT_BYOL_FORTIFLEX_LICENSE_TOKEN_B
    fgt_username             = var.USERNAME
    fgt_password             = var.PASSWORD
    fgt_cpumask              = var.fgt_b_cpumask
    fgt_ssh_public_key       = var.FGT_SSH_PUBLIC_KEY_FILE
    fgt_external_network     = var.subnet_fgt_external["b"]
    fgt_external_ipaddress   = local.fgt_b_private_ip_address_ext
    fgt_external_ipcount     = "${local.fgt_external_ipcount}"
    fgt_external_mask        = "${cidrnetmask(var.subnet_fgt_external["b"])}"
    fgt_external_gateway     = "${cidrhost(var.subnet_fgt_external["b"], 1)}"
    fgt_internal_ipaddress   = local.fgt_b_private_ip_address_int
    fgt_internal_mask        = "${cidrnetmask(var.subnet_fgt_internal["b"])}"
    fgt_internal_gateway     = "${cidrhost(var.subnet_fgt_internal["b"], 1)}"
    fgt_protected_network    = var.subnet_protected["b"]
    vnet_network             = var.vnet
    remote_protected_network = var.subnet_protected["a"]
    remote_public_ip         = local.fgt_a_private_ip_address_ext
    ipsec_psk                = random_string.ipsec_psk.result
  }))

  boot_diagnostics {
  }

  tags = var.TAGS

  depends_on = [ azurerm_network_interface_backend_address_pool_association.fgtbifcint2ilbbackendpool ]

  lifecycle {
    ignore_changes = [custom_data]
  }
}

output "fgt_b_private_ip_address" {
  value = azurerm_network_interface.fgtbifcext.private_ip_address
}

data "azurerm_public_ip" "fgtbpip" {
  name                = azurerm_public_ip.fgtbpip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
  #  depends_on          = [azurerm_linux_virtual_machine.fgtbvm]
}

output "fgt_b_public_ip_address" {
  value = data.azurerm_public_ip.fgtbpip.ip_address
}
