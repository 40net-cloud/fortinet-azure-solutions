# FortiGate - inspecting common PaaS services f.e Azure SQL, Storage Account
This document describes how to inspect traffic to PaaS services (f.e. Azure SQL) by using FortiGate and [Private Endpoint](https://docs.microsoft.com/en-us/azure/storage/common/storage-private-endpoints).
In this scenario FortiGate operates as a DNS Forwarder.
A DNS Forwarder is a Virtual Machine running on the Virtual Network linked to the Private DNS Zone that can proxy DNS queries coming from other Virtual Network or from on-premises. The main reason of using this scenario was to provide the access from on-premise network connected to FortiGate via IPSEC VPN (client-to-site or site-to-site) to the Private Endpoint and the resource (f.e. Azure SQL or Storage Account) linked to that Private Endpoint. The second scenario was to forward and filter all the DNS queries by using FortiGate Virtual Appliance.
## Requirements
-	FortiGate in Azure with at least 2 internal subnets
-	On-premise network connected to FortiGate (in my scenario it was C2S IPSEC VPN)
-	Private endpoint and resource connected to it (in my scenario it was Azure Storage Account)
-	Private DNS Zone ( privatelink.blob.core.windows.net )
## Design
The following diagram illustrates my testing environment. My main task is to make sure that IPSEC VPN clients and virtual machines from ProtectedB network will be able to connect to my storage account through the FortiGate. Since my storage account is available through the PrivateEndpoint my clients has to be able to resolve pcstorage.privatelink.blob.core.windows.net to the ip address of my Private Endpoints interface (172.16.137.6). To do this my FortiGate need to be configured as a DNS Proxy.

<img src=https://github.com/yarafe/Private-Link/blob/main/images/Azure_Private_link_Deployment_with_FGT_with_IPsec.png width="800"/>

## Pushing the traffic targeted to private endpoint through the FortiGate
When you are configuring Private Endpoint there is a routing entry that will be injected into your routing table that look as follow.

<img src=https://github.com/yarafe/Private-Link/blob/main/images/Private_Endpoint_route_entry.png width="800"/>

So, all the traffic targeted to the Private Endpoint interface will be routed through the next hop type which is “InterfaceEndpoint”. Since our task is to push all that traffic through the FortiGate we need to introduce additional routing entry that looks as follow.

<img src=https://github.com/yarafe/Private-Link/blob/main/images/Private_Endpoint_route_entry_to_FGT.png width="800"/>

## Using FortiGate as a DNS Forwarder.
1.	Under the System > Feature Visibility you need to enable DNS Database feature.
2.	Go to the Network > DNS Servers, under DNS Service on Interface we need to run DNS proxy on the specific network interface. 

    Because my task was to use FortiGate as a DNS Forwarer for my “ProtectedB” networtk and for my VPN tunnel I had to add two following entries.
    
    <img src=https://github.com/yarafe/Private-Link/blob/main/images/DNS1.png width="400"/>

    First one is for my “ProtectedB” network that is connected to FortiGate via port2. I’m forwarding DNS queries to System DNS.
    
    <img src=https://github.com/yarafe/Private-Link/blob/main/images/DNS2.png width="400"/>

    The second one is for my IPSECVPN interface

    <img src=https://github.com/yarafe/Private-Link/blob/main/images/DNS3.png width="400"/>

3.	Finally, because we want to forward DNS queries to the System DNS we need to check Network > DNS configuration. By default, FortiGate will be using FortiGuard DNS servers. We need to change it to internal Azure DNS server which is listening on 168.63.129.16.
	
    <img src=https://github.com/yarafe/Private-Link/blob/main/images/DNS4.png width="400"/>
    
 More information about using FortiGate as a DNS Proxy can be foud [here](https://docs.fortinet.com/document/fortigate/6.2.10/cookbook/121810/using-a-fortigate-as-a-dns-server)

## Changing DNS Server for IPSEC VPN client.
1.	Go to VPN > IPSEC TUNNEL and edit your tunnel settings. Under DNS Server we can configure our port2 address:

<img src=https://github.com/yarafe/Private-Link/blob/main/images/IPSEC.png width="400"/>

2.	After connecting C2S tunnel we can check our DNS settings on the client by using nslookup. The first DNS server should be our FortiGates address. 

<img src=https://github.com/yarafe/Private-Link/blob/main/images/nslookup.png width="400"/>

3.	We can check if we are able to resolve our storage accounts DNS name:

<img src=https://github.com/yarafe/Private-Link/blob/main/images/nslookup2.png width="400"/>

To use FortiGate as a DNS server for the machines inside ProtectedB network we need to change DNS configurations on those machines. Here is an example for my Windows VM. I’m using FortiGates port2 interface IP address as a DNS server.

<img src=https://github.com/yarafe/Private-Link/blob/main/images/azureDNScustom.png width="400"/>
