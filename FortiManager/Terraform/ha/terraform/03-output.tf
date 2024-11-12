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
    location               = var.location
    fmg_username           = var.username
    fmg_a_public_ip_address  = data.azurerm_public_ip.fmgapip.ip_address
    fmg_a_private_ip_address = azurerm_network_interface.fmgaifc.private_ip_address
    fmg_b_public_ip_address  = data.azurerm_public_ip.fmgbpip.ip_address
    fmg_b_private_ip_address = azurerm_network_interface.fmgbifc.private_ip_address
  })
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "subnet_id" {
  value = azurerm_subnet.subnet1.id
}
