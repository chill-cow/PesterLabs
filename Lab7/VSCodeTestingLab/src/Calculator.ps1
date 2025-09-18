class Calculator
{
    [double] Add([double] $a, [double] $b)
    {
        return $a + $b
    }
    
    [double] Subtract([double] $a, [double] $b)
    {
        return $a - $b
    }
    
    [double] Multiply([double] $a, [double] $b)
    {
        return $a * $b
    }
    
    [double] Divide([double] $a, [double] $b)
    {
        if ($b -eq 0)
        {
            throw 'Cannot divide by zero'
        }
        return $a / $b
    }
    
    [double] Power([double] $base, [double] $exponent)
    {
        return [Math]::Pow($base, $exponent)
    }
}

function New-Calculator
{
    return [Calculator]::new()
}