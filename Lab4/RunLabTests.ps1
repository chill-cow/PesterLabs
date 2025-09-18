#Requires -Version 7.4
#Requires -Modules Pester

<#
.SYNOPSIS
    Test runner for Lab 4 - Performance Testing
#>

param(
    [switch]$ShowPerformanceDetails
)

Write-Host '🧪 Lab 4: Performance Testing' -ForegroundColor Cyan
Write-Host '==============================' -ForegroundColor Cyan

# Configure Pester
$pesterConfig = [PesterConfiguration]::Default
$pesterConfig.Run.Path = "$PSScriptRoot\DataProcessor.Tests.ps1"
$pesterConfig.Run.Passthru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = "$PSScriptRoot\TestResults.xml"

# Run tests
Write-Host "`n🏃 Running performance tests..." -ForegroundColor Yellow
$testResults = Invoke-Pester -Configuration $pesterConfig

# Display results
Write-Host "`n📊 Test Results:" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "Passed: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "Failed: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "Skipped: $($testResults.SkippedCount)" -ForegroundColor Yellow

if ($testResults.FailedCount -gt 0)
{
    Write-Host "`n❌ Some tests failed!" -ForegroundColor Red
    exit 1
}
else
{
    Write-Host "`n✅ All tests passed!" -ForegroundColor Green
}

if ($ShowPerformanceDetails)
{
    Write-Host "`n📈 Performance Details:" -ForegroundColor Cyan
    Write-Host 'Check the test output above for detailed performance metrics' -ForegroundColor Gray
}