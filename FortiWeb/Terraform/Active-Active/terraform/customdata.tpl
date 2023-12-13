{
"cloud-initd":"enable",
"usr-cli":"config system ha\nset mode active-active-high-volume\nset group-id 1\nset group-name ${fwb_ha_group_name}\nset priority ${fwb_ha_priority}\nset tunnel-local ${fwb_ha_localip}\nset tunnel-peer ${fwb_ha_peerip}\nset monitor port1 port2\nend\n\n",
"HaAzureInit":"enable",
"FwbLicenseBYOL":"${fwb_license_file}",
"flex_token":"${fwb_license_fortiflex}"
}