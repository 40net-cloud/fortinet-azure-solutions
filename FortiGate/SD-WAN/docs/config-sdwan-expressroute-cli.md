
## On-premise Fortigate

```
roz (phase1-interface) # 
config vpn ipsec phase1-interface
    edit "VPN2Azure"
        set interface "port2"
        set peertype any
        set net-device disable
        set proposal aes128-sha256 aes256-sha256 aes128-sha1 aes256-sha1
        set comments "VPN: VPN2Azure (Created by VPN wizard)"
        set wizard-type static-fortigate
        set remote-gw 40.114.187.146
        set psksecret ENC sharedsecret
        set dpd-retrycount 2
        set dpd-retryinterval 2
    next
end
```

```
config vpn ipsec phase2-interface
    edit "VPN2Azure"
        set phase1name "VPN2Azure"
        set proposal aes128-sha1 aes256-sha1 aes128-sha256 aes256-sha256 aes128gcm aes256gcm chacha20poly1305
        set comments "VPN: VPN2Azure (Created by VPN wizard)"
        set src-addr-type name
        set dst-addr-type name
        set src-name "all"
        set dst-name "all"
    next
end
```

```
config system sdwan
    set status enable
    config zone
        edit "virtual-wan-link"
        next
    end
    config members
        edit 3
            set interface "VPN2Azure"
        next
        edit 6
            set interface "port1"
            set gateway 172.16.251.254
        next
    end
    config health-check
        edit "Azure"
            set server "198.18.1.1"
            set update-static-route disable
            set members 3
        next
    end
end
```

```
config router static
    edit 5
        set dst 172.16.137.0 255.255.255.0
        set distance 1
        set sdwan enable
    next
    edit 8
        set distance 254
        set blackhole enable
        set dstaddr "VPN2Azure_remote_subnet_1"
    next
end
```

```
config firewall policy
    edit 3
        set name "to-Azure"
        set uuid 23247f3a-9d15-51eb-58ab-b1e2419cdd17
        set srcintf "port5"
        set dstintf "virtual-wan-link"
        set srcaddr "via_Internet_local_subnet_1"
        set dstaddr "via_Internet_remote_subnet_1"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set logtraffic-start enable
    next
    edit 5
        set name "From-Azure"
        set uuid 2919636a-9d15-51eb-1396-396aa90f53e0
        set srcintf "virtual-wan-link"
        set dstintf "port5"
        set srcaddr "via_Internet_remote_subnet_1"
        set dstaddr "via_Internet_local_subnet_1"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set logtraffic-start enable
        set comments "From-Azure"
    next
end
```

```
config system interface
    edit "VPN2Azure"
        set vdom "root"
        set ip 198.18.1.2 255.255.255.255
        set allowaccess ping
        set type tunnel
        set remote-ip 192.18.1.1 255.255.255.0
        set role dmz
        set snmp-index 12
        config ipv6
            set ip6-allowaccess ping
        end
        set interface "port2"
    next
end
```

## Azure Fortigate
```
config vpn ipsec phase1-interface
    edit "VPN-2-Joeri-BG"
        set interface "port1"
        set peertype any
        set net-device disable
        set proposal aes128-sha256 aes256-sha256 aes128-sha1 aes256-sha1
        set comments "VPN: VPN-2-Joeri-BG (Created by VPN wizard)"
        set wizard-type static-fortigate
        set remote-gw 46.162.118.160
        set psksecret ENC sharedsecret
        set dpd-retrycount 2
        set dpd-retryinterval 2
    next
end
```

```
config vpn ipsec phase2-interface
    edit "VPN-2-Joeri-BG"
        set phase1name "VPN-2-Joeri-BG"
        set proposal aes128-sha1 aes256-sha1 aes128-sha256 aes256-sha256 aes128gcm aes256gcm chacha20poly1305
        set comments "VPN: VPN-2-Joeri-BG (Created by VPN wizard)"
        set src-addr-type name
        set dst-addr-type name
        set src-name "all"
        set dst-name "all"
    next
end
```

```
config system sdwan
    set status enable
    config zone
        edit "virtual-wan-link"
        next
    end
    config members
        edit 1
            set interface "port1"
            set gateway 172.16.136.1
        next
        edit 2
            set interface "VPN-2-Joeri-BG"
        next
    end
    config health-check
        edit "on_prem"
            set server "198.18.1.2"
            set update-static-route disable
            set members 2
        next
    end
end
```

```
config router static
    edit 1
        set gateway 172.16.136.1
        set device "port1"
    next
    edit 2
        set dst 172.16.136.0 255.255.252.0
        set gateway 172.16.136.65
        set device "port2"
    next
    edit 3
        set dst 168.63.129.16 255.255.255.255
        set gateway 172.16.136.65
        set device "port2"
    next
    edit 4
        set dst 168.63.129.16 255.255.255.255
        set gateway 172.16.136.1
        set device "port1"
    next
    edit 6
        set dst 172.16.140.0 255.255.255.0
        set gateway 172.16.136.65
        set device "port2"
    next
    edit 7
        set dst 172.16.142.0 255.255.255.0
        set gateway 172.16.136.65
        set device "port2"
    next
    edit 8
        set dst 172.16.251.0 255.255.255.0
        set gateway 172.16.136.1
        set device "port1"
    next
    edit 10
        set distance 254
        set blackhole enable
        set dstaddr "VPN-2-Joeri-BG_remote_subnet_1"
    next
    edit 9
        set dst 172.16.248.0 255.255.255.0
        set distance 1
        set sdwan enable
    next
end
```

```
config firewall policy
    edit 2
        set name "to-on-prem"
        set uuid dca4f910-9eb1-51eb-4cc7-3de870702609
        set srcintf "port2"
        set dstintf "virtual-wan-link"
        set srcaddr "VPN-2-Joeri-BG_local_subnet_1"
        set dstaddr "VPN-2-Joeri-BG_remote_subnet_1"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set logtraffic-start enable
    next
    edit 3
        set name "from-on-prem"
        set uuid 156483ba-9eb2-51eb-4a72-c02b23a700f1
        set srcintf "virtual-wan-link"
        set dstintf "port2"
        set srcaddr "VPN-2-Joeri-BG_remote_subnet_1"
        set dstaddr "VPN-2-Joeri-BG_local_subnet_1"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set logtraffic-start enable
    next
end
```

```
config system interface
    edit "port1"
        set vdom "root"
        set ip 172.16.136.6 255.255.255.192
        set allowaccess ping probe-response
        set type physical
        set description "external"
        set alias "External"
        set snmp-index 1
    next
    edit "port2"
        set vdom "root"
        set ip 172.16.136.70 255.255.255.192
        set allowaccess ping probe-response
        set type physical
        set description "internal"
        set alias "Internal"
        set snmp-index 2
    next
    edit "port3"
        set ip 172.16.136.134 255.255.255.192
        set type physical
        set description "hasync"
        set snmp-index 3
    next
    edit "port4"
        set ip 172.16.136.198 255.255.255.192
        set allowaccess ping https ssh ftm
        set type physical
        set description "mgmt"
        set snmp-index 4
    next
    edit "ssl.root"
        set vdom "root"
        set type tunnel
        set alias "SSL VPN interface"
        set snmp-index 5
    next
    edit "VPN-2-Joeri-BG"
        set vdom "root"
        set ip 198.18.1.1 255.255.255.255
        set allowaccess ping
        set type tunnel
        set remote-ip 198.18.1.2 255.255.255.0
        set snmp-index 6
        set interface "port1"
    next
end
```

