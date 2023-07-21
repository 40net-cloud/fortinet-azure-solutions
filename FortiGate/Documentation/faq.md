# FAQ

## Some templates use a basic sku public IP address and some templates use a standard public IP address. Is it possible to convert from a basic to a standard SKU public IP address?

Yes, this is now possible according to Microsoft. The IP can't be associated with any resource. More information can be found [here](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-public-ip-address-upgrade)

On September 30, 2025, Basic SKU public IPs will be retired. For more information, see the [official announcement](https://azure.microsoft.com/updates/upgrade-to-standard-sku-public-ip-addresses-in-azure-by-30-september-2025-basic-sku-will-be-retired/)

## How do I setup an IPSEC VPN tunnel from my on-premises firewall to the FortiGate VM in Microsoft Azure?

A dedicated page including troubleshooting steps can be found [here](faq-ipsec-connectivity.md)

## We can't deploy directly from the Azure Marketplace or received a custom build VHD image from Fortinet. Can we still use these templates?

Yes, the templates have an option to receive a Azure Compute Gallery resource ID to location where you upload your specific version. More information can be found [here](faq-upload-vhd.md).

## What is Accelerated Networking?

Accelerated Networking enables SR-IOV (Single Root I/O Virtualization) 

https://learn.microsoft.com/en-us/azure/virtual-network/accelerated-networking-overview

## How can I figure our what license I'm using on the FortiGate VM (PAYG vs BYOL)

A dedicated page be found [here](faq-pay-as-you-go.md)
