# Active/Active load balanced pair of standalone FortiGates for resilience and scale

[![Build Status](https://dev.azure.com/jvh-2520/Fortinet-Azure/_apis/build/status/Active-Active-ELB-ILB?branchName=main)](https://dev.azure.com/jvh-2520/Fortinet-Azure/_build/latest?definitionId=9&branchName=main)

## Introduction

Enterprises are using Microsoft Azure to extend or replace internal data centers and take advantage of the elasticity of the Public Cloud. While Azure secures the infrastructure, enterprises are responsible for protecting the resources they create. As workloads are being moved from local data centers, connectivity and security are key elements to take into account. FortiGate-VM offers a consistent security posture and protects connectivity across public and private clouds, while high-speed VPN connections protect data.

This Azure ARM template deploys an Active/Active FortiGate pair combined with the Microsoft Azure Standard Load Balancer both in the external and the internal subnet. Additionally, Fortinet Fabric Connectors deliver the ability to create dynamic security policies.

## Design

In Microsoft Azure, an active/active pair of FortiGate VMs can be deployed that communicate with each other and the Azure fabric. This FortiGate setup will receive the to be inspected traffic using user defined routing (UDR) and public IPs. Send all or specific traffic that needs inspection, going to/coming from on-premises networks or Public Internet by adapting the UDR routing.

This Azure ARM template will automatically deploy a full working environment containing the the following components.

- 2 FortiGate firewalls in an active/active deployment
- 1 external Azure Standard Load Balancer for communication with internet
- 1 internal Azure Standard Load Balancer to receive all internal traffic and forwarding towards Azure Gateways connecting ExpressRoute or Azure VPNs.
- 1 VNET containing
  - 1 External subnet
  - 1 Internal subnet
  - 2 Protected subnets
- 1 public IP for services and FortiGate management
- User Defined Routes (UDR) for the protected subnets

![active/active design](images/fgt-aa.png)

This ARM template can also be used to extend or be customized based on design requirements. Additional subnets besides the ones mentioned above are not automatically generated. By adapting the ARM template additional subnets can be added which preferably require their own routing tables.

## How to deploy

The FortiGate solution can be deployed using the Azure Portal or Azure CLI.

### Azure Portal

Azure Portal:</br>
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FAvailabilityZones%2FActive-Active-ELB-ILB-AZ%2Fazuredeploy.json" target="_blank">
  <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true"/>
</a>

<br/>
Azure Portal Wizard:</br>
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FAvailabilityZones%2FActive-Active-ELB-ILB-AZ%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FAvailabilityZones%2FActive-Active-ELB-ILB-AZ%2FcreateUiDefinition.json" target="_blank">
  <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true"/>
</a>

### Azure CLI

There are 4 variables needed to complete the deployment, the `deploy.sh` script will ask them automatically.

- PREFIX : This prefix will be added to each of the resources created by the templates.
- LOCATION : This is the Azure region where the resources will be deployed
- USERNAME : The username used to login to the FortiGate GUI and SSH management UI.
- PASSWORD : The password used for the FortiGate GUI and SSH management UI.

To deploy via Azure Cloud Shell, connect via the Azure Portal or directly to [https://shell.azure.com/](https://shell.azure.com/).

- Login into the Azure Cloud Shell
- Run the following command in the Azure Cloud:

`cd ~/clouddrive/ && wget -qO- https://github.com/movinalot/fortinet-azure-solutions/archive/main.tar.gz | tar zxf - && cd ~/clouddrive/fortinet-azure-solutions/FortiGate/AvailabilityZones/Active-Active-ELB-ILB-AZ/ && ./deploy.sh`

- The script will prompt for a few setting to perform a full deployment.

![Azure Cloud Shell](images/azure-cloud-shell.png)

After deployment the IP address of all deployed components will be displayed. Access each FortiGate's management GUI or SSH using the public IP address of the load balancer using HTTPS on port 40030, 40031 and for SSH on port 50030 and 50031. THe FortiGate VMs are also accessible using their private IPs on the internal subnet using HTTPS on port 443 and SSH on port 22.

## Requirements and limitations

The ARM template deploys different resources and is required to have the access rights and sufficient quota in the selected Microsoft Azure subscription to deploy the resources.

- By default The template will deploy Standard F2s VMs for this architecture. Other VM instances are supported as well with a minimum of 2 NICs. A list can be found [here](https://docs.fortinet.com/document/fortigate-public-cloud/7.0.0/azure-administration-guide/562841/instance-type-support)
- Licenses for FortiGate
  - BYOL: This license type is based on a `.lic` file to be uploaded during or after FortiGate VM deployment.
    - A demo license can be made available via a Fortinet partner.
    - Purchased licenses need to be registered on the [Fortinet support site] (<http://support.fortinet.com/>). Download the `.lic` file after registration. Note, these files can take up to 30 minutes to be active after the initial creation.
  - Flex-VM: This license type is based on a point system and requires an enablement token to activate
  - PAYG or OnDemand: This license type is automatically generated during the deployment of the FortiGate and billed as part of the Azure subscription monthly charges.
- The password provided during deployment must meet password complexity rules from Microsoft Azure:
  - Must be 12 characters or longer
  - Must contain characters from at least 3 of the following groups: uppercase characters, lowercase characters, numbers, and special characters excluding '\' or '-'
- The terms for the FortiGate BYOL/Flex-VM, or PAYG image in the Azure Marketplace need to be accepted before usage. This is done automatically during deployment via the Azure Portal. For the Azure CLI the commands below need to be run before the first deployment in a subscription.
  - BYOL/Flex-VM:
`az vm image accept-terms --publisher fortinet --offer fortinet_fortigate-vm_v5 --plan fortinet_fg-vm`
  - PAYG:
`az vm image accept-terms --publisher fortinet --offer fortinet_fortigate-vm_v5 --plan fortinet_fg-vm_payg_20190624`

## FortiGate configuration

The FortiGate VMs need a specific configuration to match the deployed environment. This configuration can be injected during provisioning or afterwards via the different options including GUI, CLI, FortiManager or REST API.

- [Default configuration using this template](doc/config-provisioning.md)

### Fabric Connector

The FortiGate-VM uses [Managed Identities](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/) for the SDN Fabric Connector. A SDN Fabric Connector is created automatically during deployment. After deployment, it is required to minimally apply the 'Reader' role to the Azure Subscription you want to resolve Azure Resources from. More information can be found on the [Fortinet Documentation Library](https://docs.fortinet.com/vm/azure/fortigate/7.0/azure-administration-guide/7.0.0/236610/creating-a-fabric-connector-using-a-managed-identity).

### North South traffic

When configuring the policies on the FortiGates to allow and forward traffic to internal hosts, it is recommended to enable the NAT checkbox (this will S-NAT the packets to the IP of port2). Doing so will enforce symmetric return.

It is possible to use FGSP to synchronize sessions and thereby allow asymmetric return traffic. However, this is not best practice from a security perspective, because it limits the ability of the Intrusion Prevention System (IPS) by potentially only seeing one side of the conversation on each FortiGate. The FortiGate IPS takes both sides of the conversation into account for increased security and visibility. Reducing this visibility on the FortiGate may decrease the IPS efficacy.

Often S-NAT is not desired because it is necessary to retain the original source IP. For HTTP or HTTPS traffic in particular, you can enable the Load Balancing feature on the FortiGate which provides the option to copy the source IP into the X-Forwarded-For header.

To use FGSP for session synchronization, it can be enabled during deployment by un-commenting the section in the customdata.tpl file or adding this recommended configuration to both FortiGate VMs.

```bash
config system ha
    set session-pickup enable
    set session-pickup-connectionless enable
    set session-pickup-nat enable
    set session-pickup-expectation enable
    set override disable
end

config system cluster-sync
    edit 0
        set peerip 10.0.1.x
        set syncvd "root"
    next
end
```

- Where x in 10.0.1.x is the IP of port 1 of the opposite FortiGate. With the default values this would be either 5 or 6.

### Configuration synchronization

The FortiGate VMs in this Active/Active setup are independent. The FGCP protocol used in the Active/Passive setup to sync the configuration is not applicable in an Active/Active deployment.

To enable configuration sync between both VMs the sync from the autoscaling setup can be used. This will sync all configuration except for configuration items specific to the VM, for example hostname and routing settings. To enable configuration sync the configs below can be applied to each FortiGate.

FortiGate A

```bash
config system auto-scale
    set status enable
    set role master
    set sync-interface "port2"
    set psksecret "a big secret"
end
```

FortiGate B

```bash
config system auto-scale
    set status enable
    set sync-interface "port2"
    set master-ip 172.16.136.69
    set psksecret "a big secret"
end
```

## Support

Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/40net-cloud/fortinet-azure-solutions/issues) tab of this GitHub project.

## License

[License](LICENSE) © Fortinet Technologies. All rights reserved.
