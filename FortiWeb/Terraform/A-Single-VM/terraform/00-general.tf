##############################################################################################################
#
# FortiWeb a standalone FortiWeb VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

# Prefix for all resources created for this deployment in Microsoft Azure
variable "prefix" {
  description = "Added name to each deployed resource"
}

variable "location" {
  description = "Azure region"
}

variable "username" {}

variable "password" {}

variable "subscription_id" {}

##############################################################################################################
# FortiWeb license type
##############################################################################################################

variable "FWB_IMAGE_SKU" {
  description = "Azure Marketplace default image sku hourly (PAYG 'fortinet_fw-vm_payg_v3') or byol (Bring your own license 'fortinet_fw-vm')"
  default     = "fortinet_fw-vm_payg_v3"
}

variable "FWB_VERSION" {
  description = "FortiWeb version by default the 'latest' available version in the Azure Marketplace is selected"
  default     = "7.4.0"
}

variable "FWB_BYOL_LICENSE_FILE" {
  default = ""
}

variable "FWB_BYOL_FORTIFLEX_LICENSE_TOKEN" {
  default = ""
}

variable "FWB_SSH_PUBLIC_KEY_FILE" {
  default = ""
}

##############################################################################################################
# Accelerated Networking
# Only supported on specific VM series and CPU count: D/DSv2, D/DSv3, E/ESv3, F/FS, FSv2, and Ms/Mms
# https://azure.microsoft.com/en-us/blog/maximize-your-vm-s-performance-with-accelerated-networking-now-generally-available-for-both-windows-and-linux/
##############################################################################################################
variable "FWB_ACCELERATED_NETWORKING" {
  description = "Enables Accelerated Networking for the network interfaces of the FortiWeb"
  default     = "false"
}

##############################################################################################################
# Deployment in Microsoft Azure
##############################################################################################################

terraform {
  required_version = ">= 0.12"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

##############################################################################################################
# Accept the Terms license for the FortiWeb Marketplace image
# This is a one-time agreement that needs to be accepted per subscription
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/marketplace_agreement
##############################################################################################################
#resource "azurerm_marketplace_agreement" "fortinet" {
#  publisher = "fortinet"
#  offer     = "fortinet_fortiweb-vm_v5"
#  plan      = var.FWB_IMAGE_SKU
#}

##############################################################################################################
# Static variables
##############################################################################################################

variable "vnet" {
  description = ""
  default     = "172.16.136.0/22"
}

variable "subnet" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.0/26"  # External
    "2" = "172.16.136.64/26" # Internal
  }
}

variable "subnetmask" {
  type        = map(string)
  description = ""

  default = {
    "1" = "26" # External
    "2" = "26" # Internal
  }
}

variable "fwb_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.4"  # External
    "2" = "172.16.136.68" # Internal
  }
}

variable "gateway_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.1"  # External
    "2" = "172.16.136.65" # Internal
  }
}

variable "fwb_vmsize" {
  default = "Standard_F2s"
}

variable "fortinet_tags" {
  type = map(string)
  default = {
    publisher : "Fortinet",
    template : "A-Single-VM",
    provider : "7EB3B02F-50E5-4A3E-8CB8-2E129258FWB"
  }
}

##############################################################################################################
# Resource Group
##############################################################################################################

resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.prefix}-RG"
  location = var.location
}

##############################################################################################################
