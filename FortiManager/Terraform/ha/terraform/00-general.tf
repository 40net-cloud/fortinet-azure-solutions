##############################################################################################################
#
# FortiManager - a standalone FortiManager VM
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

##############################################################################################################
# FortiManager license type
##############################################################################################################

variable "FMG_IMAGE_SKU" {
  description = "Azure Marketplace default image byol (Bring your own license 'fortinet-fortimanager)"
  default     = "fortinet-fortimanager"
}

variable "FMG_VERSION" {
  description = "FortiManager version by default the 'latest' available version in the Azure Marketplace is selected"
  default     = "latest"
}

variable "FMG_A_BYOL_LICENSE_FILE" {
  default = ""
}

variable "FMG_B_BYOL_LICENSE_FILE" {
  default = ""
}

variable "FMG_A_BYOL_FORTIFLEX_LICENSE_TOKEN" {
  default = ""
}

variable "FMG_B_BYOL_FORTIFLEX_LICENSE_TOKEN" {
  default = ""
}

variable "FMG_A_BYOL_SERIAL_NUMBER" {
  default = ""
}

variable "FMG_B_BYOL_SERIAL_NUMBER" {
  default = ""
}

variable "FMG_SSH_PUBLIC_KEY_FILE" {
  default = ""
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
    random = {
      source = "hashicorp/random"
      version = ">=2.3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_string" "random" {
  length = 8
  special = false
  upper = false
}

##############################################################################################################
# Accept the Terms license for the FortiManager Marketplace image
# This is a one-time agreement that needs to be accepted per subscription
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/marketplace_agreement
##############################################################################################################
#resource "azurerm_marketplace_agreement" "fortinet" {
#  publisher = "fortinet"
#  offer     = "fortinet-fortimanager"
#  plan      = var.FMG_IMAGE_SKU
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
    "1" = "172.16.137.0/24" # FMG network
  }
}

variable "subnetmask" {
  type        = map(string)
  description = ""

  default = {
    "1" = "24" # FMG network
  }
}

variable "fmg_a_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.137.5" # FMG network
  }
}

variable "fmg_b_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.137.6" # FMG network
  }
}

variable "gateway_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.137.1" # FMG network
  }
}

variable "fmg_vmsize" {
  default = "Standard_D2s_v3"
}

variable "fortinet_tags" {
  type = map(string)
  default = {
    publisher : "Fortinet",
    template : "FortiManager-Terraform-HA",
    provider : "7EB3B02F-50E5-4A3E-8CB8-2E129258FMGHA"
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
