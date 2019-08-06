##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
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
# FortiGate license type
##############################################################################################################

variable "IMAGESKU" {
  description = "Azure Marketplace Image SKU hourly (PAYG) or byol (Bring your own license)"
  default = "fortinet_fg-vm"
}

variable "FGT_LICENSE_FILE_A" {
  default = ""
}

variable "FGT_LICENSE_FILE_B" {
  default = ""
}

variable "FGT_SSH_PUBLIC_KEY_FILE" {
  default = ""
}

##############################################################################################################
# Microsoft Azure Storage Account for storage of Terraform state file
##############################################################################################################

terraform {
  required_version = ">= 0.11"
}

##############################################################################################################
# Deployment in Microsoft Azure
##############################################################################################################

provider "azurerm" {
}

##############################################################################################################
# Static variables
##############################################################################################################

variable "vnet" {
  type        = "map"
  description = ""

  default = {
    "a" = "172.16.136.0/22"
    "b" = "172.16.140.0/22"
  }
}

variable "subnet_fgt_external" {
  type        = "map"
  description = ""

  default = {
    "a" = "172.16.136.0/24"
    "b" = "172.16.140.0/24"
  }
}

variable "subnet_fgt_internal" {
  type        = "map"
  description = ""

  default = {
    "a"  = "172.16.137.0/24"
    "b" = "172.16.141.0/24"
  }
}

variable "subnet_protected" {
  type        = "map"
  description = ""

  default = {
    "a"  = "172.16.138.0/24"
    "b" = "172.16.142.0/24"
  }
}

variable "fgt_external_ipaddress" {
  type        = "map"
  description = ""

  default = {
    "a"  = "172.16.136.5"
    "b" = "172.16.140.5"
  }
}

variable "fgt_external_subnetmask" {
  type        = "map"
  description = ""

  default = {
    "a"  = "24"
    "b" = "24"
  }
}

variable "fgt_external_gateway" {
  type        = "map"
  description = ""

  default = {
    "a"  = "172.16.136.1"
    "b" = "172.16.140.1"
  }
}

variable "fgt_internal_ipaddress" {
  type        = "map"
  description = ""

  default = {
    "a"  = "172.16.137.5"
    "b" = "172.16.141.5"
  }
}

variable "fgt_internal_subnetmask" {
  type        = "map"
  description = ""

  default = {
    "a"  = "24"
    "b" = "24"
  }
}

variable "fgt_internal_gateway" {
  type        = "map"
  description = ""

  default = {
    "a"  = "172.16.137.1"
    "b" = "172.16.141.1"
  }
}

variable "backend_srv_ipaddress" {
  type        = "map"
  description = ""

  default = {
    "a"  = "172.16.138.5"
    "b" = "172.16.142.5"
  }
}

##############################################################################################################
# Virtual Machines sizes
##############################################################################################################

variable "fgt_vmsize" {
  default = "Standard_F4s"
}

variable "lnx_vmsize" {
  default = "Standard_D4s_v3"
}

##############################################################################################################
# Resource Groups
##############################################################################################################

resource "azurerm_resource_group" "resourcegroupa" {
  name     = "${var.PREFIX}-A-RG"
  location = "${var.LOCATION}"
}

resource "azurerm_resource_group" "resourcegroupb" {
  name     = "${var.PREFIX}-B-RG"
  location = "${var.LOCATION}"
}
##############################################################################################################

##############################################################################################################
# Generate IPSEC PSK key for VPN tunnel between FGT A and B
##############################################################################################################

resource "random_string" "ipsec_psk" {
  length = 16
  special = true
}
##############################################################################################################
