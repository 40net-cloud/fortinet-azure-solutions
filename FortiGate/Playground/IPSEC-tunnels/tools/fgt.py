#!/usr/bin/env python3

from jinja2 import Template
import ipaddress

ip_network = "10.1.0.0/16"
vpn_psk = "fortinet"
index_start = 4   # First IP in the IP network range to start counting
index_end = 5010  # Count needs to be less than the IP addresses available in the IP network
vpn_b_ip = "172.16.137.10"
vpn_b_subnet = "172.16.138.0/24"

ip_int = int(ipaddress.ip_network(ip_network).network_address)
index = index_start
end = index_end
template = """
config vpn ipsec phase1-interface
    edit "{{ vpn_a_ip }}"
        set interface "port2"
        set ike-version 2
        set keylife 28800
        set peertype any
        set net-device enable
        set proposal aes256gcm-prfsha256
        set localid "{{ tunnel }}"
        set dhgrp 21
        set nattraversal forced
        set remote-gw {{ vpn_a_ip }}
        set psksecret {{ vpn_psk }}
    next
end
config vpn ipsec phase2-interface
    edit "{{ vpn_a_ip }}"
        set phase1name "{{ vpn_a_ip }}"
        set proposal aes256gcm chacha20poly1305
        set dhgrp 21
        set auto-negotiate enable
        set keylifeseconds 3600
        set src-subnet {{ vpn_b_subnet }}
        set dst-subnet {{ vpn_a_subnet }}
    next
end
config firewall policy
    edit {{ index }}
        set name "{{ vpn_a_ip }} IN"
        set srcintf "{{ vpn_a_ip }}"
        set dstintf "port3"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set logtraffic-start enable
    next
    edit {{ 10000 + index|int }}
        set name "{{ vpn_a_ip }} OUT"
        set srcintf "port3"
        set dstintf "{{ vpn_a_ip }}"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set logtraffic-start enable
    next
end
config router static
    edit {{ index }}
        set dst {{ vpn_a_subnet }}
        set device "{{ vpn_a_ip }}"
    next
end
"""

f = open("build/fgt.conf", "w")
while index < end:
  vpn_a_ip = str(ipaddress.IPv4Address(ip_int + index))
  vpn_a_subnet = "{}{}".format(vpn_a_ip, "/32")
  index2 = index % 256                  # secondary interface nr
  index3 = int(index / 256)             # dummy interface nr
  tunnel = "{}{}".format("tunnel", index)

  tm = Template(template)
  msg = tm.render(index=index, tunnel=tunnel, vpn_a_ip=vpn_a_ip, vpn_a_subnet=vpn_a_subnet, vpn_b_ip=vpn_b_ip, vpn_b_subnet=vpn_b_subnet, vpn_psk=vpn_psk)
  f.write(msg)

  print(tunnel)
  index += 1

f.close()
