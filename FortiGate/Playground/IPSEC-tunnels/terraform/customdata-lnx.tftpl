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
  - owner: root:root
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
  - owner: root:root
    path: /etc/ipsec.secrets
    content: |
      : PSK "fortinet"
  - owner: root:root
    path: /etc/ipsec.conf
    content: |
      include ipsec.d/tunnel*.conf
runcmd:
  - [ sh, -c, chmod a+x /etc/rc.local ]
  - [ sh, -c, systemctl enable rc-local ]
  - [ sh, -c, sysctl -w net.ipv4.ip_forward=1 ]
  - [ sh, -c, curl -L https://api.github.com/repos/40net-cloud/fortinet-azure-solutions/tarball | tar -C "/root" -xz --wildcards "*/FortiGate/Playground/IPSEC-tunnels/tools/*" --strip-components=4 ]
final_message: "The system is finally up, after $UPTIME seconds"
