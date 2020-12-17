# SD-WAN - ExpressRoute

## Introduction
The goal of this webpage is document on how to configure Fortinet Secure SD-WAN between an IPsec tunnel over the internet and Azure Expressroute.
 
Azure ExpressRoute lets you extend your on-premises networks into the Microsoft cloud over a private connection facilitated by a connectivity provider. With ExpressRoute, you can establish connections to Microsoft cloud services, such as Microsoft Azure and Microsoft 365. Connectivity can be from an any-to-any (IP VPN) network, a point-to-point Ethernet network, or a virtual cross-connection through a connectivity provider at a co-location facility. ExpressRoute connections do not go over the public Internet. This allows ExpressRoute connections to offer more reliability, faster speeds, consistent latencies, and higher security than typical connections over the Internet. A good resource to learn more about Expressroute is [this video](https://www.youtube.com/watch?v=oevwZZ1YFS0).


The advantage of combining Fortinet Secure SD-WAN and Expressroute is:
- Application level visibility.
- The ability to control/prioritize critical traffic and applications.
- Dynamic path selection to select the best/preferred path to the cloud.
- Automatically route traffic to next best available link in the event of an outage.

## Flow

## Configuration