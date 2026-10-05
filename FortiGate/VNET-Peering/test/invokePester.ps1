param (
    [string]$templatename,
    [string]$sshkey,
    [string]$sshkeypub
)

$SourceDir = Join-Path $env:BUILD_SOURCESDIRECTORY "$templatename"
$TempDir = [IO.Path]::GetTempPath()
$modulePath = Join-Path $TempDir arm-ttk\arm-ttk\arm-ttk.psd1

if (-not(Test-Path $modulePath)) {
    # Note: PSGet and chocolatey are not supported in hosted vsts build agent
    git clone --depth 1 https://github.com/Azure/arm-ttk.git (Join-Path $TempDir arm-ttk)
}

Import-Module $modulePath -DisableNameChecking

Install-Module -Name Pester -Force

$modulePath = Join-Path $TempDir Export-NUnitXml.psm1

if (-not(Test-Path $modulePath)) {

    $tempFile = Join-Path $TempDir Export-NUnitXml.psm1
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest https://raw.githubusercontent.com/sam-cogan/arm-ttk-extension/master/task/Export-NUnitXml.psm1 -OutFile $tempFile
}

Import-Module $modulePath -DisableNameChecking

$outputFile = Join-Path $SourceDir "TEST-armttk.xml";

"Running ARM TTK"

$result = @(Test-AzTemplate -TemplatePath $SourceDir)
$result
Export-NUnitXml -TestResults $result -Path $SourceDir

$outputFile = Join-Path $SourceDir "TEST-custom.xml";

"Running custom tests"

$container = New-PesterContainer -Path $SourceDir -Data @{sshkey = $sshkey; sshkeypub = $sshkeypub}
$result = Invoke-Pester -Container $container -Output Detailed -PassThru -Path $SourceDir
$result
Export-NUnitReport -Result $result -Path $outputFile
