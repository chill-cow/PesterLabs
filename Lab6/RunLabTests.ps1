name: "Lab 6 - CI/CD Test Runner"
description: "Comprehensive test runner for PowerShell Module CI/CD Lab"
version: "1.0.0"

#Requires -Version 7.4
#Requires -Modules Pester

<#
.SYNOPSIS
    Comprehensive test runner for Lab 6 - CI/CD Integration with GitHub Actions.

.DESCRIPTION
    This script demonstrates the complete CI/CD testing workflow including:
    - Module import and validation
    - Unit test execution with code coverage
    - Integration test execution  
    - Performance testing
    - Code quality analysis
    - Documentation validation

.PARAMETER TestType
    Specifies which tests to run:
    - All: Run all tests (default)
    - Unit: Run only unit tests
    - Integration: Run only integration tests
    - Performance: Run performance tests only
    - Quality: Run code quality checks only

.PARAMETER GenerateReport
    Generate detailed HTML test reports.

.PARAMETER CodeCoverage
    Enable code coverage analysis.

.EXAMPLE
    .\RunLabTests.ps1
    
    Runs all tests with default settings.

.EXAMPLE
    .\RunLabTests.ps1 -TestType Unit -CodeCoverage -GenerateReport
    
    Runs unit tests with code coverage and generates HTML report.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('All', 'Unit', 'Integration', 'Performance', 'Quality')]
    [string]$TestType = 'All',
    
    [Parameter()]
    [switch]$GenerateReport,
    
    [Parameter()]
    [switch]$CodeCoverage,
    
    [Parameter()]
    [switch]$Verbose
)

# Configure verbose preference
if ($Verbose) {
    $VerbosePreference = 'Continue'
}

# Lab configuration
$LabConfig = @{
    Name = "Lab 6 - CI/CD Integration with GitHub Actions"
    Version = "1.0.0"
    ModulePath = Join-Path $PSScriptRoot "PowerShellModule.psd1"
    TestPaths = @{
        Unit = Join-Path $PSScriptRoot "tests\Unit"
        Integration = Join-Path $PSScriptRoot "tests\Integration"
        TestHelpers = Join-Path $PSScriptRoot "tests\TestHelpers"
    }
    OutputPath = Join-Path $PSScriptRoot "TestResults"
    RequiredModules = @('Pester', 'PSScriptAnalyzer')
}

Write-Host "🚀 Starting $($LabConfig.Name)" -ForegroundColor Cyan
Write-Host "Version: $($LabConfig.Version)" -ForegroundColor Cyan
Write-Host "Test Type: $TestType" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

# Function to check prerequisites
function Test-Prerequisites {
    Write-Host "`n📋 Checking Prerequisites..." -ForegroundColor Yellow
    
    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    Write-Host "PowerShell Version: $psVersion"
    
    if ($psVersion.Major -lt 7 -or ($psVersion.Major -eq 7 -and $psVersion.Minor -lt 4)) {
        throw "PowerShell 7.4 or later is required. Current version: $psVersion"
    }
    
    # Check required modules
    foreach ($moduleName in $LabConfig.RequiredModules) {
        try {
            $module = Get-Module -Name $moduleName -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
            if ($module) {
                Import-Module -Name $moduleName -Force
                Write-Host "✅ $moduleName v$($module.Version) - Available" -ForegroundColor Green
            } else {
                Write-Host "❌ $moduleName - Not found" -ForegroundColor Red
                Write-Host "Installing $moduleName..." -ForegroundColor Yellow
                Install-Module -Name $moduleName -Force -Scope CurrentUser
                Import-Module -Name $moduleName -Force
                Write-Host "✅ $moduleName - Installed and imported" -ForegroundColor Green
            }
        }
        catch {
            throw "Failed to import required module '$moduleName': $_"
        }
    }
    
    # Check module under test
    if (Test-Path $LabConfig.ModulePath) {
        Write-Host "✅ Target module found: $($LabConfig.ModulePath)" -ForegroundColor Green
    } else {
        throw "Target module not found: $($LabConfig.ModulePath)"
    }
    
    # Check test directories
    foreach ($testPath in $LabConfig.TestPaths.Values) {
        if (Test-Path $testPath) {
            Write-Host "✅ Test directory found: $testPath" -ForegroundColor Green
        } else {
            Write-Warning "Test directory not found: $testPath"
        }
    }
    
    Write-Host "✅ All prerequisites satisfied" -ForegroundColor Green
}

