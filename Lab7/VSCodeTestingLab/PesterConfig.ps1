# Pester configuration for VS Code integration

# Import Pester module
Import-Module Pester -MinimumVersion 5.0 -Force

$PesterPreference = [PesterConfiguration]::Default

# Output settings for VS Code
$PesterPreference.Output.Verbosity = 'Detailed'
$PesterPreference.Run.Exit = $false
$PesterPreference.TestResult.Enabled = $true
$PesterPreference.TestResult.OutputFormat = 'NUnitXml'
$PesterPreference.TestResult.OutputPath = './TestResults.xml'

# Code coverage settings
$PesterPreference.CodeCoverage.Enabled = $true
$PesterPreference.CodeCoverage.Path = './src/*.ps1'
$PesterPreference.CodeCoverage.OutputFormat = 'CoverageGutters'
$PesterPreference.CodeCoverage.OutputPath = './coverage.xml'

Export-ModuleMember -Variable PesterPreference