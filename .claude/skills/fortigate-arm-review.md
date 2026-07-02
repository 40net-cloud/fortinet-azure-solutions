# FortiGate ARM Template Best Practices Review

When invoked, review FortiGate Azure ARM templates against the best practices extracted from this repository. Check each section methodically and report findings with file and line references.

---

## Invocation

Use this skill with `/fortigate-arm-review` or by asking Claude to "review this ARM template against FortiGate best practices."

Scope: ARM templates only (`azuredeploy.json`, `mainTemplate.json`, nested templates). Skip Terraform, Bicep, and createUiDefinition files unless explicitly asked.

---

## Review Checklist

Work through every category below. For each finding, note: category, what is wrong, what it should be, and the JSON path or line number.

### 1. Template Schema and Version

- `$schema` must be `https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#`
- `contentVersion` must be `"1.0.0.0"`

### 2. Required Standard Parameters

Every FortiGate ARM template must have these parameters (check name, type, and that a `metadata.description` is present):

| Parameter | Type | Notes |
|---|---|---|
| `adminUsername` | string | No default – must be supplied at deploy time |
| `adminPassword` | securestring | No default – must be supplied |
| `fortiGateNamePrefix` | string | No default – drives all resource naming |
| `fortiGateLicenseType` | string | allowedValues: `fortinet_fg-vm_byol`, `fortinet_fg-vm_payg`; default `fortinet_fg-vm_byol` |
| `fortiGateInstanceArchitecture` | string | allowedValues: `x64`, `_g2`, `_arm64`; default `x64` |
| `fortiGateImageVersion_x64` | string | Curated allowedValues list only |
| `fortiGateImageVersion_x64_g2` | string | Curated allowedValues list only |
| `fortiGateImageVersion_arm64` | string | Curated allowedValues list only |
| `fortiGateAdditionalCustomData` | string | Default `""` |
| `instanceType_x64` | string | allowedValues list of supported sizes |
| `instanceType_x64_g2` | string | allowedValues list; must support 4 NICs for HA templates |
| `instanceType_arm64` | string | allowedValues list of `Standard_D*ps*` / `Standard_E*ps*` |
| `acceleratedNetworking` | string | allowedValues: `true`, `false`; HA default `true` |
| `acceleratedConnections` | bool | default `false` |
| `acceleratedConnectionsSku` | string | allowedValues: `A1`, `A2`, `A4`, `A8`; default `A1` |
| `serialConsole` | string | allowedValues: `yes`, `no`; default `yes` |
| `fortiManager` | string | allowedValues: `yes`, `no`; default `no` |
| `fortiManagerIP` | string | default `""` |
| `fortiManagerSerial` | string | default `""` |
| `location` | string | default `[resourceGroup().location]` |
| `tagsByResource` | object | default `{}` |
| `fortinetTags` | object | Must include `publisher`, `template`, and `provider` fields |

Single-VM templates also need `fortiGateLicenseBYOL`, `fortiGateLicenseFortiFlex`, `customImageReference`, `customVHDSource`.

HA templates (Active-Passive, Active-Active) need per-node license params (`fortiGateLicenseBYOLA/B`, `fortiGateLicenseFortiFlexA/B`) and availability params (`availabilityOptions`, `availabilityZoneNumber`).

HA templates with 4 NICs also need `availabilityOptions` with correct allowedValues.

### 3. Parameter Naming Conventions

- Prefix `fortiGate` for FortiGate-specific parameters.
- Subnet parameters: `subnet1Name`, `subnet1Prefix`, `subnet1StartAddress` (numbered sequentially).
- Public IP parameters: `publicIP1NewOrExisting` / `publicIP1Name` / `publicIP1ResourceGroup` (numbered).
- Use camelCase throughout.
- `fortiGateName` (optional override) must default to `""`.

### 4. fortinetTags Object

The `fortinetTags` parameter default must always contain exactly:
```json
{
  "publisher": "Fortinet",
  "template": "<template-folder-name>",
  "provider": "6EB3B02F-50E5-4A3E-8CB8-2E12925831<XX>"
}
```
- `provider` suffix (`<XX>`) is unique per template type: `VM` for single, `AP` for active-passive, `AA` for active-active, etc.
- The `template` value must match the folder/scenario name exactly.

### 5. Required Variables

Check that all of the following variables are present and use the correct expressions:

