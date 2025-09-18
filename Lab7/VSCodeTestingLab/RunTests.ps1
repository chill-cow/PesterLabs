param(
    [string]$TestPath = './tests/*.Tests.ps1',
    [switch]$Coverage,
    [switch]$Detailed
)

# Import Pester module
Import-Module Pester -MinimumVersion 5.0 -Force

$config = [PesterConfiguration]::Default
$config.Run.Path = $TestPath
$config.Output.Verbosity = if ($Detailed) { 'Detailed' } else { 'Normal' }
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = './TestResults.xml'

if ($Coverage)
{
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = './src/*.ps1'
}

Invoke-Pester -Configuration $config