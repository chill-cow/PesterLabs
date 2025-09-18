function Update-PesterLabIndex {
    <#!
    .SYNOPSIS
    Auto-generates (and optionally extends) the Labs index table in README.md.

    .DESCRIPTION
    Scans for LabN directories containing LabN.md and rebuilds the table between
    <!-- LABS_TABLE_START --> and <!-- LABS_TABLE_END --> markers in README.md.
    Supports persisting focus descriptions in a JSON focus map for future additions.

    .PARAMETER Path
    Root path containing README.md and LabN subfolders.

    .PARAMETER UpdateFocusMap
    When set, newly discovered labs (not in focus map) are appended to the focus map JSON with their resolved focus text.

    .PARAMETER FocusMapPath
    Optional explicit JSON file path for focus map. Defaults to FocusMap.json in Path.

    .EXAMPLE
    Update-PesterLabIndex -Path ./Pester/Labs

    .EXAMPLE
    Update-PesterLabIndex -Path ./Pester/Labs -UpdateFocusMap

    .NOTES
    Idempotent; only replaces table block.
    #>
    [CmdletBinding()]
    param(
        [Parameter()][string]$Path = (Get-Location).Path,
        [switch]$UpdateFocusMap,
        [string]$FocusMapPath
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if (-not (Test-Path $Path)) { throw "Path not found: $Path" }
    $readme = Join-Path $Path 'README.md'
    if (-not (Test-Path $readme)) { throw "README.md not found in $Path" }

    if (-not $FocusMapPath) { $FocusMapPath = Join-Path $Path 'FocusMap.json' }

    # Load existing map (ordered)
    $focusMap = [ordered]@{}
    if (Test-Path $FocusMapPath) {
        try {
            $json = Get-Content -Path $FocusMapPath -Raw | ConvertFrom-Json -ErrorAction Stop
            foreach ($p in $json.PSObject.Properties) { $focusMap[$p.Name] = $p.Value }
        } catch { Write-Warning "Failed to parse existing FocusMap.json: $_" }
    }

    # Seed defaults if empty
    if (-not $focusMap.Count) {
        $focusMap['1'] = 'Fundamentals & TDD'
        $focusMap['2'] = 'Test Design & AAA & Data Cases'
        $focusMap['3'] = 'Mocking & Isolation Strategy'
        $focusMap['4'] = 'Performance & Resource Testing'
        $focusMap['5'] = 'Class / Object State Testing'
        $focusMap['6'] = 'CI/CD Integration & Quality Gates'
        $focusMap['7'] = 'VS Code Test Explorer & Productivity'
    }

    # Discover labs
    $labDirs = Get-ChildItem -Path $Path -Directory -Filter 'Lab*' | Where-Object { $_.Name -match '^Lab(\d+)$' } | Sort-Object { [int]($_.Name -replace 'Lab','') }

    $rows = @()
    $newMapEntries = $false
    foreach ($d in $labDirs) {
        $num = [int]($d.Name -replace 'Lab','')
        $md = Join-Path $d.FullName ("Lab$num.md")
        if (-not (Test-Path $md)) { continue }
        $focus = $focusMap[[string]$num]
        if (-not $focus) {
            # Attempt to derive from first heading
            $heading = Select-String -Path $md -Pattern '^#\s+(.*)' | Select-Object -First 1
            if ($heading) { $focus = ($heading.Matches[0].Groups[1].Value -replace '\|','-') }
            if (-not $focus) { $focus = 'TBD Focus' }
            if ($UpdateFocusMap) {
                $focusMap[[string]$num] = $focus
                $newMapEntries = $true
            }
        }
        $rows += "| $num | $focus | [Lab $num](./$($d.Name)/Lab$num.md) |"
    }

    if (-not $rows) { throw 'No labs discovered to index.' }

    $table = @(
        '| Lab | Focus | File |'
        '|-----|-------|------|'
        $rows
    ) -join [Environment]::NewLine

    $startMarker = '<!-- LABS_TABLE_START -->'
    $endMarker   = '<!-- LABS_TABLE_END -->'

    $content = Get-Content -Path $readme -Raw
    if ($content -notmatch [regex]::Escape($startMarker) -or $content -notmatch [regex]::Escape($endMarker)) {
        throw 'Markers not found in README.md.'
    }

    $pattern = "(?s)$([regex]::Escape($startMarker)).*?$([regex]::Escape($endMarker))"
    $replacement = "$startMarker`r`n$table`r`n$endMarker"
    $newContent = [regex]::Replace($content, $pattern, $replacement)

    if ($newContent -ne $content) {
        Set-Content -Path $readme -Value $newContent -NoNewline
        Write-Verbose 'README updated'
    } else {
        Write-Verbose 'README unchanged'
    }

    if ($UpdateFocusMap -and $newMapEntries) {
        ($focusMap | ConvertTo-Json -Depth 4 | Out-String).TrimEnd() | Set-Content -Path $FocusMapPath -NoNewline
        Write-Host "Focus map updated: $FocusMapPath" -ForegroundColor Green
    }

    Write-Host "Indexed $($rows.Count) lab(s)." -ForegroundColor Cyan
}

Export-ModuleMember -Function Update-PesterLabIndex
