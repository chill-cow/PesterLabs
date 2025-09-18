function Invoke-DataProcessor
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [array]$InputData,
        
        [int]$BatchSize = 100,
        
        [switch]$UseParallel,
        
        [scriptblock]$ProcessingScript = { $_.ToString().ToUpper() }
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $processedCount = 0
    $results = @()
    
    Write-Verbose "Processing $($InputData.Count) items with BatchSize: $BatchSize"
    
    # Handle empty input
    if ($InputData.Count -eq 0)
    {
        $stopwatch.Stop()
        return [PSCustomObject]@{
            Results        = @()
            ProcessedCount = 0
            ElapsedTime    = $stopwatch.Elapsed
            ItemsPerSecond = 0
            BatchSize      = $BatchSize
            UsedParallel   = $UseParallel.IsPresent
        }
    }
    
    # Process in batches
    for ($i = 0; $i -lt $InputData.Count; $i += $BatchSize)
    {
        $endIndex = [Math]::Min($i + $BatchSize - 1, $InputData.Count - 1)
        $batch = $InputData[$i..$endIndex]
        
        if ($UseParallel)
        {
            $batchResults = $batch | ForEach-Object -Parallel $ProcessingScript
        }
        else
        {
            $batchResults = $batch | ForEach-Object $ProcessingScript
        }
        
        $results += $batchResults
        $processedCount += $batch.Count
        
        Write-Progress -Activity 'Processing' -Status "$processedCount/$($InputData.Count)" -PercentComplete (($processedCount / $InputData.Count) * 100)
    }
    
    $stopwatch.Stop()
    Write-Progress -Activity 'Processing' -Completed
    
    return [PSCustomObject]@{
        Results        = $results
        ProcessedCount = $processedCount
        ElapsedTime    = $stopwatch.Elapsed
        ItemsPerSecond = if ($stopwatch.Elapsed.TotalSeconds -gt 0)
        { 
            [Math]::Round($processedCount / $stopwatch.Elapsed.TotalSeconds, 2) 
        }
        else { 0 }
        BatchSize      = $BatchSize
        UsedParallel   = $UseParallel.IsPresent
    }
}