# Cloud Security Services Hub using VNET peering and FortiGate Active/Passive High Availability with Azure Standard Load Balancer - External and Internal
*Fortinet FortiGate Terraform deployment template*

## Introduction

As organizations grow, and their consumption of the cloud increases and expands, the need to separate security management from application development increases. Different organizational units tend to build applications in different virtual networks and even different clouds and data centers. With each new deployment the complexity of keeping these secure increases.

By moving security functionality to a central hub (transit network) that securely interconnects disperse networks, locations, clouds, and data centers, one can effectively enforce security policies between the different virtual networks and locations as well as offer central security filtering for traffic between these networks and the internet. Thus, organizations can effectively split the role of security management from application development.

## Design

In Microsoft Azure, this central security service hub is commonly implemented using local VNET peering. The central security services hub component will receive, using user-defined routing (UDR), all or specific traffic that needs inspection going to/coming from on-prem networks or the public internet.

This Azure ARM template will automatically deploy a full working environment containing the following components.

- 2 FortiGate firewalls in an active/passive deployment
- 1 external Azure Standard Load Balancer for communication with the internet
- 1 internal Azure Standard Load Balancer to receive all internal traffic and forward it to Azure Gateways, connecting ExpressRoute, or Azure VPNs
- 3 VNETs (1 hub and 2 spoke networks) with each spoke network containing 1 subnet and the hub containing 2 extra protected subnets
- VNET peering between HUB and spoke networks
- User Defined Routes (UDR) for the different protected subnets

![VNET peering design](images/fgt-ha-vnet-peering.png)

This Terraform template can also be extended or customized based on your requirements. Additional subnets besides the ones mentioned above are not automatically generated. By extending the Terraform templates additional subnets can be added. Additional subnets will require their own routing tables and VNET peering configuration.

# Deployment

For the deployment Terraform is required. This multi-cloud deployment tool can be downloaded from the website of [Hashicorp](https://www.terraform.io/) who created and maintains it. You can either run the different stage manually (terraform init, plan, apply) or you can use the deploy.sh script. There are 4 variables needed to complete kickstart the deployment. The deploy.sh script will ask them automatically. When you run the terraform command manually you need to provide the variables yourself.

- PREFIX : This prefix will be added to each of the resources created by the template for ease of use and visibility.
- LOCATION : This is the Azure region where the deployment will be deployed.
- USERNAME : The username used to login to the FortiGate GUI and SSH management UI.
- PASSWORD : The password used for the FortiGate GUI and SSH management UI.

For Microsoft Azure there is a fast track option by using the Azure Cloud Shell. The Azure Cloud Shell is an in-browser CLI that contains Terraform and other tools for deployment into Microsoft Azure. It is accessible via the Azure Portal or directly via [https://shell.azure.com/](https://shell.azure.com). You can copy and past the below one-liner to get start with your deployment.

`cd ~/clouddrive/ && wget -qO- https://github.com/40net-cloud/fortinet-azure-solutions/archive/main.tar.gz | tar zxf - && cd ~/clouddrive/fortinet-azure-solutions-main/FortiGate/Terraform/VNET-Peering/ && ./deploy.sh`

![Azure Cloud Shell](images/azure-cloud-shell.png)

After deployment you will be shown the IP address of all deployed components, this information is also stored in the output directory in the summary.out file. You can access both management GUI's using the public management IP's using HTTPS on port 443.

!!! Beware that the output directory, Terraform Plan file and Terraform State files contain deployment information such as password, usernames, IP addresses and others.

## Requirements and limitations

This architecture uses the Active/Passive building block. More information about configuration can be found [here](../../Active-Passive-ELB-ILB/README.md).

## License
[License](LICENSE) © Fortinet Technologies. All rights reserved.
