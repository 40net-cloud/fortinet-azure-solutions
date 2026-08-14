# Azure Virtual WAN static routing

## Introduction

The script below deploys Azure Virtual WAN, FortiGate and required static routing for the different traffic flows.

- [Fortinet Secure SD-WAN Enhances Azure Virtual WAN Integrations](https://www.fortinet.com/blog/business-and-technology/fortinet-secure-sd-wan-enhances-azure-virtual-wan-integrations)
- Microsoft docs:
  - [Routing traffic through NVAs](https://learn.microsoft.com/en-us/azure/virtual-wan/indirect-spoke-architecture)
  - [How to configure virtual hub routing](https://learn.microsoft.com/en-us/azure/virtual-wan/about-virtual-hub-routing)

## Azure CLI

`cd ~/clouddrive/ && wget -qO- https://github.com/40net-cloud/fortinet-azure-solutions/archive/main.tar.gz | tar zxf - && cd ~/clouddrive/fortinet-azure-solutions-main/FortiGate/AzureVirtualWAN/routing/ && ./deploy.sh`