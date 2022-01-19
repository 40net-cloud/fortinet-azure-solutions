# Deployment templates for FortiGate Next-Generation Firewall in Microsoft Azure

## Use cases

The FortiGate can be used in different scenario's to protect assets deployed in Microsoft Azure Virtual Networks.

- Secure hybrid cloud
- Cloud security services hub
- Logical (intent-based) segmentation
- Secure remote access

Click [here](https://www.fortinet.com/products/public-cloud-security/azure#usecases) for a general overview of the different public cloud use cases.

## Deployment options and architectures

When designing a reliable architecture in Microsoft Azure it is important to take resiliency and High Availability into account. Microsoft has the [Microsoft Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/resiliency/overview) available.

Running the FortiGate Next-Generation Firewall inside of Microsoft Azure can offer different levels of reliability based on the different building blocks and architectures. Over the years, new functionality has been released in Microsoft Azure for specific deployments.

For each architecture/building block, there is information in the table whether it is supported (yes) by each architecture or not (no). Take into account that each architecture has requirements and limitations that are listed on their respective page.

| Use cases/ Architectures              | [Single FGT](https://github.com/40net-cloud/fortinet-azure-solutions/tree/main/FortiGate/A-Single-VM) | [Active Passive SDN ](https://github.com/40net-cloud/fortinet-azure-solutions/tree/main/FortiGate/Active-Passive-SDN)| [Active Passive ELB/ILB](https://github.com/40net-cloud/fortinet-azure-solutions/tree/main/FortiGate/Active-Passive-ELB-ILB) | [Active Active ELB/ILB](https://github.com/40net-cloud/fortinet-azure-solutions/tree/main/FortiGate/Active-Active-ELB-ILB) | [Virtual WAN](https://github.com/40net-cloud/fortinet-azure-solutions/tree/main/FortiGate/AzureVirtualWAN) | [Active Passive Azure Route Server](https://github.com/40net-cloud/fortinet-azure-solutions/tree/main/FortiGate/AzureRouteServer) | [Auto-Scale Cluster](https://github.com/40net-cloud/fortinet-azure-solutions/tree/main/FortiGate/Autoscale) | [Gateway Load Balancer](https://github.com/fortinetsolutions/Azure-Templates/tree/master/GWLB) |
|---------------------------------------|------------|--------------------|------------------------|-----------------------|-------------|-----------------------------------|--------------------|-----------------------|
| North-South (ingress) filtering       |     YES    |         YES        |           YES          |          YES        |     YES     |                YES                |         YES       |          YES          |
| East-West filtering                   |     YES    |         YES        |           YES          |          YES          |     YES     |                YES                |         YES        |           NO          |
| South-North (egress) filtering        |     YES    |         YES        |           YES          |          YES          |     YES     |                YES                |         YES        |          YES          |
| SDWAN                                 |     YES    |         YES        |           YES          |          YES          |     YES     |                YES                |         YES        |           NO          |
| Site to Site VPN                      |     YES    |         YES        |           YES          |          YES          |     YES     |                YES                |         NO        |           NO          |
| Client to Site VPN                    |     YES    |         YES        |           YES          |          YES          |     YES     |                YES                |         NO        |           NO          |
| Express Route Filtering               |     YES    |         YES        |           YES          |          YES          |     YES     |                YES                |         YES        |           NO          |
| Scalability - vertical                |     YES    |         YES        |           YES          |          YES          |     YES     |                YES                |         YES        |          YES          |
| Scalability - horizontal              |     NO     |         NO         |           NO           |          YES          |     YES     |                 NO                |         YES        |          YES          |
| Protect resources in multiple regions |     YES    |         YES        |           YES          |          YES          |     YES      |                YES                 |         YES        |          YES          |

### SLA

Microsoft offers different [SLAs](https://azure.microsoft.com/en-au/support/legal/sla/virtual-machines/) on Microsoft Azure based on the deployment used.
- [Availability Zone](AvailabilityZones/) (different datacenter in the same region): 99,99%
- Availability Set (different rack and power): 99,95%
- Single VM with Premium SSD: 99.9%

### Building blocks

- [__**A Single VM**__](A-Single-VM/): This single FortiGate VM will process all the traffic and as such become a single point of failure during operations as well as upgrades. This block can also be used in an architecture with multiple regions where a FortiGate is deployed in each region. This setup provides an SLA of 99.9% when using a Premium SSD disk.

More information can be found [here](A-Single-VM/)

<p align="center">
  <a href="A-Single-VM/"><img width="500px" src="A-Single-VM/images/fgt-single-vm.png" alt="FortiGate building blocks"></a>
</p

- [__**Active/Passive with external and internal Azure Load Balancer**__](Active-Passive-ELB-ILB): This design will deploy 2 FortiGate VMs in Active/Passive connected using the unicast FGCP HA protocol. The failover of the traffic in this setup is handled by the Microsoft Azure Load Balancer using a health probe towards the FortiGate VMs. THe failover times are based on the health probe of the Microsoft Azure Load Balancer (2 failed attempts per 5 seconds with a max of 15 seconds). The public IPs are configured on the Microsoft Azure Load Balancer and provide ingress and egress flows with inspection from the FortiGate. Microsoft provides some guidance on this architecture [here](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-ha-ports-overview).

More information can be found [here](Active-Passive-ELB-ILB/)

<p align="center">
  <a href="Active-Passive-ELB-ILB/"><img width="500px" src="Active-Passive-ELB-ILB/images/fgt-ap.png" alt="FortiGate building blocks"></a>
</p

- [__**Active/Passive with Fabric Connector Failover**__](Active-Passive-SDN/): This design will deploy 2 FortiGate VMs in Active/Passive connected using unicast FGCP HA protocol. This protocol will synchronize the configuration. On failover the passive FortiGate takes control and will issue api calls to Microsoft Azure to shift the Public IP and update the internal User Defined Routing (UDR) to itself. Shifting the public IP and gateway IPs of the routes will take some time to complete on the Microsoft Azure platform. Microsoft provides a general architecture [here](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/dmz/nva-ha#pip-udr-nvas-without-snat), in the FortiGate case the API calls logic is built in instead of requiring additional outside logic like Azure Functions or ZooKeeper nodes. Due to the faster failover times and easier management the Active/Passive with the Azure Load Balancer is the preferred building block compared to this one.

More information can be found [here](Active-Passive-SDN/)

<p align="center">
  <a href="Active-Passive-SDN/"><img width="500px" src="Active-Passive-SDN/images/fgt-ap-sdn.png" alt="FortiGate building blocks"></a>
</p

- [__**Active/Active with external and internal Azure Load Balancer**__](Active-Active-ELB-ILB): This design will deploy 2 FortiGate VMs in Active/Active as 2 independent systems. The failover of the traffic in this setup is handled by the Microsoft Azure Load Balancer using a health probe towards the FortiGate VMs. The public IPs are configured on the Microsoft Azure Load Balancer and provide ingress and egress flows with inspection from the FortiGate. To sync the configuration of this setup a FortiManager or local replication can be used. Microsoft provides some guidance on this architecture [here](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-ha-ports-overview).

More information can be found [here](Active-Active-ELB-ILB/)

<p align="center">
  <a href="Active-Active-ELB-ILB/"><img width="500px" src="Active-Active-ELB-ILB/images/fgt-aa.png" alt="FortiGate building blocks"></a>
</p

*By default these building blocks are using Availability Sets. The Availability Zone templates are also available [here](AvailabilityZones/) for a higher SLA.*

## Selecting your architecture in Microsoft Azure

The FortiGate Next-Generation Firewall can be deployed in Microsoft Azure in different architectures each with their specific properties that can be an advantage or disadvantage in your environment.

- __**Single VNET**__: All the building block above are ready to deploy in a new or existing VNET. Select your block above to get started.
- [__**Cloud Security Services Hub (VNET peering)**__](VNET-Peering/): With VNET peering it is possible to have different islands deploying different services managed by diferent internal and/or external teams but to maintain a single point of control going to on-premise, other clouds or public internet. By connecting the different VNETs in a Hub-Spoke setup the Hub can control all traffic. Get started [here](VNET-Peering/).
- [__**Azure Application Gateway**__](AzureApplicationGateway/): How to integrate the FortiGate with the web traffic load balancer found in Microsoft Azure.
- [__**Autoscaling**__](Autoscale/): For application that are fluid in the amount of resources the FortiGate can also be deployed with a autoscaling architecture. This architecture is documented [here](https://docs.fortinet.com/vm/azure/fortigate/7.0/azure-administration-guide/7.0.0/161167/deploying-auto-scaling-on-azure) or a quickstart script is available [here](Autoscale/).
- [__**Azure Virtual WAN**__](AzureVirtualWAN/): Azure Virtual WAN offers a central connectivity point between regions, on-premise. Fortinet offers [automation](https://www.fortinet.com/content/dam/fortinet/assets/deployment-guides/dg-fortigate-azure-wan-integration.pdf) as well as [different deployment modes](AzureVirtualWAN/).
- [__**SD-WAN Connectivity**__](SD-WAN/): Connecting the on-premise environment with your Microsoft Azure environment.

Coming soon...

- __**Multi region - Azure Traffic Manager**__

## Support
Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/40net-cloud/fortinet-azure-solutions/issues) tab of this GitHub project.

## License
[License](LICENSE) © Fortinet Technologies. All rights reserved.
