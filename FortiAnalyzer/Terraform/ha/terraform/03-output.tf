##############################################################################################################
#
# FortiAnalyzer VM
# Active / Passive deployment
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
#
# Output summary of deployment
#
##############################################################################################################

output "deployment_summary" {
  value = templatefile("${path.module}/summary.tftpl", {
    location             = var.LOCATION
    faz_username         = var.USERNAME
    faz_public_ip        = data.azurerm_public_ip.fazpip.ip_address
    faz_a_mgmt_public_ip = data.azurerm_public_ip.fazpip2.ip_address
    faz_b_mgmt_public_ip = data.azurerm_public_ip.fazpip3.ip_address
  })
}