**Image/SKU resolution:**
```
"imagePublisher": "fortinet"
"imageOffer": "fortinet_fortigate-vm"
"VMInstanceArchitecture": "[if(equals(parameters('fortiGateInstanceArchitecture'),'x64'),'',parameters('fortiGateInstanceArchitecture'))]"
"fortiGateImageVersion": "[if(equals(parameters('fortiGateInstanceArchitecture'), '_arm64'), parameters('fortiGateImageVersion_arm64'), if(equals(parameters('fortiGateInstanceArchitecture'), '_g2'),parameters('fortiGateImageVersion_x64_g2'),parameters('fortiGateImageVersion_x64')))]"
"fortiGateImageSKU": "[concat(parameters('fortiGateLicenseType'),'_',take(replace(variables('fortiGateImageVersion'), '.',''), 2),variables('VMInstanceArchitecture'))]"
"instanceType": "[if(equals(parameters('fortiGateInstanceArchitecture'), '_arm64'), parameters('instanceType_arm64'), if(equals(parameters('fortiGateInstanceArchitecture'), '_g2'),parameters('instanceType_x64_g2'),parameters('instanceType_x64')))]"
"diskControllerType": "[if(and(equals(parameters('fortiGateInstanceArchitecture'), '_g2'),contains(parameters('instanceType_x64_g2'), '_v6')),'NVMe',json('null'))]"
```

**Image references:**
```
"imageReferenceMarketplace": { "publisher": "...", "offer": "...", "sku": "...", "version": "..." }
"imageReferenceCustomImage": { "id": "[parameters('customImageReference')]" }
"virtualMachinePlan": { "name": "...", "publisher": "...", "product": "..." }
```

**Accelerated connections:**
```
"fastpathtag": { "fastpathenabled": "[if(and(equals(parameters('acceleratedNetworking'),'true'),parameters('acceleratedConnections')),'true','false')]" }
"LegacyNVA": { "LegacyVMNVA": "Use legacy MLX ConnectX NIC" }
"LegacyVMNVATag": "[if(equals(parameters('fortiGateInstanceArchitecture'),'x64'),variables('LegacyNVA'),json('{}'))]"
"auxiliaryMode": "[if(and(equals(parameters('acceleratedNetworking'),'true'),parameters('acceleratedConnections')),'AcceleratedConnections','None')]"
"auxiliarySku": "[if(and(equals(parameters('acceleratedNetworking'),'true'),parameters('acceleratedConnections')),parameters('acceleratedConnectionsSku'),'None')]"
```

**Availability:**
```
"useAZ": "[and(not(empty(pickZones('Microsoft.Compute', 'virtualMachines', parameters('location')))), equals(parameters('availabilityOptions'), 'Availability zone'))]"
"pipZones": "[if(variables('useAZ'), pickZones('Microsoft.Network', 'publicIPAddresses', parameters('location'), 3), json('null'))]"
```
Note: Single-VM uses `"Availability zone"` (singular); HA templates may use `"Availability Zones"` (plural) – be consistent with the parameter's `allowedValues`.

**Serialconsole:**
```
"serialConsoleEnabled": "[if(equals(parameters('serialConsole'),'yes'),'true','false')]"
```

**IP address calculation** (per subnet `snN`):
The gateway is always +1 from the network address (derived from the prefix, not the start address). The pattern used throughout:
```
"snNCIDRmask": "[string(int(variables('snNIPArray2nd')[1]))]"
"snNIPArray3": "[string(add(int(variables('snNIPArray2nd')[0]),1))]"   ← gateway offset
"snNGatewayIP": "[concat(...,'.',variables('snNIPArray3'))]"
"snNIPfgt": "[concat(...,int(variables('snNIPStartAddress')[3]))]"
```

### 6. Resources

#### 6a. Deployment Telemetry Resource (Required)

Every template must have an empty deployment resource for Fortinet telemetry tracking:
```json
{
  "name": "[concat(parameters('fortiGateNamePrefix'), '-fortinetdeployment-', uniquestring(resourceGroup().id))]",
  "type": "Microsoft.Resources/deployments",
  "apiVersion": "2025-04-01",
  "properties": {
    "mode": "Incremental",
    "template": {
      "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
      "contentVersion": "1.0.0.0",
      "resources": []
    }
  }
}
```

#### 6b. API Versions

