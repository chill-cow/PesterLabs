function ConvertTo-Uppercase
{
    param(
        [ValidatePattern('^[a-zA-Z\s]+$')]
        [ValidateNotNullOrEmpty()]    
        [string[]]$text)
    $text.ToUpper()
}