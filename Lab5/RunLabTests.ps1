#Requires -Version 7.4
#Requires -Modules Pester

<#
.SYNOPSIS
    Test runner for Lab 5 - Class Testing
#>

param(
    [switch]$ShowDetails
)

Write-Host '🧪 Lab 5: Class Testing' -ForegroundColor Cyan
Write-Host '========================' -ForegroundColor Cyan

# Configure Pester
$pesterConfig = [PesterConfiguration]::Default
$pesterConfig.Run.Path = "$PSScriptRoot\Task.Tests.ps1"
$pesterConfig.Run.Passthru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = "$PSScriptRoot\TestResults.xml"

# Run tests
Write-Host "`n🏃 Running class tests..." -ForegroundColor Yellow
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

if ($ShowDetails)
{
    Write-Host "`n📈 Class Testing Summary:" -ForegroundColor Magenta
    Write-Host 'This lab demonstrated class testing concepts:' -ForegroundColor White
    Write-Host '• Constructor testing with different parameters' -ForegroundColor Gray
    Write-Host '• Property validation and type checking' -ForegroundColor Gray
    Write-Host '• Method behavior testing' -ForegroundColor Gray
    Write-Host '• Business logic validation' -ForegroundColor Gray
    Write-Host '• String representation testing' -ForegroundColor Gray
}

Write-Host "`n🎉 Lab 5 completed successfully!" -ForegroundColor Green