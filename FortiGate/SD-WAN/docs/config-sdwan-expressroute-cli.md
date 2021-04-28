
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