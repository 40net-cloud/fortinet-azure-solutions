##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

resource "azurerm_public_ip" "fgtbpip" {
  name                = "${local.fgt_b_prefix}-PIP"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "b-fgt-pip")
  sku                 = "Standard"
}

resource "azurerm_lb" "fgtbilb" {
  name                = "${local.fgt_b_prefix}-InternalLoadBalancer"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "${local.fgt_b_prefix}-ILB-PIP"
    subnet_id                     = azurerm_subnet.subnet2b.id
    private_ip_address            = cidrhost(var.subnet_fgt_internal["b"], -2)
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_lb_backend_address_pool" "fgtbilbbackend" {
  loadbalancer_id = azurerm_lb.fgtbilb.id
  name            = "BackEndPool"
}

resource "azurerm_lb_probe" "fgtbilbprobe" {
  loadbalancer_id     = azurerm_lb.fgtbilb.id
  name                = "lbprobe"
  port                = 8008
  interval_in_seconds = 5
  number_of_probes    = 2
  protocol            = "Tcp"
}

resource "azurerm_lb_rule" "fgtblb_haports_rule" {
  loadbalancer_id                = azurerm_lb.fgtbilb.id
  name                           = "lb_haports_rule"
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "${local.fgt_b_prefix}-ILB-PIP"
  probe_id                       = azurerm_lb_probe.fgtbilbprobe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.fgtbilbbackend.id]
}

resource "azurerm_network_interface" "fgtbifcext" {
  name                          = "${local.fgt_b_prefix}-IFC-EXT"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1b.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnet_fgt_external["b"], "4")
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.fgtbpip.id
  }
  dynamic "ip_configuration" {
    for_each = range(2, "${local.fgt_external_ipcount + 1}")
    content {
      name                          = "interface${ip_configuration.value}"
      subnet_id                     = azurerm_subnet.subnet1b.id
      private_ip_address_allocation = "Static"
      private_ip_address            = cidrhost(var.subnet_fgt_external["b"], "${ip_configuration.value + 3}")
      primary                       = false
    }
  }
}

resource "azurerm_network_interface" "fgtbifcint" {
  name                          = "${local.fgt_b_prefix}-IFC-INT"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet2b.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnet_fgt_internal["b"], 4)
  }
}

resource "azurerm_linux_virtual_machine" "fgtbvm" {
  name                  = local.fgt_b_vm_name
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.fgtbifcext.id, azurerm_network_interface.fgtbifcint.id]
  size                  = var.fgt_vmsize

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
    fgt_csp                = "Azure"
    fgt_vm_name            = "${local.fgt_b_vm_name}"
    fgt_license_file       = var.FGT_BYOL_LICENSE_FILE_B
    fgt_license_fortiflex  = var.FGT_BYOL_FORTIFLEX_LICENSE_TOKEN_B
    fgt_username           = var.USERNAME
    fgt_password           = var.PASSWORD
    fgt_ssh_public_key     = var.FGT_SSH_PUBLIC_KEY_FILE
    fgt_external_network   = var.subnet_fgt_external["b"]
    fgt_external_ipaddress = "${cidrhost(var.subnet_fgt_external["b"], 4)}"
    fgt_external_ipcount   = "${local.fgt_external_ipcount}"
    fgt_external_mask      = "${cidrnetmask(var.subnet_fgt_external["b"])}"
    fgt_external_gateway   = "${cidrhost(var.subnet_fgt_external["b"], 1)}"
    fgt_internal_ipaddress = "${cidrhost(var.subnet_fgt_internal["b"], 4)}"
    fgt_internal_mask      = "${cidrnetmask(var.subnet_fgt_internal["b"])}"
    fgt_internal_gateway   = "${cidrhost(var.subnet_fgt_internal["b"], 1)}"
    vnet_network           = var.vnet
    remote_protected_net   = var.subnet_fgt_internal["a"]
    remote_public_ip       = data.azurerm_public_ip.fgtapip.ip_address
    ipsec_psk              = random_string.ipsec_psk.result
  }))

  boot_diagnostics {
  }

  tags = var.TAGS

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
