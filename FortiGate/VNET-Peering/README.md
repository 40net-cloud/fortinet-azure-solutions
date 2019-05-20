## Active/Passive High Available pair FortiGates

[![Build Status](https://dev.azure.com/jvh-2520/Fortinet-Azure/_apis/build/status/jvhoof.fortinet-azure-solutions?branchName=master)](https://dev.azure.com/jvh-2520/Fortinet-Azure/_build/latest?definitionId=13&branchName=master)

## How to deploy

The FortiGate solution can be deployed using the Azure Portal or Azure CLI. Using the deploy button you will open the Azure portal and you are required to fill in at least 5 variables. You can customize the deployment but referencing the resources like VNET, subnet and other resources.  
### Azure Portal

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjvhoof%2Ffortinet-azure-solutions%2Fmaster%2FFortiGate%2FActive-Passive-ELB-ILB%2Fazuredeploy.json" target="_blank"><img src="http://azuredeploy.net/deploybutton.png"/></a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fjvhoof%2Ffortinet-azure-solutions$2Fmaster%2FFortiGate%2FActive-Passive-ELB-ILB%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

### Azure CLI

To deploy via Azure Cloud Shell you can connect via the Azure Portal or directly to [https://shell.azure.com/](https://shell.azure.com/).

- Login into the Azure Cloud Shell 
- Run the following command in the Azure Cloud:

`cd ~/clouddrive/ && wget -qO- https://github.com/jvhoof/fortinet-azure-solutions/archive/master.zip | jar x && cd ~/clouddrive/fortinet-azure-solutions-master/FortiGate/Active-Passive-ELB-ILB/ && ./deploy.sh`

- The script will ask you a few questions to bootstrap a full deployment.

## Deployed resources
	- vnet with five subnets or uses an existing vnet of your selection.  If using an existing vnet, it must already have 5 subnets.
	- three public IPs. The first public IP is for cluster access to/through the active FortiGate.  The other two PIPs are for Management access
	- Two FortiGate virtual appliances

A typical use case will be for Site-to-Site VPN termination as in the following diagram:
---

![Example Diagram](APDiagram1.png)

---

This second diagram shows what will happen in the event FortiGate A is shut down:
---

![Example Diagram](APDiagram2.png)

---

### FortiGate configuration:

The FortiGates will be preconfigured similar to the following.  You should be able to connect via https on port 8443 (example: https://104.45.185.229:8443) or via SSH on port 22.  Use the management Public IP for each FortiGate to connect.

    FortiGate-A:
    
    config system global
      set admin-sport 8443
    end
    config router static
      edit 1
        set gateway 10.0.1.1
        set device port1
      next
      edit 2
        set dst 10.0.0.0 255.255.0.0
        set gateway 10.0.2.1
        set device "port2"
      next
    end
    config system interface
      edit "port1"
        set vdom "root"
        set mode static
        set ip 10.0.1.4 255.255.255.0
        set allowaccess ping https ssh
        set description "external"
      next
      edit "port2"
        set vdom "root"
        set mode static
        set ip 10.0.2.4 255.255.255.0
        set description "internal"
      next
      edit "port3"
        set vdom "root"
        set mode static
        set ip 10.0.3.4 255.255.255.240
        set description "hasyncport"
      next
      edit "port4"
        set vdom "root"
        set mode static
        set ip 10.0.4.4 255.255.255.240
        set allowaccess ping https ssh 
        set description "management"
      next
    end
    
    config system ha
      set group-name "AzureHA"
      set mode a-p
      set hbdev "port3" 100
      set session-pickup enable
      set session-pickup-connectionless enable
      set ha-mgmt-status enable
      config ha-mgmt-interfaces
        edit 1
          set interface "port4"
          set gateway 10.0.4.1
        next
      end
      set override disable
      set priority 255
      set unicast-hb enable
      set unicast-hb-peerip 10.0.3.5
    end
    
    FortiGate B:
    
    config system global
      set admin-sport 8443
    end
    config router static
      edit 1
        set gateway 10.0.1.1
        set device port1
      next
      edit 2
        set dst 10.0.0.0 255.255.0.0
        set gateway 10.0.2.1
      set device "port2"
      next
    end
    config system interface
      edit "port1"
        set vdom "root"
        set mode static
        set ip 10.0.1.5 255.255.255.0
        set allowaccess ping https ssh 
        set description "external"
      next
      edit "port2"
        set vdom "root"
        set mode static
        set ip 10.0.2.5 255.255.255.0
        set description "internal"
      next
      edit "port3"
        set mode static
        set ip 10.0.3.5 255.255.255.240
        set description "hasyncport"
      next
      edit "port4"
        set vdom "root"
        set mode static
        set ip 10.0.4.5 255.255.255.240
        set allowaccess ping https ssh
        set description "management"
      next
    end
    config system ha
      set group-name "AzureHA"
      set mode a-p
      set hbdev "port3" 100
      set session-pickup enable
      set session-pickup-connectionless enable
      set ha-mgmt-status enable
      config ha-mgmt-interfaces
        edit 1
          set interface "port4"
          set gateway 10.0.4.1
        next
      end
      set override disable
      set priority 1
      set unicast-hb enable
      set unicast-hb-peerip 10.0.3.4
    end

Next you need to apply the license unless you are using PAYG licensing.  To apply BYOL licenses, first register the licenses with http://support.fortinet.com and download the .lic files.  Note, these files may not work until 30 minutes after it's initiall created.

Next, connect via HTTPS to both FortiGates via their management addresses and upload unique license files for each.

Once, licensed and rebooted, you can proceed to configure the Azure settings to enable the cluster IP and route table failover:

For FortiGate A (Most of this config will be specific to your environment and so must be modified):
    
    config system sdn-connector
      edit "AZConnector"
      set type azure
      set tenant-id "942e801f-1c18-237a-8fa1-4e2bde2161ba"
      set subscription-id "2g95c73c-dg16-47a1-1536-65124d1a5e11"
      set resource-group "fortigateapha"
      set client-id "7d1234a4-a123-1234-abc4-d80e7af9123a"
      set client-secret i7I21/mabcgbYW/K1l0zABC/6M86lAdTc312345Tps1=
      config nic
        edit "FortiGate-A-NIC1"
          config ip
            edit "ipconfig1"
            set public-ip "FGTAPClusterPublicIP"
          next
        end
        next
      end
      config route-table
        edit "FortiGateDefaultAPRouteTable"
        config route
        edit "toDefault"
          set next-hop "10.0.2.4"
        next
      end
      next
     end
    end

For FortiGate B:

    config system sdn-connector
      edit "AZConnector"
      set type azure
      set tenant-id "942e801f-1c18-237a-8fa1-4e2bde2161ba"
      set subscription-id "2g95c73c-dg16-47a1-1536-65124d1a5e11"
      set resource-group "fortigateapha"
      set client-id "7d1234a4-a123-1234-abc4-d80e7af9123a"
      set client-secret i7I21/mabcgbYW/K1l0zABC/6M86lAdTc312345Tps1=
      config nic
        edit "FortiGate-B-NIC1"
        config ip
          edit "ipconfig1"
          set public-ip "FGTAPClusterPublicIP"
        next
      end
      next
      end
      config route-table
        edit "FortiGateDefaultAPRouteTable"
          config route
          edit "toDefault"
             set next-hop "10.0.2.5"
          next
        end
        next
      end
    end


