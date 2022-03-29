# Active/Passive High Available FortiGate pair with external and internal Azure Standard Load Balancer

## Introduction

In FortiGate 7.0.x release it is not possible to deploy a FGCP cluster with only 3 NICs instead of four. The HA MGMT and HA SYNC are combined into 1 inteface. All other deployment information can be found [here](/FortiGate/Active-Passive-ELB-ILB/README.md).

Azure Portal Wizard Template Deployment:
[![Deploy Azure Portal Button](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FPlayground%2FActive-Passive-ELB-ILB-3NIC%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FPlayground%2FActive-Passive-ELB-ILB-3NIC%2FcreateUiDefinition.json)

Standard Custom Template Deployment:
[![Deploy Azure Portal Button](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FPlayground%2FActive-Passive-ELB-ILB-3NIC%2Fazuredeploy.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions$2Fmain%2FFortiGate%2FPlayground%2FActive-Passive-ELB-ILB-3NIC%2Fazuredeploy.json)

## Support

Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/fortinet/azure-templates/issues) tab of this GitHub project.
For other questions related to this project, contact [github@fortinet.com](mailto:github@fortinet.com).

## License

[License](LICENSE) © Fortinet Technologies. All rights reserved.
