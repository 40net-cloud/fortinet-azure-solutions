##############################################################################################################
#
# Fortiweb a standalone Fortiweb VM
# Terraform deployment template for Microsoft Azure
#
# The Fortiweb VMs are reachable via the public IP address.
# Management GUI HTTPS on port 8443.
#
# BEWARE: The state files contain sensitive data like passwords and others. After the demo clean up your
#         clouddrive directory.
#
# Deployment location: ${location}
# Username: ${username}
#
# Management Fortiweb: https://${fwb_ipaddress}:8443/
#
##############################################################################################################

fwb_ipaddress = ${fwb_ipaddress}
fwb_private_ip_address_ext = ${fwb_private_ip_address_ext}
fwb_private_ip_address_int = ${fwb_private_ip_address_int}

##############################################################################################################