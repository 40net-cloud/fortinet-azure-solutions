##############################################################################################################
#
# Terraform configuration
#
##############################################################################################################

output "deployment_summary" {
  value = templatefile(
    "${path.module}/summary.tpl",
    {
      location                   = "${var.LOCATION}",
      fgt_private_ip_address_ext = "${azurerm_network_interface.fgtifcext.private_ip_address}",
      fgt_private_ip_address_int = "${azurerm_network_interface.fgtifcint.private_ip_address}",
      fgt_public_ip_address      = "${data.azurerm_public_ip.fgtpip.ip_address}",
      lnx_a_public_ip_address    = "${data.azurerm_public_ip.lnxapip.ip_address}",
      lnx_a_private_ip_address   = "${azurerm_network_interface.lnxaifc.private_ip_address}",
      lnx_b_public_ip_address    = "${data.azurerm_public_ip.lnxbpip.ip_address}",
      lnx_b_private_ip_address   = "${azurerm_network_interface.lnxbifc.private_ip_address}"
    }
  )
}
