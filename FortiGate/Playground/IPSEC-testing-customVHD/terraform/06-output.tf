##############################################################################################################
#                                                    
# Terraform configuration
#
##############################################################################################################

data "template_file" "summary" {
  template = file("${path.module}/summary.tpl")

  vars {
    location                     = var.LOCATION
    fgt_a_private_ip_address_ext = azurerm_network_interface.fgtaifcext.private_ip_address
    fgt_a_private_ip_address_int = azurerm_network_interface.fgtaifcint.private_ip_address
    fgt_a_public_ip_address      = data.azurerm_public_ip.fgtapip.ip_address
    lnx_a_public_ip_address      = data.azurerm_public_ip.lnxapip.ip_address
    lnx_a_private_ip_address     = azurerm_network_interface.lnxaifc.private_ip_address
    fgt_b_private_ip_address_ext = azurerm_network_interface.fgtbifcext.private_ip_address
    fgt_b_private_ip_address_int = azurerm_network_interface.fgtbifcint.private_ip_address
    fgt_b_public_ip_address      = data.azurerm_public_ip.fgtbpip.ip_address
    lnx_b_public_ip_address      = data.azurerm_public_ip.lnxbpip.ip_address
    lnx_b_private_ip_address     = azurerm_network_interface.lnxbifc.private_ip_address
  }
}

output "deployment_summary" {
  value = data.template_file.summary.rendered
}