Use these exact API versions (current as of the latest templates):
| Resource type | API version |
|---|---|
| `Microsoft.Compute/virtualMachines` | `2025-04-01` |
| `Microsoft.Compute/availabilitySets` | `2025-04-01` |
| `Microsoft.Resources/deployments` | `2025-04-01` |
| `Microsoft.Network/virtualNetworks` | `2025-05-01` |
| `Microsoft.Network/networkInterfaces` | `2025-05-01` |
| `Microsoft.Network/networkSecurityGroups` | `2025-05-01` |
| `Microsoft.Network/publicIPAddresses` | `2025-05-01` |
| `Microsoft.Network/loadBalancers` | `2025-05-01` |
| `Microsoft.Network/routeTables` | `2025-05-01` |

Flag any API version older than the above.

#### 6c. Availability Set

- Must use `"sku": { "name": "Aligned" }` (not Classic).
- `platformFaultDomainCount: 2`, `platformUpdateDomainCount: 2`.
- For HA templates: conditional on `not(variables('useAZ'))`.
- For single-VM: conditional on `variables('useAS')` and `equals(parameters('existingAvailabilitySetName'),'')`.

#### 6d. Virtual Network

- `condition` must gate on `equals(parameters('vnetNewOrExisting'), 'new')`.
- All protected subnets must have `"defaultoutboundaccess": false` set at the subnet property level.
- External/internal subnets backing the FortiGate directly should also set `"defaultoutboundaccess": false`.
- `dependsOn` must include the route table resource so the route table exists before the VNet references it.

#### 6e. Route Tables (Protected Subnets)

Every protected subnet behind the FortiGate must have a route table with:
- A route for `0.0.0.0/0` → `VirtualAppliance` → FortiGate internal NIC IP (ILB frontend IP for HA).
- A route for the VNET prefix → `VirtualAppliance` → same next hop.
- A route for the subnet itself → `VnetLocal` (single-VM) OR omitted when ILB is used (HA).
- Route table must be deployed before the VNET (`dependsOn`).

For HA deployments the next hop must point to the **ILB frontend IP** (`sn2IPlb`), not directly to a VM NIC.

#### 6f. Network Security Group

- NSG must be applied to **all** FortiGate NICs.
- Standard pattern: two rules only:
  - `AllowAllInbound` – priority 100, direction Inbound, allow `*` → `*`
  - `AllowAllOutbound` – priority 105, direction Outbound, allow `*` → `*`
- The rationale: FortiGate is the stateful firewall; the NSG is intentionally permissive. Do not tighten NSG rules as it conflicts with FortiGate policy enforcement.
- NSG name must use `uniqueString(resourceGroup().id)` to avoid cross-deployment collisions when deploying multiple clusters in the same subscription.

#### 6g. Public IP Addresses

- Must use `"sku": { "name": "Standard" }` (not Basic).
- Must use `"publicIPAllocationMethod": "Static"` (not Dynamic).
- Zones: must use `"zones": "[variables('pipZones')]"` so it follows AZ configuration.
- DNS label (where applicable): `"domainNameLabel": "[concat(toLower(variables('fgtVmName')), '-', uniquestring(resourceGroup().id))]"`.
- Public IP parameters must support `new` / `existing` / `none` options (where `none` means no public IP is attached).
- Standard SKU LBs require Standard SKU public IPs.

#### 6h. Load Balancers (HA Templates)

Both ELB and ILB must use `"sku": { "name": "Standard" }`.

**External Load Balancer:**
- Frontend IP: public IP address.
- LB rules must have `"enableFloatingIP": true` and `"disableOutboundSnat": true`.
- Must include an outbound rule.
- Probe port: TCP 8008 (FortiGate probe-response port).
- `probeThreshold`: 2, `intervalInSeconds`: 5.

**Internal Load Balancer:**
- Frontend IP: static private IP (`sn2IPlb`) allocated from the internal subnet.
- HA-port rule: `protocol: "all"`, `frontendPort: 0`, `backendPort: 0`, `enableFloatingIP: true`.
- Same probe configuration: TCP 8008, interval 5s, threshold 2.
- Frontend IP configuration zones: `"[if(variables('useAZ'), variables('pipZones'), json('null'))]"`.

#### 6i. Network Interfaces

All FortiGate NICs must have:
- `"enableIPForwarding": true`
- `"enableAcceleratedNetworking": "[parameters('acceleratedNetworking')]"`
- `"auxiliaryMode": "[variables('auxiliaryMode')]"`
- `"auxiliarySku": "[variables('auxiliarySku')]"`
- `"networkSecurityGroup": { "id": "[variables('nsgId')]" }`
- Static private IP allocation (`"privateIPAllocationMethod": "Static"`).

