##############################################################################################################
#
# FortiAnalyzer VM
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

variable "username" {
}

variable "password" {
}

variable "subscription_id" {}

##############################################################################################################
# FortiAnalyzer license type
##############################################################################################################

variable "FAZ_IMAGE_SKU" {
  description = "Azure Marketplace default image byol (Bring your own license 'fortinet-fortianalyzer')"
  default     = "fortinet-fortianalyzer"
}

variable "FAZ_VERSION" {
  description = "FortiAnalyzer version by default the 'latest' available version in the Azure Marketplace is selected"
  default     = "latest"
}

variable "FAZ_BYOL_LICENSE_FILE" {
  default = ""
}

variable "FAZ_BYOL_FORTIFLEX_LICENSE_TOKEN" {
  default = ""
}

variable "FAZ_SSH_PUBLIC_KEY_FILE" {
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
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

##############################################################################################################
# Accept the Terms license for the FortiGate Marketplace image
# This is a one-time agreement that needs to be accepted per subscription
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/marketplace_agreement
##############################################################################################################
#resource "azurerm_marketplace_agreement" "fortinet" {
#  publisher = "fortinet"
#  offer     = "fortinet-fortianalyzer"
#  plan      = var.FAZ_IMAGE_SKU
#}

##############################################################################################################
# Static variables
##############################################################################################################

variable "vnet" {
  description = ""
  default     = "172.16.140.0/24"
}

variable "subnet" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.140.0/26" # FAZ network
  }
}

variable "subnetmask" {
  type        = map(string)
  description = ""

  default = {
    "1" = "26" # FAZ network
  }
}

variable "faz_ipaddress_a" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.140.4" # FAZ network
  }
}

variable "gateway_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.140.1" # FAZ network
  }
}

variable "faz_vmsize" {
  default = "Standard_D2s_v3"
}

variable "fortinet_tags" {
  type = map(string)
  default = {
    publisher : "Fortinet",
    template : "FortiAnalyzer-Terraform",
    provider : "6EB3B02F-50E5-4A3E-8CB8-2E1292583FAZ"
  }
}

##############################################################################################################
# Resource Group
##############################################################################################################

resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.prefix}-rg"
  location = var.location
}

##############################################################################################################
