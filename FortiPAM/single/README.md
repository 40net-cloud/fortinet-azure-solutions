# FortiPAM - A Single VM

:wave: - [Introduction](#introduction) - [Design](#design) - [Deployment](#deployment) - [Post-deployment configuration](#post-deployment-configuration) :wave:

## Introduction

FortiPAM is a privileged access management solution providing role-based access, auditing, and security options for privileged users — users that have system access beyond that of a regular user. It secures, controls, and records privileged sessions to critical assets such as servers, network devices, and cloud consoles.

Running FortiPAM in Microsoft Azure fits naturally in a **centrally hosted PAM deployment**: the FortiPAM VM runs in Azure and brokers privileged access to targets in Azure, on-premises, or across multiple sites — over VNET peering, VPN, or ExpressRoute — while all sessions, approvals, credential rotations, and video recordings are managed and stored centrally.

## Design

In Microsoft Azure, this single FortiPAM-VM setup is a basic setup to start exploring the capabilities of the FortiPAM privileged access management platform.

This Azure ARM template will automatically deploy a full working environment containing the following components.

- 1 FortiPAM VM (Azure Marketplace image `fortinet:fortinet-fortipam:fortinet-fpam`, FortiPAM 1.9.x) with two data disks — one for logs and one for video recordings (minimum 10 GB each)
- 1 VNET containing a subnet for the FortiPAM
- 1 Network Security Group allowing TCP 22 (SSH/CLI) and TCP 443 (HTTPS GUI) inbound
- Optional: 1 Standard public IP

This Azure ARM template can also be extended or customized based on your requirements. Additional subnets besides the ones mentioned above are not automatically generated. The FortiPAM VM can also be deployed without a public IP on the network interface by selecting 'None' as the public IP.

### VM Server Resource Sizing

Size the instance type according to the number of users, as documented in the [FortiPAM system requirements](https://docs.fortinet.com/document/fortipam-public-cloud/1.9.0/azure-administration-guide/669737/system-requirements). The default VM size in this template is `Standard_D4s_v5` (4 vCPU / 16 GB).

| Users | vCPU | Memory (GB) | Storage |
| --- | --- | --- | --- |
| 20 - 1000 | 4 - 64 | 16 - 256 | 2 TB - 16 TB |

### Log and video disk requirements

| Disk | Minimum size | Purpose |
| --- | --- | --- |
| Log disk | 10 GB | System and event logs |
| Video disk | 10 GB | Privileged session video recordings (~250 MB per hour of session) |

The recommended log to video disk ratio is **1:3**. Plan the video disk size according to the number of recorded sessions and their duration.

## Deployment

For the deployment, you can use the Azure Portal, Azure CLI, Powershell or Azure Cloud Shell. The Azure ARM templates are exclusive to Microsoft Azure and can't be used in other cloud environments. The main template is the `mainTemplate.json` which you can use in the Azure Portal. A `deploy.sh` script is provided to facilitate the deployment. You'll be prompted to provide the 4 required variables:

- PREFIX : This prefix will be added to each of the resources created by the template for ease of use and visibility.
- LOCATION : This is the Azure region where the deployment will be deployed.
- USERNAME : The username used to login to the FortiPAM GUI and SSH CLI.
- PASSWORD : The password used for the FortiPAM GUI and SSH CLI.

> [!WARNING]
> Licensing is done **after deployment**. FortiPAM uses a BYOL (yearly user subscription) model: the license file (`.lic`) is uploaded via SCP or the GUI once the VM is running — it is NOT injected during deployment. An evaluation license is not available on Azure, and each FortiPAM instance must have its own valid license. See [Post-deployment configuration](#post-deployment-configuration).

### Azure Portal

Azure Portal Wizard:
[![Azure Portal Wizard](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiPAM%2Fsingle%2FmainTemplate.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiPAM%2Fsingle%2FcreateUiDefinition.json)

Custom deployment:
[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiPAM%2Fsingle%2FmainTemplate.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiPAM%2Fsingle%2FmainTemplate.json)

### Azure CLI

Use the Azure Cloud Shell ([https://shell.azure.com/](https://shell.azure.com)):

`cd ~/clouddrive/ && wget -qO- https://github.com/40net-cloud/fortinet-azure-solutions/archive/main.tar.gz | tar zxf - && cd ~/clouddrive/fortinet-azure-solutions-main/FortiPAM/single/ && ./deploy.sh`

## Post-deployment configuration

### First access and licensing

1. **Login to the GUI** at `https://<public-ip>` (HTTPS, port 443) with the USERNAME and PASSWORD provided during deployment. The CLI is reachable over SSH on port 22 with the same credentials.

2. **Register the FortiPAM-VM on FortiCloud** ([support.fortinet.com](https://support.fortinet.com)) with your license contract and download the license file (`.lic`). See [Register FortiPAM-VM on FortiCloud](https://docs.fortinet.com/document/fortipam-public-cloud/1.9.0/azure-administration-guide/889428/register-fortipam-vm-on-forticloud).

3. **Upload the license file**, either:

   - **via the GUI**: login and upload the `.lic` file when prompted on the license page, or
   - **via SCP** (SSH access must be reachable on port 22):

     ```
     scp <license-file>.lic <username>@<public-ip>:.
     ```

     See [Uploading the license using SCP](https://docs.fortinet.com/document/fortipam-public-cloud/1.9.0/azure-administration-guide/498103/uploading-the-license-using-scp).

4. **Wait for the reboot**. The FortiPAM-VM restarts to apply the license, then validates it against FortiGuard. Verify the license status on the dashboard after logging back in.

### Initial configuration

After licensing, complete the initial setup following [Configure your FortiPAM-VM](https://docs.fortinet.com/document/fortipam-public-cloud/1.9.0/azure-administration-guide/476219/configure-your-fortipam-vm):

- Verify the log and video data disks are recognized and configured. The recommended log to video disk ratio is 1:3.
- Configure DNS, NTP, and the management interface settings.
- Create secret folders, targets, and privileged user roles as required.

Additional service ports (e.g. TCP 8443 reverse service, TCP 4433 FortiToken Mobile push) are documented in the [FortiPAM ports reference](https://docs.fortinet.com/document/fortipam/1.9.0/fortipam-ports) — open them in the Network Security Group if needed.

## Resources

- [FortiPAM 1.9.0 Azure Administration Guide](https://docs.fortinet.com/document/fortipam-public-cloud/1.9.0/azure-administration-guide/532845/introduction)
- [FortiPAM Administration Guide - Installation on Azure](https://docs.fortinet.com/document/fortipam/latest/administration-guide/125907/installation-on-azure)
- [FortiPAM system requirements and sizing](https://docs.fortinet.com/document/fortipam-public-cloud/1.9.0/azure-administration-guide/669737/system-requirements)
- [FortiPAM HA on Azure](https://docs.fortinet.com/document/fortipam-public-cloud/1.9.0/azure-administration-guide/953635/fortipam-ha-on-azure)

## TODO (attribution GUIDs - non-blocking placeholders)

Two attribution identifiers are placeholders pending confirmation:

- `fortinetTags.provider` in `mainTemplate.json` + `mainTemplate.parameters.json`: currently `6EB3B02F-50E5-4A3E-8CB8-2E1292583TODO` (pending the real FortiPAM provider suffix from the repo maintainer).
- Partner Center PID resource name in `mainTemplate.json`: currently `pid-00000000-0000-0000-0000-000000000000-partnercenter` (pending the real CUA tracking GUID from Partner Center).

Both are attribution-only and do not affect deployment.

## Support
Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/40net-cloud/fortinet-azure-solutions/issues) tab of this GitHub project.

## License
[License](/../../blob/main/LICENSE) © Fortinet Technologies. All rights reserved.
