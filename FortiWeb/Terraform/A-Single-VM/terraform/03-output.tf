##############################################################################################################
#
# FortiWeb a standalone FortiWeb VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
#
# Output summary of deployment
#
##############################################################################################################

output "deployment_summary" {
  value = templatefile("${path.module}/summary.tpl", {
    username                   = var.username
    location                   = var.location
    fwb_ipaddress              = data.azurerm_public_ip.fwbpip.ip_address
    fwb_private_ip_address_ext = azurerm_network_interface.fwbifcext.private_ip_address
    fwb_private_ip_address_int = azurerm_network_interface.fwbifcint.private_ip_address
  })
}