# Function to run code quality checks
function Invoke-CodeQualityCheck {
    Write-Host "`n🔍 Running Code Quality Analysis..." -ForegroundColor Yellow
    
    $sourceFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot "src") -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
    
    if (-not $sourceFiles) {
        Write-Warning "No source files found for analysis"
        return
    }
    
    $analysisResults = @()
    
    foreach ($file in $sourceFiles) {
        Write-Verbose "Analyzing: $($file.FullName)"
        $results = Invoke-ScriptAnalyzer -Path $file.FullName -Severity @('Error', 'Warning', 'Information')
        if ($results) {
            $analysisResults += $results
        }
    }
    
    if ($analysisResults) {
        $errorCount = ($analysisResults | Where-Object Severity -eq 'Error').Count
        $warningCount = ($analysisResults | Where-Object Severity -eq 'Warning').Count
        $infoCount = ($analysisResults | Where-Object Severity -eq 'Information').Count
        
        Write-Host "PSScriptAnalyzer Results:" -ForegroundColor Cyan
        Write-Host "  Errors: $errorCount" -ForegroundColor Red
        Write-Host "  Warnings: $warningCount" -ForegroundColor Yellow
        Write-Host "  Information: $infoCount" -ForegroundColor Blue
        
        if ($errorCount -gt 0) {
            Write-Host "`nErrors found:" -ForegroundColor Red
            $analysisResults | Where-Object Severity -eq 'Error' | ForEach-Object {
                Write-Host "  $($_.ScriptName):$($_.Line) - $($_.Message)" -ForegroundColor Red
            }
        }
        
        if ($warningCount -gt 0 -and $Verbose) {
            Write-Host "`nWarnings found:" -ForegroundColor Yellow
            $analysisResults | Where-Object Severity -eq 'Warning' | ForEach-Object {
                Write-Host "  $($_.ScriptName):$($_.Line) - $($_.Message)" -ForegroundColor Yellow
            }
        }
        
        return $analysisResults
    } else {
        Write-Host "✅ No issues found" -ForegroundColor Green
        return @()
    }
}

# Function to test module import
function Test-ModuleImport {
    Write-Host "`n📦 Testing Module Import..." -ForegroundColor Yellow
    
    try {
        # Test module manifest
        $manifest = Test-ModuleManifest -Path $LabConfig.ModulePath -ErrorAction Stop
        Write-Host "✅ Module manifest is valid" -ForegroundColor Green
        Write-Host "  Name: $($manifest.Name)" -ForegroundColor Cyan
        Write-Host "  Version: $($manifest.Version)" -ForegroundColor Cyan
        Write-Host "  Author: $($manifest.Author)" -ForegroundColor Cyan
        
        # Import module
        Import-Module $LabConfig.ModulePath -Force -ErrorAction Stop
        $functions = Get-Command -Module PowerShellModule
        
        Write-Host "✅ Module imported successfully" -ForegroundColor Green
        Write-Host "  Exported Functions: $($functions.Count)" -ForegroundColor Cyan
        
        foreach ($function in $functions) {
            Write-Host "    - $($function.Name)" -ForegroundColor Gray
        }
        
        return $true
    }
    catch {
        Write-Host "❌ Module import failed: $_" -ForegroundColor Red
        return $false
    }
}

# Function to run unit tests
function Invoke-UnitTests {
    Write-Host "`n🧪 Running Unit Tests..." -ForegroundColor Yellow
    
    if (-not (Test-Path $LabConfig.TestPaths.Unit)) {
        Write-Warning "Unit tests directory not found"
        return $null
    }
    
    $outputFile = Join-Path $LabConfig.OutputPath "UnitTest-Results.xml"
    $coverageFile = Join-Path $LabConfig.OutputPath "Coverage-Unit.xml"
    
    $pesterConfig = [PesterConfiguration]::Default
    $pesterConfig.Run.Path = $LabConfig.TestPaths.Unit
    $pesterConfig.Run.Passthru = $true
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
    $pesterConfig.TestResult.OutputPath = $outputFile
    $pesterConfig.Output.Verbosity = if ($Verbose) { 'Detailed' } else { 'Normal' }
    
    if ($CodeCoverage) {
        $pesterConfig.CodeCoverage.Enabled = $true
        $pesterConfig.CodeCoverage.Path = Join-Path $PSScriptRoot "src\**\*.ps1"
        $pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
        $pesterConfig.CodeCoverage.OutputPath = $coverageFile
    }
    
    $testResults = Invoke-Pester -Configuration $pesterConfig
    
    Write-Host "`n📊 Unit Test Results:" -ForegroundColor Cyan
    Write-Host "  Total: $($testResults.TotalCount)"
    Write-Host "  Passed: $($testResults.PassedCount)" -ForegroundColor Green
    Write-Host "  Failed: $($testResults.FailedCount)" -ForegroundColor Red
    Write-Host "  Skipped: $($testResults.SkippedCount)" -ForegroundColor Yellow
    
    if ($testResults.CodeCoverage) {
        $coverage = [Math]::Round($testResults.CodeCoverage.CoveragePercent, 2)
        Write-Host "  Code Coverage: $coverage%" -ForegroundColor Cyan
    }
    
    return $testResults
}

