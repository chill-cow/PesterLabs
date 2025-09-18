# Private helper functions for the PowerShell Testing Module

function Write-ModuleLog {
    <#
    .SYNOPSIS
        Internal logging function for module operations.
    
    .DESCRIPTION
        Provides consistent logging for internal module operations.
        Not exported from the module.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Information', 'Warning', 'Error', 'Verbose')]
        [string]$Level = 'Information'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        'Information' { Write-Host $logMessage -ForegroundColor Green }
        'Warning' { Write-Warning $logMessage }
        'Error' { Write-Error $logMessage }
        'Verbose' { Write-Verbose $logMessage }
    }
}

function Test-EmailFormat {
    <#
    .SYNOPSIS
        Internal email validation helper.
    
    .DESCRIPTION
        Provides email format validation for internal use.
        Not exported from the module.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Email,
        
        [Parameter()]
        [switch]$Strict
    )
    
    $basicPattern = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    $strictPattern = '^[a-zA-Z0-9!#$%&''*+/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&''*+/=?^_`{|}~-]+)*@(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?$'
    
    $pattern = if ($Strict) { $strictPattern } else { $basicPattern }
    
    return $Email -match $pattern
}

function Get-RandomSeed {
    <#
    .SYNOPSIS
        Generates a deterministic seed for consistent "random" data.
    
    .DESCRIPTION
        Creates a seed value for generating consistent demo data.
        Not exported from the module.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Index,
        
        [Parameter()]
        [int]$Multiplier = 12345
    )
    
    return ($Index * $Multiplier) % 1000000
}