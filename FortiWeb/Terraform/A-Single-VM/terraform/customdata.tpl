Content-Type: multipart/mixed; boundary="===============0086047718136476635=="
MIME-Version: 1.0

--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="config"


config sys global
    set hostname "${fwb_vm_name}"
    set gui-theme mariner
end


%{ if fwb_ssh_public_key != "" }
config system admin
    edit "${fwb_username}"
        set ssh-public-key1 "${trimspace(file(fwb_ssh_public_key))}"
    next
end
%{ endif }
#
# Example config to provision an API user which can be used with the FortiWeb Terraform Provider
# The API key is either an encrypted version. An unencrypted key can provided (exact 30 char long)
#config system api-user
#    edit restapi
#         set api-key Abcdefghijklmnopqrtsuvwxyz1234
#         set accprofile "super_admin"
#         config trusthost
#             edit 1
#                 set ipv4-trusthost w.x.y.z a.b.c.d
#             next
#        end
#    next
#end
#
%{ if fwb_license_fortiflex != "" }
--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="license"

LICENSE-TOKEN:${fwb_license_fortiflex}

%{ endif } %{ if fwb_license_file != "" }
--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="${fwb_license_file}"

${file(fwb_license_file)}

%{ endif }
--===============0086047718136476635==--
