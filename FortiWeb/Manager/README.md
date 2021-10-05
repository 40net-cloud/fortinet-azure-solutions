# Deploy FortiWeb Manager from custom VHD

## Introduction

In some large-scale FortiWeb deployments, it is required to use additional FortiWeb Manager VM for managing unified configuration. FortiWeb Manager is a separate product not currently available on the Azure Marketplace and needs to be deployed from a custom VHD. Full instructions on how to download firmware from [Fortinet support portal](https://support.fortinet.com) and use it to create new VM are available [here](https://docs.fortinet.com/document/fortiweb-manager/6.2.3/deploying-fortiweb-manager-vm-on-azure/275937).

## Design

This ARM template will deploy a single FortiWeb Manager VM containing the following components.

- 1 VM deployed from provided image with a single NIC
- 2 disks (boot and log) mounted in the VM instance
- (optionally) 1 VNET with 1 subnet
- (optionally) 1 Public IP Address associated with VM

This Azure ARM template can also be extended or customized based on your requirements. Additional subnets besides the ones mentioned above are not automatically generated. By extending the Azure ARM templates additional subnets can be added. Additional subnets will require their own routing tables.

## Deployment

For the deployment, you can use the Azure Portal, Azure CLI, Powershell or Azure Cloud Shell. The Azure ARM templates are exclusive to Microsoft Azure and can't be used in other cloud environments. The main template is the `azuredeploy.json` which you can use in the Azure Portal.

### Azure Portal

In the Azure Portal you can deploy the template either by clicking the buttons below or by pasting the contents of the 'azuredeploy.json' file in the 'Deploy a custom template' location.

[![Deploy to Azure](https://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiWeb%2FManager%2Fazuredeploy.json)

[![Visualize](http://armviz.io/visualizebutton.png)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiWeb%2FManager%2Fazuredeploy.json)

#### Manual deployment

- Search for 'Deploy a customer template' in the top search bar of the Azure portal
![Azure Portal 1](https://raw.githubusercontent.com/40net-cloud/fortinet-azure-solutions/main/FortiGate/Playground/CustomVHD/images/azure-portal-1.png)
- Select the option 'Build your own template in the editor
![Azure Portal 2](https://raw.githubusercontent.com/40net-cloud/fortinet-azure-solutions/main/FortiGate/Playground/CustomVHD/images/azure-portal-2.png)
- Copy in the contents of the 'azuredeploy.json' file into the editor
![Azure Portal 3](https://raw.githubusercontent.com/40net-cloud/fortinet-azure-solutions/main/FortiGate/Playground/CustomVHD/images/azure-portal-3.png)
- Complete the required variables. THe VHD uri is created using the 'Add-AzVhd' command
![Azure Portal 4](https://raw.githubusercontent.com/40net-cloud/fortinet-azure-solutions/main/FortiGate/Playground/CustomVHD/images/azure-portal-4.png)

### Powershell and Azure Cloud Shell

The below is an example on how to deploy a customer VHD using powershell instead of using an ARM Template. Verify and replace the variables in the begining and run the commands one by one to verify.

```powershell

# Variables to be changed
$location = "westeurope"
$rg = "FORTI-RG"
$username = "azureuser"
$password = "xxxxxxxxxxxxxxxxxxxx"
$osdiskvhduri = "https://xxxxxxxxxxx.blob.core.windows.net/vhds/fortios-v6-buildxxxxx.vhd"

# Resource group
New-AzResourceGroup -Name $rg -Location $location

# Image
$image = New-AzImageConfig -Location $location
$image = Set-AzImageOsDisk -Image $image -OsState Generalized -OsType Linux -BlobUri $osdiskvhduri
$imagedisk = New-AzImage -ImageName "FORTI-IMAGE" -ResourceGroupName $rg -Image $image

# Virtual network and subnets
$virtualNetwork = New-AzVirtualNetwork -ResourceGroupName “FORTI-RG” -Location “westeurope” -Name “fwbmanager-vnet” -AddressPrefix “172.16.136.0/22”
$subnet1 = Add-AzVirtualNetworkSubnetConfig -Name “default” -AddressPrefix 172.16.136.0/26 -VirtualNetwork $virtualNetwork
$virtualNetwork | Set-AzVirtualNetwork

# Network security groups (required when using standard SKU IPs)
$rule1 = New-AzNetworkSecurityRuleConfig -Name "Allow_All_Outbound" -Protocol * -SourcePortRange * -DestinationPortRange * -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 100 -Direction Outbound
$rule2 = New-AzNetworkSecurityRuleConfig -Name "Allow_SSH_In" -Protocol TCP -SourcePortRange * -DestinationPortRange 22 -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 100 -Direction Inbound
$rule3 = New-AzNetworkSecurityRuleConfig -Name "Allow_80_In" -Protocol TCP -SourcePortRange * -DestinationPortRange 80 -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 100 -Direction Inbound
$rule4 = New-AzNetworkSecurityRuleConfig -Name "Allow_443_In" -Protocol TCP -SourcePortRange * -DestinationPortRange 443 -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 100 -Direction Inbound
$rule5 = New-AzNetworkSecurityRuleConfig -Name "Allow_8989_In" -Protocol TCP -SourcePortRange * -DestinationPortRange 8989 -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 100 -Direction Inbound
$nsg = New-AzNetworkSecurityGroup -Name "FORTI-NSG" -ResourceGroupName $rg -Location $location -SecurityRules $rule1,$rule2

# Network interfaces for external and internal of the FWB
$virtualNetwork = Get-AzVirtualNetwork -Name "FORTI-VNET" -ResourceGroupName $rg

$nic1 = New-AzNetworkInterface -ResourceGroupName $rg -Location $location -Name "FORTI-FWB-A-NIC1" -PublicIpAddressId $pip.Id -SubnetId $virtualNetwork.Subnets[0].Id -NetworkSecurityGroupId $nsg.Id

# Virtual Machine
$vm = New-AzVMConfig -VMName "fwbmanager" -VMSize "Standard_F2s_v2"
$credentials = New-Object PSCredential $username, ($password | ConvertTo-SecureString -AsPlainText -Force)
$vm = Set-AzVMOperatingSystem -VM $vm -Linux -ComputerName "FORTI-FWB-A" -Credential $credentials
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic1.Id -Primary
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic2.Id
$vm = Set-AzVMSourceImage -VM $vm -Id $imagedisk.Id
$vm = Set-AzVMBootDiagnostic -VM $vm -Disable
$result = New-AzVM -ResourceGroupName $rg -Location $location -VM $vm

```

## Requirements and limitations

This template will not deploy the default Azure Marketplace images. You can deploy using this template a custom VHD. These specific VHD's can be downloaded from support.fortinet.com. Once downloaded you need to upload this VHD to an Azure storage account. You can find more information on how to create the storage account on [this link](https://docs.microsoft.com/en-us/azure/storage/common/storage-quickstart-create-account?tabs=azure-portal). Once you have the URI for the storage account you need to use the below 'Add-AzVhd' powershell command to upload the image (if you use the legacy Azure RM Powershell package the command is `Add-AzureRMVhd`). The FortiWeb Manager image is very compressed and needs to extracted during the upload process. This is only working well using this powershell command. In the end you need to have a 2Gb VHD in your storage account.

`Add-AzVhd -LocalFilePath ./boot.vhd -ResourceGroupName XXX-RG -Destination 'https://xxx.blob.core.windows.net/vhds/boot.vhd'`

![Storage Account](https://raw.githubusercontent.com/40net-cloud/fortinet-azure-solutions/main/FortiGate/Playground/CustomVHD/images/storageaccount.png)

The Azure ARM template deployment deploys different resources and is required to have the access rights and quota in your Microsoft Azure subscription to deploy the resources.

## License

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
