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
    $config = "config system global `n set gui-theme mariner `n end `n config system admin `n edit devops `n set accprofile super_admin `n set ssh-public-key1 `""
    $config += Get-Content $sshkeypub
    $config += "`" `n set password $testsResourceGroupName `n next `n end"
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
    Context 'Validation' {
        It 'Has a JSON template' {
            $templateFileLocation | Should -Exist
        }
    }

    Context 'Deployment test' {

        BeforeAll {
            $fgt = "w.jvh.be"
            Write-Host ("FortiGate public IP: " + $fgt)
            Write-Host ("FortiGate public IP: " + $fgt)
            dir
            dir /home/runner/
            Write-Host ("SSH Check: ")
            ls 
            Write-Host ("SSH Check: ")
            ls /home/runner/
            Write-Host ("SSH Check: ")
            ls /home/runner/.ssh/
            Write-Host ("SSH Check: ")
            chmod 400 $sshkey
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
            dir
            dir /home/runner/
            Write-Host ("SSH Check: ")
            ls 
            Write-Host ("SSH Check: ")
            ls /home/runner/
            Write-Host ("SSH Check: ")
            ls /home/runner/.ssh/
            Write-Host ("SSH Check: ")
            ForEach( $port in $ports ) {
                Write-Host ("Check port: $port" )
                $portListening = (Test-Connection -TargetName $fgt -TCPPort $port -TimeoutSeconds 100)
                $portListening | Should -Be $true
            }
        }
        It "FGT: Verify FortiGate A configuration" {
            $result = $verify_commands | ssh -tt -i $sshkey -o StrictHostKeyChecking=no devops@$fgt
            Write-Host (": " + $result) -Separator `n
        }
    }

    Context 'Cleanup' {
        It "Cleanup of deployment" {
            Remove-AzResourceGroup -Name $testsResourceGroupName -Force
        }
    }
}
