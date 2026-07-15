# Active/Passive High Available FortiGate pair with Fabric Connector Failover

[![[FGT] ARM - Active-Passive-SDN](https://github.com/40net-cloud/fortinet-azure-solutions/actions/workflows/fgt-arm-active-passive-sdn.yml/badge.svg)](https://github.com/40net-cloud/fortinet-azure-solutions/actions/workflows/fgt-arm-active-passive-sdn.yml)

:wave: - [Introduction](#introduction) - [Design](#design) - [Deployment](#deployment) - [Requirements](#requirements-and-limitations) - [Configuration](#configuration) - :wave:

## Introduction

More and more enterprises are turning to Microsoft Azure to extend internal data centers and take advantage of the elasticity of the public cloud. While Azure secures the infrastructure, you are responsible for protecting everything you put in it. Fortinet Security Fabric provides Azure the broad protection, native integration and automated management enabling customers with consistent enforcement and visibility across their multi-cloud infrastructure.

This ARM template deploys a High Availability pair of FortiGate Next-Generation Firewalls accompanied by the required infrastructure. Additionally, Fortinet Fabric Connectors deliver the ability to create dynamic security policies.

## Design

In Microsoft Azure, you can deploy an active/passive pair of FortiGate VMs that communicate with each other and the Azure fabric. This FortiGate setup will receive the to be inspected traffic using user defined routing (UDR) and public IPs. You can send all or specific traffic that needs inspection, going to/coming from on-prem networks or public internet by adapting the UDR routing.

This Azure ARM template will automatically deploy a full working environment containing the the following components.

- 2 FortiGate firewall's in an active/passive deployment
- 1 VNET with 2 protected subnets and 4 subnets required for the FortiGate deployment (external, internal, ha mgmt and ha sync). If using an existing vnet, it must already have 5 subnets
- 3 public IPs. The first public IP is for cluster access to/through the active FortiGate.  The other two PIPs are for Management access
- User Defined Routes (UDR) for the protected subnets

![active/passive design](images/fgt-ap-sdn.png)

To enhance the availability of the solution VM can be installed in different Availability Zones instead of an Availability Set. If Availability Zones deployment is selected but the location does not support Availability Zones an Availability Set will be deployed. If Availability Zones deployment is selected and Availability Zones are available in the location, FortiGate A will be placed in Zone 1, FortiGate B will be placed in Zone 2.

![active/passive design](images/fgt-ap-sdn-az.png)

This ARM template can also be used to extend or customized based on your requirements. Additional subnets besides the one's mentioned above are not automatically generated. By adapting the ARM templates you can add additional subnets which preferably require their own routing tables.

## Deployment

The FortiGate solution can be deployed using the Azure Portal or Azure CLI. There are 4 variables needed to complete kickstart the deployment. The deploy.sh script will ask them automatically. When you deploy the ARM template the Azure Portal will request the variables as a requirement.

- PREFIX : This prefix will be added to each of the resources created by the templates for easy of use, manageability and visibility.
- LOCATION : This is the Azure region where the deployment will be deployed
- USERNAME : The username used to login to the FortiGate GUI and SSH management UI.
- PASSWORD : The password used for the FortiGate GUI and SSH management UI.

### Azure Portal

Azure Portal Wizard:
[![Deploy Azure Portal Button](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FActive-Passive-SDN%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FActive-Passive-SDN%2FcreateUiDefinition.json)

Custom deployment:
[![Deploy Azure Portal Button](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FActive-Passive-SDN%2Fazuredeploy.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions$2Fmain%2FFortiGate%2FActive-Passive-SDN%2Fazuredeploy.json)

As of March 2026, new FortiGate SKUs were introduced in the Azure Marketplace that provide access to the latest marketplace features. In specific regions (e.g. GovCloud, private offers, ...) and deployment scenarios, legacy SKUs are still required; [those templates can be found in the legacy directory](legacy/).

- Marketplace information:
  - Publisher: fortinet
  - Offer: fortinet_fortigate-vm
  - SKU / plan: fortinet_fg-vm_byol_70, fortinet_fg-vm_payg_70, fortinet_fg-vm_byol_72, fortinet_fg-vm_payg_72, fortinet_fg-vm_byol_74, fortinet_fg-vm_payg_74, fortinet_fg-vm_byol_76, fortinet_fg-vm_payg_76

### Azure CLI

To deploy via Azure Cloud Shell you can connect via the Azure Portal or directly to [https://shell.azure.com/](https://shell.azure.com/).

- Login into the Azure Cloud Shell
- Run the following command in the Azure Cloud:

`cd ~/clouddrive/ && wget -qO- https://github.com/40net-cloud/fortinet-azure-solutions/archive/main.tar.gz | tar zxf - && cd ~/clouddrive/fortinet-azure-solutions-main/FortiGate/Active-Passive-SDN/ && ./deploy.sh`

- The script will ask you a few questions to bootstrap a full deployment.

![Azure Cloud Shell](images/azure-cloud-shell.png)

After deployment you will be shown the IP address of all deployed components. Both FortiGate VMs are accessible using the public management IPs using HTTPS on port 443 and SSH on port 22.

## Requirements and limitations

The ARM template deploys different resources and it is required to have the access rights and quota in your Microsoft Azure subscription to deploy the resources.

- This architecture relies on API calls to Azure. Shifting the public IP address and gateway IP addresses of the routes takes time for Azure to complete especially if environment is larger and there are multiple Public IPs to be shifted and multiple routes to be changed. The failover time is variable depending on the platform.
- The template will deploy Standard F4s VMs for this architecture. Other VM instances are supported as well with a minimum of 4 NICs. A list can be found [here](https://docs.fortinet.com/document/fortigate-public-cloud/7.4.0/azure-administration-guide/562841/instance-type-support)
- Licenses for FortiGate
  - BYOL: A demo license can be made available via your Fortinet partner or on our website. These can be injected during deployment or added after deployment. Purchased licenses need to be registered on the [Fortinet support site](http://support.fortinet.com). Download the .lic file after registration. Note, these files may not work until 60 minutes after it's initial creation.
  - PAYG or OnDemand: These licenses are automatically generated during the deployment of the FortiGate systems.
- The password provided during deployment must need password complexity rules from Microsoft Azure:
  - It must be 12 characters or longer
  - It needs to contain characters from at least 3 of the following groups: uppercase characters, lowercase characters, numbers, and special characters excluding '\' or '-'
- The terms for the FortiGate PAYG or BYOL image in the Azure Marketplace needs to be accepted once before usage. This is done automatically during deployment via the Azure Portal. For the Azure CLI the commands below need to be run before the first deployment in a subscription.
  - BYOL/FLEX
`az vm image terms accept --publisher fortinet --offer fortinet_fortigate-vm --plan fortinet_fg-vm-byol_76`
  - PAYG
`az vm image terms accept --publisher fortinet --offer fortinet_fortigate-vm --plan fortinet_fg-vm_payg_76`

## Configuration

The FortiGate VMs need a specific configuration to operate in your environment. This configuration can be injected during provisioning or afterwards via the different management options including GUI, CLI, FortiManager or REST API.

- [Fabric Connector](#fabric-connector)
- [VNET peering](#vnet-peering)
- [Failover configuration](#failover-configuration)
- [Availability Zone](#availability-zone)
- [Default configuration using this template](#default-configuration)
- [Upload VHD](https://community.fortinet.com/t5/FortiGate-Azure-Technical/Deployment-of-FortiGate-VM-using-a-VHD-image-file/ba-p/320338)

### Fabric Connector

The FortiGate-VM uses [Managed Identities](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/) for the SDN Fabric Connector. A SDN Fabric Connector is created automatically during deployment. After deployment, it is required apply the 'Reader' role to the Azure Subscription you want to resolve Azure Resources from. More information can be found on the [Fortinet Documentation Libary](https://docs.fortinet.com/document/fortigate-public-cloud/7.6.0/azure-administration-guide/236610/configuring-an-sdn-connector-using-a-managed-identity).

### VNET peering

In Microsoft Azure, this central security services hub is commonly implemented using VNET peering. The central security services hub component will receive, using user-defined routing (UDR), all or specific traffic that needs inspection going to/coming from on-prem networks or the public internet. This deployment can be used as the hub section of such a [Hub-Spoke network topology](https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke?tabs=cli#communication-through-an-nva)

### Failover configuration

Once, licensed and rebooted, the FortiGate Fabric Connector needs to be configured to enable the cluster IP and route table to failover. Most of this config will be specific to your environment and so must be modified. The authentication part by default is configured using [managed identities](https://docs.fortinet.com/document/fortigate-public-cloud/7.6.0/azure-administration-guide/236610/configuring-an-sdn-connector-using-a-managed-identity). It can be done a service principal as well more information can be found [here](https://docs.fortinet.com/document/fortigate-public-cloud/7.2.0/azure-administration-guide/948968/azure-sdn-connector-service-principal-configuration-requirements)

#### FortiGate A

```text
config system sdn-connector
  edit "AzureSDN"
  set type azure
  set ha-status enable
  set resource-group "fortigateapha"
  set subscription-id 00000000-0000-0000-0000-000000000000
  config nic
    edit "FortiGate-A-NIC1"
      config ip
        edit "ipconfig1"
        set public-ip "FGTAPClusterPublicIP"
      next
    end
    next
  end
  config route-table
    edit "FGTDefaultAPRouteTable"
    config route
    edit "toDefault"
      set next-hop "172.16.136.68"
    next
  end
  next
 end
end
```

#### FortiGate B

```text
config system sdn-connector
  edit "AzureSDN"
  set type azure
  set ha-status enable
  set resource-group "fortigateapha"
  set subscription-id 00000000-0000-0000-0000-000000000000
  config nic
    edit "FortiGate-B-NIC1"
    config ip
      edit "ipconfig1"
      set public-ip "FGTAPClusterPublicIP"
    next
  end
  next
  end
  config route-table
    edit "FGTDefaultAPRouteTable"
      config route
      edit "toDefault"
         set next-hop "172.16.136.69"
      next
    end
    next
  end
end
```

### Availability Zone

Microsoft defines an Availability Zone to have the following properties:

- Unique physical location with an Azure Region
- Each zone is made up of one or more datacenter(s)
- Independent power, cooling and networking
- Inter Availability Zone network latency < 2ms (radius of +/- 100km)
- Fault-tolerant to protect from datacenter failure

Based on information in the presentation ['Inside Azure datacenter architecture with Mark Russinovich' at Microsoft Ignite 2019](https://www.youtube.com/watch?v=X-0V6bYfTpA)

![active/passive design](images/fgt-ap-sdn-az.png)

### Default configuration

After deployment, the below configuration has been automatically injected during the deployment. The bold sections are the default values. If parameters have been changed during deployment these values will be different.

#### FortiGate A

<pre><code>
config system global
  set admin-sport 8443
end
config router static
  edit 1
    set gateway <b>10.0.1.1</b>
    set device port1
  next
  edit 2
    set dst <b>10.0.0.0/16</b>
    set gateway <b>10.0.2.1</b>
    set device "port2"
  next
end
config system interface
  edit "port1"
    set vdom "root"
    set mode static
    set ip <b>10.0.1.4 255.255.255.0</b>
    set allowaccess ping https ssh
    set description "external"
  next
  edit "port2"
    set vdom "root"
    set mode static
    set ip <b>10.0.2.4 255.255.255.0</b>
    set description "internal"
  next
  edit "port3"
    set vdom "root"
    set mode static
    set ip <b>10.0.3.4 255.255.255.240</b>
    set description "hasyncport"
  next
  edit "port4"
    set vdom "root"
    set mode static
    set ip <b>10.0.4.4 255.255.255.240</b>
    set allowaccess ping https ssh
    set description "management"
  next
end
config system ha
  set group-name "AzureHA"
  set mode a-p
  set hbdev "port3" 100
  set session-pickup enable
  set session-pickup-connectionless enable
  set ha-mgmt-status enable
  config ha-mgmt-interfaces
    edit 1
      set interface "port4"
      set gateway <b>10.0.4.1</b>
    next
  end
  set override disable
  set priority 255
  set unicast-hb enable
  set unicast-hb-peerip <b>10.0.3.5</b>
end
</code></pre>

#### FortiGate B

<pre><code>
config system global
  set admin-sport 8443
end
config router static
  edit 1
    set gateway <b>10.0.1.1</b>
    set device port1
  next
  edit 2
    set dst <b>10.0.0.0 255.255.0.0</b>
    set gateway <b>10.0.2.1</b>
  set device "port2"
  next
end
config system interface
  edit "port1"
    set vdom "root"
    set mode static
    set ip <b>10.0.1.5 255.255.255.0</b>
    set allowaccess ping https ssh
    set description "external"
  next
  edit "port2"
    set vdom "root"
    set mode static
    set ip <b>10.0.2.5 255.255.255.0</b>
    set description "internal"
  next
  edit "port3"
    set mode static
    set ip <b>10.0.3.5 255.255.255.240</b>
    set description "hasyncport"
  next
  edit "port4"
    set vdom "root"
    set mode static
    set ip <b>10.0.4.5 255.255.255.240</b>
    set allowaccess ping https ssh
    set description "management"
  next
end
config system ha
  set group-name "AzureHA"
  set mode a-p
  set hbdev "port3" 100
  set session-pickup enable
  set session-pickup-connectionless enable
  set ha-mgmt-status enable
  config ha-mgmt-interfaces
    edit 1
      set interface "port4"
      set gateway <b>10.0.4.1</b>
    next
  end
  set override disable
  set priority 1
  set unicast-hb enable
  set unicast-hb-peerip <b>10.0.3.4</b>
end
</code></pre>

## Support

Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/fortinet/azure-templates/issues) tab of this GitHub project.
For other questions related to this project, contact [github@fortinet.com](mailto:github@fortinet.com).

## License

[License](/../../blob/main/LICENSE) © Fortinet Technologies. All rights reserved.
