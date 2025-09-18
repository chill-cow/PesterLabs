<#!
.SYNOPSIS
Generate audience and speaker PDF decks from Marp markdown sources using a custom dark theme.

.DESCRIPTION
Invokes marp.exe (expected at c:\bin2\marp.exe) to export:
 - PesterLabSummaryPresentation.md (audience)
 - PesterLabSummaryPresentation-SpeakerNotes.md (speaker)
Adds build timestamp subfolder under ./deck-dist (e.g., deck-dist/2025-09-17_143210).
Copies source markdown and theme for traceability.

.REQUIREMENTS
- marp.exe accessible at the supplied -MarpPath (default c:\bin2\marp.exe)
- Node fonts / standard system fonts for monospace

.PARAMETER MarpPath
Path to marp CLI executable.

.PARAMETER ThemeCss
Relative or absolute path to theme CSS (default ./themes/pester-dark.css).

.PARAMETER OutDir
Output root directory (default ./deck-dist).

.PARAMETER Open
Open the generated PDFs after creation (Windows only; uses Start-Process).

.EXAMPLE
pwsh ./Export-PesterDecks.ps1 -Open
#>
[CmdletBinding()]
param(
    [string]$MarpPath = 'c:/bin2/marp.exe',
    [string]$ThemeCss = './themes/pester-dark.css',
    [string]$OutDir = './deck-dist',
    [switch]$Open
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-File
{
    param([string]$Path, [string]$Message)
    if (-not (Test-Path $Path)) { throw ($Message ?? "Required file missing: $Path") }
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $scriptRoot
try
{
    Assert-File -Path $MarpPath -Message "marp.exe not found at $MarpPath"
    Assert-File -Path 'PesterLabSummaryPresentation.md' -Message 'Audience deck source missing'
    Assert-File -Path 'PesterLabSummaryPresentation-SpeakerNotes.md' -Message 'Speaker deck source missing'
    Assert-File -Path $ThemeCss -Message "Theme CSS missing: $ThemeCss"

    $timestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
    $finalOut = Join-Path $scriptRoot (Join-Path $OutDir $timestamp)
    New-Item -ItemType Directory -Path $finalOut -Force | Out-Null

    $commonArgs = @('--allow-local-files', '--theme', $ThemeCss, '--pdf')

    Write-Host 'Exporting audience deck...' -ForegroundColor Cyan
    & $MarpPath 'PesterLabSummaryPresentation.md' @commonArgs '--output' (Join-Path $finalOut 'PesterLabs-Audience.pdf')

    Write-Host 'Exporting speaker deck...' -ForegroundColor Cyan
    & $MarpPath 'PesterLabSummaryPresentation-SpeakerNotes.md' @commonArgs '--pdf-notes' '--output' (Join-Path $finalOut 'PesterLabs-Speaker.pdf')

    # Copy sources + theme for provenance
    Copy-Item 'PesterLabSummaryPresentation.md', 'PesterLabSummaryPresentation-SpeakerNotes.md' -Destination $finalOut
    $themeTargetDir = Join-Path $finalOut 'themes'
    New-Item -ItemType Directory -Path $themeTargetDir -Force | Out-Null
    Copy-Item $ThemeCss -Destination (Join-Path $themeTargetDir (Split-Path $ThemeCss -Leaf))

    Write-Host "Decks exported to $finalOut" -ForegroundColor Green

    if ($Open)
    {
        Start-Process (Join-Path $finalOut 'PesterLabs-Audience.pdf')
        Start-Process (Join-Path $finalOut 'PesterLabs-Speaker.pdf')
    }
}
finally
{
    Pop-Location
}
