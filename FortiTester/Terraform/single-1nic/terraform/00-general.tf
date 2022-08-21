##############################################################################################################
#
# FortiTester VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

# Prefix for all resources created for this deployment in Microsoft Azure
variable "PREFIX" {
  description = "Added name to each deployed resource"
}

variable "LOCATION" {
  description = "Azure region"
}

variable "USERNAME" {
}

variable "PASSWORD" {
}

variable "FTSOSDISKVHDURI" {
  description = "Link to a FortiTester VHD expanded and stored in an Azure Storage Account."
}

##############################################################################################################
# FortiTester license type
##############################################################################################################

variable "FTS_IMAGE_SKU" {
  description = "Azure Marketplace image byol (Bring your own license 'fts-vm-byol')"
  default     = "fts-vm-byol"
}

variable "FTS_VERSION" {
  description = "FortiTester version by default the 'latest' available version in the Azure Marketplace is selected"
  default     = "latest"
}

variable "FTS_BYOL_LICENSE_FILE" {
  default = ""
}

variable "FTS_SSH_PUBLIC_KEY_FILE" {
  default = ""
}

##############################################################################################################
# FortiGate license type
##############################################################################################################

variable "FGT_IMAGE_SKU" {
  description = "Azure Marketplace default image sku hourly (PAYG 'fortinet_fg-vm_payg_2022') or byol (Bring your own license 'fortinet_fg-vm')"
  default     = "fortinet_fg-vm"
}

variable "FGT_VERSION" {
  description = "FortiGate version by default the 'latest' available version in the Azure Marketplace is selected"
  default     = "latest"
}

variable "FGT_BYOL_LICENSE_FILE" {
  default = ""
}

variable "FGT_BYOL_FLEXVM_LICENSE_FILE" {
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

variable "fts_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.4"  # FTS network
    "2" = "172.16.137.20" # FTS network
    "3" = "172.16.138.20" # FTS network
  }
}

variable "fgt_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1"  = "172.16.136.10" # MGMT
    "2a" = "172.16.137.10" # PORT 1
    "3"  = "172.16.138.10" # PORT 2
    "2b" = "172.16.137.11" # PORT 1
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

variable "fts_vmsize" {
  default = "Standard_DS3_v2"
}

variable "fgt_vmsize" {
  default = "Standard_F4s"
}

variable "fortinet_tags" {
  type = map(string)
  default = {
    publisher : "Fortinet",
    template : "FortiTester",
    provider : "7EB3B02F-50E5-4A3E-8CB8-2E129258FTS"
  }
}

##############################################################################################################
# Resource Group
##############################################################################################################

resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.PREFIX}-RG"
  location = var.LOCATION
}

##############################################################################################################
