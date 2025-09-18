#Requires -Version 7.4

<#
.SYNOPSIS
    PowerShell Testing Module with CI/CD Integration
    
.DESCRIPTION
    This module provides sample functions for demonstrating comprehensive testing
    patterns and CI/CD integration with GitHub Actions.
    
.NOTES
    Module: PowerShellModule
    Author: Your Name
    Version: 1.0.0
#>

# Get public and private function definition files
$Public = @(Get-ChildItem -Path $PSScriptRoot\src\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\src\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
        Write-Verbose "Imported $($import.FullName)"
    }
    catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $Public.BaseName

# Module initialization
Write-Verbose "PowerShell Testing Module loaded successfully"
Write-Verbose "Exported functions: $($Public.BaseName -join ', ')"