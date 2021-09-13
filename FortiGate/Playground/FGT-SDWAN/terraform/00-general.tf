##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template
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
  default     = "fortinet_fg-vm"
}

variable "FGT_LICENSE_LOCATION" {
  default = ""
}

variable "FGT_LICENSE_FILE_A" {
  default = ""
}

variable "FGT_LICENSE_FILE_B" {
  default = ""
}

variable "FGT_LICENSE_FILE_C" {
  default = ""
}

variable "FGT_LICENSE_FILE_D" {
  default = ""
}

variable "FGT_SSH_PUBLIC_KEY_FILE" {
  default = ""
}

##############################################################################################################
# Microsoft Azure Storage Account for storage of Terraform state file
##############################################################################################################

terraform {
  required_version = ">= 0.12"
}

##############################################################################################################
# Deployment in Microsoft Azure
##############################################################################################################

provider "azurerm" {
}

##############################################################################################################
# Static variables - HUB network
##############################################################################################################

variable "vnet" {
  description = ""
  default     = "172.16.136.0/22"
}

variable "subnet" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.0/26"   # External
    "2" = "172.16.136.64/26"  # Internal
    "3" = "172.16.136.128/26" # HASYNC
    "4" = "172.16.136.192/26" # MGMT
    "5" = "172.16.137.0/24"   # Protected a
    "6" = "172.16.138.0/24"   # Protected b
  }
}

variable "subnetmask" {
  type        = map(string)
  description = ""

  default = {
    "1" = "26" # External
    "2" = "26" # Internal
    "3" = "26" # HASYNC
    "4" = "26" # MGMT
    "5" = "24" # Protected a
    "6" = "24" # Protected b
  }
}

variable "fgt_ipaddress_a" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.5"   # External
    "2" = "172.16.136.69"  # Internal
    "3" = "172.16.136.133" # HASYNC
    "4" = "172.16.136.197" # MGMT
  }
}

variable "fgt_ipaddress_b" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.6"   # External
    "2" = "172.16.136.70"  # Internal
    "3" = "172.16.136.134" # HASYNC
    "4" = "172.16.136.198" # MGMT
  }
}

variable "gateway_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.1"   # External
    "2" = "172.16.136.65"  # Internal
    "3" = "172.16.136.133" # HASYNC
    "4" = "172.16.136.193" # MGMT
  }
}

variable "lb_internal_ipaddress" {
  description = ""

  default = "172.16.136.68"
}

variable "fgt_vmsize" {
  default = "Standard_F4s"
}

##############################################################################################################
# Static variables - BRANCH 1 network
##############################################################################################################

variable "vnetbranch1" {
  description = ""
  default     = "172.16.140.0/23"
}

variable "subnetbranch1" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.140.0/26"   # SUBNET 1 in BRANCH 1
    "2" = "172.16.140.64/26"  # SUBNET 2 in BRANCH 1
    "3" = "172.16.140.128/26" # SUBNET 3 in BRANCH 1
    "4" = "172.16.141.0/26"   # SUBNET 4 in BRANCH 1
    "5" = "172.16.141.64/26"  # SUBNET 5 in BRANCH 1
  }
}

variable "fgt_ipaddress_branch1" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.140.5"   # External
    "2" = "172.16.140.69"  # External2
    "3" = "172.16.140.132" # Internal
  }
}

variable "gateway_ipaddress_branch1" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.140.1"   # External
    "2" = "172.16.140.65"  # External2
    "3" = "172.16.140.129" # Internal
  }
}

##############################################################################################################
# Static variables - BRANCH 2 network
##############################################################################################################

variable "vnetbranch2" {
  description = ""
  default     = "172.16.142.0/23"
}

variable "subnetbranch2" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.142.0/26"   # SUBNET 1 in BRANCH 2
    "2" = "172.16.142.64/26"  # SUBNET 2 in BRANCH 2
    "3" = "172.16.142.128/26" # SUBNET 3 in BRANCH 2
    "4" = "172.16.143.0/26"   # SUBNET 4 in BRANCH 2
    "5" = "172.16.143.64/26"  # SUBNET 4 in BRANCH 2
  }
}

variable "fgt_ipaddress_branch2" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.142.5"   # External
    "2" = "172.16.142.69"  # External2
    "3" = "172.16.142.132" # Internal
  }
}

variable "gateway_ipaddress_branch2" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.142.1"   # External
    "2" = "172.16.142.65"  # External2
    "2" = "172.16.142.129" # Internal
  }
}

##############################################################################################################
# Static variables - FMG network
##############################################################################################################

variable "vnetfmg" {
  description = ""
  default     = "172.16.144.0/23"
}

variable "subnetfmg" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.144.0/26"  # SUBNET 1 in BRANCH 2
    "2" = "172.16.144.64/26" # SUBNET 2 in BRANCH 2
  }
}

variable "fmg_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.145.5" # External
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

##############################################################################################################
# Retrieve client public IP for Rest API ACL
##############################################################################################################

data "external" "client_public_ip" {
  program = ["sh", "${path.module}/get-public-ip.sh"]
}

output "ip" {
  value = data.external.client_public_ip.result["ip"]
}
##############################################################################################################

##############################################################################################################
# Generate random key for api usage
##############################################################################################################

resource "random_string" "fgt_api_key" {
  length  = 16
  special = true
}
##############################################################################################################