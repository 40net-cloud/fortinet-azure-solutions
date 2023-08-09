config system sdn-connector
edit AzureSDN
set type azure
next
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
set device port1
set gateway ${fgt_external_gw}
next
end
config system probe-response
set mode http-probe
end
config router bgp
set as 65005
set keepalive-timer 1
set holdtime-timer 3
set ebgp-multipath enable
set graceful-restart enable
config neighbor
edit ${bgp_peer1}
set capability-default-originate enable
set ebgp-enforce-multihop enable
set soft-reconfiguration enable
set interface port2
set remote-as 65515
next
edit ${bgp_peer2}
set capability-default-originate enable
set ebgp-enforce-multihop enable
set soft-reconfiguration enable
set interface port2
set remote-as 65515
next
end
end
config system interface
edit port1
set mode static
set ip ${fgt_external_ipaddr}/${fgt_external_mask}
set description external
set allowaccess probe-response
next
edit port2
set mode static
set ip ${fgt_internal_ipaddr}/${fgt_internal_mask}
set description internal
next
edit port3
set mode static
set ip ${fgt_hasync_ipaddr}/${fgt_hasync_mask}
set description hasyncport
next
edit port4
set mode static
set ip ${fgt_mgmt_ipaddr}/${fgt_mgmt_mask}
set description hammgmtport
set allowaccess ping https ssh ftm
next
end
%{ if fgt_ssh_public_key != "" }
config system admin
    edit "${fgt_username}"
        set ssh-public-key1 "${trimspace(file(fgt_ssh_public_key))}"
    next
end
%{ endif }
config system ha
set group-name AzureHA
set mode a-p
set hbdev port3 100
set session-pickup enable
set session-pickup-connectionless enable
set ha-mgmt-status enable
config ha-mgmt-interfaces
edit 1
set interface port4
set gateway ${fgt_mgmt_gw}
next
end
set override disable
set priority ${fgt_ha_priority}
set unicast-hb enable
set unicast-hb-peerip ${fgt_ha_peerip}
end


%{ if fgt_license_fortiflex != "" }
--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="license"

LICENSE-TOKEN:${fgt_license_fortiflex}

%{ endif }
%{ if fgt_license_file != "" }
--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="${fgt_license_file}"

${file(fgt_license_file)}

%{ endif }