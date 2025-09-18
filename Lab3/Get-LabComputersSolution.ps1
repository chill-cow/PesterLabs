
function Get-LabComputers
{
    param([int]$throttleLimit = 100, [int]$timeout = 120, $Computers = ((Get-ADComputer -Filter *).name))
    
    # Check PowerShell version - requires 7.4+ for proper SendPingAsync functionality
    if ($PSVersionTable.PSVersion -lt [Version]'7.4.0')
    {
        throw "This function requires PowerShell 7.4 or newer due to .NET 8+ SendPingAsync method updates. Current version: $($PSVersionTable.PSVersion)"
    }
    
    $Computers = $Computers | Where-Object { $_ -notmatch $Env:COMPUTERNAME }
    
    # Return early if no computers to process
    if (-not $Computers)
    {
        return
    }
    
    $results = $computers | ForEach-Object {
        $ping = New-Object System.Net.NetworkInformation.Ping
        $timespan = New-Object -TypeName System.timespan -ArgumentList 0, 0, 0, 0, 2
        $ping.SendPingAsync($_, $timespan) | Add-Member -MemberType NoteProperty -Name ComputerName -Value $_ -PassThru
    }
    $waitforPings = $true
    while ($waitforPings)
    {
        $waitforPings = $false
        foreach ($result in $results)
        {
            if ($result.IsCompleted -ne $true)
            {
                $waitforPings = $true
                Start-Sleep -Milliseconds 2
                break
            }
        }
    }
    $results | Where-Object IsCompletedSuccessfully | Select-Object -ExpandProperty ComputerName
    if ($results)
    {
        $results.Dispose()
    }
}
