# active/passive high available fortigate pair with external and internal azure standard load balancer

[![[fgt] arm - active-passive-elb-ilb](https://github.com/40net-cloud/fortinet-azure-solutions/actions/workflows/fgt-arm-active-passive-elb-ilb.yml/badge.svg)](https://github.com/40net-cloud/fortinet-azure-solutions/actions/workflows/fgt-arm-active-passive-elb-ilb.yml)

:wave: - [introduction](#introduction) - [design](#design) - [deployment](#deployment) - [requirements](#requirements-and-limitations) - [configuration](#configuration) - [troubleshooting](#troubleshooting) :wave:

## introduction

more and more enterprises are turning to microsoft azure to extend internal data centers and take advantage of the elasticity of the public cloud. while azure secures the infrastructure, you are responsible for protecting everything you put in it. fortinet security fabric provides azure the broad protection, native integration and automated management enabling customers with consistent enforcement and visibility across their multi-cloud infrastructure.

this arm template deploys a high availability pair of fortigate next-generation firewalls accompanied by the required infrastructure. additionally, fortinet fabric connectors deliver the ability to create dynamic security policies.

## design

in microsoft azure, you can deploy an active/passive pair of fortigate vms that communicate with each other and the azure fabric. this fortigate setup will receive the traffic to be inspected using user defined routing (udr) and public ips. you can send all or specific traffic that needs inspection, going to/coming from on-prem networks or public internet by adapting the udr routing.

this azure arm template will automatically deploy a full working environment containing the following components.

- 2 fortigate firewalls in an active/passive deployment
- 1 external azure standard load balancer for communication with internet
- 1 internal azure standard load balancer to receive all internal traffic and forwarding towards azure gateways connecting expressroute or azure vpns
- 1 vnet with 1 protected subnet and 4 subnets required for the fortigate deployment (external, internal, ha mgmt and ha sync). if using an existing vnet, it must already have 5 subnets
- 3 public ips. the first public ip is for cluster access to/through the active fortigate. the other two pips are for management access
- user defined routes (udr) for the protected subnets

![active/passive design](images/fgt-ap.png)

to enhance the availability of the solution, vms can be installed in different availability zones instead of an availability set. if availability zones deployment is selected but the location does not support availability zones an availability set will be deployed. if availability zones deployment is selected and availability zones are available in the location, fortigate a will be placed in zone 1, fortigate b will be placed in zone 2.

![active/passive design](images/fgt-ap-az.png)

this arm template can also be used to be extended or customized based on your requirements. additional subnets besides the ones mentioned above are not automatically generated. by adapting the arm templates you can add additional subnets which preferably require their own routing tables.

## deployment

the fortigate solution can be deployed using the azure portal or azure cli. there are 4 variables needed to kickstart the deployment. the deploy.sh script will ask them automatically. when you deploy the arm template the azure portal will request the variables as a requirement.

- prefix : this prefix will be added to each of the resources created by the templates for ease of use, manageability and visibility.
- location : this is the azure region where the deployment will take place.
- username : the username used to log in to the fortigate gui and ssh management ui.
- password : the password used for the fortigate gui and ssh management ui.

### azure portal

azure portal wizard template deployment:
[![deploy azure portal button](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/microsoft.template/uri/https%3a%2f%2fraw.githubusercontent.com%2f40net-cloud%2ffortinet-azure-solutions%2fmain%2ffortigate%2factive-passive-elb-ilb%2fazuredeploy.json/createuidefinitionuri/https%3a%2f%2fraw.githubusercontent.com%2f40net-cloud%2ffortinet-azure-solutions%2fmain%2ffortigate%2factive-passive-elb-ilb%2fcreateuidefinition.json)

standard custom template deployment:
[![deploy azure portal button](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/microsoft.template/uri/https%3a%2f%2fraw.githubusercontent.com%2f40net-cloud%2ffortinet-azure-solutions%2fmain%2ffortigate%2factive-passive-elb-ilb%2fazuredeploy.json)
[![visualize](https://raw.githubusercontent.com/azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3a%2f%2fraw.githubusercontent.com%2f40net-cloud%2ffortinet-azure-solutions$2fmain%2ffortigate%2factive-passive-elb-ilb%2fazuredeploy.json)

as of march 2026, new fortigate skus were introduced in the azure marketplace that provide access to the latest marketplace features. in specific regions (e.g. govcloud, private offers, ...) and deployment scenarios, legacy skus are still required; [those templates can be found in the legacy directory](legacy/).

- marketplace information:
  - publisher: fortinet
  - offer: fortinet_fortigate-vm
  - sku / plan: fortinet_fg-vm_byol_70, fortinet_fg-vm_payg_70, fortinet_fg-vm_byol_72, fortinet_fg-vm_payg_72, fortinet_fg-vm_byol_74, fortinet_fg-vm_payg_74, fortinet_fg-vm_byol_76, fortinet_fg-vm_payg_76

### azure cli

for microsoft azure there is a second option by using the azure cloud shell. the azure cloud shell is an in-browser cli that contains all tools for deployment into microsoft azure. it is accessible via the azure portal or directly via [https://shell.azure.com/](https://shell.azure.com). you can copy and paste the below one-liner to get started with your deployment.
to deploy via azure cloud shell you can connect via the azure portal or directly to [https://shell.azure.com/](https://shell.azure.com/).

- login into the azure cloud shell
- run the following command in the azure cloud:

`cd ~/clouddrive/ && wget -qo- https://github.com/40net-cloud/fortinet-azure-solutions/archive/main.tar.gz | tar zxf - && cd ~/clouddrive/fortinet-azure-solutions-main/fortigate/active-passive-elb-ilb/ && ./deploy.sh`

- the script will ask you a few questions to bootstrap a full deployment.

![azure cloud shell](images/azure-cloud-shell.png)

after deployment you will be shown the ip address of all deployed components. both fortigate vms are accessible using the public management ips using https on port 443 and ssh on port 22.

## requirements and limitations

the arm template deploys different resources and it is required to have the access rights and quota in your microsoft azure subscription to deploy the resources.

- the azure standard load balancer only supports tcp and udp protocols (https, dns, ssh, ...). to create a highly available architecture where you can use other protocols an architecture with the sdn connector failover is preferred. more details can be found [here](https://docs.microsoft.com/en-us/azure/load-balancer/components)
- in case of failover the azure load balancer will send existing sessions to the failed vm as explained [here](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-custom-probe-overview#probedown).
- the template will deploy standard f4s vms for this architecture. other vm instances are supported as well with a minimum of 4 nics. a list can be found [here](https://docs.fortinet.com/document/fortigate-public-cloud/7.4.0/azure-administration-guide/562841/instance-type-support)
- licenses for fortigate
  - byol: a demo license can be made available via your fortinet partner or on our website. these can be injected during deployment or added after deployment. purchased licenses need to be registered on the [fortinet support site](http://support.fortinet.com). download the .lic file after registration. note, these files may not work until 60 minutes after its initial creation.
  - payg or ondemand: these licenses are automatically generated during the deployment of the fortigate systems.
- the password provided during deployment must meet the password complexity rules from microsoft azure:
  - it must be 12 characters or longer
  - it needs to contain characters from at least 3 of the following groups: uppercase characters, lowercase characters, numbers, and special characters excluding '\' or '-'
- the terms for the fortigate payg or byol image in the azure marketplace need to be accepted once before usage. this is done automatically during deployment via the azure portal. for the azure cli the commands below need to be run before the first deployment in a subscription.
  - byol/flex
`az vm image terms accept --publisher fortinet --offer fortinet_fortigate-vm --plan fortinet_fg-vm-byol_76`
  - payg
`az vm image terms accept --publisher fortinet --offer fortinet_fortigate-vm --plan fortinet_fg-vm_payg_76`

## configuration

the fortigate vms need a specific configuration to match the deployed environment. this configuration can be injected during provisioning or afterwards via the different options including gui, cli, fortimanager or rest api.

- [fabric connector](#fabric-connector)
- [vnet peering](#vnet-peering)
- [east-west connections](#east-west-connections)
- [inbound connections](#inbound-connections)
  - [ipsec configuration](#inbound-ipsec-configuration)
- [outbound connections](#outbound-connections)
  - [nat considerations: 1-to-1 and 1-to-many](#outbound-connections---nat-considerations)
- [ipsec connectivity](../documentation/faq-ipsec-connectivity.md)
- [high availability](#high-availability-probe-configuration)
- [cloud-init](#cloud-init)
- [availability zone](#availability-zone)
- [default configuration using this template](#default-configuration)
- [upload vhd](https://community.fortinet.com/fortigate-azure-technical-learning-161/deployment-of-fortigate-vm-using-a-vhd-image-file-171850)

### fabric connector

the fortigate-vm uses [managed identities](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/) for the sdn fabric connector. a sdn fabric connector is created automatically during deployment. after deployment, it is required to apply the 'reader' role to the azure subscription you want to resolve azure resources from. more information can be found on the [fortinet documentation library](https://docs.fortinet.com/document/fortigate-public-cloud/7.6.0/azure-administration-guide/236610/configuring-an-sdn-connector-using-a-managed-identity).

### vnet peering

in microsoft azure, this central security services hub is commonly implemented using vnet peering. the central security services hub component will receive, using user-defined routing (udr), all or specific traffic that needs inspection going to/coming from on-prem networks or the public internet. this deployment can be used as the hub section of such a [hub-spoke network topology](https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke?tabs=cli#communication-through-an-nva)

![vnet peering](images/vnet-peering.png)

### east-west connections

east-west connections are considered the connections between internal subnets within the vnet or peered vnets. the goal is to direct this traffic via the fortigate.

to direct traffic to the fortigate ngfw routing needs to be adapted on microsoft azure using user defined routing (udr). with udrs the routing in azure can be adapted to send traffic destined for a specific network ip range to a specific destination such as internet, vpn gateway, virtual network (vnet), ... in order for the fortigate to become the destination there is a specific destination called virtual appliance. either the private ip of the fortigate or the private ip of the internal load balancer is provided. more information about user defined routing can be found [here](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview).

in this design an azure standard load balancer internal is used with a specific feature called ha ports. this feature allows fast failover between the different members of the fortigate ha cluster for all tcp, udp and icmp protocols. it is only available in the standard load balancer and as such all load balancers connected to the fortigate need to be of the standard type. also the public ips connected to the fortigate need to be of the standard type. there is no possibility to migrate between basic and standard public ip skus. more information about ha ports can be found [here](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-ha-ports-overview).

#### east-west flow

in the diagram the different steps to establish a session are laid out. this flow is based on the configuration as deployed in this template.

![east west flow](images/eastwest-flow.png)

1. connection from client to the private ip of server. azure routes the traffic using udr to the internal load balancer - s: 172.16.137.4 - d: 172.16.138.4
2. azure internal load balancer probes and send the packet to the active fgt - s: 172.16.137.4 - d: 172.16.138.4
3. fgt inspects the packet and when allowed sends the packet to the server - s: 172.16.137.4 - d: 172.16.138.4
4. the server responds to the request - s: 172.16.137.4 - d: 172.16.138.4
5. the azure external load balancer sends the returns packet to the active fortigate - s: 172.16.137.4 - d: 172.16.138.4
6. the active fgt accepts the return packet after inspection - s: 172.16.137.4 - d: 172.16.138.4

#### east-west configuration

to configure the east-west connectivity to a service there are 2 resources that need to be verified/configured:

- fortigate
- azure user defined routing

the drawing in the [flow](#east-west-flow) section is used in the configuration screenshots.

##### azure user defined routing

<p align="center">
  <img width="500px" src="images/ew-udr-a.png">
</p>

<p align="center">
  <img width="500px" src="images/ew-udr-b.png">
</p>

<p align="center">
  <img width="500px" src="images/ew-udr.png">
</p>

##### fortigate

on the fortigate vm, a firewall policy rule needs to be created to allow traffic from specific ip ranges going in and out of the same internal interface (port2).

make sure to verify that the option allow-traffic-redirect is disabled to make sure the fortigate handles the ingress and egress traffic on the same logical interface. more information can be found in [this article](https://community.fortinet.com/t5/fortigate/technical-tip-traffic-handled-by-fortigate-for-packet-which/ta-p/196651).

#### limitations

- in case of failover the azure load balancer will send existing sessions to the failed vm as explained [here](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-custom-probe-overview#probedown).

### inbound connections

inbound connections are considered the connections coming from the internet towards the azure load balancer to publish services like a webserver or other hosted in the vnet or peered vnets. the published services via the azure load balancer are limited to the tcp and udp protocols, as the azure load balancer does not support any other protocols.

to go beyond the limitation of the azure load balancer and use other protocols (e.g. icmp,esp,ftp,...), an instance level public ip on each of the vms in the cluster is required. load balancing would then be possible using azure traffic manager, azure frontdoor or fortigslb services using dns or anycast mechanisms. using an instance level public ip will change the behaviour of the outbound connections. the use of azure traffic manager or fortigslb services is out of the scope of this article.

there are 2 public ip skus: basic and standard. this template will use the standard sku as we are using the azure standard load balancer. the standard public ip by default is a static allocation. more information can be found [in the microsoft documentation](https://docs.microsoft.com/en-us/azure/virtual-network/public-ip-addresses).

#### inbound flow

in the diagram the different steps to establish a session are laid out. this flow is based on the configuration as deployed in this template.

<p align="center">
  <img width="800px" src="images/inbound-flow.png" alt="inbound flow">
</p>

1. connection from client to the public ip of the azure standard load balancer - s: w.x.y.z - d: a.b.c.d
2. azure lb probes and send the packet to the active fgt using floating ip. no nat - s: w.x.y.z - d: a.b.c.d
3. fgt vip picks up, translates (dnat) and sends the packet to the server via routing in azure - s: w.x.y.z - d: 172.16.137.4
4. server responds to the request and send the packet to default gateway. azure routes the traffic using user defined routing (udr) to the internal load balancer - s: 172.16.137.4 - d: w.x.y.z
5. azure internal load balancer send the traffic to the active fgt - s: 172.16.137.4 - d: w.x.y.z
6. active fgt translates the source to the fgt vip on the external interface - s: a.b.c.d - d: w.x.y.z
7. packet is routed to the client using dsr (direct server return) - s: a.b.c.d - d: w.x.y.z

#### when to enable the floating ip in the azure load balancing rule?

##### traffic transiting the fortigate vms

enabling the floating ip option in a load balancing rule results in the azure load balancer to pass the source and destination ip unchanged to the backend fortigate vms. in the fortigate vm you can use the virtual ip (vip) construct to pick up this traffic and perform destination network address translation (dnat).

if you disable the floating ip option on the load balancing rule the destination ip of the inbound packet is translated (dnat) to the ip address of the backend fortigate vms as configured in the backend configuration of the azure load balancer. in our example, this would be 172.16.136.5 or 172.16.136.6 for the primary or secondary fortigate respectively. to configure the fortigate for a non floating ip load balancing rule it is required to create a vip with the same name on each fortigate vm and assign it in the rulebase on both units.

in case you have a requirement to host multiple public ips for different services using the floating ip method makes it easy for the fortigate to distinguish the different inbound requests.

an example of the configuration of the fortigate can be found [here](#fortigate).

##### traffic connecting to a service on the fortigate vms

for traffic destined to terminate on the fortigate vms (e.g. ipsec tunnels, ssl vpn, ...) the fortigate is by default not aware of the public ip address attached to the azure load balancer. in this case, where you have the service part of the fortigate vms it is best practice to disable the floating ip option.

an example of the configuration of the fortigate can be found [here](#inbound-ipsec-configuration).

#### inbound configuration

to configure the inbound connectivity to a service there are 2 resources that need to be adapted:

- azure standard load balancer rules
- fortigate

the drawing in the [flow](#inbound-flow) section is used in the configuration screenshots with a standard public ip in azure of 51.124.146.120 and the backend vm having the internal ip 172.16.137.4.

##### azure standard load balancer

after deployment of the template, the external azure load balancer is available in the resource group. once opened, the load balancing rules will show you 2 default rules one for tcp/80 and one for udp/10551. these rules are not required and are created as the azure load balancer needs these to allow tcp/udp traffic outbound.

<p align="center">
  <img width="500px" src="images/inbound-lbrules.png" alt="inbound load balancing rules">
</p>

to create a new rule you can follow the settings from the tcp/80 rule that was automatically created. the following variables need verification and/or completion:

- name: complete with a name for this specific rule
- frontend ip address: select the default frontend public ip or any additional frontend ip that was added to the azure load balancer
- protocol: what protocol is the inbound connection using: tcp or udp
- port: the port used by the client to connect to the public ip on the azure load balancer
- backend port: if you want to configure port translation you can specify a different port. otherwise the same port as in the port field is used
- backend pool: this needs to be the backend pool created by the template which contains fortigate instances
- health probe: the azure load balancer sends out a probe to a tcp/udp port to verify if the vm is up and running. in the fortigate a specific probe config is activated on tcp/8008
- session persistence: by default the azure load balancer uses a 5 tuple distribution mode. if only the client ip and optionally the protocol need to provide persistence you change this here.. more information on this topic can be found [here](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-distribution-mode)
- floating ip (direct server return): this setting needs to be enabled for any service located behind the fortigate. this will allow the packet towards the fortigate to contain the public ip as the destination ip. that allows for easy identification and policy enforcement of the inbound connection on the fortigate. services running on the fortigate like ipsec disable this option. it allows the ipsec engine to pick up the traffic to the local process on the private ip of the vm.
- create implicit outbound rules: enabling this option will create an outbound snat rule for this protocol (tcp, udp) and frontend ip address. this allows the azure load balancer to use this frontend ip address for outbound connections.


<p align="center">
  <img width="500px" src="images/inbound-lbrule-create.png" alt="lb rules create">
</p>

##### fortigate

on the fortigate a virtual ip (vip) needs to be created as well as a firewall policy to allow traffic to be translated and passed to the backend server.

the virtual ip (vip) is used to translate the inbound packets destination ip and optionally destination port towards the backend server.

- name: a name for this vip
- external ip address/range: the frontend ip configured on the azure load balancer for this service
- internal ip address/range: the internal ip of the service or internal azure load balancer used to load balance multiple servers
- port forwarding: the port used for the service e.g. port 80.
***caveat:***** if the port forwarding option is not enabled outbound connectivity might be impacted. the fortigate will translate all outbound traffic from the internal ip address/range to the external ip address which causes azure to drop these packets. nat to a public ip is always managed by microsoft azure.**

<p align="center">
  <img width="500px" src="images/inbound-fgt-vip.png" alt="fortigate vip">
</p>

secondly, a firewall policy rule needs to be created to allow the packets to traverse the fortigate and configure any security inspection for the communication.

- name: a name for this vip
- incoming interface: the interface where the packet is coming from. in this template it is port1
- outgoing interface: the interface where the packet is routed to, to connect to the internal server
- source: restrict which ip can connect to the service here or set this to all
- destination:  the vip created in step one
- service: the destination port on the internal server
- nat: source nat is not needed for an active/passive setup. for an active/active setup it is recommended so the packet is returning to the firewall that maintains the state of the session

<p align="center">
  <img width="500px" src="images/inbound-fgt-policy.png" alt="fortigate policy">
</p>

#### inbound ipsec configuration

connectivity is one of the main use cases for the deployment of a fortigate ngfw in microsoft azure. to connect branches and datacenters to the fortigate vm, a few items need to be taken into account.

- terminating an ipsec tunnel via the azure load balancer is limited to the tcp and udp protocols. for ipsec this means that both endpoints need to support nat-t and run the data connection over udp/4500 instead of the esp protocol.
- in the azure load balancer 2 load balancing rules need to be created:
<p align="center">
  <img width="500px" src="images/inbound-ipsec-rules.png" alt="lb rules ipsec">
</p>
  - ike on port udp/500
<p align="center">
  <img width="500px" src="images/inbound-ipsec-ike.png" alt="lb rule ike udp/500">
</p>
  - ipsec nat-t on port udp/4500
<p align="center">
  <img width="500px" src="images/inbound-ipsec-natt.png" alt="lb rule natt udp/4500">
</p>
- on the fortigate configure an ipsec tunnel either with the ipsec wizard or a custom ipsec tunnel. the fortigate to fortigate wizard enables nat-t automatically. for a custom ipsec tunnel make sure to enable this feature.

  - ipsec wizard
<p align="center">
  <img width="500px" src="images/inbound-ipsec-fgt-wizard.png" alt="fgt ipsec wizard">
</p>

  - ipsec custom
<p align="center">
  <img width="500px" src="images/inbound-ipsec-fgt-custom.png" alt="fgt ipsec custom">
</p>

### outbound connections

outbound connections are considered the connections coming from the internal subnets within the vnet or peered vnets via the fortigate towards the internet.

to direct traffic to the fortigate ngfw routing needs to be adapted on microsoft azure using user defined routing (udr). with udrs the routing in azure can be adapted to send traffic destined for a specific network ip range to a specific destination such as internet, vpn gateway, virtual network (vnet), ... in order for the fortigate to become the destination there is a specific destination called virtual appliance. either the private ip of the fortigate or the frontend ip of the internal load balancer is provided. more information about user defined routing can be found [here](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview).

in this design an azure standard load balancer internal is used with a specific feature called ha ports. this feature allows fast failover between the different members of the fortigate ha cluster for all tcp, udp and icmp protocols. it is only available in the standard load balancer and as such all load balancers connected to the fortigate need to be of the standard type. also the public ips connected to the fortigate need to be of the standard type. there is no possibility to migrate between basic and standard public ip skus. more information about ha ports can be found [here](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-ha-ports-overview).

#### outbound flow

in the diagram the different steps to establish a session are laid out. this flow is based on the configuration as deployed in this template.

![outbound flow](images/outbound-flow.png)

1. connection from client to the public ip of server. azure routes the traffic using udr to the internal load balancer. - s: 172.16.137.4 - d: a.b.c.d
2. azure internal load balancer probes and send the packet to the active fgt. - s: 172.16.137.4 - d: a.b.c.d
3. fgt inspects the packet and when allowed sends the packet translated to its external port private ip to the azure external load balancer. - s: 172.16.136.5 - d: a.b.c.d
4. the azure external load balancer picks one of the available public ip address attached and translates the source ip - s: w.x.y.z - d: a.b.c.d
5. the server responds to the request - s: a.b.c.d - d: w.x.y.z
6. the azure external load balancer sends the returns packet to the active fortigate - s: a.b.c.d - d: 172.16.136.5
7. the active fgt accepts the return packet after inspection. it translates and routes the packet to the client - s: a.b.c.d - d: 172.16.137.4

#### outbound configuration

outbound connectivity in azure has several properties that are specific to the platform. these need to be taken into account. this configuration is a basic configuration that will nat all outbound connections behind 1 or more public ips on the azure load balancer. more specific cases are explained [here](#outbound-connections---nat-considerations).

this template deploys 2 azure load balancers with a standard sku which requires standard sku public ip connected to the vm or load balancer. a standard sku public ip requires a network security group, is zone aware and always has a static assignment.

for more information on outbound connections in azure the microsoft documentation can be found [here](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-outbound-connections).

to configure the outbound connectivity to a service there are 2 resources that need to be verified/configured:

- fortigate
- azure standard load balancer rules

the drawing in the [flow](#outbound-flow) section is used in the configuration screenshots with a standard public ip in azure of 40.114.187.146 on the azure load balancer, the fortigate private ip of 172.16.136.5 (primary) or 172.16.136.6 (secondary) and the backend vm having the internal ip 172.16.137.4.

##### azure standard load balancer

after deployment of the template, the external azure load balancer is available in the resource group. once opened, the load balancing rules will show you 2 default rules one for tcp/80 and one for udp/10551. these rules are not required and are created as the azure load balancer needs these to allow tcp/udp traffic outbound.

if there is a public ip assigned to the port1 network interface of the fortigate where also the azure load balancer is connected this will take precedence outbound nat.

the inbound rules have the option enabled to create outbound rules automatically. this enables outbound snat using the configured frontend ip for traffic coming from the fortigate vm with its private ip.

<p align="center">
  <img width="500px" src="images/inbound-lbrule-create.png">
</p>

##### fortigate

on the fortigate vm, a firewall policy rule needs to be created to allow traffic from the internal interface to the external interface with any or specific ip ranges and nat enabled using the "outgoing interface address".

<p align="center">
  <img width="500px" src="images/outbound-fgt-policy.png">
</p>

the nat behind the fortigate outgoing interface allows for a very simple configuration. on failover the private ip of the fortigate outgoing interface changes but there is no configuration change needed.

#### limitations

- azure has certain limitations on outbound connections, [more info](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-outbound-connections#limitations)
- azure has a limited number of outbound ports it can allocate per public ip. more information and optimisations can be found [here](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-outbound-connections#preallocatedports)
- in case of failover the azure load balancer will send existing sessions to the failed vm as explained [here](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-custom-probe-overview#probedown).

### outbound connections - nat considerations

this chapter goes beyond the [default scenario](#outbound-connections) with 1 or multiple public ips that handle all outbound traffic. the azure load balancer has a pool of ips that can be used. in some deployments customers would like to have specific 1-to-1 nat or nat behind separate public ips for one service, server or user. these nat scenarios are mostly requested for specific acls implemented at the other side or for validation of public ips in case of sending email, ...

the azure load balancer is limited in available outbound rules direct traffic as we would like for 1-to-1 nat or nat of specific services. the outbound rules only apply to the primary ip configuration of a nic (limitations can be found [here](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-outbound-connections#limitations)). this prevents us from differentiating the traffic based on different outbound ips on the fortigate.

to achieve this nat one or more public ips needs to be attached to the external nic of the fortigate. in this active-passive ha cluster it is best to use the sdn connector to failover the public ip from the primary to the secondary in case of failure of the primary fortigate.

#### outbound nat flow

in the diagram the different steps to establish a session are laid out. this flow is based on the configuration as deployed in this template.

![outbound flow](images/outbound-121-flow.png)

1. connection from client to the public ip of server. azure routes the traffic using udr to the internal load balancer - s: 172.16.137.4 - d: a.b.c.d
2. azure internal load balancer probes and send the packet to the active fgt - s: 172.16.137.4 - d: a.b.c.d
3. fgt inspects the packet and when allowed performs source nat using ip pool settings to the secondary ip on the external interface - s: 172.16.136.7 (or 8) - d: a.b.c.d
4. the azure router will nat the source ip of the packet to the attached public ip - s: w.x.y.z - d: a.b.c.d
5. the server responds to the request - s: a.b.c.d - d: w.x.y.z
6. the azure router nats the destination address to the private ip of the secondary ip configuration of the external nic attached to the public ip - s: a.b.c.d - d: 172.16.136.7 (or 8)
7. the active fgt accepts the return packet after inspection. it translates and routes the packet to the client - s: a.b.c.d - d: 172.16.137.4

#### outbound nat configuration

outbound connectivity in azure has several properties that are specific to the platform. these need to be taken into account.

for more information on outbound connections in azure the microsoft documentation can be found [here](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-outbound-connections).

to configure the 1-to-1 outbound connectivity to a service there are 2 resources that need to be verified/configured:

- azure portal: public ip and network interfaces of both fortigate vms
- fortigate

the drawing in the [flow](#outbound-nat-flow) section is used in the configuration screenshots with a standard public ip in azure of 40.114.187.146 on the azure load balancer, the fortigate private ip of 172.16.136.5 (primary) or 172.16.136.6 (secondary) and the backend vm having the internal ip 172.16.137.4.

##### azure portal

1. create a new public ip in azure. make sure to match the other public ip skus used connected to the fortigate cluster and azure load balancer. the sku needs to be 'standard' when using the azure load balancer in this setup.

<p align="center">
  <img width="500px" src="images/outbound-121-azure-create-public-ip.png">
</p>

2. add a secondary private ip address on the nic1 (external nic) of the primary fortigate vm in azure. associate the public ip created in step 1.

<p align="center">
  <img width="500px" src="images/outbound-121-azure-fgta-ip-configuration.png">
</p>

<p align="center">
  <img width="500px" src="images/outbound-121-azure-fgta-ip-configuration2.png">
</p>

3. add a secondary private ip address on the nic1 (external nic) of the secondary fortigate vm in azure. do not associate the public ip created in step 1.

<p align="center">
  <img width="500px" src="images/outbound-121-azure-fgtb-ip-configuration.png">
</p>

##### fortigate

on the fortigate vm, a firewall policy rule needs to be created to allow traffic from the internal interface to the external interface with any or specific ip ranges and nat enabled using the "outgoing interface address".

1. open the cli of primary fortigate and execute the below commands to make a vdom exception. this will cause the ip pool objects to not synchronize between cluster members. this feature is available in fortios 6.2.4, 6.4.0 or above. each fortigate vm needs to have a unique ip pool configured because each has a unique secondary private ip address which was configured in the azure portal.

```
config system vdom-exception
edit 0
  set object firewall.ippool
next
end
```

2. in the primary fortigate gui configure an ip pool with the private ip address of ifconfig2 as the external ip address

<p align="center">
  <img width="500px" src="images/outbound-121-fgta-ip-pool.png">
</p>

3. in the secondary fortigate gui configure an ip pool with the private ip address of ifconfig2 as the external ip address. make sure the name is exactly the same as on the primary unit to match the firewall policy

<p align="center">
  <img width="500px" src="images/outbound-121-fgtb-ip-pool.png">
</p>

3. configure firewall policy using ip pool object from step 4 & 5 for example for particular server which you would like to use public ip configured in step 1 for outbound connections instead of public ip attached to azure external load balancer.

<p align="center">
  <img width="500px" src="images/outbound-121-fgt-policy.png">
</p>

4. configure the azure fabric connector on the fortigate cli. via an api call to azure it will move the public ip from nic1 of primary fortigate to nic1 of secondary fortigate in case ha cluster failover. to authenticate to azure either managed identity or a service principal can be used. the authentication must be configured for the azure fabric connector to work and information can be found on the [fortinet documentation site](https://docs.fortinet.com/document/fortigate-public-cloud/7.2.0/azure-administration-guide/502895/configuring-an-sdn-connector-in-azure).

- primary fortigate

```text
config system sdn-connector
    edit "azuresdn"
        set type azure
        set ha-status enable
        config nic
            edit "accelerate-fgt-a-nic1"
                config ip
                    edit "ipconfig2"
                        set public-ip "accelerate-fgt-servicea"
                    next
               end
           next
       end
end
```

- secondary fortigate

```text
config system sdn-connector
    edit "azuresdn"
        set type azure
        set ha-status enable
        config nic
            edit "accelerate-fgt-b-nic1"
                config ip
                    edit "ipconfig2"
                        set public-ip "accelerate-fgt-servicea"
                    next
               end
           next
       end
end
```

#### outbound nat limitations

- azure has certain limitations on outbound connections: https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-outbound-connections#limitations
- traffic not matching the firewall policy created here will use the standard nat via the azure load balancer
- failover using the sdn connector is dependent on the execution time of the azure api. if that timing is not acceptable it is possible to configure a public ip on both nics and not use the sdn connector. the downside is that each firewall has a different public ip address

### high availability

for this active/passive setup external and internal load balancers are used. these need to detect which fortigate vms are online. this is done using a health probe on both azure load balancers.

#### high availability probe configuration

##### azure load balancer

on both the internal and the external azure load balancer a probe needs to be configured and attached to load balancing rules for the fortigate backend systems.

on the external azure load balancer this probe is needed for each port you open. on the internal azure load balancer a catch-all 'ha port' rule is used.

![ha probe](images/ha-probe1.png)
![ha probe 2](images/ha-probe2.png)

##### fortigate

the probe configured on the azure load balancer needs to be enabled on the fortigate. there are 4 lines of config that will enable the active fortigate to respond on tcp port 8008 based on the state of the fgcp unicast ha protocol.

```text
config system probe-response
  set http-probe-value ok
  set mode http-probe
end
```

the microsoft azure load balancer sends out probes from a specific ip, 168.63.129.16. this ip requires to have a response from the same interface as it packet arrived from. to ensure that the probes sent for the external or internal load balancer are sent via the correct interface, the configuration deployed by the template adds static routes for this microsoft probe ip for both the external and internal interface of the firewall.

more information about this probe and the source ip can be found [here](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-custom-probe-overview#probesource)

```text
config router static
  edit 3
    set dst 168.63.129.16 255.255.255.255
    set device port2
    set gateway <b>172.16.136.65</b>
  next
  edit 4
    set dst 168.63.129.16 255.255.255.255
    set device port1
    set gateway <b>172.16.136.1</b>
  next
end
```

### cloud-init

microsoft azure offers the possibility to inject a configuration during deployment. this method is referred to as cloud-init. both using templates (arm or terraform) or via cli (powershell, azure cli), it is possible to provide a file with this configuration. in the case of fortigate there are 3 options available.

#### inline configuration file

in this arm template, a fortigate configuration is passed via the customdata field used by azure for the cloud-init process. using variables and parameters you can customize the configuration based on the input provided during deployment. the full configuration injected during deployment with the default parameters can be found [here](#default-configuration).

```text
...
    "fgacustomdata": "[base64(concat('config system...
...
  "osprofile": {
...
    "customdata": "[variables('fgacustomdata')]"
  },
...
```

#### inline configuration and license file

to provide the configuration and the license during deployment it is required to encode both using mime. part 1 will contain the fortigate configuration and part 2 can contain the fortigate license file. the code snippet below requires the config and license file content in the respective bold text placeholders.

```text
content-type: multipart/mixed; boundary="===============0086047718136476635=="
mime-version: 1.0

--===============0086047718136476635==
content-type: text/plain; charset="us-ascii"
mime-version: 1.0
content-transfer-encoding: 7bit
content-disposition: attachment; filename="config"

<b>your fortigate configuration file</b>

--===============0086047718136476635==
content-type: text/plain; charset="us-ascii"
mime-version: 1.0
content-transfer-encoding: 7bit
content-disposition: attachment; filename="${fgt_license_file}"

<b>your fortigate license file content</b>

--===============0086047718136476635==--

```

if you want to inject the license file via the azure cli, powershell or via the azure portal (custom deployment) as a string, you need to remove the newline characters. the string in the 'fortigatelicensebyola' or 'fortigatelicensebyolb' parameters should be without newline. to remove the newline or carriage return out of the license file retrieved from fortinet support you can use the below command:

bash

```text
$ tr -d '\r\n' < fgvmxxxxxxxxxxxx.lic

-----begin fgt vm license-----yourlicensecode-----end fgt vm license-----
```

powershell

```text
> (get-content 'fgvmxxxxxxxxxxxx.lic') -join ''

-----begin fgt vm license-----yourlicensecode-----end fgt vm license-----
```

#### externally loaded configuration and/or license file

in certain environments it is possible to pull a configuration and license from a central repository. for example an azure storage account or configuration management system. it is possible to provide these instead of the full configuration. the configuri and licenseuri need to be replaced with a http(s) url that is accessible by the fortigate during deployment.

```text
{
  "config-url": "<b>configuri</b>",
  "license-url": "<b>licenseuri</b>"
}
```

it is recommended to secure the access to the configuration and license file using an sas token. more information can be found [here](https://docs.microsoft.com/en-us/azure/storage/common/storage-sas-overview).

#### more information

these links give you more information on these provisioning techniques:

- [https://docs.microsoft.com/en-us/azure/virtual-machines/custom-data](https://docs.microsoft.com/en-us/azure/virtual-machines/custom-data)
- [https://docs.fortinet.com/document/fortigate-public-cloud/7.4.0/azure-administration-guide/61731/bootstrapping-the-fortigate-cli-and-byol-license-at-initial-bootup-using-user-data](https://docs.fortinet.com/document/fortigate-public-cloud/7.4.0/azure-administration-guide/61731/bootstrapping-the-fortigate-cli-and-byol-license-at-initial-bootup-using-user-data)

#### debugging

after deployment, it is possible to review the cloudinit data on the fortigate by running the command 'diag debug cloudinit show'

```text
ftnt-fgt-a # diagnose debug cloudinit show
 >> checking metadata source azure
 >> azure waiting for customdata file
 >> azure waiting for customdata file
 >> azure customdata file found
 >> azure cloudinit decrypt successfully
 >> mime parsed config script
 >> mime parsed vm license
 >> azure customdata processed successfully
 >> trying to install vmlicense ...
 >> run config script
 >> finish running script
 >> ftnt-fgt-a $  config system sdn-connector
 >> ftnt-fgt-a (sdn-connector) $  edit azuresdn
 >> ftnt-fgt-a (azuresdn) $  set type azure
 >> ftnt-fgt-a (azuresdn) $  next
 >> ftnt-fgt-a (sdn-connector) $  end
 >> ftnt-fgt-a $  config router static
 >> ftnt-fgt-a (static) $  edit 1
...
```

### availability zone

microsoft defines an availability zone to have the following properties:

- unique physical location within an azure region
- each zone is made up of one or more datacenter(s)
- independent power, cooling and networking
- inter availability zone network latency < 2ms (radius of +/- 100km)
- fault-tolerant to protect from datacenter failure

based on information in the presentation ['inside azure datacenter architecture with mark russinovich' at microsoft ignite 2019](https://www.youtube.com/watch?v=x-0v6byftpa)

![active/passive design](images/fgt-ap-az.png)

### default configuration

after deployment, the below configuration has been automatically injected during the deployment. the bold sections are the default values. if parameters have been changed during deployment these values will be different.

#### fortigate a

<pre><code>
config system sdn-connector
  edit azuresdn
    set type azure
  next
end
config router static
  edit 1
    set gateway <b>172.16.136.1</b>
    set device port1
  next
  edit 2
    set dst <b>172.16.136.0/22</b>
    set device port2
    set gateway <b>172.16.136.65</b>
  next
  edit 3
    set dst 168.63.129.16 255.255.255.255
    set device port2
    set gateway <b>172.16.136.65</b>
  next
  edit 4
    set dst 168.63.129.16 255.255.255.255
    set device port1
    set gateway <b>172.16.136.1</b>
  next
end
config system probe-response
  set http-probe-value ok
  set mode http-probe
end
config system interface
  edit port1
    set mode static
    set ip <b>172.16.136.5/26</b>
    set description external
    set allowaccess probe-response
  next
  edit port2
    set mode static
    set ip <b>172.16.136.69/26</b>
    set description internal
    set allowaccess probe-response
  next
  edit port3
    set mode static
    set ip <b>172.16.136.133/26</b>
    set description hasyncport
  next
  edit port4
    set mode static
    set ip <b>172.16.136.197/26</b>
    set description hammgmtport
    set allowaccess ping https ssh ftm
  next
end
config system ha
  set group-name azureha
  set mode a-p
  set hbdev port3 100
  set session-pickup enable
  set session-pickup-connectionless enable
  set ha-mgmt-status enable
  config ha-mgmt-interfaces
    edit 1
      set interface port4
      set gateway <b>172.16.136.193</b>
    next
  end
  set override disable
  set priority 255
  set unicast-hb enable
  set unicast-hb-peerip <b>172.16.136.134</b>
end
</code></pre>

#### fortigate b

<pre><code>
config system sdn-connector
  edit azuresdn
    set type azure
  next
end
config router static
  edit 1
    set gateway <b>172.16.136.1</b>
    set device port1
  next
  edit 2
    set dst <b>172.16.136.0/22</b>
    set device port2
    set gateway <b>172.16.136.65</b>
  next
  edit 3
    set dst 168.63.129.16 255.255.255.255
    set device port2
    set gateway <b>172.16.136.65</b>
  next
  edit 4
    set dst 168.63.129.16 255.255.255.255
    set device port1
    set gateway <b>172.16.136.1</b>
  next
end
config system probe-response
  set http-probe-value ok
  set mode http-probe
end
config system interface
  edit port1
    set mode static
    set ip <b>172.16.136.6/26</b>
    set description external
    set allowaccess probe-response
  next
  edit port2
    set mode static
    set ip <b>172.16.136.70/26</b>
    set description internal
    set allowaccess probe-response
  next
  edit port3
    set mode static
    set ip <b>172.16.136.134/26</b>
    set description hasyncport
  next
  edit port4
    set mode static
    set ip <b>172.16.136.198/26</b>
    set description hammgmtport
    set allowaccess ping https ssh ftm
  next
end
config system ha
  set group-name azureha
  set mode a-p
  set hbdev port3 100
  set session-pickup enable
  set session-pickup-connectionless enable
  set ha-mgmt-status enable
  config ha-mgmt-interfaces
    edit 1
      set interface port4
      set gateway <b>172.16.136.193</b>
    next
  end
  set override disable
  set priority 1
  set unicast-hb enable
  set unicast-hb-peerip <b>172.16.136.133</b>
end
</code></pre>

## troubleshooting

there are different components in the whole delivery chain

- [azure load balancer](#troubleshooting-azure-load-balancer)
- [network security groups](#troubleshooting-network-security-groups-nsg)
- [standard public ip](#troubleshooting-standard-public-ip)
- [fortigate](#troubleshooting-fortigate)
- [ipsec troubleshooting](../documentation/faq-ipsec-connectivity.md#troubleshooting)

### troubleshooting azure load balancer

the azure load balancer comes in 2 different flavors/skus: basic and standard. due to the requirements in this deployment standard sku load balancers are used in this setup.
microsoft provides extensive documentation on the azure load balancer [here](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-overview). before deployment it is advised to verify the [different components and concepts](https://docs.microsoft.com/en-us/azure/load-balancer/components) of the azure load balancer.

once deployed and the traffic is somehow not flowing as expected the azure load balancer, as it is in the data path, could be the source. most of the issues seen with the azure load balancer are regarding the health probes not responding. the current status of the health probes can be verified in the azure portal > your azure load balancer > monitoring > metrics > metric - 'health probe status'. the example taken from a test setup shows a health probe that stops responding around 5:30 pm.

<p align="center">
  <img width="500px" src="images/troubleshooting-loadbalancer.png">
</p>

microsoft provides additional troubleshooting steps on the azure load balancer [here](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-troubleshoot).

### troubleshooting network security groups (nsg)

microsoft provides access control lists (acl) on azure networking attaching to a subnet or a network interface of a virtual machine. debugging is possible by writing logs to a storage account or azure log analytics. more information can be found [here](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log)

below you can see an output in json of a log rule as they can be found on the storage account:

```
{
  "records": [
    {
      "time": "2020-08-03t07:18:43.2317151z",
      "systemid": "ca0eb670-63ac-4f05-9d82-7c01addd59f3",
      "macaddress": "000d3abeb097",
      "category": "networksecuritygroupflowevent",
      "resourceid": "/subscriptions/f7f4728a-781f-470f-b029-bac8a9df75af/resourcegroups/jvhazs-rg/providers/microsoft.network/networksecuritygroups/jvhazs-host1-nsg",
      "operationname": "networksecuritygroupflowevents",
      "properties": {
        "version": 2,
        "flows": [
          {
            "rule": "defaultrule_denyallinbound",
            "flows": [
              {
                "mac": "000d3abeb097",
                "flowtuples": [
                  "1596439087,94.102.51.77,10.0.0.4,58501,8121,t,i,d,b,,,,",
                  "1596439097,194.26.29.143,10.0.0.4,53411,32457,t,i,d,b,,,,",
                  "1596439102,87.251.74.200,10.0.0.4,44755,8213,t,i,d,b,,,,",
                  "1596439103,45.129.33.8,10.0.0.4,51401,9849,t,i,d,b,,,,"
                ]
              }
            ]
          }
        ]
      }
    }
  ]
}

```

### troubleshooting standard public ip

the standard public ip has some extra features like zone redundancy. the most important property of this standard sku resource is that inbound communication fails until a network security group is associated with the network interface or subnet that allows the inbound traffic.

more information can be found [here](https://docs.microsoft.com/en-us/azure/virtual-network/public-ip-addresses#standard)

### troubleshooting fortigate

on the fortigate there is a plethora of troubleshooting tools available. more can be found [here](https://docs2.fortinet.com/document/fortigate/6.4.3/administration-guide/244292/troubleshooting).

for your deployment in azure there are some specific items to be aware of:

- accelerated networking: this enables direct connection from the vm to the backend ethernet hardware on the hypervisor and enables much better throughput.
  - on the fortigate you can retrieve the network interface configuration. the sr-iov pseudo interface should only be available when accelerated networking is activated. on the driver side the driver called 'hv_netvsc' needs to be active. if the speed lists 40000full or 50000full the accelerated networking driver is active. the fortios gui does not display the virtual interface.
  - on the azure portal it can be verified on the network interface properties pane. alternatively this information can be requested via the azure cli.

```text
<vm name> # fnsysctl ifconfig
port1 link encap:ethernet hwaddr 00:0d:3a:b4:87:70
inet addr:172.29.0.4 bcast:172.29.0.255 mask:255.255.255.0
up broadcast running multicast mtu:1500 metric:1
rx packets:5689 errors:0 dropped:0 overruns:0 frame:0
tx packets:0 errors:0 dropped:0 overruns:0 carrier:0
collisions:0 txqueuelen:1000
rx bytes:1548978 (1.5 mb) tx bytes:0 (0 bytes)
sriovslv0 link encap:ethernet hwaddr 00:0d:3a:b4:87:70
up broadcast running slave multicast mtu:1500 metric:1
rx packets:35007 errors:0 dropped:0 overruns:0 frame:0
tx packets:33674 errors:0 dropped:0 overruns:0 carrier:0
collisions:0 txqueuelen:1000
rx bytes:34705194 (33.1 mb) tx bytes:10303956 (9.8 mb)
```

```text
<vm name> # diagnose hardware deviceinfo nic port1
name: port1
driver: hv_netvsc
...
speed:           40000full
```

or

```text
<vm name> # diagnose hardware deviceinfo nic port1
name: port1
driver: hv_netvsc
...
speed:           50000full

```

azure cli nic information

```text
# az network nic show -g <resource group name> -n <nic name>
```

- fabric connector: this connector enables integration with the azure platform. more troubleshooting can be found [here](https://docs.fortinet.com/document/fortigate-public-cloud/7.2.0/azure-administration-guide/985498/troubleshooting-azure-sdn-connector)

## support

fortinet-provided scripts in this and other github projects do not fall under the regular fortinet technical support scope and are not supported by forticare support services.
for direct issues, please refer to the [issues](https://github.com/fortinet/azure-templates/issues) tab of this github project.
for other questions related to this project, contact [github@fortinet.com](mailto:github@fortinet.com).

## license

[license](/../../blob/main/license) © fortinet technologies. all rights reserved.
