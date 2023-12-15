##############################################################################################################
#
# Fortinet FortiGate Terraform deployment 
# Azure Virtual WAN NVA deployment
#
##############################################################################################################
# Variables
##############################################################################################################

# Prefix for all resources created for this deployment in Microsoft Azure
variable "PREFIX" {
  description = "Added name to each deployed resource"
}

variable "LOCATION" {
  description = "Azure region"
}

variable "USERNAME" {}

variable "PASSWORD" {}

##############################################################################################################
# Deployment in Microsoft Azure
##############################################################################################################
terraform {
  required_version = ">= 0.12"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.12.0"
    }
  }
}

provider "azurerm" {
  features {}
}

##############################################################################################################
# Variables
##############################################################################################################

# Azure Virtual WAN NVA sku 'fortinet-sdwan-and-ngfw' or 'fortinet-ngfw'
variable "fgt_sku" {
  default = "fortinet-ngfw"
}

variable "fgt_scaleunit" {
  default = "2"
}

variable "fgt_license_file_byol" {
  default = ""
}

variable "fgt_license_token_fortiflex" {
  default = ""
}

variable "fgt_customdata" {
  default = ""
}

variable "tags" {
  type        = map(string)
  description = "A map of tags added to the deployed resources"

  default = {
    "environment"  = "VirtualWAN-FortiGate"
    "publisher"    = "Fortinet"
    "FTNT-CREATOR" = "jvanhoof@fortinet-us.com"
  }
}

variable "vnet_vhub" {
  default = "172.16.120.0/24"
}

variable "vnet" {
  type        = map(string)
  description = ""

  default = {
    "spoke1" = "172.16.121.0/24"
    "spoke2" = "172.16.122.0/24"
  }
}

variable "spoke_subnet" {
  type        = map(string)
  description = ""

  default = {
    "spoke1" = "172.16.121.0/26"
    "spoke2" = "172.16.122.0/26"
  }
}

variable "fmg_host" {
  type = string

  default = "fmg.jvh.be"
}

variable "fmg_serial" {
  type = string

  default = "FMG-VMTM22015743"
}

variable "fgt_asn" {
  type = string

  default = "65007"
}

variable "fgt_version" {
  description = "FortiGate version by default the 'latest' available version in the Azure Marketplace is selected"
  default     = "7.4.0"
}

##############################################################################################################
# Virtual Machines sizes
##############################################################################################################

variable "lnx_vmsize" {
  default = "Standard_B1s"
}
