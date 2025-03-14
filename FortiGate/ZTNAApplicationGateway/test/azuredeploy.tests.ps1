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
  $templateName = "ZTNAApplicationGateway"
  $sourcePath = "$env:GITHUB_WORKSPACE\FortiGate\$templateName"
  $scriptPath = "$env:GITHUB_WORKSPACE\FortiGate\$templateName\test"
  $templateFileName = "azuredeploy.json"
  $templateFileLocation = "$sourcePath\$templateFileName"
  $templateParameterFileName = "azuredeploy.parameters.json"
  $templateParameterFileLocation = "$sourcePath\$templateParameterFileName"

  # Basic Variables
  $testsRandom = Get-Random 10001
  $testsPrefix = "FORTIQA-$testsRandom"
  $testsResourceGroupName = "FORTIQA-$testsRandom-$templateName"
  $testsAdminUsername = "azureuser"
  $testsResourceGroupLocation = "westeurope"

  # ARM Template Variables
  $config = "config system global `n set gui-theme mariner `n end `n config system admin `n edit devops `n set accprofile super_admin `n set ssh-public-key1 `""
  $config += Get-Content $sshkeypub
  $config += "`" `n set password $testsResourceGroupName `n next `n end"
  $publicIPName = "$testsPrefix-FGT-PIP"
  $params = @{ 'adminUsername'      = $testsAdminUsername
    'adminPassword'                 = $testsResourceGroupName
    'fortiGateNamePrefix'           = $testsPrefix
    'fortiGateAdditionalCustomData' = $config
    'publicIP1Name'                 = $publicIPName
    'backendWebServer'              = "1.1.1.1"
    'ztnaUsername'                  = $testsAdminUsername
    'ztnaPassword'                  = $testsResourceGroupName
  }
  $ports = @(8443, 22)
}

Describe 'FGT Single VM' {
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
      $diff = ( Compare-Object -ReferenceObject $expectedProperties -DifferenceObject $templateProperties | Format-Table | Out-String )
      if ($diff) { Write-Host ( "Diff: $diff" ) }
      $templateProperties | Should -Be $expectedProperties
    }

    It 'Creates the expected Azure resources' {
      $expectedResources = 'Microsoft.Resources/deployments',
      'Microsoft.Network/virtualNetworks',
      'Microsoft.Resources/deployments'
      $templateResources = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue).Resources.type
      $diff = ( Compare-Object -ReferenceObject $expectedResources -DifferenceObject $templateResources | Format-Table | Out-String )
      if ($diff) { Write-Host ( "Diff: $diff" ) }
      $templateResources | Should -Be $expectedResources
    }

    It 'Contains the expected parameters' {
      $expectedTemplateParameters = 'acceleratedNetworking',
      'adminPassword',
      'adminUsername',
      'backendWebServer',
      'emsCloud',
      'emsServerIP',
      'emsServerPort',
      'fortiGateAdditionalCustomData',
      'fortiGateAdminPort',
      'fortiGateImageSKU',
      'fortiGateImageVersion',
      'fortiGateLicenseBYOL',
      'fortiGateLicenseFortiFlex',
      'fortiGateName',
      'fortiGateNamePrefix',
      'fortiManager',
      'fortiManagerIP',
      'fortiManagerSerial',
      'fortinetTags',
      'instanceType',
      'location',
      'publicIP1AddressType',
      'publicIP1Name',
      'publicIP1NewOrExisting',
      'publicIP1ResourceGroup',
      'publicIP1SKU',
      'serialConsole',
      'subnet1Name',
      'subnet1Prefix',
      'subnet1StartAddress',
      'subnet2Name',
      'subnet2Prefix',
      'subnet2StartAddress',
      'vnetAddressPrefix',
      'vnetName',
      'vnetNewOrExisting',
      'vnetResourceGroup',
      'ztnaHTTPSAccessPort',
      'ztnaPassword',
      'ztnaUserName'                                          
      $templateParameters = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters | Get-Member -MemberType NoteProperty | % Name | Sort-Object
      $diff = ( Compare-Object -ReferenceObject $expectedTemplateParameters -DifferenceObject $templateParameters | Format-Table | Out-String )
      if ($diff) { Write-Host ( "Diff: $diff" ) }
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
      $fgt = (Get-AzPublicIpAddress -Name $publicIPName -ResourceGroupName $testsResourceGroupName).IpAddress
      Write-Host ("FortiGate public IP: " + $fgt)
      $verify_commands = @'
            config system console
            set output standard
            end
            get system status
            show system interface
            show router static
            diag debug cloudinit show
            exit
'@
      $OFS = "`n"
    }
    It "FGT: Ports listening" {
      ForEach ( $port in $ports ) {
        Write-Host ("Check port: $port" )
        $portListening = (Test-Connection -TargetName $fgt -TCPPort $port -TimeoutSeconds 100)
        $portListening | Should -BeTrue
      }
    }
    It "FGT: Verify FortiGate configuration" {
      $result = $verify_commands | ssh -v -tt -i $sshkey -o StrictHostKeyChecking=no devops@$fgt
      $LASTEXITCODE | Should -Be "0"
      Write-Host ("FGT CLI info: " + $result) -Separator `n
      $result | Should -Not -BeLike "*Command fail*"
    }
  }

  Context 'Cleanup' {
    It "Cleanup of deployment" {
      Write-Host ("ERROR: Cleanup disabled" )
      Remove-AzResourceGroup -Name $testsResourceGroupName -Force
    }
  }
}
