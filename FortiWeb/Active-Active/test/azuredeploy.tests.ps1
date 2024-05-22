#Requires -Modules Pester
<#
.SYNOPSIS
    Tests a specific ARM template
.EXAMPLE
    Invoke-Pester
.NOTES
    This file has been created as an example of using Pester to evaluate ARM templates
#>

param (
  [string]$sshkey,
  [string]$sshkeypub
)
$VerbosePreference = "Continue"

BeforeAll {
  $templateName = "Active-Active"
  $sourcePath = "$env:GITHUB_WORKSPACE\FortiWeb\$templateName"
  $scriptPath = "$env:GITHUB_WORKSPACE\FortiWeb\$templateName\test"
  $templateFileName = "mainTemplate.json"
  $templateFileLocation = "$sourcePath\$templateFileName"
  $templateParameterFileName = "mainTemplate.parameters.json"
  $templateParameterFileLocation = "$sourcePath\$templateParameterFileName"

  # Basic Variables
  $testsRandom = Get-Random 10001
  $testsPrefix = "FORTIQA"
  $testsResourceGroupName = "FORTIQA-$testsRandom-$templateName"
  $testsAdminUsername = "azureuser"
  $testsResourceGroupLocation = "westeurope"

  # ARM Template Variables
  $config = "config system global `n set hostname FortiWebTest `n end `n config system admin `n edit devops `n set access-profil prof_admin `n set sshkey `""
  $config += Get-Content $sshkeypub
  $config += "`" `n set password $testsResourceGroupName `n next `n end"
  $publicIPName = "$testsPrefix-fwb-pip"
  $params = @{ 'adminUsername'      = $testsAdminUsername
    'adminPassword'                 = $testsResourceGroupName
    'fortiWebNamePrefix'            = $testsPrefix
    'fortiWebAAdditionalCustomData' = $config
    'fortiWebBAdditionalCustomData' = $config
    'publicIPName'                  = $publicIPName
    'imageSku'                      = "fortinet_fw-vm_payg_v3"
    'availabilityOptions'           = "Availability Zones"
  }
  $ports = @(40030, 50030, 40031, 50031)
}

Describe 'FWB Active/Active' {
  Context 'Validation' {
    It 'Has a JSON template' {
      $templateFileLocation | Should -Exist
    }

    It 'Has a parameters file' {
      $templateParameterFileLocation | Should -Exist
    }

    It 'Converts from JSON and has the expected properties' {
      $expectedProperties = '$schema',
      'contentVersion',
      'outputs',
      'parameters',
      'resources',
      'variables'
      $templateProperties = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue) | Get-Member -MemberType NoteProperty | % Name
      $templateProperties | Should -Be $expectedProperties
    }

    It 'Creates the expected Azure resources' {
      $expectedResources = 'Microsoft.Resources/deployments',
      'Microsoft.Compute/availabilitySets',
      'Microsoft.Network/virtualNetworks',
      'Microsoft.Network/networkSecurityGroups',
      'Microsoft.Network/publicIPAddresses',
      'Microsoft.Network/loadBalancers',
      'Microsoft.Network/networkInterfaces',
      'Microsoft.Network/networkInterfaces',
      'Microsoft.Network/networkInterfaces',
      'Microsoft.Network/networkInterfaces',
      'Microsoft.Compute/virtualMachines',
      'Microsoft.Compute/virtualMachines'
      $templateResources = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue).Resources.type
      $templateResources | Should -Be $expectedResources
    }

    It 'Contains the expected parameters' {
      $expectedTemplateParameters = 'acceleratedNetworking',
      'adminPassword',
      'adminUsername',
      'availabilityOptions',
      'fortinetTags',
      'fortiWebAAdditionalCustomData',
      'fortiWebALicenseBYOL',
      'fortiWebALicenseFortiFlex',
      'fortiWebBAdditionalCustomData',
      'fortiWebBLicenseBYOL',
      'fortiWebBLicenseFortiFlex',
      'fortiWebHaGroupId',
      'fortiWebHaOverride',
      'fortiWebNamePrefix',
      'haApplicationId',
      'haApplicationSecret',
      'haSubscriptionId',
      'haTenantId',
      'imageSku',
      'imageVersion',
      'instanceType',
      'location',
      'publicIPName',
      'publicIPNewOrExistingOrNone',
      'publicIPResourceGroup',
      'publicIPType',
      'serialConsole',
      'subnet1Name',
      'subnet1Prefix',
      'subnet1StartAddress',
      'subnet2Name',
      'subnet2Prefix',
      'subnet2StartAddress',
      'tagsByResource',
      'vnetAddressPrefix',
      'vnetName',
      'vnetNewOrExisting',
      'vnetResourceGroup'
      $templateParameters = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters | Get-Member -MemberType NoteProperty | % Name | Sort-Object
      $templateParameters | Should -Be $expectedTemplateParameters
    }

  }

  Context 'Deployment' {

    It "Test Deployment" {
      New-AzResourceGroup -Name $testsResourceGroupName -Location "$testsResourceGroupLocation"
            (Test-AzResourceGroupDeployment -ResourceGroupName "$testsResourceGroupName" -TemplateFile "$templateFileLocation" -TemplateParameterObject $params).Count | Should -Not -BeGreaterThan 0
    }
    It "Deployment" {
      Write-Host ( "Deployment name: $testsResourceGroupName" )

      $resultDeployment = New-AzResourceGroupDeployment -ResourceGroupName "$testsResourceGroupName" -TemplateFile "$templateFileLocation" -TemplateParameterObject $params
      Write-Host ($resultDeployment | Format-Table | Out-String)
      Write-Host ("Deployment state: " + $resultDeployment.ProvisioningState | Out-String)
      $resultDeployment.ProvisioningState | Should -Be "Succeeded"
    }
    It "Search deployment" {
      $result = Get-AzVM | Where-Object { $_.Name -like "$testsPrefix*" }
      Write-Host ($result | Format-Table | Out-String)
      $result | Should -Not -Be $null
    }
  }

  Context 'Deployment test' {

    BeforeAll {
      $fwb = (Get-AzPublicIpAddress -Name $publicIPName -ResourceGroupName $testsResourceGroupName).IpAddress
      Write-Host ("FortiWeb public IP: " + $fwb)
      Write-Host ("FortiWeb username: " + $testsAdminUsername)
      Write-Host ("FortiWeb password: " + $testsResourceGroupName)
      $sshkeycontent = Get-Content($sshkey)
      Write-Host ("FortiWeb sshkey: " + $sshkeycontent)
    }
    It "FWB: Ports listening" {
      ForEach ( $port in $ports ) {
        Write-Host ("Check port: $port" )
        $portListening = (Test-Connection -TargetName $fwb -TCPPort $port -TimeoutSeconds 100)
        $portListening | Should -Be $true
      }
    }
    It "FWB A: Verify configuration" {
      $result = $verify_commands | ssh -p 50030 -v -tt -i $sshkey -o StrictHostKeyChecking=no devops@$fwb
      $LASTEXITCODE | Should -Be "0"
      Write-Host ("FWB CLI info: " + $result) -Separator `n
      $result | Should -Not -BeLike "*Command fail*"
    }
    It "FWB B: Verify configuration" {
      $result = $verify_commands | ssh -p 50031 -v -tt -i $sshkey -o StrictHostKeyChecking=no devops@$fwb
      $LASTEXITCODE | Should -Be "0"
      Write-Host ("FWB CLI info: " + $result) -Separator `n
      $result | Should -Not -BeLike "*Command fail*"
    }
  }

  #  Context 'Cleanup' {
  #    It "Cleanup of deployment" {
  #      Remove-AzResourceGroup -Name $testsResourceGroupName -Force
  #    }
  #  }
}