HA-Sync (port3) and HA-Management (port4) NICs do not need auxiliary mode or accelerated connections but must still have `enableIPForwarding: true` and the NSG.

NIC 1 (external) must be associated with the ELB backend pool.
NIC 2 (internal) must be associated with the ILB backend pool.

Tags on NICs with accelerated networking must merge the `fastpathtag`:
```
"tags": "[ if(contains(parameters('tagsByResource'), 'Microsoft.Network/networkInterfaces'), union(parameters('fortinetTags'),parameters('tagsByResource')['Microsoft.Network/networkInterfaces'],variables('fastpathtag')), union(parameters('fortinetTags'),variables('fastpathtag'))) ]"
```

#### 6j. Virtual Machine

**Identity:** Must use `"identity": { "type": "SystemAssigned" }` – required for the Azure SDN Connector.

**Plan:** Must conditionally omit the `plan` when using a custom image from support.fortinet.com:
```json
"plan": "[if(and(...equals(parameters('customVHDSource'),'fortinetsite')), json('null'), variables('virtualMachinePlan'))]"
```

**Storage Profile:**
- `imageReference`: conditionally choose `imageReferenceCustomImage` vs `imageReferenceMarketplace`.
- `diskControllerType`: `"[variables('diskControllerType')]"` (NVMe for _v6 Gen2 instances, null otherwise).
- `osDisk`: `"createOption": "FromImage"` only – no explicit managed disk type needed.
- `dataDisks`: exactly one data disk, `diskSizeGB: 30`, `lun: 0`, `createOption: "Empty"`.

**OS Profile:**
- `customData` must be base64-encoded using `[base64(...)]`.
- When both BYOL license and FortiFlex token are empty, pass plain config (no MIME wrapper).
- When either license is provided, wrap in MIME multipart format with boundary `"12345"`.

**Diagnostics:**
- `"bootDiagnostics": { "enabled": "[variables('serialConsoleEnabled')]" }` – no storage URI (uses managed storage account).

**Security Profile (optional, Gen2 only):**
```json
"securityProfile": "[if(equals(parameters('VMSecurityType'),'TrustedLaunch'),union(variables('VM.securityProfile'),variables('VM.uefiSettings')),json('null'))]"
```

**Availability:**
- Zones: `"[if(variables('useAZ'), variables('zone1'), json('null'))]"` for FGT-A; `variables('zone2')` for FGT-B.
- AvailabilitySet: `"[if(not(variables('useAZ')), variables('availabilitySetId'), json('null'))]"` (HA) or `"[if(variables('useAS'), variables('availabilitySetId'), json('null'))]"` (single VM).

**VM Tags:** Must merge `LegacyVMNVATag`:
```
"tags": "[ if(contains(parameters('tagsByResource'), 'Microsoft.Compute/virtualMachines'), union(variables('LegacyVMNVATag'),parameters('fortinetTags'),parameters('tagsByResource')['Microsoft.Compute/virtualMachines']), union(variables('LegacyVMNVATag'),parameters('fortinetTags'))) ]"
```

**Network Profile:** First NIC must have `"primary": true`, all others `"primary": false`.

### 7. FortiGate Boot Configuration (customData)

The `customData` string must configure:

**SDN Connector:**
```
config system sdn-connector
edit AzureSDN
set type azure
next
end
```

**Static Routes:**
- Route 1: default gateway via port1 (`sn1GatewayIP`).
- Route 2: VNET prefix via port2 (`sn2GatewayIP`).
- For HA/LB templates: additional routes for Azure metadata IP `168.63.129.16/32` via both port1 and port2.

**Interface configuration:**
- `set mode static`, `set ip <ip>/<mask>`, `set description external|internal|hasyncport|hammgmtport`.
- External port1: `set allowaccess ping ssh https` (single VM) or `set allowaccess probe-response` (HA/LB).
- Internal port2: `set allowaccess ping ssh https` (single VM) or `set allowaccess probe-response` (HA/LB).
- HA sync port3: no `allowaccess` beyond default.
- HA management port4: `set allowaccess ping https ssh ftm`.

**Probe response (HA templates only):**
```
config system probe-response
set http-probe-value OK
set mode http-probe
end
```

