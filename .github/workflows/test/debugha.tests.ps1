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
    [string]$sshkey
)
$VerbosePreference = "Continue"

BeforeAll {
    $templateName = "A-Single-VM"
    $sourcePath = "$env:GITHUB_WORKSPACE\FortiGate\$templateName"
    $scriptPath = "$env:GITHUB_WORKSPACE\FortiGate\$templateName\test"
    $templateFileName = "azuredeploy.json"
    $templateFileLocation = "$sourcePath\$templateFileName"
    $templateParameterFileName = "azuredeploy.parameters.json"
    $templateParameterFileLocation = "$sourcePath\$templateParameterFileName"

    # Basic Variables
    $testsRandom = Get-Random 10001
    $testsPrefix = "FORTIQA"
    $testsResourceGroupName = "FORTIQA-$testsRandom-$templateName"
    $testsAdminUsername = "azureuser"
    $testsResourceGroupLocation = "westeurope"

    # ARM Template Variables
    $publicIPName = "$testsPrefix-FGT-PIP"
    $params = @{ 'adminUsername'=$testsAdminUsername
                 'adminPassword'=$testsResourceGroupName
                 'fortiGateNamePrefix'=$testsPrefix
                 'fortiGateAdditionalCustomData'=$config
                 'publicIP1Name'=$publicIPName
               }
    $ports = @(443, 22)
}

Describe 'FGT Single VM' {
    Context 'Deployment test' {

        BeforeAll {
            $fgt = "roz.jvh.be"
            Write-Host ("FortiGate public IP: " + $fgt)
            $verify_commands = @'
            config system console
            set output standard
            end
            show system interface
            show router static
            diag debug cloudinit show
            exit
'@
            $OFS = "`n"
        }
        It "FGT: Ports listening" {
            Write-Host ("FortiGate public IP: " + $fgt)
            ForEach( $port in $ports ) {
                Write-Host ("Check port: $port" )
                $portListening = (Test-Connection -TargetName $fgt -TCPPort $port -TimeoutSeconds 100)
                $portListening | Should -Be $true
            }
        }
        It "FGT: Verify FortiGate A configuration" {
            $result = $($verify_commands | ssh -v -tt -i $sshkey -o StrictHostKeyChecking=no devops@$fgt)
            $LASTEXITCODE | Should -Be "0"
            Write-Host ("FGT CLI info: " + $result) -Separator `n
            $result | Should -Not -BeLike "*Command fail*"
        }
    }
}
