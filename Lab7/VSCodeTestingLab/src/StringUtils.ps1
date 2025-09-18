function Test-IsEmail
{
    param([string] $Email)
    
    if ([string]::IsNullOrWhiteSpace($Email))
    {
        return $false
    }
    
    return $Email -match '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
}

function Format-PhoneNumber
{
    param([string] $PhoneNumber)
    
    # Remove all non-digits
    $digits = $PhoneNumber -replace '\D', ''
    
    if ($digits.Length -eq 10)
    {
        return "($($digits.Substring(0,3))) $($digits.Substring(3,3))-$($digits.Substring(6,4))"
    }
    elseif ($digits.Length -eq 11 -and $digits.StartsWith('1'))
    {
        return "+1 ($($digits.Substring(1,3))) $($digits.Substring(4,3))-$($digits.Substring(7,4))"
    }
    else
    {
        throw 'Invalid phone number format'
    }
}

function Get-Initials
{
    param([string] $FullName)
    
    if ([string]::IsNullOrWhiteSpace($FullName))
    {
        return ''
    }
    
    $words = $FullName.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)
    $initials = $words | ForEach-Object { $_.Substring(0, 1).ToUpper() }
    
    return $initials -join ''
}