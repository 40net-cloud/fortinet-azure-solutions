# JVH prefix
variable "prefix" {
  type    = string
  default = "jvh"
}
# GCP region
variable "region" {
  type    = string
  default = "europe-west1" #Default Region
}
# GCP zone
variable "zone" {
  type    = string
  default = "europe-west1-c" #Default Zone
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
# VPC CIDR
variable "vpc_cidr" {
  type    = string
  default = "172.16.0.0/16"
}
# Public Subnet CIDR
variable "public_subnet" {
  type    = string
  default = "172.16.0.0/24"
}
# Private Subnet CIDR
variable "protected_subnet" {
  type    = string
  default = "172.16.1.0/24"
}
# HA Subnet CIDR
variable "ha_subnet" {
  type    = string
  default = "172.16.2.0/24"
}
# MGMT Subnet CIDR
variable "mgmt_subnet" {
  type    = string
  default = "172.16.3.0/24"
}
# license file for active
variable "licenseFile" {
  type    = string
  default = "FGVM4VTM20000326.lic"
}
# license file for passive
variable "licenseFile2" {
  type    = string
  default = "FGVM4VTM20000327.lic"
}

# hamgmt gateway ip, depends on your mgmt subnet cidr
variable "mgmt_gateway" {
  type    = string
  default = "172.16.3.1"
}
variable "mgmt_mask" {
  type    = string
  default = "255.255.255.0"
}

# active interface ip assignments
# active ext
variable "active_port1_ip" {
  type    = string
  default = "172.16.0.2"
}
variable "active_port1_mask" {
  type    = string
  default = "24"
}
# active int
variable "active_port2_ip" {
  type    = string
  default = "172.16.1.2"
}
variable "active_port2_mask" {
  type    = string
  default = "24"
}
# active sync
variable "active_port3_ip" {
  type    = string
  default = "172.16.2.2"
}
variable "active_port3_mask" {
  type    = string
  default = "24"
}
# active hamgmt
variable "active_port4_ip" {
  type    = string
  default = "172.16.3.2"
}
variable "active_port4_mask" {
  type    = string
  default = "24"
}


# passive sync interface ip assignments
#passive ext
variable "passive_port1_ip" {
  type    = string
  default = "172.16.0.3"
}
variable "passive_port1_mask" {
  type    = string
  default = "24"
}

# passive int
variable "passive_port2_ip" {
  type    = string
  default = "172.16.1.3"
}
variable "passive_port2_mask" {
  type    = string
  default = "24"
}


# passive sync
variable "passive_port3_ip" {
  type    = string
  default = "172.16.2.3"
}
variable "passive_port3_mask" {
  type    = string
  default = "24"
}


# passive hamgmt
variable "passive_port4_ip" {
  type    = string
  default = "172.16.3.3"
}
variable "passive_port4_mask" {
  type    = string
  default = "24"
}


