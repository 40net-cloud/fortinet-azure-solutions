# Frequently Asked Questions

1. [Outbound SMTP in Public Cloud](#faq-1-outbound-smtp-restrictions)

## FAQ #1: Outbound SMTP restrictions

Public Cloud providers have restrictions on outbound connections from a deployed VM or VM ScaleSets. In general, CSPs suggest to use relay services SendGrid, Mailgin, Mailjet or your mailsystems like Microsoft 365, Google Workspace. All CSPs also offers the possibility to remove these restrictions after verification via their support services. More information per CSP can be found here:

- [Azure](https://docs.microsoft.com/en-us/azure/virtual-network/troubleshoot-outbound-smtp-connectivity)
- [AWS](https://aws.amazon.com/premiumsupport/knowledge-center/ec2-port-25-throttle/)
- [GCP](https://cloud.google.com/compute/docs/tutorials/sending-mail)
- [OCI](https://docs.oracle.com/en-us/iaas/releasenotes/changes/f7e95770-9844-43db-916c-6ccbaf2cfe24/)
