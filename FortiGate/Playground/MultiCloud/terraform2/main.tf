terraform {
  required_version = ">=0.12"
  required_providers {
    fortios = {
      source  = "fortinetdev/fortios"
      version = ">=1.6.0"
    }
  }
}

provider "fortios" {
    hostname = "x.y.z.w:8443"
    token    = "test12345"
    insecure = "true"
}

resource "fortios_vpnipsec_phase1interface" "mc_test_phase1" {
  name                      = "mc_test"
  interface                 = "port2"
  peertype                  = "any"
  net_device                = "disable"
  proposal                  = "aes128-sha256 aes256-sha256 aes128-sha1 aes256-sha1"
  wizard_type               = "static-fortigate"
#  local_gw                 = "172.16.241.46"
  remote_gw                 = "1.2.3.5"
  psksecret                 = "Q1w2e34567890--"
  comments                  = "VPN: Terraform"
}

resource "fortios_vpnipsec_phase2interface" "mc_test_phase2" {
  name                     = fortios_vpnipsec_phase1interface.mc_test_phase1.name
  phase1name               = fortios_vpnipsec_phase1interface.mc_test_phase1.name
  proposal                 = "aes128-sha1 aes256-sha1 aes128-sha256 aes256-sha256 aes128gcm aes256gcm chacha20poly1305"
  src_addr_type            = "subnet"
  src_subnet               = "0.0.0.0 0.0.0.0"
  dst_addr_type            = "subnet"
  dst_subnet               = "0.0.0.0 0.0.0.0"
}

resource "fortios_firewall_policy" "mc_test_inbound" {
  policyid           = 10
  action             = "accept"
  logtraffic         = "all"
  name               = "mc_test_inbound"
  schedule           = "always"

  dstaddr {
    name = "all"
  }

  dstintf {
    name = "port3"
  }

  service {
    name = "ALL"
  }

  srcaddr {
    name = "all"
  }

  srcintf {
    name = "mc_test"
  }
}

resource "fortios_firewall_policy" "mc_test_outbound" {
  policyid           = 14
  action             = "accept"
  logtraffic         = "all"
  name               = "mc_test_outbound"
  schedule           = "always"

  dstaddr {
    name = "all"
  }

  dstintf {
    name = "mc_test"
  }

  service {
    name = "ALL"
  }

  srcaddr {
    name = "all"
  }

  srcintf {
    name = "port3"
  }
}

resource "fortios_router_bgp" "trname" {
  as                                 = 65010

  neighbor {
    ip = "172.16.241.46"
    remote_as = "65514"
  }
  neighbor {
    ip = "172.16.241.47"
    remote_as = "65514"
  }

  network {
    id = "1"
    prefix = "172.16.60.0 255.255.255.0"
  }
}

resource "fortios_system_interface" "mc_test2" {
  type         = "tunnel"
  ip           = "172.16.241.33/32"
  name         = "mc_test"
  interface    = "port2"
  vdom         = "root"
#  mode         = "static"
  description  = "Created by Terraform Provider for FortiOS"
}
