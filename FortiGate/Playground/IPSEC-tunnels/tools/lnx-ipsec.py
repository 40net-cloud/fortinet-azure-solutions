#!/usr/bin/env python3

from jinja2 import Template
import ipaddress

ip_network = "10.1.0.0/16"
vpn_psk = "fortinet"
index_start = 4   # First IP in the IP network range to start counting
index_end = 1010  # Count needs to be less than the IP addresses available in the IP network
vpn_b_ip = "172.16.137.10"
vpn_b_subnet = "172.16.138.0/24"

ip_int = int(ipaddress.ip_network(ip_network).network_address)
index = index_start
end = index_end
template = """
conn {{ tunnel }}
        rekey=yes
        left={{ vpn_a_ip }}
        leftsubnet={{ vpn_a_ip }}/32
        right={{ vpn_b_ip }}
        rightsubnet={{ vpn_b_subnet }}
        rightid=@{{ tunnel }}
        ikelifetime=28800s
        lifetime=3600s
        authby=secret
        type=tunnel
        auto=start
        ike=aes256gcm16-prfsha256-ecp521
        esp=aes256gcm16-ecp521
        fragmentation=yes
        dpddelay=3
        dpdtimeout=20
        dpdaction=restart

"""

while index < end:
  vpn_a_ip = str(ipaddress.IPv4Address(ip_int + index))
  index2 = index % 256                  # secondary interface nr
  index3 = int(index / 256)             # dummy interface nr
  tunnel = "{}{}".format("tunnel", index)

  tm = Template(template)
  msg = tm.render(tunnel=tunnel, vpn_a_ip=vpn_a_ip, vpn_b_ip=vpn_b_ip, vpn_b_subnet=vpn_b_subnet)
  f = open("/etc/ipsec.d/"+ tunnel + ".conf", "w")
  f.write(msg)
  f.close()

  print(tunnel)
  index += 1

