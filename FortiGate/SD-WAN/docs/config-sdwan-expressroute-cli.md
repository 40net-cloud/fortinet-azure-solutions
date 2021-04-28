
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