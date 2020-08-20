# Deployment templates for FortiGate Next-Generation Firewall in Microsoft Azure

## Use cases

The FortiGate can be used in different scenario's to protect assets deployed in Microsoft Azure Virtual Networks.

- Secure hybrid cloud
- Cloud security services hub
- Logical (intent-based) segmentation
- Secure remote access

Click [here](https://www.fortinet.com/products/public-cloud-security/azure#usecases) for a general overview of the different public cloud use cases.

## Resiliency and High Availability

When designing a reliable architecture in Microsoft Azure it is important to take resiliency and High Availability into account. Microsoft has the [Microsoft Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/resiliency/overview) available.

Running the FortiGate Next-Generation Firewall inside of Microsoft Azure can offer different levels of reliability based these building blocks

Microsoft offers different [SLAs](https://azure.microsoft.com/en-au/support/legal/sla/virtual-machines/) on Microsoft Azure based on the deployment used.
- Availability Zone (different datacenter in the same region): 99,99%
- Availability Set (different rack and power): 99,95%
- Single VM with Premium SSD: 99.9%

### Building blocks

- A Single VM: This single FortiGate VM will process all the traffic and as such become a single point of failure during operations as well as upgrades. This block can also be used in an architecture with multiple regions where a FortiGate is deployed in each region. This setup provides an SLA of 99.9% when using a Premium SSD disk.

More information can be found [here](A-Single-VM/)

- Active/Passive with Fabric Connector Failover: This design will deploy 2 FortiGate VMs in Active/Passive connected using unicast FGCP HA protocol. This protocol will synchronize the configuration. On failover the passive FortiGate takes control and will issue api calls to Microsoft Azure to shift the Public IP and update the internal User Defined Routing (UDR) to itself. Shifting the public IP and gateway IPs of the routes will take some time to complete on the Microsoft Azure platform. Microsoft provides a general architecture [here](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/dmz/nva-ha#pip-udr-nvas-without-snat), in the FortiGate case the API calls logic is built in instead of requiring additional outside logic like Azure Functions or ZooKeeper nodes.

More information can be found [here](Active-Passive-SDN/)

- Active/Passive with external and internal Azure Load Balancer: This design will deploy 2 FortiGate VMs in Active/Passive connected using the unicast FGCP HA protocol. The failover of the traffic in this setup is handled by the Microsoft Azure Load Balancer using a health probe towards the FortiGate VMs. THe failover times are based on the health probe of the Microsoft Azure Load Balancer (2 failed attempts per 5 seconds with a max of 15 seconds). The public IPs are configured on the Microsoft Azure Load Balancer and provide ingress and egress flows with inspection from the FortiGate. Microsoft provides some guidance on this architecture [here](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-ha-ports-overview).

More information can be found [here](Active-Passive-ELB-ILB/)

- Active/Active with external and internal Azure Load Balancer: This design will deploy 2 FortiGate VMs in Active/Active as 2 independent systems. The failover of the traffic in this setup is handled by the Microsoft Azure Load Balancer using a health probe towards the FortiGate VMs. The public IPs are configured on the Microsoft Azure Load Balancer and provide ingress and egress flows with inspection from the FortiGate. To sync the configuration of this setup a FortiManager or local replication can be used. Microsoft provides some guidance on this architecture [here](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-ha-ports-overview).

More information can be found [here](Active-Active-ELB-ILB/)

## Selecting your architecture in Microsoft Azure

The FortiGate Next-Generation Firewall can be deployed in Microsoft Azure in different architectures each with their specific properties that can be an advantage or disadvantage in your environment.

- Single VNET
- VNET peering
- Autoscaling
- Multi region - Azure Traffic Manager
- Azure Application Gateway
