# FAQ - Pay as you go (PAYG) 

FortiGate on Microsoft Azure supports the PAYG as well as the BYOL model. PAYG allows you to pay for the FortiGate VM on a consumption basis, meaning you are billed only for the resources you use. This can be particularly advantageous for businesses with fluctuating workloads or seasonal demands, as you can scale the FortiGate VM up or down as needed and avoid upfront costs. 

The PAYG license includes the UTM bundle. Please refer [https://www.fortinet.com/content/dam/fortinet/assets/data-sheets/FortiGate_VM_Azure.pdf](https://www.fortinet.com/content/dam/fortinet/assets/data-sheets/FortiGate_VM_Azure.pdf) for the details. 

[Azure Marketplace listing](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/fortinet.fortinet-fortigate?tab=overview)

Pricing requires 4 components:
- Azure compute
- Azure storage 
- Bandwidth charges
- FortiGate PAYG license

Microsoft provides a [calculator](https://azure.microsoft.com/en-gb/pricing/calculator/) to determine your Microsoft Azure costs: [https://azure.microsoft.com/en-gb/pricing/calculator/](https://azure.microsoft.com/en-gb/pricing/calculator/)

## Pay as you go vs Bring your own license

Pay as you go advantages:

- Cost Efficiency: PAYG allows you to pay for the FortiGate VM on a consumption basis, meaning you are billed only for the resources you use. This can be particularly advantageous for businesses with fluctuating workloads or seasonal demands, as you can scale the FortiGate VM up or down as needed and avoid upfront costs.

- Flexibility: PAYG offers greater flexibility in terms of licensing. You have the option to start with PAYG and then switch to a BYOL model if your business requirements change. Both BYOL and PAYG have longer-term licensing for cost optimization, contact [azure@fortinet.com](mailto:azure@fortinet.com) for more information. Fortinet solutions for Azure also help draw down your Microsoft Azure Consumption Commitment (MACC)

- Lower Initial Investment: For organizations that are new to FortiGate or need to test the solution in their Azure environment, PAYG provides a lower entry barrier. There is no upfront capital expenditure on licenses, making it easier to evaluate FortiGate's performance and capabilities.

Bring your own license advantages:

- Cost Predictability: With BYOL, you have fixed license costs, which can be beneficial for organizations with stable workloads and well-defined infrastructure requirements. This model can offer more predictable budgeting and cost management.

- Cost Optimization: BYOL can offer cost optimization for longer running stable environments that do not require tweaking and changing due to fluctuating workloads.

- Contractual Agreements: Some organizations may have specific contractual agreements or special pricing arrangements with Fortinet for their licenses. BYOL allows them to maintain compliance with these agreements while deploying FortiGate in Azure.

The choice between PAYG and BYOL comes down to different factors within your organization:
- workload patterns
- budget considerations
- existing licensing agreements
- your preference for licensing management. 
It is advisable to assess your specific needs and consult with your IT and finance teams to determine the most suitable licensing model for your Azure-based FortiGate deployment.

## How to verify that I'm running PAYG

There are 2 locations to verify you are running PAYG.

- Login via Web UI or CLI on the FortiGate VM and verify the serial number. The serial number will start with 'FGTAZR'. In the CLI use the command 'get system status'. In the Web UI, the serial number can be found on the dashboard.

[Web UI serial number](faq-payg-web-u.png)

- Access to the Web UI or CLI can be limited, or it is required to verify that PAYG was uses during deployment, it is possible to retrieve this. Locate the FortiGate VM OsDisk in the Azure Portal and select export template. In de generated tempalte a field creationData will list the original disk image that was referenced. If PAYG was used this will be shown in the sku part of the reference.

[export template](faq-payg-export-template.png)

## Registering your PAYG license

It is important to register your PAYG license on [support.fortinet.com](https://support.fortinet.com/) to receive the included support. More information can be found on our [docs pages](https://docs.fortinet.com/document/fortigate-public-cloud/7.4.0/azure-administration-guide/533394/creating-a-support-account).

## Changing between PAYG and BYOL

When deploying a FortiGate-VM on public cloud, you determine the license type (pay as you go (PAYG) or bring your own license (BYOL)) during deployment. The license type is fixed for the VM's lifetime. The image that you use to deploy the FortiGate-VM on the public cloud marketplace predetermines the license type. Migrating a FortiGate-VM instance from one license type to another requires a new deployment. 

More information can be found [here](https://docs.fortinet.com/document/fortigate-public-cloud/7.4.0/azure-administration-guide/81283/migrating-a-fortigate-vm-instance-between-license-types)
