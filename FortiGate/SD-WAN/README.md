# SD-WAN

## Introduction

Software-defined wide-area network (SD-WAN) solutions transform an organization’s capabilities by leveraging the corporate wide-area network (WAN) as well as multi-cloud connectivity to deliver high-speed application performance at the edge of branch sites. One of the benefits of SD-WAN is that it provides a dynamic path selection among connectivity options: MPLS, 4G/5G and/or broadband, ensuring organizations can quickly and easily access business-critical cloud applications.

To provide connectivity to Microsoft Azure there are multiple scenarios available. They range from a very easy and IPSEC tunnel up to SDWAN scenarios integrating multiple connectivity options.

- [Scenario 1](https://docs.fortinet.com/document/fortigate/latest/administration-guide/255100/ipsec-vpn-to-azure-with-virtual-network-gateway): VPN Tunnel using IPSEC from the FortiGate edge devices to the Microsoft VPN gateway
- [Scenario 2](docs/config-sdwan-ipsec.md): VPN Tunnel using IPSEC from the FortiGate edge devices to a FortiGate deployed in Microsoft Azure
- [Scenario 3](docs/config-sdwan-expressroute.md): Connecting Azure ExpressRoute and VPN tunnel from the FortiGate edge device to Microsoft Azure
- [Scenario 4](docs/config-sdwan-encrypted-expressroute.md): Encrypting the communication over Azure ExpressRoute using FortiGate at the edge and in Microsoft Azure
- [Scenario 5](../AzureVirtualWAN): How to integrate with Microsoft Virtual WAN connectivity solution
