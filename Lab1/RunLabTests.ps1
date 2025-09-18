<#
.SYNOPSIS
    Test runner for ConvertTo-Uppercase function Lab

.DESCRIPTION
    Demonstrates Pester v5 best practices for running tests with configuration,
    code coverage, and different output formats.

.PARAMETER CodeCoverage
    Whether to include code coverage analysis

.PARAMETER OutputPath
    Path where test results and coverage reports should be saved

.EXAMPLE
    .\RunLabTests.ps1
    Runs all tests with default configuration

.EXAMPLE
    .\RunLabTests.ps1 -CodeCoverage
    Runs tests with code coverage analysis
#>

[CmdletBinding()]
param(
    [switch]$CodeCoverage,
    [string]$OutputPath = $PSScriptRoot
)

# Ensure Pester v5 is available
$PesterVersion = Get-Module -Name Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
if (-not $PesterVersion -or $PesterVersion.Version.Major -lt 5)
{
    Write-Warning "Pester v5.0 or higher is required. Current version: $($PesterVersion.Version)"
    Write-Host 'Install Pester v5 with: Install-Module -Name Pester -Force -SkipPublisherCheck'
    return
}

Write-Host "Using Pester version: $($PesterVersion.Version)" -ForegroundColor Green
Import-Module Pester -Force

# Create Pester configuration
$config = New-PesterConfiguration

# Configure paths
$config.Run.Path = Join-Path $PSScriptRoot 'ConvertToUpperCaseSolution.Tests.ps1'
$config.Run.PassThru = $true

# Configure output
$config.Output.Verbosity = 'Detailed'
$config.Output.StackTraceVerbosity = 'Filtered'

# Configure code coverage if requested
if ($CodeCoverage)
{
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = Join-Path $PSScriptRoot 'ConvertToUpperCaseSolution.ps1'
    $config.CodeCoverage.OutputFormat = 'JaCoCo'
    $config.CodeCoverage.OutputPath = Join-Path $OutputPath 'coverage.xml'
    Write-Host "Code coverage enabled - Report will be saved to: $($config.CodeCoverage.OutputPath)" -ForegroundColor Yellow
}

# Configure test results
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.TestResult.OutputPath = Join-Path $OutputPath 'testresults.xml'

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputPath))
{
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

Write-Host "Test results will be saved to: $($config.TestResult.OutputPath)" -ForegroundColor Yellow

# Run the tests
Write-Host "`nRunning ConvertTo-Uppercase function tests..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $config

# Display summary
Write-Host "`n" -NoNewline
Write-Host '=== TEST SUMMARY ===' -ForegroundColor Magenta
Write-Host "Tests Run: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "Passed: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "Failed: $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "Skipped: $($testResults.SkippedCount)" -ForegroundColor Yellow

if ($testResults.CodeCoverage)
{
    if ($testResults.CodeCoverage.NumberOfCommandsAnalyzed -gt 0)
    {
        $coveragePercent = [math]::Round(($testResults.CodeCoverage.NumberOfCommandsExecuted / $testResults.CodeCoverage.NumberOfCommandsAnalyzed) * 100, 2)
        Write-Host "Code Coverage: $coveragePercent%" -ForegroundColor $(if ($coveragePercent -ge 80) { 'Green' } elseif ($coveragePercent -ge 60) { 'Yellow' } else { 'Red' })
        
        # Show missed commands if any
        if ($testResults.CodeCoverage.MissedCommands.Count -gt 0)
        {
            Write-Host "`nMissed Commands:" -ForegroundColor Yellow
            $testResults.CodeCoverage.MissedCommands | ForEach-Object {
                Write-Host "  Line $($_.Line): $($_.Command)" -ForegroundColor Yellow
            }
        }
    }
    else
    {
        Write-Host 'Code Coverage: No commands analyzed' -ForegroundColor Yellow
    }
}

Write-Host "Duration: $([math]::Round($testResults.Duration.TotalSeconds, 2)) seconds" -ForegroundColor White

# Exit with appropriate code
if ($testResults.FailedCount -gt 0)
{
    Write-Host "`nTests failed! Check the output above for details." -ForegroundColor Red
    exit 1
}
else
{
    Write-Host "`nAll tests passed! ✅" -ForegroundColor Green
    exit 0
}