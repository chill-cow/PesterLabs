Set-Location $PSScriptRoot

#note, if you are going to put your environment checks in your test runner, you can remove them from the tests script to speed up execution.
try
{
    Get-Command -Name Get-ADDomain -ErrorAction stop | Out-Null
    $domainInfo = Get-ADDomain -ErrorAction Stop
    if ($domainInfo.NetBIOSName -in @('KAYLOSLAB', 'CONTOSO'))
    {    
        Write-Host "Connected to domain: $domainName, Running All Tests" -ForegroundColor Green
        Invoke-Pester
    }
    else
    {
        throw 'No Lab Domain Detected'
    }
}
catch
{
    $isLabDomain = $false
    $domainName = 'Unknown'
    Write-Warning "Unable to connect to Lab Active Directory: $($_.Exception.Message), skipping Integration Tests"
    Invoke-Pester -ExcludeTagFilter 'Integration'
}
    