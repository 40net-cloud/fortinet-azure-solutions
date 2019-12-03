Content-Type: multipart/mixed; boundary="===============0086047718136476635=="
MIME-Version: 1.0

--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="config"

config system sdn-connector
	edit AzureSDN
		set type azure
	end
end
config sys global
    set admintimeout 120
    set hostname "${fgt_vm_name}"
    set timezone 26
    set admin-sport 8443
    set gui-theme mariner
end
config vpn ssl settings
    set port 7443
end
config router static
    edit 1
        set gateway ${fgt_external_gw}
        set device port1
    next
    edit 2
        set dst ${vnet_network}
        set gateway ${fgt_internal_gw}
        set device port2
    next
    edit 3
        set dst 168.63.129.16 255.255.255.255
        set device port2
        set gateway ${fgt_internal_gw}
    next
    edit 4
        set dst 168.63.129.16 255.255.255.255
        set device port1
        set gateway ${fgt_external_gw}
    next
    edit 5
        set dst ${remote_protected_net}
        set device "IPSEC-A-B"
        set comment "VPN: IPSEC-A-B"
        set dstaddr "IPSEC-A-B_remote"
    next
    edit 6
        set dst ${remote_protected_net}
        set distance 254
        set comment "VPN: IPSEC-A-B"
        set blackhole enable
        set dstaddr "IPSEC-A-B_remote"
    next

end
config system interface
    edit port1
        set mode static
        set ip ${fgt_external_ipaddr}/${fgt_external_mask}
        set description external
        set allowaccess ping https ssh ftm
    next
    edit port2
        set mode static
        set ip ${fgt_internal_ipaddr}/${fgt_internal_mask}
        set description internal
    next
    edit "IPSEC-A-B"
        set vdom "root"
        set type tunnel
        set snmp-index 4
        set interface "port1"
    next
end
config system accprofile
    edit "restapi"
        set secfabgrp read-write
        set ftviewgrp read-write
        set authgrp read-write
        set sysgrp read-write
        set netgrp read-write
        set loggrp read-write
        set fwgrp read-write
        set vpngrp read-write
        set utmgrp read-write
        set wanoptgrp read-write
        set wifi read-write
    next
end
%{ if fgt_ssh_public_key != "" }
config system admin
    edit "${fgt_username}"
        set ssh-public-key1 "${trimspace(file(fgt_ssh_public_key))}"
    next
end
%{ endif }
config firewall address
    edit "IPSEC-A-B_local_subnet_1"
        set allow-routing enable
        set subnet ${fgt_protected_net}
    next
    edit "IPSEC-A-B_remote_subnet_1"
        set allow-routing enable
        set subnet ${remote_protected_net}
    next
end
config firewall addrgrp
    edit "IPSEC-A-B_local"
        set member "IPSEC-A-B_local_subnet_1"
        set comment "VPN: IPSEC-A-B"
        set allow-routing enable
    next
    edit "IPSEC-A-B_remote"
        set member "IPSEC-A-B_remote_subnet_1"
        set comment "VPN: IPSEC-A-B"
        set allow-routing enable
    next
end
config vpn ipsec phase1-interface
    edit "IPSEC-A-B"
        set interface "port1"
        set peertype any
        set proposal aes128-sha256 aes256-sha256 aes128-sha1 aes256-sha1
        set comments "VPN: IPSEC-A-B"
        set wizard-type static-fortigate
        set remote-gw ${remote_public_ip}
        set psksecret ${ipsec_psk}
    next
end
config vpn ipsec phase2-interface
    edit "IPSEC-A-B"
        set phase1name "IPSEC-A-B"
        set proposal aes128-sha1 aes256-sha1 aes128-sha256 aes256-sha256 aes128gcm aes256gcm chacha20poly1305
        set comments "VPN: IPSEC-A-B"
        set src-addr-type name
        set dst-addr-type name
        set src-name "IPSEC-A-B_local"
        set dst-name "IPSEC-A-B_remote"
    next
end
config firewall policy
    edit 1
        set name "vpn_IPSEC-A-B_local"
        set srcintf "port2"
        set dstintf "IPSEC-A-B"
        set srcaddr "IPSEC-A-B_local"
        set dstaddr "IPSEC-A-B_remote"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic disable
        set fsso disable
        set comments "VPN: IPSEC-A-B"
    next
    edit 2
        set name "vpn_IPSEC-A-B_remote"
        set srcintf "IPSEC-A-B"
        set dstintf "port2"
        set srcaddr "IPSEC-A-B_remote"
        set dstaddr "IPSEC-A-B_local"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic disable
        set fsso disable
        set comments "VPN: IPSEC-A-B"
    next
end

%{ if fgt_license_file != "" }
--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="${fgt_license_file}"

${file(fgt_license_file)}

%{ endif }
--===============0086047718136476635==--