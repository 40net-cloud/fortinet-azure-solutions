#!/usr/bin/env python3

from jinja2 import Template
import ipaddress

ip_network = "10.1.0.0/16"
vpn_psk = "fortinet"
index_start = 4   # First IP in the IP network range to start counting
index_end = 1010  # Count needs to be less than the IP addresses available in the IP network

ip_int = int(ipaddress.ip_network(ip_network).network_address)
index = index_start
end = index_end
template = """{% if index2 == 0 or index == index_start %}ip link delete loop{{ index3 }}
ip link add name loop{{ index3 }} type dummy
ip link set loop{{ index3 }} up
echo loop{{ index3 }}
ip addr add {{ vpn_a_ip }}/32 dev loop{{ index3 }}
{% else %}echo loop{{ index3 }}:{{ index2 }}
ip addr add {{ vpn_a_ip }}/32 dev loop{{ index3 }}:{{ index2 }}
{% endif %}"""

f = open("build/ifc.sh", "w")
f.write("#!/bin/bash\n")

while index < end:
  vpn_a_ip = str(ipaddress.IPv4Address(ip_int + index))
  index2 = index % 256                  # secondary interface nr
  index3 = int(index / 256)             # dummy interface nr

  tm = Template(template)
  msg = tm.render(index=index, index2=index2, index3=index3, vpn_a_ip=vpn_a_ip, index_start=index_start)

  f.write(msg)

  print(index)
  index += 1

f.close()
