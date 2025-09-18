<#!
.SYNOPSIS
Wrapper script for Update-PesterLabIndex function.

.DESCRIPTION
Keeps backward compatibility. Imports the module-local function and passes parameters through.

.PARAMETERS
See Get-Help Update-PesterLabIndex -Full
#>
[CmdletBinding()]
param(
    [string]$Path = (Split-Path -Parent $MyInvocation.MyCommand.Path),
    [switch]$UpdateFocusMap
)

$modulePath = Join-Path (Split-Path $MyInvocation.MyCommand.Path) 'PesterLabTools.psm1'
if (-not (Test-Path $modulePath)) { throw "Module file not found: $modulePath" }
Import-Module $modulePath -Force
Update-PesterLabIndex -Path $Path -UpdateFocusMap:$UpdateFocusMap