# Function to run integration tests
function Invoke-IntegrationTests {
    Write-Host "`n🔗 Running Integration Tests..." -ForegroundColor Yellow
    
    if (-not (Test-Path $LabConfig.TestPaths.Integration)) {
        Write-Warning "Integration tests directory not found"
        return $null
    }
    
    $outputFile = Join-Path $LabConfig.OutputPath "IntegrationTest-Results.xml"
    
    $pesterConfig = [PesterConfiguration]::Default
    $pesterConfig.Run.Path = $LabConfig.TestPaths.Integration
    $pesterConfig.Run.Passthru = $true
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
    $pesterConfig.TestResult.OutputPath = $outputFile
    $pesterConfig.Output.Verbosity = if ($Verbose) { 'Detailed' } else { 'Normal' }
    
    $testResults = Invoke-Pester -Configuration $pesterConfig
    
    Write-Host "`n📊 Integration Test Results:" -ForegroundColor Cyan
    Write-Host "  Total: $($testResults.TotalCount)"
    Write-Host "  Passed: $($testResults.PassedCount)" -ForegroundColor Green
    Write-Host "  Failed: $($testResults.FailedCount)" -ForegroundColor Red
    Write-Host "  Skipped: $($testResults.SkippedCount)" -ForegroundColor Yellow
    
    return $testResults
}

# Function to run performance tests
function Invoke-PerformanceTests {
    Write-Host "`n⚡ Running Performance Tests..." -ForegroundColor Yellow
    
    # Import test helpers
    if (Test-Path $LabConfig.TestPaths.TestHelpers) {
        Import-Module (Join-Path $LabConfig.TestPaths.TestHelpers "TestHelpers.psm1") -Force
    }
    
    # Import the main module
    Import-Module $LabConfig.ModulePath -Force
    
    $performanceResults = @()
    
    # Test ConvertTo-UpperCase performance
    Write-Host "Testing ConvertTo-UpperCase performance..."
    $testData = 1..1000 | ForEach-Object { "teststring$_" }
    
    $duration = Measure-Command {
        $testData | ConvertTo-UpperCase | Out-Null
    }
    
    $performanceResults += [PSCustomObject]@{
        Function = 'ConvertTo-UpperCase'
        DataSize = $testData.Count
        Duration = $duration.TotalMilliseconds
        ItemsPerSecond = [Math]::Round($testData.Count / $duration.TotalSeconds, 2)
    }
    
    # Test Get-EmailAddress performance
    Write-Host "Testing Get-EmailAddress performance..."
    $emailData = 1..500 | ForEach-Object { "user$_@example.com" }
    
    $duration = Measure-Command {
        $emailData | Get-EmailAddress | Out-Null
    }
    
    $performanceResults += [PSCustomObject]@{
        Function = 'Get-EmailAddress'
        DataSize = $emailData.Count
        Duration = $duration.TotalMilliseconds
        ItemsPerSecond = [Math]::Round($emailData.Count / $duration.TotalSeconds, 2)
    }
    
    # Test Get-DemoComputers performance
    Write-Host "Testing Get-DemoComputers performance..."
    
    $duration = Measure-Command {
        Get-DemoComputers -Count 100 -IncludeProperties 'All' | Out-Null
    }
    
    $performanceResults += [PSCustomObject]@{
        Function = 'Get-DemoComputers'
        DataSize = 100
        Duration = $duration.TotalMilliseconds
        ItemsPerSecond = [Math]::Round(100 / $duration.TotalSeconds, 2)
    }
    
    Write-Host "`n📊 Performance Test Results:" -ForegroundColor Cyan
    $performanceResults | Format-Table -AutoSize
    
    return $performanceResults
}

