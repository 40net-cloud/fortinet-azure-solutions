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
    set gui-theme mariner
end
config vpn ssl settings
    set port 7443
end
config router static
    edit 1
        set gateway ${fgt_mgmt_gw}
        set device port1
    next
    edit 2
        set dst ${vnet_network}
        set gateway ${fgt_internal_gw}
        set device port2
    next
end
config system probe-response
    set http-probe-value OK
    set mode http-probe
end
config system interface
    edit port1
        set mode static
        set ip ${fgt_mgmt_ipaddr}/${fgt_mgmt_mask}
        set description mgmt
        set allowaccess probe-response ping https ssh ftm
    next
    edit port2
        set mode static
        set ip ${fgt_external_ipaddr}/${fgt_external_mask}
        set description external
        set secondary-IP enable
        config secondaryip
            edit 1
                set ip ${fgt_external_ipaddr_2}/${fgt_external_mask}
                set allowaccess ping
            next
        end
    next
    edit port3
        set mode static
        set ip ${fgt_internal_ipaddr}/${fgt_internal_mask}
        set description internal
    next
end
config firewall policy
    edit 1
        set name "allow"
        set srcintf "any"
        set dstintf "any"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
    next
end
config system admin
    edit devops
    set accprofile super_admin
    set password ${fgt_password}
end
%{ if fgt_ssh_public_key != "" }
config system admin
    edit "${fgt_username}"
        set ssh-public-key1 "${trimspace(file(fgt_ssh_public_key))}"
    next
end
%{ endif }
%{ if fgt_license_flexvm != "" }
exec vm-license ${fgt_license_flexvm}
%{ endif }
config vpn ipsec phase1-interface
    edit "tester"
        set type dynamic
        set interface "port2"
        set ike-version 2
        set local-gw 172.16.137.11
        set peertype any
        set psksecret fortinet
    next
end
config vpn ipsec phase2-interface
    edit "tester"
        set phase1name "tester"
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
