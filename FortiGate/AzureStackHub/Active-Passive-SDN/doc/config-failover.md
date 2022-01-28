# Failover configuration

Once, licensed and rebooted, the FortiGate Fabric Connector needs to be configured to enable the cluster IP and route table to failover. Most of this config will be specific to your environment and so must be modified. A service principal is needed for the access, more information can be found [here](https://docs.fortinet.com/document/fortigate-public-cloud/7.0.0/azure-administration-guide/419755/sdn-connector-in-azure-stack)

## FortiGate A

```text
config system sdn-connector
  edit "AZConnector"
  set type azure
  set ha-status enable
  set resource-group "fortigateapha"
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
```

For FortiGate B:

```text
config system sdn-connector
  edit "AZConnector"
  set type azure
  set ha-status enable
  set resource-group "fortigateapha"
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
```
