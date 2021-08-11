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
*** Targets ***

probe = FPing

menu = Top
title = Network Latency Grapher
remark = Remark \
	 Remark2

+ VPN
menu = VPN
title = VPN

++ group0
menu = group0
title = group0
{% for i in range(index_start, index_end) %}
{% if i is divisibleby 256 %}
++ group{{ i }}
menu = group{{ i }}
title = group{{ i }}
{% endif %}
+++ tunnel{{ i }}
menu = {{ ipaddress.IPv4Address(i|int + ip_int|int) }}
title = {{ ipaddress.IPv4Address(i|int + ip_int|int) }}
host = {{ ipaddress.IPv4Address(i|int + ip_int|int) }}
{% endfor %}
"""

f = open("build/Targets", "w")

tm = Template(template)
msg = tm.render(index_start=index_start, index_end=index_end, ip_int=ip_int, ipaddress=ipaddress)
f.write(msg)

f.close()
