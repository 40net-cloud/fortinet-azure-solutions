##############################################################################################################
#
# IPSEC Tunnels
# Terraform deployment template for Microsoft Azure
#
# The LNX VM is reachable via the public or private IP address
# Management SSH on port 22
#
# BEWARE: The state files contain sensitive data like passwords and others. After the demo clean up your
#         clouddrive directory
#
# Deployment region: ${region}
# Username: ${username}
#
# Management FortiGate: https://${fgt_public_fqdn}/ or https://${fgt_public_ip_address}/
# Management LNX: ssh://${lnx_public_fqdn}
#
##############################################################################################################

lnx_public_ip_address = ${lnx_public_ip_address}
lnx_private_ip_address = ${lnx_private_ip_address}
lnx_public_fqdn = ${lnx_public_fqdn}
lnx_instance_id = ${lnx_instance_id}

lnx2_public_ip_address = ${lnx2_public_ip_address}
lnx2_private_ip_address = ${lnx2_private_ip_address}
lnx2_public_fqdn = ${lnx2_public_fqdn}
lnx2_instance_id = ${lnx2_instance_id}

fgt_public_ip_address = ${fgt_public_ip_address}
fgt_private_ip_address_mgmt = ${fgt_private_ip_address_mgmt}
fgt_private_ip_address_ext = ${fgt_private_ip_address_ext}
fgt_private_ip_address_int = ${fgt_private_ip_address_int}
fgt_instance_id = ${fgt_instance_id}


##############################################################################################################
