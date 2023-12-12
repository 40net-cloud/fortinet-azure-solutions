##############################################################################################################
#
# FortiWeb HA-Active-Active
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
# Management Fortiweb A: https://${elb_ipaddress}:40030/
# Management Fortiweb B: https://${elb_ipaddress}:40031/
#
##############################################################################################################

elb_ipaddress = ${elb_ipaddress}
fwb_a_private_ip_address_ext = ${fwb_a_private_ip_address_ext}
fwb_a_private_ip_address_int = ${fwb_a_private_ip_address_int}
fwb_b_private_ip_address_ext = ${fwb_b_private_ip_address_ext}
fwb_b_private_ip_address_int = ${fwb_b_private_ip_address_int}

##############################################################################################################