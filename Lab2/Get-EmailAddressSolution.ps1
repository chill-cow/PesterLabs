#function to parse text for valid email addresses and return them optionally delimited for pasting into an email program.
function Get-EmailAddress
{
    [cmdletbinding()]
    param(
        [parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [string[]]$string,
        [string]$Delimiter)
    begin
    {
        $regex = '\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b'
        $EmailAddresses = @()
    }
    process
    {
        if ($string)
        {
            $EmailAddresses += $string | Select-String -Pattern $regex -AllMatches |
                ForEach-Object { $_.matches.value } 
        }
        else
        {
            Write-Verbose "skipping $string"

        }
    }
    end
    {
        $EmailAddresses = $EmailAddresses | Select-Object -Unique
        #extra Filtering for no .., .@., and that the non-domain part is 64 characters or less
        $EmailAddresses = $EmailAddresses | Where-Object { $_ -notlike '*..*' -and $_ -notlike '*.@.*' -and $_ -notmatch '\.@|@\.' -and $_.Split('@')[0].length -le 64 }

        if ($Delimiter)
        { 
            $EmailAddresses -join $Delimiter
        }
        else
        {
            $EmailAddresses
        }
    }
}

<#
#get-content .\EmailAddresses.csv | Get-Emailaddress | Set-Clipboard
#https://en.wikipedia.org/wiki/Email_address
#Examples
Get-Clipboard | Get-Emailaddress -Delimiter ';' | Set-Clipboard
Get-Clipboard | Get-Emailaddress | Measure-Object
Get-Clipboard | Get-Emailaddress | Out-GridView
Get-Clipboard | Get-Emailaddress | Set-Clipboard
$emails = Get-Clipboard | Get-Emailaddress 
$emails2= Get-Clipboard | Get-Emailaddress
#show me emails in list 2 that weren't in list 1
Compare-Object -ReferenceObject $emails -DifferenceObject $emails2 | Where-Object -Property sideindicator -eq '=>'
#>