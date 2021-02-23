config system global
    set hostname ${fgt_vm_name}
end
config system sdn-connector
    edit "gcp"
        set type gcp
    next
end
config router static
    edit 1
        set gateway ${fgt_external_gw}
        set device port1
    next
    edit 2
        set dst ${vpc_network}
        set gateway ${fgt_internal_gw}
        set device port2
    next
end
config system interface
    edit port1
        set mode static
        set ip ${fgt_external_ipaddr}/${fgt_external_mask}
        set description external
        set allowaccess probe-response fgfm
    next
    edit port2
        set mode static
        set ip ${fgt_internal_ipaddr}/${fgt_internal_mask}
        set description internal
        set allowaccess probe-response fgfm
    next
    edit port3
        set mode static
        set ip ${fgt_hasync_ipaddr}/${fgt_hasync_mask}
        set description hasync
    next
    edit port4
        set mode static
        set ip ${fgt_mgmt_ipaddr}/${fgt_mgmt_mask}
        set description mgmt
        set allowaccess ping https ssh ftm
    next
end
config system admin
    edit api-user
        set accprofile super_admin
        set password ${fgt_password}
    next
end
config system api-user
    edit api-token
         set api-key ${fgt_password}
         set accprofile "super_admin"
         config trusthost
             edit 1
                 set ipv4-trusthost ${client_ip} 255.255.255.255
             next
             edit 2
                 set ipv4-trusthost 46.162.118.212 255.255.255.255
             next
    next
end
config system ha
    set group-name GCPHA
    set mode a-p
    set hbdev port3 50
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
    set unicast-hb-netmask ${fgt_hasync_mask}
end
