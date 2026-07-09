#Requires -Modules Pester
<#
.SYNOPSIS
    Tests the FortiPAM A-Single-VM ARM template
.EXAMPLE
    Invoke-Pester
.NOTES
    Docs-faithful: no customData config injection, no SSH-key injection.
    Verifies TTK-style structure + deploy + ports 22/443 + HTTPS reachable.
#>

BeforeAll {
  $templateName = "A-Single-VM"
  $sourcePath = "$env:GITHUB_WORKSPACE\FortiPAM\$templateName"
  $scriptPath = "$env:GITHUB_WORKSPACE\FortiPAM\$templateName\test"
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

  # ARM Template Variables -- docs-faithful: no customData, no license injection.
  $publicIPName = "$testsPrefix-fpam-pip"
  $params = @{
    'adminUsername'      = $testsAdminUsername
    'adminPassword'      = $testsResourceGroupName
    'namePrefix'         = $testsPrefix
    'imageSku'           = 'fortinet-fpam'
    'imageVersion'       = '1.9.0'
    'instanceType'       = 'Standard_D4s_v5'
    'publicIPName'       = $publicIPName
    'dataDiskCount'      = 2
  }
  $ports = @(22, 443)
}

Describe 'FPAM Single VM' {
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
      # FPAM = single NIC (one networkInterfaces entry), unlike the dual-NIC variant.
      $expectedResources = 'Microsoft.Resources/deployments',
      'Microsoft.Compute/availabilitySets',
      'Microsoft.Network/virtualNetworks',
      'Microsoft.Network/networkSecurityGroups',
      'Microsoft.Network/publicIPAddresses',
      'Microsoft.Network/networkInterfaces',
      'Microsoft.Compute/virtualMachines'
      $templateResources = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue).Resources.type
      $diff = ( Compare-Object -ReferenceObject $expectedResources -DifferenceObject $templateResources | Format-Table | Out-String )
      if ($diff) { Write-Host ( "Diff: $diff" ) }
      $templateResources | Should -Be $expectedResources
    }

    It 'Contains the expected parameters' {
      $expectedTemplateParameters = 'additionalCustomData',
      'adminPassword',
      'adminUsername',
      'availabilityOptions',
      'availabilityZoneNumber',
      'dataDiskCount',
      'dataDiskSize',
      'diskType',
      'existingAvailabilitySetName',
      'fortinetTags',
      'imageSku',
      'imageVersion',
      'instanceType',
      'location',
      'namePrefix',
      'publicIPName',
      'publicIPNewOrExisting',
      'publicIPResourceGroup',
      'serialConsole',
      'subnet1Name',
      'subnet1Prefix',
      'subnet1StartAddress',
      'vnetAddressPrefix',
      'vnetName',
      'vnetNewOrExisting',
      'vnetResourceGroup'
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
      $fpam = (Get-AzPublicIpAddress -Name $publicIPName -ResourceGroupName $testsResourceGroupName).IpAddress
      Write-Host ("FortiPAM public IP: " + $fpam)
    }

    It "FPAM: Ports listening" {
      ForEach ( $port in $ports ) {
        Write-Host ("Check port: $port" )
        $portListening = (Test-Connection -TargetName $fpam -TCPPort $port -TimeoutSeconds 100)
        $portListening | Should -Be $true
      }
    }

    It "FPAM: HTTPS GUI reachable" {
      # Docs-faithful: FortiPAM license is uploaded post-deploy via SCP, so the
      # GUI may show a license-upload page rather than a login screen. We assert
      # only that HTTPS (443) returns an HTTP response, not a specific page body.
      $resp = $null
      try {
        $resp = Invoke-WebRequest -Uri "https://$fpam/" -SkipCertificateCheck -TimeoutSec 100 -UseBasicParsing
      } catch {
        $resp = $_.Exception.Response
      }
      Write-Host ("HTTPS status: " + $resp.StatusCode)
      $resp | Should -Not -Be $null
    }
  }

  Context 'Cleanup' {
    It "Cleanup of deployment" {
      Remove-AzResourceGroup -Name $testsResourceGroupName -Force
    }
  }
}
