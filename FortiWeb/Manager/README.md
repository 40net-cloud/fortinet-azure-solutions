# Deploy FortiWeb Manager from custom VHD

## Introduction

In some large-scale FortiWeb deployments, an additional FortiWeb Manager VM is required to manage a unified configuration. FortiWeb Manager is a separate product that is not currently available on the Azure Marketplace and must be deployed from a custom VHD. Full instructions for downloading firmware from the [Fortinet support portal](https://support.fortinet.com) and using it to create a new VM are available [here](https://docs.fortinet.com/document/fortimanager-public-cloud/7.2.0/azure-administration-guide/889571).

## Design

This ARM template deploys a single FortiWeb Manager VM with the following components:

- 1 VM deployed from a provided image with a single NIC
- 2 disks (boot and log) mounted in the VM instance
- (Optionally) 1 VNet with 1 subnet
- (Optionally) 1 public IP address associated with the VM

This Azure ARM template can also be extended or customized based on your requirements. Additional subnets beyond those mentioned above are not automatically generated. By extending the Azure ARM template, you can add additional subnets. Each additional subnet requires its own routing table.

## Deployment

For deployment, you can use the Azure portal, Azure CLI, PowerShell, or Azure Cloud Shell. The Azure ARM templates are exclusive to Microsoft Azure and cannot be used in other cloud environments. The main template is `azuredeploy.json`, which you can use in the Azure portal.

### Azure Portal

In the Azure portal, you can deploy the template either by clicking the buttons below or by pasting the contents of the `azuredeploy.json` file into the **Deploy a custom template** page.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiWeb%2FManager%2Fazuredeploy.json)

[![Visualize](https://raw.githubusercontent.com/azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiWeb%2FManager%2Fazuredeploy.json)

#### Manual deployment

- Search for **Deploy a custom template** in the Azure portal's top search bar.
![Azure Portal 1](https://raw.githubusercontent.com/40net-cloud/fortinet-azure-solutions/main/FortiGate/Playground/CustomVHD/images/azure-portal-1.png)
- Select **Build your own template in the editor**.
![Azure Portal 2](https://raw.githubusercontent.com/40net-cloud/fortinet-azure-solutions/main/FortiGate/Playground/CustomVHD/images/azure-portal-2.png)
- Copy the contents of the `azuredeploy.json` file into the editor.
![Azure Portal 3](https://raw.githubusercontent.com/40net-cloud/fortinet-azure-solutions/main/FortiGate/Playground/CustomVHD/images/azure-portal-3.png)
- Complete the required variables. The VHD URI is created using the `Add-AzVhd` command.
![Azure Portal 4](https://raw.githubusercontent.com/40net-cloud/fortinet-azure-solutions/main/FortiGate/Playground/CustomVHD/images/azure-portal-4.png)

### PowerShell and Azure Cloud Shell

The following example shows how to deploy a custom VHD using PowerShell instead of an ARM template. Verify and replace the variables at the beginning, then run the commands one by one.

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

# Network interfaces for the FortiWeb Manager VM
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

This template does not deploy the default Azure Marketplace images. Instead, you can use it to deploy a custom VHD. These VHDs can be downloaded from the Fortinet support portal. After downloading the VHD, upload it to an Azure storage account. For more information about creating a storage account, see [this guide](https://docs.microsoft.com/en-us/azure/storage/common/storage-quickstart-create-account?tabs=azure-portal). Once you have the storage account URI, use the `Add-AzVhd` PowerShell command below to upload the image. If you use the legacy AzureRM PowerShell package, use `Add-AzureRMVhd` instead. The FortiWeb Manager image is highly compressed and must be extracted during the upload process; this PowerShell command handles that process. You should have a 2 GB VHD in your storage account when the upload is complete.

`Add-AzVhd -LocalFilePath ./boot.vhd -ResourceGroupName XXX-RG -Destination 'https://xxx.blob.core.windows.net/vhds/boot.vhd'`

![Storage Account](https://raw.githubusercontent.com/40net-cloud/fortinet-azure-solutions/main/FortiGate/Playground/CustomVHD/images/storageaccount.png)

The Azure ARM template deployment creates several resources. Ensure that your Microsoft Azure subscription has the required permissions and quotas to deploy them.

## License

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
