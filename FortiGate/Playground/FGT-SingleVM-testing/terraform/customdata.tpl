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
    edit "${prefix}-SUBNET-PROTECTED-A"
        set allow-routing enable
        set subnet ${fgt_protected_net_a}
    next
    edit "${prefix}-SUBNET-PROTECTED-B"
        set allow-routing enable
        set subnet ${fgt_protected_net_b}
    next
end
config firewall policy
    edit 1
        set name "protected-a-2-protected-b"
        set srcintf "port2"
        set dstintf "port2"
        set srcaddr "${prefix}-SUBNET-PROTECTED-A"
        set dstaddr "${prefix}-SUBNET-PROTECTED-B"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic disable
        set fsso disable
        set comments "Allow protected networks to talk to each other"
    next
    edit 2
        set name "protected-b-2-protected-a"
        set srcintf "port2"
        set dstintf "port2"
        set srcaddr "${prefix}-SUBNET-PROTECTED-B"
        set dstaddr "${prefix}-SUBNET-PROTECTED-A"
        set action accept
        set schedule "always"
        set service "ALL"
        set logtraffic disable
        set fsso disable
        set comments "Allow protected networks to talk to each other"
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
        set device port2
        set gateway ${fgt_internal_gw}
    next
    edit 4
        set dst 168.63.129.16 255.255.255.255
        set device port1
        set gateway ${fgt_external_gw}
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