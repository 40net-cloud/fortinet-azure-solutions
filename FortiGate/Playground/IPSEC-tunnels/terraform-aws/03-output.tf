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

output "template_file" {
  value = templatefile("${path.module}/../templates/summary.tftpl", {
    region                      = var.REGION
    username                    = var.username
    lnx_public_ip_address       = aws_eip.lnxpip.public_ip
    lnx_public_fqdn             = aws_eip.lnxpip.public_dns
    lnx_private_ip_address      = data.aws_network_interface.lnxnicmgmt.private_ip
    lnx_instance_id             = aws_instance.lnxvm.id
    lnx2_public_ip_address      = aws_eip.lnx2pip.public_ip
    lnx2_public_fqdn            = aws_eip.lnx2pip.public_dns
    lnx2_private_ip_address     = data.aws_network_interface.lnx2nicmgmt.private_ip
    lnx2_instance_id            = aws_instance.lnx2vm.id
    fgt_public_ip_address       = aws_eip.fgtpip.public_ip
    fgt_public_fqdn             = aws_eip.fgtpip.public_ip
    fgt_private_ip_address_mgmt = data.aws_network_interface.fgtnicmgmt.private_ip
    fgt_private_ip_address_ext  = data.aws_network_interface.fgtnicext.private_ip
    fgt_private_ip_address_int  = data.aws_network_interface.fgtnicint.private_ip
    fgt_instance_id             = aws_instance.fgtvm.id
  })
}
