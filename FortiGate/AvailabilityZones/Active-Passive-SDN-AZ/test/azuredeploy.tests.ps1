#Requires -Modules Pester
<#
.SYNOPSIS
    Tests a specific ARM template
.EXAMPLE
    Invoke-Pester 
.NOTES
    This file has been created as an example of using Pester to evaluate ARM templates
#>

Function random-password ($length = 15) {
    $punc = 46..46
    $digits = 48..57
    $letters = 65..90 + 97..122

    # Thanks to
    # https://blogs.technet.com/b/heyscriptingguy/archive/2012/01/07/use-pow
    $password = get-random -count $length `
        -input ($punc + $digits + $letters) |
        % -begin { $aa = $null } `
        -process {$aa += [char]$_} `
        -end {$aa}

    return $password
}

$templateName = "Active-Passive-SDN-AZ"
$sourcePath = "$env:BUILD_SOURCESDIRECTORY\FortiGate\AvailabilityZones\$templateName"
$scriptPath = "$env:BUILD_SOURCESDIRECTORY\FortiGate\AvailabilityZones\$templateName\test"
$templateFileName = "azuredeploy.json"
$templateFileLocation = "$sourcePath\$templateFileName"
$templateMetadataFileName = "metadata.json"
$templateMetadataFileLocation = "$sourcePath\$templateMetadataFileName"
$templateParameterFileName = "azuredeploy.parameters.json"
$templateParameterFileLocation = "$sourcePath\$templateParameterFileName" 

# Basic Variables
$testsRandom = Get-Random 10001
$testsPrefix = "FORTIQA"
$testsResourceGroupName = "FORTIQA-$testsRandom-$templateName"
$testsAdminPassword = $testsResourceGroupName | ConvertTo-SecureString -AsPlainText -Force
$testsResourceGroupLocation = "East US2"

Describe 'ARM Templates Test : Validation & Test Deployment' {
    Context 'Template Validation' {
        It 'Has a JSON template' {        
            $templateFileLocation | Should Exist
        }
        
        It 'Has a parameters file' {        
            $templateParameterFileLocation | Should Exist
        }
		
        It 'Has a metadata file' {        
            $templateMetadataFileLocation | Should Exist
        }

        It 'Converts from JSON and has the expected properties' {
            $expectedProperties = '$schema',
            'contentVersion',
            'parameters',
            'resources',                                
            'variables'
            $templateProperties = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue) | Get-Member -MemberType NoteProperty | % Name
            $templateProperties | Should Be $expectedProperties
        }
        
        It 'Creates the expected Azure resources' {
            $expectedResources = 'Microsoft.Resources/deployments',
                                 'Microsoft.Network/routeTables',
                                 'Microsoft.Network/virtualNetworks',
                                 'Microsoft.Network/networkSecurityGroups',
                                 'Microsoft.Network/publicIPAddresses',
                                 'Microsoft.Network/publicIPAddresses',
                                 'Microsoft.Network/publicIPAddresses',
                                 'Microsoft.Network/networkInterfaces',
                                 'Microsoft.Network/networkInterfaces',
                                 'Microsoft.Network/networkInterfaces',
                                 'Microsoft.Network/networkInterfaces',
                                 'Microsoft.Network/networkInterfaces',
                                 'Microsoft.Network/networkInterfaces',
                                 'Microsoft.Network/networkInterfaces',
                                 'Microsoft.Network/networkInterfaces',
                                 'Microsoft.Compute/virtualMachines',
                                 'Microsoft.Compute/virtualMachines'
            $templateResources = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue).Resources.type
            $templateResources | Should Be $expectedResources
        }
        
        It 'Contains the expected parameters' {
            $expectedTemplateParameters = 'adminPassword',
                                          'adminUsername',
                                          'FortiGateImageSKU',
                                          'FortiGateImageVersion',
                                          'FortiGateNamePrefix',
                                          'FortinetTags',
                                          'instanceType',
                                          'publicIP2Name',
                                          'publicIP2NewOrExisting',
                                          'publicIP2ResourceGroup',
                                          'publicIP3Name',
                                          'publicIP3NewOrExisting',
                                          'publicIP3ResourceGroup',
                                          'publicIPAddressType',
                                          'publicIPName',
                                          'publicIPNewOrExisting',
                                          'publicIPResourceGroup',
                                          'subnet1Name',
                                          'subnet1Prefix',
                                          'subnet2Name',
                                          'subnet2Prefix',
                                          'subnet3Name',
                                          'subnet3Prefix',
                                          'subnet4Name',
                                          'subnet4Prefix',
                                          'subnet5Name',
                                          'subnet5Prefix',
                                          'vnetAddressPrefix',
                                          'vnetName',
                                          'vnetNewOrExisting',
                                          'vnetResourceGroup'
            $templateParameters = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters | Get-Member -MemberType NoteProperty | % Name | sort
            $templateParameters | Should Be $expectedTemplateParameters
        }

    }

    Context 'Template Test Deployment' {

        # Set working directory & create resource group
        Set-Location $sourcePath
        New-AzureRmResourceGroup -Name $testsResourceGroupName -Location "$testsResourceGroupLocation"

        # Validate all ARM templates one by one
        $testsErrorFound = $false

        $params = @{ 'ResourceGroupName'=$testsResourceGroupName;
                     'TemplateFile'='azuredeploy.json';
                     'TemplateParameterFile'='azuredeploy.parameters.json';
                     'adminPassword'=$testsAdminPassword;
                     'FortiGateNamePrefix'=$testsPrefix;
                     'publicIPName'=$testsPrefix + '-PIP';
                     'publicIP2Name'=$testsPrefix + '-PIP2';
                     'publicIP3Name'=$testsPrefix + '-PIP3';
                     'vnetName'=$testsPrefix + '-VNET';
                     'vnetResourceGroup'=$testsResourceGroupName;
                    }

        It "Test Deployment of ARM template $templateFileName with parameter file $templateParameterFileName" {
            (Test-AzureRmResourceGroupDeployment @params ).Count | Should not BeGreaterThan 0
        }
        It "Deployment of ARM template $templateFileName with parameter file $templateParameterFileName" {
            $resultDeployment = New-AzureRmResourceGroupDeployment @params
            Write-Host ($resultDeployment | Format-Table | Out-String)
            Write-Host ("Deployment state: " + $resultDeployment.ProvisioningState | Out-String)
            $resultDeployment.ProvisioningState | Should Be "Succeeded"
        }
        It "Deployment in Azure validation" {
            $result = Get-AzureRmVM | Where-Object { $_.Name -like "$testsPrefix*" } 
            Write-Host ($result | Format-Table | Out-String)
            $result | Should Not Be $null
        }

        8443, 22 | Foreach-Object {
            it "Port [$_] is listening" {
                $result = Get-AzureRmPublicIpAddress -Name $params['publicIPName'] -ResourceGroupName $params['ResourceGroupName']
                $portListening = (Test-NetConnection -Port $_ -ComputerName $result.IpAddress).TcpTestSucceeded
                $portListening | Should -Be $true
                $result = Get-AzureRmPublicIpAddress -Name $params['publicIP2Name'] -ResourceGroupName $params['ResourceGroupName']
                $portListening = (Test-NetConnection -Port $_ -ComputerName $result.IpAddress).TcpTestSucceeded
                $portListening | Should -Be $true
                $result = Get-AzureRmPublicIpAddress -Name $params['publicIP3Name'] -ResourceGroupName $params['ResourceGroupName']
                $portListening = (Test-NetConnection -Port $_ -ComputerName $result.IpAddress).TcpTestSucceeded
                $portListening | Should -Be $true
            }
        }
    }

    Context 'Cleanup' {
        It "Cleanup of deployment" {
            Remove-AzureRmResourceGroup -Name $testsResourceGroupName -Force
        }
    }
}