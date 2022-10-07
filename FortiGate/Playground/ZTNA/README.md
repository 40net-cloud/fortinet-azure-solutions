# FortiGate Next-Generation Firewall - ZTNA

## Deployment

For the deployment, you can use the Azure Portal, Azure CLI, Powershell or Azure Cloud Shell. The Azure ARM templates are exclusive to Microsoft Azure and can't be used in other cloud environments. The main template is the `azuredeploy.json` which you can use in the Azure Portal. A `deploy.sh` script is provided to facilitate the deployment. You'll be prompted to provide the 4 required variables:

- PREFIX : This prefix will be added to each of the resources created by the template for ease of use and visibility.
- LOCATION : This is the Azure region where the deployment will be deployed.
- USERNAME : The username used to login to the FortiGate GUI and SSH management UI.
- PASSWORD : The password used for the FortiGate GUI and SSH management UI.

### Azure Portal

Azure Portal Wizard:
[![Azure Portal Wizard](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FPlayground%2FZTNA%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FPlayground%2FZTNA%2FcreateUiDefinition.json)

Custom Deployment:
[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FPlayground%2FZTNA%2Fazuredeploy.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions$2Fmain%2FFortiGate%2FPlayground%2FZTNA%2Fazuredeploy.json)

## Requirements and limitations

More information can be found [here](/FortiGate/A-Single-VM/README.md).

## FortiGate configuration

The FortiGate VMs need a specific configuration to match the deployed environment. This configuration can be injected during provisioning or afterwards via the different options including GUI, CLI, FortiManager or REST API.

This template used the default A Single VM ARM template. This tempalte already configures different aspects of the FortiGate during deployment. This configuration can be found [here](/FortiGate/A-Single-VM/doc/config-provisioning.md). Aditionaly, the below config is injected during provisioning with the correct values in bold replaced for your environment.

<pre><code>
config firewall address
  edit webserver1
    set subnet <b>w.x.y.z</b> 255.255.255.255
  next
end
config firewall addrgrp
  edit "Webserver"
    set member "webserver1"
  next
end
config user local
  edit <b>username</b>
    set type password
    set passwd <b>password</b>
  next
end
config user group
  edit sslvpn_group
    set member <b>username</b>
  next
end
config firewall vip
  edit "ZTNAServer"
    set type access-proxy
    set extip <b>172.16.136.5</a>
    set extintf "port1"
    set server-type https
    set extport 9443
    set ssl-certificate "Fortinet_Factory"
  next
end
config firewall access-proxy
  edit "ZTNAServer"
    set client-cert disable
    set vip "ZTNAServer"
    config api-gateway
      edit 1
        config realservers
          edit 1
            set ip <b>w.x.y.z</b>
          next
        end
      next
    end
  next
end
config firewall proxy-policy
  edit 1
    set name "ZTNA Web Server"
    set proxy access-proxy
    set access-proxy "ZTNAServer"
    set srcintf "port1"
    set srcaddr "all"
    set dstaddr "Webserver"
    set action accept
    set schedule "always"
    set logtraffic all
    set groups "sslvpn_group"
  next
end
config authentication scheme
  edit "ZTNA"
    set method basic
    set user-database "local-user-db"
  next
end
config authentication rule
  edit "ZTNA"
    set srcintf "port1"
    set srcaddr "all"
    set ip-based disable
    set active-auth-method "ZTNA"
  next
end
config endpoint-control fctems
  edit "ems"
    set fortinetone-cloud-authentication enable
  next
end
</code></pre>

## Support

Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/40net-cloud/fortinet-azure-solutions/issues) tab of this GitHub project.

## License

[License](LICENSE) © Fortinet Technologies. All rights reserved.
