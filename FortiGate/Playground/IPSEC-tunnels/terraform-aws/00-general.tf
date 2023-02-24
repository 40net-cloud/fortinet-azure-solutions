##############################################################################################################
#
# FortiGate VM
# Terraform deployment template for AWS
#
##############################################################################################################

# Prefix for all resources created for this deployment in Microsoft Azure
variable "PREFIX" {
  description = "Added name to each deployed resource"
}

variable "REGION" {
  description = "AWS region"
}

variable "USERNAME" {
  description = "Default username for FortiGate-VM in AWS is admin"
  default     = "admin"
}

variable "PASSWORD" {
  description = "Default password for admin user is the instance id"
  default     = ""
}

//AWS Configuration
variable "ACCESS_KEY" {}
variable "SECRET_KEY" {}

//  Existing SSH Key on the AWS
variable "KEY_PAIR" {
}

##############################################################################################################
# FortiGate license type
##############################################################################################################

variable VERSION {
  default = "7.2.4"
}

variable "FGT_BYOL_LICENSE_FILE" {
  default = ""
}

variable "FGT_BYOL_FLEXVM_LICENSE" {
  default = ""
}

variable "FGT_SSH_PUBLIC_KEY_FILE" {
  default = ""
}

// License Type to create FortiGate-VM
// Provide the license type for FortiGate-VM Instances, either byol or payg.
variable "license_type" {
  default = "byol"
}

// instance architect
// Either arm64 or x86_64
variable "arch" {
  default = "x86_64"
}

variable "fgtlocator" {
  type = map(any)
  default = {
    payg = {
      arm64 = "FortiGate-VMARM64-AWSONDEMAND "
      x86_64 = "FortiGate-VM64-AWSONDEMAND "
    },
    byol = {
      arm64 = "FortiGate-VMARM64-AWS "
      x86_64 = "FortiGate-VM64-AWS "
    }
  }
}

data "aws_ami" "fgt_ami" {
  most_recent = true
  owners      = ["679593333241"] # Fortinet

  filter {
    name   = "name"
    values = ["${var.fgtlocator[var.license_type][var.arch]}*${var.VERSION}*"]
  }

  filter {
    name   = "architecture"
    values = [var.arch]
  }
}

data "aws_ami" "lnx_ami" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

##############################################################################################################
# Deployment in AWS
##############################################################################################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region     = var.REGION
  access_key = var.ACCESS_KEY
  secret_key = var.SECRET_KEY

  default_tags {
    tags = var.fortinet_tags
  }
}

// Availability zones for the region
locals {
  az1 = "${var.REGION}a"
}

##############################################################################################################
# Static variables
##############################################################################################################

variable "vpc" {
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
    "2" = "172.16.138.20" # PORT2
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
  default = "c5n.xlarge"
}

variable "lnx2_vmsize" {
  default = "c5n.xlarge"
}

// instance type needs to match the architect
// c5n.xlarge is x86_64
// c6g.xlarge is arm
// For detail, refer to https://aws.amazon.com/ec2/instance-types/
variable "fgt_vmsize" {
  default = "c5n.xlarge"
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
