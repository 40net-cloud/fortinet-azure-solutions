##############################################################################################################
#
# FortiManager - a standalone FortiManager VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
#
# Output summary of deployment
#
##############################################################################################################

output "deployment_summary" {
  value = templatefile("${path.module}/summary.tpl", {
    location               = var.LOCATION
    fmg_username           = var.USERNAME
    fmg_public_ip_address  = data.azurerm_public_ip.fmgpip.ip_address
    fmg_private_ip_address = azurerm_network_interface.fmgifc.private_ip_address
  })
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "subnet_id" {
  value = azurerm_subnet.subnet1.id
}
