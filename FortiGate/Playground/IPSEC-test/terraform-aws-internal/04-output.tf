##############################################################################################################
#
# FortiTester VM
# Terraform deployment template for AWS
#
##############################################################################################################
#
# Output summary of deployment
#
##############################################################################################################

output "deployment_summary" {
  value = templatefile(
    "${path.module}/../templates/summary.tftpl",
    {
      location                     = var.REGION
      fgt_a_private_ip_address_ext = data.aws_network_interface.fgtaifcext.private_ip
      fgt_a_private_ip_address_int = data.aws_network_interface.fgtaifcint.private_ip
      fgt_a_public_ip_address      = aws_eip.fgtapip.public_ip
      lnx_a_public_ip_address      = "${join(",", aws_eip.lnxapip.*.public_ip)}"
      lnx_a_private_ip_address     = "${join(",", aws_network_interface.lnxaifc.*.private_ip)}"
      fgt_b_private_ip_address_ext = data.aws_network_interface.fgtbifcext.private_ip
      fgt_b_private_ip_address_int = data.aws_network_interface.fgtaifcint.private_ip
      fgt_b_public_ip_address      = aws_eip.fgtbpip.public_ip 
      lnx_b_public_ip_address      = "${join(",", aws_eip.lnxbpip.*.public_ip)}"
      lnx_b_private_ip_address     = "${join(",", aws_network_interface.lnxbifc.*.private_ip)}"
    }
  )
}
