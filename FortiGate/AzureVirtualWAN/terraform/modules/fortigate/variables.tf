##############################################################################################################
#
# Fortinet FortiGate Terraform deployment
# Azure Virtual WAN NVA deployment
#
##############################################################################################################
# Variables
##############################################################################################################
variable "prefix" {}
variable "name" {}
variable "location" {}
variable "resource_group_name" {}
variable "username" {}
variable "password" {}
variable "sku" {}
variable "scaleunit" {}
variable "mpversion" {}
variable "asn" {}
variable "tags" {}
variable "fmg_host" {}
variable "fmg_serial" {}
variable "vhub_id" {}
variable "vhub_virtual_router_ip1" {}
variable "vhub_virtual_router_ip2" {}
variable "vhub_virtual_router_asn" {}
variable "license_file_byol" {
  default = ""
}
variable "license_token_fortiflex" {
  default = ""
}
variable "customdata" {
  default = ""
}

##############################################################################################################
# Provider
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