**HA configuration (Active-Passive):**
```
config system ha
set group-id 1
set group-name AzureHA
set mode a-p
set hbdev port3 100
set session-pickup enable
set session-pickup-connectionless enable
set ha-mgmt-status enable
config ha-mgmt-interfaces
  edit 1
  set interface port4
  set gateway <sn4GatewayIP>
  next
end
set override disable
set priority 255   ← FGT-A; FGT-B uses priority 1
set unicast-hb enable
set unicast-hb-peerip <peer-sn3-IP>
set password <adminPassword>
end
```

**Global settings:**
```
config system global
set hostname <vmName>
set allow-traffic-redirect disable
end
```

**FortiManager (conditional):**
```
config system central-management
set type fortimanager
set fmg <fortiManagerIP>
set serial-number <fortiManagerSerial>
end
config system interface
edit port1
append allowaccess fgfm
end
config system interface
edit port2
append allowaccess fgfm
end
```

### 8. Tagging Pattern

Every resource must use this conditional union pattern:
```
"tags": "[ if(contains(parameters('tagsByResource'), '<ResourceType>'), union(parameters('fortinetTags'),parameters('tagsByResource')['<ResourceType>']), parameters('fortinetTags')) ]"
```

NIC resources with accelerated networking add `variables('fastpathtag')` to the union. VM resources add `variables('LegacyVMNVATag')`.

Flag any resource missing the tagging pattern, using hardcoded tags, or not supporting `tagsByResource` overrides.

### 9. Naming Conventions

| Resource | Pattern |
|---|---|
| FortiGate VMs (single) | `<prefix>-fgt` (or `fortiGateName` override) |
| FortiGate VMs (HA) | `<prefix>-FGT-A`, `<prefix>-FGT-B` |
| NICs | `<vmName>-nic1`, `<vmName>-nic2`, etc. |
| Public IPs | `<prefix>-fgt-pip`, `<prefix>-fgt-a-mgmt-pip`, `<prefix>-fgt-b-mgmt-pip` |
| NSG | `<prefix>-<uniqueString(rg.id)>-nsg` |
| VNet | `<prefix>-vnet` |
| Route tables | `<prefix>-routetable-<subnetName>` |
| Availability set | `<prefix>-AvailabilitySet` |
| ELB | `<prefix>-externalloadbalancer` |
| ILB | `<prefix>-internalloadbalancer` |
| LB frontend | `<prefix>-ILB-<subnetName>-frontend` / `<prefix>-elb-<subnetName>-frontend` |
| LB backend | `<prefix>-ILB-<subnetName>-backend` / `<prefix>-elb-<subnetName>-backend` |

### 10. Outputs

Minimum required outputs:
- `fortiGatePublicIP` – type `string`, conditional on `publicIP1NewOrExisting != 'none'`.
- `fortiGateFQDN` – type `string`, conditional on public IP present.

HA templates additionally output:
- `fortiGateAManagementPublicIP`
- `fortiGateBManagementPublicIP`

Output references must use the same API version as the resource (`2025-05-01` for public IPs).

### 11. Subnet Defaults and Security

- `"defaultoutboundaccess": false` must be set on every subnet that does not require direct outbound internet access (internal, HA sync, HA management, protected subnets).
- External subnet (port1 subnet) may omit this if it requires direct outbound access, but preferred to set false and rely on ELB outbound rules.
- Protected subnets must have a `routeTable` reference pointing to a route table that forces traffic through the FortiGate.

### 12. Load Balancer Probe Health

The FortiOS config on each FortiGate must enable probe-response to match the LB probe on port 8008:
```
config system probe-response
set http-probe-value OK
set mode http-probe
end
```
And the interface must have `allowaccess probe-response` set.

If the probe is TCP-based (port 8008), the interface must at minimum listen on that port. Flag templates where the LB probe port does not match the FortiOS probe-response configuration.

### 13. Active-Active Specific Patterns

Active-Active templates (ELB-ILB, RouteServer Active-Active) have additional requirements:

**ARM User-Defined Functions:** The Active-Active ELB-ILB template uses a `functions` block with a `ha` namespace to generate FGSP peer CLI strings dynamically. Check that the `functions` block is present before `parameters` and uses the `ha` namespace.

**IP address calculation — newer parseCidr/cidrHost style (preferred in Active-Active-ELB-ILB):**
```json
"sn1CidrObject": "[parseCidr(parameters('subnet1Prefix'))]",
"sn1GatewayIP": "[variables('sn1CidrObject').firstUsable]"
```
And NIC IPs via a `copy` loop using `cidrHost`. Both the older string-split method and the newer `parseCidr` method are valid; do not flag the older method as wrong, only flag if an inconsistent mix appears within the same template.

