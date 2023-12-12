##############################################################################################################
#
# FortiWeb HA-Active-Active
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
#
# Output summary of deployment
#
##############################################################################################################

output "deployment_summary" {
  value = templatefile("${path.module}/summary.tpl", {
    username                   = var.USERNAME
    location                   = var.LOCATION
	elb_ipaddress                = data.azurerm_public_ip.elbpip.ip_address
    fwb_a_private_ip_address_ext = azurerm_network_interface.fwbaifcext.private_ip_address
    fwb_a_private_ip_address_int = azurerm_network_interface.fwbaifcint.private_ip_address
	fwb_b_private_ip_address_ext = azurerm_network_interface.fwbbifcext.private_ip_address
    fwb_b_private_ip_address_int = azurerm_network_interface.fwbbifcint.private_ip_address
  })
}
