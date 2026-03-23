#Requires -Modules Pester
<#
.SYNOPSIS
    Pester v5 tests for the ZTNAApplicationGateway ARM template
.DESCRIPTION
    Validates the template structure, deploys to Azure, and verifies the FortiGate
    is reachable on its management and ZTNA access ports.
.EXAMPLE
    Invoke-Pester
    ./test/Invoke-Tests.ps1
#>

param (
    [string]$sshkey    = "",
    [string]$sshkeypub = ""
)

BeforeAll {
    $templateName = "ZTNAApplicationGateway"

    # Resolve source path — works both in GitHub Actions and locally
    $sourcePath = if ($env:GITHUB_WORKSPACE) {
        "$env:GITHUB_WORKSPACE/FortiGate/$templateName"
    } else {
        (Resolve-Path "$PSScriptRoot/..").Path
    }

    $templateFileLocation          = "$sourcePath/azuredeploy.json"
    $templateParameterFileLocation = "$sourcePath/azuredeploy.parameters.json"

    # Unique prefix per run to avoid resource name collisions
    $testsRandom        = Get-Random 10001
    $testsPrefix        = "FORTIQA"
    $testsAdminUsername = "azureuser"

    $testsResourceGroupLocation = "westeurope"
    $testsResourceGroupName     = "FORTIQA-$testsRandom-$templateName"

    # Use a known PIP name so we can look it up after deployment
    $publicIPName = "$testsPrefix-fgt-pip"

    # FortiGate cloud-init: add a devops admin with the test SSH public key
    $config = ""
    if ($sshkeypub -and (Test-Path $sshkeypub)) {
        $pubkey  = Get-Content $sshkeypub
        $config  = "config system console`nset output standard`nend`n"
        $config += "config system global`nset gui-theme mariner`nend`n"
        $config += "config system admin`nedit devops`nset accprofile super_admin`n"
        $config += "set ssh-public-key1 `"$pubkey`"`n"
        $config += "set password $testsResourceGroupName`nnext`nend"
    }

    $params = @{
        adminUsername               = $testsAdminUsername
        adminPassword               = $testsResourceGroupName
        fortiGateNamePrefix         = $testsPrefix
        fortiGateAdditionalCustomData = $config
        publicIP1Name               = $publicIPName
        backendWebServer            = "1.1.1.1"
        ztnaUsername                = $testsAdminUsername
        ztnaPassword                = $testsResourceGroupName
    }
}

AfterAll {
    if ($testsResourceGroupName -and
        (Get-AzResourceGroup -Name $testsResourceGroupName -ErrorAction SilentlyContinue)) {
        Write-Host "Cleaning up resource group: $testsResourceGroupName"
        Remove-AzResourceGroup -Name $testsResourceGroupName -Force
    }
}

Describe "FGT ZTNA Application Gateway" {

    Context 'Validation' {

        It 'Has a JSON template' {
            $templateFileLocation | Should -Exist
        }

        It 'Has a parameters file' {
            $templateParameterFileLocation | Should -Exist
        }

        It 'Converts from JSON and has the expected top-level properties' {
            $expectedProperties = '$schema', 'contentVersion', 'outputs', 'parameters', 'resources', 'variables'
            $templateProperties = (Get-Content $templateFileLocation |
                ConvertFrom-Json -ErrorAction SilentlyContinue) |
                Get-Member -MemberType NoteProperty | ForEach-Object Name
            $diff = Compare-Object -ReferenceObject $expectedProperties -DifferenceObject $templateProperties |
                Format-Table | Out-String
            if ($diff.Trim()) { Write-Host "Diff: $diff" }
            $templateProperties | Should -Be $expectedProperties
        }

        It 'Declares the expected Azure resource types' {
            $expectedResources = @(
                'Microsoft.Resources/deployments',
                'Microsoft.Network/virtualNetworks',
                'Microsoft.Resources/deployments'
            )
            $templateResources = (Get-Content $templateFileLocation |
                ConvertFrom-Json -ErrorAction SilentlyContinue).Resources.type
            $diff = Compare-Object -ReferenceObject $expectedResources -DifferenceObject $templateResources |
                Format-Table | Out-String
            if ($diff.Trim()) { Write-Host "Diff: $diff" }
            $templateResources | Should -Be $expectedResources
        }

        It 'Contains the expected parameters' {
            $expectedTemplateParameters = @(
                'acceleratedNetworking',
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
                'ztnaUsername'
            )
            $templateParameters = (Get-Content $templateFileLocation |
                ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters |
                Get-Member -MemberType NoteProperty | ForEach-Object Name | Sort-Object
            $diff = Compare-Object -ReferenceObject $expectedTemplateParameters -DifferenceObject $templateParameters |
                Format-Table | Out-String
            if ($diff.Trim()) { Write-Host "Diff: $diff" }
            $templateParameters | Should -Be $expectedTemplateParameters
        }
    }

    Context 'Deployment' {

        It 'ARM template validation passes' {
            New-AzResourceGroup -Name $testsResourceGroupName -Location $testsResourceGroupLocation
            $result = Test-AzResourceGroupDeployment `
                -ResourceGroupName $testsResourceGroupName `
                -TemplateFile $templateFileLocation `
                -TemplateParameterObject $params
            Write-Host ($result | Format-Table -Wrap -AutoSize | Out-String)
            $result.Count | Should -Not -BeGreaterThan 0
        }

        It 'ARM template deploys successfully' {
            $script:deployment = New-AzResourceGroupDeployment `
                -ResourceGroupName $testsResourceGroupName `
                -TemplateFile $templateFileLocation `
                -TemplateParameterObject $params
            Write-Host ("Provisioning state: " + $script:deployment.ProvisioningState)
            $script:deployment.ProvisioningState | Should -Be "Succeeded"
        }

        It 'FortiGate VM exists in the resource group' {
            $result = Get-AzVM -ResourceGroupName $testsResourceGroupName |
                Where-Object { $_.Name -like "$testsPrefix*" }
            Write-Host ($result | Format-Table | Out-String)
            $result | Should -Not -Be $null
        }
    }

    Context 'Connectivity' {

        BeforeAll {
            $script:fgt = (Get-AzPublicIpAddress -Name $publicIPName -ResourceGroupName $testsResourceGroupName).IpAddress
            Write-Host "FortiGate public IP: $($script:fgt)"

            $script:verify_commands = @'
get system status
show system interface
show router static
diag debug cloudinit show
exit
'@
        }

        It 'FGT: port <port> is reachable' -ForEach @(
            @{ port = 8443 },
            @{ port = 22   }
        ) {
            $listening = Test-Connection -TargetName $script:fgt -TCPPort $port -TimeoutSeconds 100
            $listening | Should -Be $true
        }

        It 'SSH: FGT configuration applied correctly' {
            $result = $script:verify_commands | ssh -tt -i $sshkey -o StrictHostKeyChecking=no devops@$($script:fgt)
            $LASTEXITCODE | Should -Be 0
            Write-Host ("FGT CLI output:`n" + ($result -join "`n"))
            $result | Should -Not -BeLike "*Command fail*"
        }
    }
}
