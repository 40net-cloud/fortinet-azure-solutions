###############################################################################################################
#
# Cloud Security Services Hub
# using VNET peering and FortiGate Active/Passive High Availability with Azure Standard Load Balancer - External and Internal
# Fortinet FortiGate Terraform deployment template
#
##############################################################################################################
#
# Input variables
#
##############################################################################################################

# Prefix for all resources created for this deployment in Microsoft Azure
variable "PREFIX" {
  description = "Added name to each deployed resource"
}

# Azure region
variable "AZURE_LOCATION" {
  description = "Azure region"
}

variable "USERNAME" {
}

variable "PASSWORD" {
}

# GCP region
variable "GCP_REGION" {
  type = string
}

# GCP zone 1
variable "GCP_ZONE1" {
  type = string
}

# GCP zone 2
variable "GCP_ZONE2" {
  type = string
}

# GCP project name
variable "project" {
  type    = string
  default = "infra-lodge-268907"
}

# GCP service account JSON file.
variable "account" {
  type    = string
  default = "~/.ssh/infra-lodge-268907-645e17abb2a9.json"
}

##############################################################################################################
# FortiGate variables
##############################################################################################################

variable "FGT_IMAGE_SKU" {
  description = "Azure Marketplace default image sku hourly (PAYG 'fortinet_fg-vm_payg_2022') or byol (Bring your own license 'fortinet_fg-vm')"
  default     = "fortinet_fg-vm_payg_2022"
}

variable "FGT_VERSION" {
  description = "FortiGate version by default the 'latest' available version in the Azure Marketplace is selected"
  default     = "latest"
}

variable "FGT_BYOL_LICENSE_FILE_A" {
  default = ""
}

variable "FGT_BYOL_LICENSE_FILE_B" {
  default = ""
}
# license file for active
variable "GCP_FGT_BYOL_LICENSE_FILE_A" {
  type    = string
  default = "FGVM4VTM20000326.lic"
}
# license file for passive
variable "GCP_FGT_BYOL_LICENSE_FILE_B" {
  type    = string
  default = "FGVM4VTM20000327.lic"
}

variable "FGT_SSH_PUBLIC_KEY_FILE" {
  default = ""
}

# FortiGate Image name
# 6.4.2 payg is projects/fortigcp-project-001/global/images/fortinet-fgtondemand-642-20200810-001-w-license
# 6.4.2 byol is projects/fortigcp-project-001/global/images/fortinet-fgt-642-20200810-001-w-license
variable "image" {
  type    = string
  default = "projects/fortigcp-project-001/global/images/fortinet-fgt-642-20200810-001-w-license"
}

# GCP instance machine type
variable "machine" {
  type    = string
  default = "n1-standard-4"
}

##############################################################################################################
# Accelerated Networking
# Only supported on specific VM series and CPU count: D/DSv2, D/DSv3, E/ESv3, F/FS, FSv2, and Ms/Mms
# https://azure.microsoft.com/en-us/blog/maximize-your-vm-s-performance-with-accelerated-networking-now-generally-available-for-both-windows-and-linux/
##############################################################################################################
variable "FGT_ACCELERATED_NETWORKING" {
  description = "Enables Accelerated Networking for the network interfaces of the FortiGate"
  default     = "true"
}

##############################################################################################################
# Terraform provider configuration
##############################################################################################################

terraform {
  required_version = ">=0.12"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~>3.45.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~>3.45.0"
    }
    random = {
      source = "hashicorp/random"
    }
    template = {
      source = "hashicorp/template"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "google" {
  credentials = file(var.account)
  project     = var.project
  region      = var.GCP_REGION
  zone        = var.GCP_ZONE1
}

provider "google-beta" {
  credentials = file(var.account)
  project     = var.project
  region      = var.GCP_REGION
  zone        = var.GCP_ZONE1
}

# Randomize string to avoid duplication
resource "random_string" "random_name_post" {
  length           = 3
  special          = true
  override_special = ""
  min_lower        = 3
}

##############################################################################################################
# Static variables - Azure HUB network
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

variable "fortinet_tags" {
  type = map(any)
  default = {
    publisher : "Fortinet",
    template : "VNET Peering",
    provider : "7EB3B02F-50E5-4A3E-8CB8-2E12925831AB-VNETPeering"
  }
}

##############################################################################################################
# Static variables - SPOKE 1 network
##############################################################################################################

variable "vnetspoke1" {
  description = ""
  default     = "172.16.140.0/24"
}

variable "subnetspoke1" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.140.0/26" # SUBNET 1 in SPOKE 1
  }
}

##############################################################################################################
# Static variables - SPOKE 2 network
##############################################################################################################

variable "vnetspoke2" {
  description = ""
  default     = "172.16.142.0/24"
}

variable "subnetspoke2" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.142.0/26" # SUBNET 1 in SPOKE 2
  }
}

##############################################################################################################
# Static variables - GCP HUB network
##############################################################################################################

variable "gcp_vpc" {
  description = ""
  default     = "172.16.148.0/22"
}

variable "gcp_subnet" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.148.0/26"   # External
    "2" = "172.16.148.64/26"  # Internal
    "3" = "172.16.148.128/26" # HASYNC
    "4" = "172.16.148.192/26" # MGMT
    "5" = "172.16.137.0/24"   # Protected a
    "6" = "172.16.138.0/24"   # Protected b
  }
}

variable "gcp_subnetmask" {
  type        = map(string)
  description = ""

  default = {
    "1" = "255.255.255.192" # External
    "2" = "255.255.255.192" # Internal
    "3" = "255.255.255.192" # HASYNC
    "4" = "255.255.255.192" # MGMT
    "5" = "255.255.255.0"   # Protected a
    "6" = "255.255.255.0"   # Protected b
  }
}

variable "gcp_fgt_ipaddress_a" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.148.5"   # External
    "2" = "172.16.148.69"  # Internal
    "3" = "172.16.148.133" # HASYNC
    "4" = "172.16.148.197" # MGMT
  }
}

variable "gcp_fgt_ipaddress_b" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.148.6"   # External
    "2" = "172.16.148.70"  # Internal
    "3" = "172.16.148.134" # HASYNC
    "4" = "172.16.148.198" # MGMT
  }
}

variable "gcp_gateway_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.148.1"   # External
    "2" = "172.16.148.65"  # Internal
    "3" = "172.16.148.133" # HASYNC
    "4" = "172.16.148.193" # MGMT
  }
}

variable "gcp_lb_internal_ipaddress" {
  description = ""

  default = "172.16.148.68"
}

##############################################################################################################
# Static variables - GCP SPOKE 2 network
##############################################################################################################

# Spoke1 Subnet CIDR
variable "spoke1_subnet" {
  type    = string
  default = "172.16.149.0/24"
}
# Spoke2 Subnet CIDR
variable "spoke2_subnet" {
  type    = string
  default = "172.16.150.0/24"
}

##############################################################################################################
# Resource Group
##############################################################################################################

resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.PREFIX}-RG"
  location = var.AZURE_LOCATION
}

##############################################################################################################
# Retrieve my client public IP for REST API ACL
##############################################################################################################

data "http" "client_ip" {
  url = "http://w.jvh.be/ip"
}

##############################################################################################################