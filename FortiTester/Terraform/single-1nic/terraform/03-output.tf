##############################################################################################################
#
# FortiTester VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
#
# Output summary of deployment
#
##############################################################################################################

data "template_file" "summary" {
  template = file("${path.module}/summary.tpl")

  vars = {
    location                    = var.LOCATION
    username                    = var.USERNAME
    fts_public_ip_address       = data.azurerm_public_ip.ftspip.ip_address
    fts_public_fqdn             = data.azurerm_public_ip.ftspip.fqdn
    fts_private_ip_address      = azurerm_network_interface.ftsifc1.private_ip_address
    fgt_public_ip_address       = data.azurerm_public_ip.fgtpip.ip_address
    fgt_public_fqdn             = data.azurerm_public_ip.fgtpip.fqdn
    fgt_private_ip_address_mgmt = azurerm_network_interface.fgtifcmgmt.private_ip_address
    fgt_private_ip_address_ext  = azurerm_network_interface.fgtifcext.private_ip_address
    fgt_private_ip_address_int  = azurerm_network_interface.fgtifcint.private_ip_address
  }
}

output "deployment_summary" {
  value = data.template_file.summary.rendered
}
