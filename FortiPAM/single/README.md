# FortiPAM

## Introduction

FortiPAM - Privileged Access Management

FortiPAM provides role-based access, auditing, and security options for privileged users. This ARM template deploys a single FortiPAM-VM accompanied by the required infrastructure.

## Design

This Azure ARM template deploys a single FortiPAM-VM in a basic standalone setup to start exploring the capabilities of the FortiPAM privileged access management platform.

This Azure ARM template automatically deploys a full working environment containing the following components:

- 1 FortiPAM VM with two data disks (one for logs, one for video recordings). Minimum 10 GB each; the recommended log:video disk ratio is 1:3.
- 1 VNET containing a subnet for the FortiPAM VM
- Optional: 1 Standard public IP

This Azure ARM template can be extended or customized based on your requirements. Additional subnets are not automatically generated.

The FortiPAM VM can also be deployed without a public IP on the network interface. Select 'None' as the public IP.

## Deployment

For the deployment, you can use the Azure Portal, Azure CLI, PowerShell or Azure Cloud Shell. The Azure ARM templates are exclusive to Microsoft Azure. The main template is `mainTemplate.json`. A `deploy.sh` script is provided to facilitate the deployment. You will be prompted for the 4 required variables:

- PREFIX : added to each resource created by the template.
- LOCATION : the Azure region for the deployment.
- USERNAME : the username used to login to the FortiPAM GUI and SSH CLI.
- PASSWORD : the password used for the FortiPAM GUI and SSH CLI.

**Marketplace terms:** the FortiPAM marketplace image (`fortinet:fortinet-fortipam:fortinet-fpam`) requires terms acceptance. The `deploy.sh` script runs `az vm image terms accept` automatically before deploying.

**Licensing:** FortiPAM uses a BYOL (yearly user subscription) model. The license file (`.lic`) is uploaded **after deployment via SCP or the GUI** -- it is NOT injected during deployment. "Evaluation license is not available on Azure." Each FortiPAM instance must have its own valid license.

### Azure Portal

Azure Portal Wizard:
[![Azure Portal Wizard](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiPAM%2Fsingle%2FmainTemplate.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiPAM%2Fsingle%2FcreateUiDefinition.json)

Custom deployment:
[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiPAM%2Fsingle%2FmainTemplate.json)

### Azure CLI

Use the Azure Cloud Shell ([https://shell.azure.com/](https://shell.azure.com)):

`cd ~/clouddrive/ && wget -qO- https://github.com/40net-cloud/fortinet-azure-solutions/archive/main.tar.gz | tar zxf - && cd ~/clouddrive/fortinet-azure-solutions-main/FortiPAM/single/ && ./deploy.sh`

After deployment you can access the FortiPAM GUI over HTTPS on port 443 using the public IP, and the CLI over SSH on port 22.

## Requirements and limitations

- The default VM size is `Standard_D4s_v5` (4 vCPU / 16 GB). FortiPAM sizing: 4-64 vCPU, 16-256 GB RAM for 20-1000 users. The FortiPAM image is x64 only.
- A Network Security Group opens TCP 22 (SSH/CLI) and 443 (HTTPS GUI) inbound, and all outbound. Additional ports (e.g. 8443 reverse service, 4433 FortiToken Mobile) are documented in the [FortiPAM ports reference](https://docs.fortinet.com/document/fortipam/1.9.0/fortipam-ports).
- License for FortiPAM: BYOL, uploaded post-deploy via SCP or GUI.

## TODO (attribution GUIDs -- non-blocking placeholders)

Two attribution identifiers are placeholders pending confirmation:

- `fortinetTags.provider` in `mainTemplate.json` + `mainTemplate.parameters.json`: currently `6EB3B02F-50E5-4A3E-8CB8-2E1292583TODO` (pending the real FortiPAM provider suffix from the repo maintainer).
- Partner Center PID resource name in `mainTemplate.json`: currently `pid-00000000-0000-0000-0000-000000000000-partnercenter` (pending the real CUA tracking GUID from Partner Center).

Both are attribution-only and do not affect deployment.

## Support

Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services. For direct issues, please refer to the [Issues](https://github.com/40net-cloud/fortinet-azure-solutions/issues) tab of this GitHub project.

## License
[License](/../../blob/main/LICENSE) (c) Fortinet Technologies. All rights reserved.
