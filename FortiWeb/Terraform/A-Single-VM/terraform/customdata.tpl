{
    "cloud-initd": "enable",
    "usr-cli": "config sys global
    \n set hostname "${fwb_vm_name}"\n 
    set gui-theme mariner\n 
    end\n",
    "HaAzureInit": "enable",
%{ if fwb_license_file != "" }
    "FwbLicenseBYOL": "${file(fwb_license_file)}",
%{ endif }
%{ if fwb_license_fortiflex != "" }
    "flex_token":  "${fwb_license_fortiflex}"
%{ endif }
}