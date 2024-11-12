##############################################################################################################
#
# FortiGate VM
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
# FortiGate license type
##############################################################################################################

variable "FGT_IMAGE_SKU" {
  description = "Azure Marketplace default image sku hourly (PAYG 'fortinet_fg-vm_payg_2023') or byol (Bring your own license 'fortinet_fg-vm')"
  default     = "fortinet_fg-vm"
}

variable "FGT_VERSION" {
  description = "FortiGate version by default the 'latest' available version in the Azure Marketplace is selected"
  default     = "latest"
}

variable "FGT_BYOL_LICENSE_FILE" {
  default = ""
}

variable "FGT_BYOL_FORTIFLEX_LICENSE_TOKEN" {
  default = ""
}

variable "FGT_SSH_PUBLIC_KEY_FILE" {
  default = ""
}

##############################################################################################################
# Accelerated Networking
# Only supported on specific VM series and CPU count: D/DSv2, D/DSv3, E/ESv3, F/FS, FSv2, and Ms/Mms
# https://azure.microsoft.com/en-us/blog/maximize-your-vm-s-performance-with-accelerated-networking-now-generally-available-for-both-windows-and-linux/
##############################################################################################################
variable "ACCELERATED_NETWORKING" {
  description = "Enables Accelerated Networking for the network interfaces of the FortiGate"
  default     = "true"
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
# Static variables
##############################################################################################################

variable "vnet" {
  default     = "172.16.136.0/22"
  description = ""
}

variable "subnet" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.0/24" # MGMT
    "2" = "172.16.137.0/24" # PORT 1
    "3" = "172.16.138.0/24" # PORT 2
  }
}

variable "subnetmask" {
  type        = map(string)
  description = ""

  default = {
    "1" = "24" # MGMT
    "2" = "24" # PORT1
    "3" = "24" # PORT2
  }
}

variable "lnx_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.4"  # MGMT
    "2" = "172.16.137.20" # PORT1
  }
}

variable "lnx2_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.5"  # MGMT
    "2" = "172.16.138.20" # PORT1
  }
}

variable "fgt_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.10" # MGMT
    "2" = "172.16.137.10" # PORT 1
    "3" = "172.16.138.10" # PORT 2
  }
}

variable "gateway_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.1" # MGMT
    "2" = "172.16.137.1" # PORT 1
    "3" = "172.16.138.1" # PORT 2
  }
}

variable "lnx_vmsize" {
  default = "Standard_D4as_v5"
}

variable "lnx2_vmsize" {
  default = "Standard_D4as_v5"
}

variable "fgt_vmsize" {
  default = "Standard_D8as_v5"
}

variable "fortinet_tags" {
  type = map(string)
  default = {
    publisher : "Fortinet",
    template : "IPSEC-tunnels",
    provider : "7EB3B02F-50E5-4A3E-8CB8-2E129258IPSECTUNNELS"
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
