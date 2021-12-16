# Active/Passive High Available FortiGate pair with external and internal Azure Standard Load Balancer

[![Build Status](https://dev.azure.com/jvh-2520/Fortinet-Azure/_apis/build/status/Azure-Passive-ELB-ILB?branchName=main)](https://dev.azure.com/jvh-2520/Fortinet-Azure/_build/latest?definitionId=13&branchName=main)

## Introduction

More and more enterprises are turning to Microsoft Azure to extend internal data centers and take advantage of the elasticity of the public cloud. While Azure secures the infrastructure, you are responsible for protecting everything you put in it. Fortinet Security Fabric provides Azure the broad protection, native integration and automated management enabling customers with consistent enforcement and visibility across their multi-cloud infrastructure.

This ARM template deploys a High Availability pair of FortiGate Next-Generation Firewalls accompanied by the required infrastructure. Additionally, Fortinet Fabric Connectors deliver the ability to create dynamic security policies.

## Design

In Microsoft Azure, you can deploy an active/passive pair of FortiGate VMs that communicate with each other and the Azure fabric. This FortiGate setup will receive the traffic to be inspected traffic using user defined routing (UDR) and public IPs. You can send all or specific traffic that needs inspection, going to/coming from on-prem networks or public internet by adapting the UDR routing.

This Azure ARM template will automatically deploy a full working environment containing the following components.

- 2 FortiGate firewall's in an active/passive deployment
- 1 external Azure Standard Load Balancer for communication with internet
- 1 internal Azure Standard Load Balancer to receive all internal traffic and forwarding towards Azure Gateways connecting ExpressRoute or Azure VPN's
- 1 VNET with 2 protected subnets and 4 subnets required for the FortiGate deployment (external, internal, ha mgmt and ha sync). If using an existing vnet, it must already have 5 subnets
- 3 public IPs. The first public IP is for cluster access to/through the active FortiGate.  The other two PIPs are for Management access
- User Defined Routes (UDR) for the protected subnets

![active/passive design](images/fgt-ap.png)

This ARM template can also be used to extend or customized based on your requirements. Additional subnets besides the one's mentioned above are not automatically generated. By adapting the ARM templates you can add additional subnets which preferably require their own routing tables.

## How to deploy

The FortiGate solution can be deployed using the Azure Portal.

### Azure Portal

Standard Custom Template Deployment:

[![Deploy Azure Portal Button](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FAvailabilityZones%2FActive-Passive-ELB-ILB-AZ%2Fazuredeploy.json)

Azure Portal Wizard Template Deployment:

[![Deploy Azure Portal Button](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FAvailabilityZones%2FActive-Passive-ELB-ILB-AZ%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FAvailabilityZones%2FActive-Passive-ELB-ILB-AZ%2FcreateUiDefinition.json)

## Requirements and limitations

More documentation can be found on [the Availability Set version of this template](/FortiGate/Active-Passive-ELB-ILB/README.md#requirements-and-limitations).

## FortiGate configuration

More documentation can be found on [the Availability Set version of this template](/FortiGate/Active-Passive-ELB-ILB/README.md#fortigate-configuration).

## Troubleshooting

You can find a troubleshooting guide for this setup [here](/FortiGate/Active-Passive-ELB-ILB/doc/troubleshooting.md)

## Support

Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/fortinet/azure-templates/issues) tab of this GitHub project.
For other questions related to this project, contact [github@fortinet.com](mailto:github@fortinet.com).

## License

[License](/LICENSE) © Fortinet Technologies. All rights reserved.
