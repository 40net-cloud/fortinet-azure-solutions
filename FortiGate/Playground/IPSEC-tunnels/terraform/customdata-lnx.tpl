#cloud-config
package_upgrade: true
packages:
  - nginx
  - iperf3
  - strongswan
  - strongswan-pki
  - libcharon-extra-plugins
  - libcharon-extauth-plugins
  - libstrongswan-extra-plugins
write_files:
  - owner: root:root
    path: /etc/systemd/system/rc-local.service
    content: |
 [Unit]
 Description=/etc/rc.local Compatibility
 ConditionPathExists=/etc/rc.local

[Service]
 Type=forking
 ExecStart=/etc/rc.local start
 TimeoutSec=0
 StandardOutput=tty
 RemainAfterExit=yes
 SysVStartPriority=99

[Install]
 WantedBy=multi-user.target
  - owner: root:too
    path: /etc/rc.local
    content: |
#!/bin/bash

cd /root/tools
mkdir -p /root/tools/build

echo "Generating dummy interfaces ..."
/usr/bin/python3 /root/tools/lnx-ifc.py
echo "Activating dummy interfaces ..."
/root/tools/build/ifc.sh
echo "Generating IPSEC config ..."
/usr/bin/python3 /root/tools/lnx-ipsec.py
echo "Restarting IPSEC daemon ..."
/usr/sbin/ipsec restart
runcmd:
  - systemctl enable rc-local
  - sysctl -w net.ipv4.ip_forward=1
  - echo ': PSK "fortinet"' >> /etc/ipsec.secrets
  - echo "include ipsec.d/tunnel*.conf" >> /etc/ipsec.conf
  - cd "/root"
  - curl -L https://api.github.com/repos/40net-cloud/fortinet-azure-solutions/tarball | tar xz --wildcards "*/FortiGate/Playground/IPSEC-tunnels/tools/*" --strip-components=4
