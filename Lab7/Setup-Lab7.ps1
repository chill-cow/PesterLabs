# Lab 7 Setup Script
# This script helps you set up the VS Code Testing Lab environment

Write-Host '🧪 Setting up Lab 7: VS Code Testing Integration' -ForegroundColor Cyan
Write-Host ''

# Check PowerShell version
Write-Host 'Checking PowerShell version...' -ForegroundColor Yellow
if ($PSVersionTable.PSVersion.Major -lt 7)
{
    Write-Warning "PowerShell 7+ is recommended for this lab. Current version: $($PSVersionTable.PSVersion)"
}
else
{
    Write-Host "✅ PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor Green
}

# Check Pester installation
Write-Host 'Checking Pester installation...' -ForegroundColor Yellow
$pesterModule = Get-Module Pester -ListAvailable | Where-Object { $_.Version -ge [Version]'5.7.0' } | Select-Object -First 1

if ($pesterModule)
{
    Write-Host "✅ Pester version: $($pesterModule.Version)" -ForegroundColor Green
}
else
{
    Write-Host '⚠️ Installing Pester 5.7.1...' -ForegroundColor Yellow
    Install-Module Pester -MinimumVersion 5.7.1 -Force -SkipPublisherCheck
    Write-Host '✅ Pester installed' -ForegroundColor Green
}

# Test the sample project
Write-Host 'Testing the sample project...' -ForegroundColor Yellow
Push-Location "$PSScriptRoot\VSCodeTestingLab"

try
{
    $testResult = & '.\RunTests.ps1'
    if ($LASTEXITCODE -eq 0)
    {
        Write-Host '✅ All tests passed!' -ForegroundColor Green
    }
    else
    {
        Write-Warning 'Some tests failed. Please check the output above.'
    }
}
catch
{
    Write-Error "Failed to run tests: $_"
}
finally
{
    Pop-Location
}

Write-Host ''
Write-Host '🎯 Lab 7 Setup Complete!' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Next steps:' -ForegroundColor White
Write-Host '1. Install VS Code extensions (see Lab7.md for details)' -ForegroundColor Gray
Write-Host '2. Open VSCodeTestingLab folder in VS Code' -ForegroundColor Gray
Write-Host '3. Explore Test Explorer and start the lab exercises' -ForegroundColor Gray
Write-Host ''
Write-Host 'Command to open in VS Code:' -ForegroundColor White
Write-Host "code '$PSScriptRoot\VSCodeTestingLab'" -ForegroundColor Yellow