# Function to generate reports
function New-TestReport {
    param($Results)
    
    if (-not $GenerateReport) {
        return
    }
    
    Write-Host "`n📋 Generating Test Report..." -ForegroundColor Yellow
    
    $reportPath = Join-Path $LabConfig.OutputPath "TestReport.html"
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>$($LabConfig.Name) - Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #2E86AB; color: white; padding: 10px; }
        .section { margin: 20px 0; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>$($LabConfig.Name)</h1>
        <p>Generated: $(Get-Date)</p>
    </div>
"@
    
    foreach ($result in $Results.GetEnumerator()) {
        $html += "<div class='section'><h2>$($result.Key)</h2>"
        
        if ($result.Value) {
            $html += "<p class='success'>✅ Completed</p>"
            
            if ($result.Value.GetType().Name -eq 'Object[]') {
                $html += "<table><tr>"
                $result.Value[0].PSObject.Properties.Name | ForEach-Object {
                    $html += "<th>$_</th>"
                }
                $html += "</tr>"
                
                foreach ($item in $result.Value) {
                    $html += "<tr>"
                    $item.PSObject.Properties.Value | ForEach-Object {
                        $html += "<td>$_</td>"
                    }
                    $html += "</tr>"
                }
                $html += "</table>"
            }
        } else {
            $html += "<p class='error'>❌ Failed or Skipped</p>"
        }
        
        $html += "</div>"
    }
    
    $html += "</body></html>"
    
    Set-Content -Path $reportPath -Value $html -Encoding UTF8
    Write-Host "✅ Test report generated: $reportPath" -ForegroundColor Green
}

# Main execution
try {
    # Create output directory
    if (-not (Test-Path $LabConfig.OutputPath)) {
        New-Item -Path $LabConfig.OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # Check prerequisites
    Test-Prerequisites
    
    # Initialize results tracking
    $allResults = @{}
    $overallSuccess = $true
    
    # Test module import
    $moduleImportSuccess = Test-ModuleImport
    $allResults['Module Import'] = $moduleImportSuccess
    
    if (-not $moduleImportSuccess) {
        throw "Module import failed - cannot continue with tests"
    }
    
    # Run tests based on TestType parameter
    switch ($TestType) {
        'All' {
            $allResults['Code Quality'] = Invoke-CodeQualityCheck
            $allResults['Unit Tests'] = Invoke-UnitTests
            $allResults['Integration Tests'] = Invoke-IntegrationTests
            $allResults['Performance Tests'] = Invoke-PerformanceTests
        }
        'Unit' {
            $allResults['Unit Tests'] = Invoke-UnitTests
        }
        'Integration' {
            $allResults['Integration Tests'] = Invoke-IntegrationTests
        }
        'Performance' {
            $allResults['Performance Tests'] = Invoke-PerformanceTests
        }
        'Quality' {
            $allResults['Code Quality'] = Invoke-CodeQualityCheck
        }
    }
    
    # Check for test failures
    foreach ($result in $allResults.GetEnumerator()) {
        if ($result.Value -and $result.Value.GetType().Name -like '*TestResult*') {
            if ($result.Value.FailedCount -gt 0) {
                $overallSuccess = $false
                Write-Host "❌ $($result.Key) had $($result.Value.FailedCount) failures" -ForegroundColor Red
            }
        }
    }
    
    # Generate report if requested
    New-TestReport -Results $allResults
    
    # Summary
    Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
    Write-Host "📋 Lab 6 Test Summary" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan
    
    foreach ($result in $allResults.GetEnumerator()) {
        $status = if ($result.Value) { "✅ PASSED" } else { "❌ FAILED" }
        $color = if ($result.Value) { "Green" } else { "Red" }
        Write-Host "$($result.Key): $status" -ForegroundColor $color
    }
    
    Write-Host "`nOverall Result: " -NoNewline
    if ($overallSuccess) {
        Write-Host "✅ SUCCESS" -ForegroundColor Green
        Write-Host "`n🎉 Lab 6 completed successfully!" -ForegroundColor Green
        Write-Host "You have demonstrated comprehensive CI/CD testing with:" -ForegroundColor Green
        Write-Host "  • Multi-platform PowerShell module testing" -ForegroundColor Green
        Write-Host "  • GitHub Actions workflow integration" -ForegroundColor Green
        Write-Host "  • Code quality analysis and validation" -ForegroundColor Green
        Write-Host "  • Automated testing and deployment pipelines" -ForegroundColor Green
    } else {
        Write-Host "❌ FAILED" -ForegroundColor Red
        Write-Host "`nSome tests failed. Please review the results above." -ForegroundColor Yellow
        exit 1
    }
    
} catch {
    Write-Host "`n❌ Lab 6 execution failed: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}