**FGSP (FortiGate Session Synchronisation Protocol) for Active-Active:**
The `customDataBody` must include FGSP peer configuration when `fortiGateSessionSync` is enabled:
```
config system standalone-cluster
set standalone-group-id 1
set group-member-id <0|1|...>
set layer2-connection available
config cluster-peer
  edit 1
  set peerip <peer_sn3_ip>
  next
end
end
```

**Outbound connectivity options (Active-Active):** Templates should support `outboundConnectivity` parameter with options: `per-node-standard-sku-pip`, `deploy-nat-gateway`, `external-nat-device-or-elb`. Flag missing NAT Gateway support when the template claims to support the `deploy-nat-gateway` option.

**Session sync parameter:** `fortiGateSessionSync` (bool, default false) and `fortiGateProbeResponse` (bool, default true) must be present.

**Per-node management NAT Rules** (optional, via `Microsoft.Network/loadBalancers/inboundNatRules`): Numbered per FortiGate node for HTTPS (TCP/8443) and SSH (TCP/22) management access through the ELB.

### 14. Autoscale Templates

Autoscale (`Autoscale/ums/mainTemplate.json`) uses a VMSS (Virtual Machine Scale Set) instead of individual VMs. Standard per-VM checks do NOT apply to VMSS properties — apply these instead:

- `orchestrationMode: "Flexible"` (not Uniform).
- `platformFaultDomainCount: 1`, `singlePlacementGroup: false`, `zoneBalance: false`.
- `upgradePolicy.mode: "Manual"`.
- NIC configurations inside `virtualMachineProfile.networkProfile.networkInterfaceConfigurations`.
- Autoscale-specific customData must include `config system auto-scale / set role primary / set cloud-mode ums`.
- FortiManager integration required for Autoscale — `fortiManager` parameter should default to `yes` or be mandatory.
- `Microsoft.Insights/autoscaleSettings` resource required with scale-in/scale-out rules.

Skip standard Availability Set checks for Autoscale templates.

### 15. Gateway Load Balancer Patterns

`AzureGatewayLoadBalancer` uses a different LB backend pool configuration:
- Backend pool must include `tunnelInterfaces` with VxLan encapsulation:
  ```json
  {"port": 2000, "identifier": 800, "protocol": "VxLan", "type": "Internal"},
  {"port": 2001, "identifier": 801, "protocol": "VxLan", "type": "External"}
  ```
- The Gateway LB frontend does not have a public IP — it uses a private IP in the external subnet.
- NSG for Gateway LB may have more specific rules (allow VxLan UDP/2000-2001) rather than AllowAll.

### 16. Legacy/Deprecated Patterns (Flag These)

- `"publicIPAllocationMethod": "Dynamic"` – must be Static.
- `"sku": { "name": "Basic" }` on public IPs or load balancers – must be Standard.
- Missing `enableIPForwarding: true` on any FortiGate NIC.
- `"type": "SystemAssigned"` missing from VM identity.
- Hard-coded resource names without the prefix pattern.
- Using `"latest"` as the image version in production templates (acceptable only in playground/legacy folders).
- NSG rules more restrictive than AllowAll (breaks FortiGate policy enforcement via the NSG layer).
- Availability set using `"sku": { "name": "Classic" }`.
- Basic SKU load balancer.
- Missing `"defaultoutboundaccess": false` on internal/protected subnets.
- Missing deployment telemetry resource.
- Missing `"diskControllerType"` variable for Gen2 support.
- Missing `LegacyVMNVATag` on VM resources.

---

## How to Report

After reviewing, produce a structured report:

```
## FortiGate ARM Template Review

### Template: <path/to/file>

#### PASS ✓
- <category>: <brief note>

#### FINDINGS
1. [CRITICAL] <category> — <what is wrong>
   Path: <json path>
   Expected: <correct value or pattern>
   Found: <actual value>

2. [WARNING] <category> — <what is wrong>
   ...

3. [INFO] <category> — <minor deviation or suggestion>
   ...

#### Summary
- Critical: N
- Warnings: N
- Info: N
```

Severity guide:
- **CRITICAL**: Would cause deployment failure, security misconfiguration, or HA failover failure.
- **WARNING**: Deviation from standard that may cause operational issues or inconsistency.
- **INFO**: Style/naming inconsistency or missing optional best practice.
