##############################################################################################################
#
# FortiGate VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
#
# Output summary of deployment
#
##############################################################################################################

output "template_file" {
  value = templatefile("${path.module}/../templates/summary.tftpl", {
    region                      = var.location
    username                    = var.username
    lnx_public_ip_address       = data.azurerm_public_ip.lnxpip.ip_address
    lnx_public_fqdn             = data.azurerm_public_ip.lnxpip.fqdn
    lnx_private_ip_address      = azurerm_network_interface.lnxifc1.private_ip_address
    lnx_instance_id             = ""
    lnx2_public_ip_address       = data.azurerm_public_ip.lnx2pip.ip_address
    lnx2_public_fqdn             = data.azurerm_public_ip.lnx2pip.fqdn
    lnx2_private_ip_address      = azurerm_network_interface.lnx2ifc1.private_ip_address
    lnx2_instance_id             = ""
    fgt_public_ip_address       = data.azurerm_public_ip.fgtpip.ip_address
    fgt_public_fqdn             = data.azurerm_public_ip.fgtpip.fqdn
    fgt_private_ip_address_mgmt = azurerm_network_interface.fgtifcmgmt.private_ip_address
    fgt_private_ip_address_ext  = azurerm_network_interface.fgtifcext.private_ip_address
    fgt_private_ip_address_int  = azurerm_network_interface.fgtifcint.private_ip_address
    fgt_instance_id             = ""
  })
}
