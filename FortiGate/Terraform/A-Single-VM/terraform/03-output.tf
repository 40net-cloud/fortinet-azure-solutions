##############################################################################################################
#
# FortiGate Active/Active Load Balanced pair of standalone FortiGate VMs for resilience and scale
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
    username                   = var.USERNAME
    location                   = var.LOCATION
    fgt_ipaddress              = data.azurerm_public_ip.fgtpip.ip_address
    fgt_private_ip_address_ext = azurerm_network_interface.fgtifcext.private_ip_address
    fgt_private_ip_address_int = azurerm_network_interface.fgtifcint.private_ip_address
  }
}

output "deployment_summary" {
  value = data.template_file.summary.rendered
}

