##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
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
  description = "Azure Marketplace Image SKU hourly (PAYG) or byol (Bring your own license)"
  default     = "fortinet_fg-vm"
}

variable "FGT_VERSION" {
  description = "FortiGate version by default the 'latest' available version in the Azure Marketplace is selected"
  default     = "7.4.4"
}

variable "FGT_BYOL_LICENSE_FILE_A" {
  default = ""
}

variable "FGT_BYOL_FORTIFLEX_LICENSE_TOKEN_A" {
  default = ""
}

variable "FGT_BYOL_LICENSE_FILE_B" {
  default = ""
}

variable "FGT_BYOL_FORTIFLEX_LICENSE_TOKEN_B" {
  default = ""
}

##############################################################################################################
# VM options
##############################################################################################################

variable "FGT_SSH_PUBLIC_KEY_FILE" {
  default = ""
}

variable "ACCELERATED_NETWORKING" {
  type        = string
  description = "(Optional) Enable/Disable accelerated networking (default: true)"
  default     = "true"
}

variable "TAGS" {
  type        = map(string)
  description = "A map of tags added to the deployed resources"

  default = {
    "environment" = "IPSEC-test"
    "publisher"   = "Fortinet"
    "FTNT-CREATOR" = "user@domain.com"
  }
}

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
  subscription_id = var.subscription_id
}

##############################################################################################################
# Static variables
##############################################################################################################

variable "vnet" {
  type        = map(string)
  description = ""

  default = {
    "a" = "172.16.136.0/24"
    "b" = "172.16.137.0/24"
  }
}

variable "subnet_fgt_external" {
  type        = map(string)
  description = ""

  default = {
    "a" = "172.16.136.0/26"
    "b" = "172.16.137.0/26"
  }
}

variable "subnet_fgt_internal" {
  type        = map(string)
  description = ""

  default = {
    "a" = "172.16.136.64/26"
    "b" = "172.16.137.64/26"
  }
}

variable "subnet_protected" {
  type        = map(string)
  description = ""

  default = {
    "a" = "172.16.136.128/26"
    "b" = "172.16.137.128/26"
  }
}

##############################################################################################################
# Virtual Machines sizes
##############################################################################################################

variable "fgt_a_vmsize" {
  default = "Standard_D16s_v5"
}

variable "fgt_b_vmsize" {
  default = "Standard_D16s_v5"
}

# Change cpumask depending on instance type: 
# 4 core = f
# 8 core = ff
# 16 core = ffff
variable "fgt_a_cpumask" {
  default = "ffff"
}

variable "fgt_b_cpumask" {
  default = "ffff"
}

variable "lnx_vmsize" {
  default = "Standard_D4s_v4"
}

variable "lnx_count" {
  default = 2
}

##############################################################################################################
# Resource Groups
##############################################################################################################

resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.prefix}-rg"
  location = var.location

  tags = var.TAGS

  lifecycle {
    ignore_changes = [
      tags["CreatedOnDate"], tags["FTNT-CREATOR"],
    ]
  }
}

##############################################################################################################
# Storage Accounts for boot diagnostics
##############################################################################################################

resource "random_id" "saname" {

  byte_length = 6
}

##############################################################################################################
# Generate IPSEC PSK key for VPN tunnel between FGT A and B
##############################################################################################################

resource "random_string" "ipsec_psk" {
  length  = 16
  special = true
}
##############################################################################################################

locals {
  fgt_external_ipcount = 32
  fgt_a_prefix         = "${var.prefix}-fgt-a"
  fgt_a_vm_name        = "${local.fgt_a_prefix}-vm"
  fgt_a_private_ip_address_ext = cidrhost(var.subnet_fgt_external["a"], 5)
  fgt_a_private_ip_address_int = cidrhost(var.subnet_fgt_internal["a"], 5)
  fgt_b_prefix         = "${var.prefix}-fgt-b"
  fgt_b_vm_name        = "${local.fgt_b_prefix}-vm"
  fgt_b_private_ip_address_ext = cidrhost(var.subnet_fgt_external["b"], 5)
  fgt_b_private_ip_address_int = cidrhost(var.subnet_fgt_internal["b"], 5)
}

##############################################################################################################
