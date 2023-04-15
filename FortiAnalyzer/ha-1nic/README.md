# FortiAnalyzer High Availability

## Introduction

FortiAnalyzer underpins the Fortinet Security Fabric, providing centralized logging and analysis, plus end-to-end visibility. As a result, analysts can manage security posture more effectively, automate security processes, and respond to threats quickly.

FortiAnalyzer automatically collects, stores, and analyzes logs from all Fortinet security devices including FortiGate Next-Generation Firewalls, VPNs, and intrusion detection and prevention systems. You can easily manage large volumes of logs and search for specific events using various search criteria.

## Design

In Microsoft Azure, this single FortiAnalyzer-VM setup a basic setup to start exploring the capabilities of the management platform for the FortiGate next generation firewall.

This Azure ARM template will automatically deploy a full working environment containing the following components.

- 2 FortiAnalyzer VM with a 1Tb data disk for log storage
- 1 VNETs containing a subnet for the FortiAnalyzer
- 1 Basic/Standard public IPs

![FortiAnalyzer HA azure design](images/faz-ha.png)

To enhance the availability of the solution VM can be installed in different Availability Zones instead of an Availability Set. If Availability Zones deployment is selected but the location does not support Availability Zones an Availability Set will be deployed. If Availability Zones deployment is selected and Availability Zones are available in the location, FortiAnalyzer A will be placed in Zone 1, FortiAnalyzer B will be placed in Zone 2.

![FortiAnalyzer HA az design](images/faz-ha-az.png)

This Azure ARM template can also be extended or customized based on your requirements. Additional subnets besides the ones mentioned above are not automatically generated.

## Deployment

For the deployment, you can use the Azure Portal, Azure CLI, Powershell or Azure Cloud Shell. The Azure ARM templates are exclusive to Microsoft Azure and can't be used in other cloud environments. The main template is the `mainTemplate.json` which you can use in the Azure Portal. A `deploy.sh` script is provided to facilitate the deployment. You'll be prompted to provide the 4 required variables:

- PREFIX : This prefix will be added to each of the resources created by the template for ease of use and visibility.
- LOCATION : This is the Azure region where the deployment will be deployed.
- USERNAME : The username used to login to the FortiAnalyzer GUI and SSH management UI.
- PASSWORD : The password used for the FortiAnalyzer GUI and SSH management UI.

### Azure Portal

Azure Portal Wizard:
[![Azure Portal Wizard](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiAnalyzer%2Fha-1nic%2FmainTemplate.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiAnalyzer%2Fha-1nic%2FcreateUiDefinition.json)

Custom Deployment:
[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiAnalyzer%2Fha-1nic%2FmainTemplate.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions$2Fmain%2FFortiAnalyzer%2Fha-1nic%2FmainTemplate.json)

### Azure CLI
To fast track the deployment, use the Azure Cloud Shell. The Azure Cloud Shell is an in-browser CLI that contains Terraform and other tools for deployment into Microsoft Azure. It is accessible via the Azure Portal or directly at [https://shell.azure.com/](https://shell.azure.com). You can copy and paste the below one-liner to get started with your deployment.

`cd ~/clouddrive/ && wget -qO- https://github.com/40net-cloud/fortinet-azure-solutions/archive/main.tar.gz | tar zxf - && cd ~/clouddrive/fortinet-azure-solutions-main/FortiAnalyzer/ha-1nic/ && ./deploy.sh`

![Azure Cloud Shell](images/azure-cloud-shell.png)

After deployment, you will be shown the IP addresses of all deployed components. This information is also stored in the output directory in the 'summary.out' file. You can access both management GUI's using the public management IP addresses using HTTPS on port 443.

## Requirements and limitations

The Azure ARM template deployment deploys different resources and is required to have the access rights and quota in your Microsoft Azure subscription to deploy the resources.

- The template will deploy Standard D4as_v4 VMs for this architecture. Other VM instances are supported as well with a recommended minimum of 2 vCPU and 4Gb of RAM. A list can be found [here](https://docs.fortinet.com/document/fortianalyzer-public-cloud/7.2.0/azure-administration-guide/351055/instance-type-support)
- A Network Security Group is installed that only opens TCP port 22, 443 and 514 for access to the FortiAnalyzer. Additional ports might be needed to support your use case and are documented [here](https://docs.fortinet.com/document/fortimanager/7.0.0/fortimanager-ports/465971/incoming-ports)
- License for FortiAnalyzer
  - BYOL: A demo license can be made available via your Fortinet partner or on our website. These can be injected during deployment or added after deployment.

## FortiAnalyzer configuration

### High Availability

FortiAnalyzer high availability (HA) provided enhanded reliability of the solution. In case of failure of the primary unit, a backup unit can be promoted.

In Microsoft Azure, the FortiAnalyzer manual HA failover is supported. Both units have a private and optionally a public IP configured. The FortiGate need to be configured with either the both private or both public IPs depending on the which are reachable.

More information on FortiAnalyzer High Availability can be found in [the FortiAnalyzer documentation](https://docs.fortinet.com/document/fortimanager/7.2.2/administration-guide/568591/high-availability) as well as the specific Azure HA configuration steps [here]( https://docs.fortinet.com/document/fortianalyzer-public-cloud/7.2.0/azure-administration-guide/416866/configuring-fortianalyzer-ha).

### Primary FortiAnalyzer configuration

<pre>
config system ha
  set mode a-p
  set group-id 10
  set group-name FAZAZURE
  set password xxx
  config peer
    edit 1
      set serial-number <b>FortiAnalyzer B serial number</b>
      set ip <b>FortiAnalyzer B IP address</b>
    next
  end
  set preferred-role primary
  set vip <b>FortiAnalyzer Public IP address in Azure</b>
  set vip-interface port1
end
</pre>

### Secondary FortiAnalyzer configuration

<pre>
config system ha
  set mode a-p
  set group-id 10
  set group-name FAZAZURE
  set password xxx
  config peer
    edit 1
      set serial-number <b>FortiAnalyzer A serial number</b>
      set ip <b>FortiAnalyzer A IP address</b>
    next
  end
  set preferred-role secondary
  set vip <b>FortiAnalyzer Public IP address in Azure</b>
  set vip-interface port1
end
</pre>

### FortiGate configuration


## Support
Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/40net-cloud/fortinet-azure-solutions/issues) tab of this GitHub project.

## License
[License](LICENSE) © Fortinet Technologies. All rights reserved.
## Support
Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/40net-cloud/fortinet-azure-solutions/issues) tab of this GitHub project.

## License
[License](LICENSE) © Fortinet Technologies. All rights reserved.
