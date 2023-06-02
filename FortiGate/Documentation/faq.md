# FAQ

Q: Some templates use a basic sku public IP address and some templates use a standard public IP address. Is it possible to convert from a basic to a standard SKU public IP address?

A: Yes, this is now possible according to Microsoft. The IP can't be associated with any resource. More information can be found [here](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-public-ip-address-upgrade)

Q: How do I setup an IPSEC VPN tunnel from my on-premises firewall to the FortiGate VM in Microsoft Azure?

A: A dedicated page including troubleshooting steps can be found [here](faq-ipsec-connectivity.md)

Q: We can't deploy directly from the Azure Marketplace or received a custom build VHD image from Fortinet. Can we still use these templates?

A: Yes, the templates have an option to receive a Azure Compute Gallery resource ID to location where you upload your specific version. More information can be found [here](faq-upload-vhd.md).