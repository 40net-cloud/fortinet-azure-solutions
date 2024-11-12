##############################################################################################################
#
# Fortinet FortiGate Terraform deployment template to deploy a IPSEC test setup
#
##############################################################################################################

# Prefix for all resources created for this deployment in Microsoft Azure
variable "prefix" {
  description = "Added name to each deployed resource"
}

variable "REGION" {
  description = "AWS region"
}

variable "username" {
  description = "Default username for FortiGate-VM in AWS is admin"
  default     = "admin"
}

variable "password" {
  description = "Default password for admin user is the instance id"
  default     = ""
}

//AWS Configuration
variable "AWS_ACCESS_KEY_ID" {
  description = "Your AWS Access Key ID"
  type        = string
  sensitive   = true
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "Your AWS Secret Key"
  type        = string
  sensitive   = true
}

//  Existing SSH Key on the AWS
variable "KEY_PAIR" {
}

##############################################################################################################
# FortiGate license type
##############################################################################################################

variable VERSION {
  default = "7.4.4"
}

variable "FGT_BYOL_LICENSE_FILE_A" {
  default = ""
}

variable "FGT_BYOL_LICENSE_FILE_B" {
  default = ""
}

variable "FGT_BYOL_FORTIFLEX_LICENSE_TOKEN_A" {
  default = ""
}

variable "FGT_BYOL_FORTIFLEX_LICENSE_TOKEN_B" {
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
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY

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

// instance type needs to match the architect
// c5n.xlarge is x86_64
// c6g.xlarge is arm
// For detail, refer to https://aws.amazon.com/ec2/instance-types/
variable "fgt_a_vmsize" {
  default = "c5n.xlarge"
}

variable "fgt_b_vmsize" {
  default = "c5n.xlarge"
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

variable "lnx_count" {
  default = 2
}

variable "lnx_vmsize" {
  default = "c5n.xlarge"
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

variable "fortinet_tags" {
  type = map(string)
  default = {
    publisher : "Fortinet",
    template : "IPSEC-test",
    provider : "7EB3B02F-50E5-4A3E-8CB8-2E129258IPSECTUNNELS"
  }
}

##############################################################################################################
