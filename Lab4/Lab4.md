# Lab 4: Performance Testing with Pester

## Lab Overview

In this lab, you'll learn the fundamentals of performance testing with Pester. You'll master:

- **Basic execution time testing** with `Measure-Command`
- **Memory usage monitoring** during function execution
- **Performance baselines** and validation
- **Parallel processing testing**

## Prerequisites

- PowerShell 7.4 or later
- Pester v5.7.1 or later
- Labs 1-3 completion

## Lab Setup

### Step 1: Function to Test

We'll test a data processing function. Create `DataProcessor.ps1`:

```powershell
function Invoke-DataProcessor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$InputData,
        
        [int]$BatchSize = 100,
        
        [switch]$UseParallel,
        
        [scriptblock]$ProcessingScript = { $_.ToString().ToUpper() }
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $processedCount = 0
    $results = @()
    
    Write-Verbose "Processing $($InputData.Count) items with BatchSize: $BatchSize"
    
    # Process in batches
    for ($i = 0; $i -lt $InputData.Count; $i += $BatchSize) {
        $endIndex = [Math]::Min($i + $BatchSize - 1, $InputData.Count - 1)
        $batch = $InputData[$i..$endIndex]
        
        if ($UseParallel) {
            $batchResults = $batch | ForEach-Object -Parallel $ProcessingScript
        } else {
            $batchResults = $batch | ForEach-Object $ProcessingScript
        }
        
        $results += $batchResults
        $processedCount += $batch.Count
        
        Write-Progress -Activity "Processing" -Status "$processedCount/$($InputData.Count)" -PercentComplete (($processedCount / $InputData.Count) * 100)
    }
    
    $stopwatch.Stop()
    Write-Progress -Activity "Processing" -Completed
    
    return [PSCustomObject]@{
        Results = $results
        ProcessedCount = $processedCount
        ElapsedTime = $stopwatch.Elapsed
        ItemsPerSecond = if ($stopwatch.Elapsed.TotalSeconds -gt 0) { 
            [Math]::Round($processedCount / $stopwatch.Elapsed.TotalSeconds, 2) 
        } else { 0 }
        BatchSize = $BatchSize
        UsedParallel = $UseParallel.IsPresent
    }
}
```

### Step 2: Performance Tests

Create `DataProcessor.Tests.ps1`:

```powershell
BeforeAll {
    # Import the function
    . "$PSScriptRoot\DataProcessor.ps1"
    
    # Test data generator
    function New-TestData {
        param([int]$Count = 100)
        1..$Count | ForEach-Object { "TestItem$_" }
    }
}

Describe 'Invoke-DataProcessor Performance Tests' {
    
    Context 'Basic Function Tests' {
        It 'Should process data and return results' {
            $testData = New-TestData -Count 10
            
            $result = Invoke-DataProcessor -InputData $testData
            
            $result.ProcessedCount | Should -Be 10
            $result.Results | Should -HaveCount 10
            $result.ElapsedTime | Should -BeOfType [TimeSpan]
        }
        
        It 'Should have correct parameter types' {
            $function = Get-Command Invoke-DataProcessor
            
            $function.Parameters['InputData'].ParameterType | Should -Be ([array])
            $function.Parameters['BatchSize'].ParameterType | Should -Be ([int])
            $function.Parameters['UseParallel'].ParameterType | Should -Be ([switch])
            $function.Parameters['ProcessingScript'].ParameterType | Should -Be ([scriptblock])
        }
    }
    
    Context 'Performance Testing' {
        It 'Should process small dataset quickly' {
            $testData = New-TestData -Count 100
            
            $duration = Measure-Command {
                $result = Invoke-DataProcessor -InputData $testData
            }
            
            # Should complete within 5 seconds
            $duration.TotalSeconds | Should -BeLessThan 5
            Write-Host "Processed 100 items in $($duration.TotalMilliseconds)ms" -ForegroundColor Green
        }
        
        It 'Should calculate items per second correctly' {
            $testData = New-TestData -Count 50
            
            $result = Invoke-DataProcessor -InputData $testData
            
            $result.ItemsPerSecond | Should -BeGreaterThan 0
            Write-Host "Performance: $($result.ItemsPerSecond) items/second" -ForegroundColor Cyan
        }
        
        It 'Should handle different batch sizes' {
            $testData = New-TestData -Count 200
            
            $result1 = Invoke-DataProcessor -InputData $testData -BatchSize 50
            $result2 = Invoke-DataProcessor -InputData $testData -BatchSize 100
            
            $result1.ProcessedCount | Should -Be 200
            $result2.ProcessedCount | Should -Be 200
            $result1.BatchSize | Should -Be 50
            $result2.BatchSize | Should -Be 100
        }
    }
    
    Context 'Memory Usage Testing' {
        It 'Should not use excessive memory' {
            $testData = New-TestData -Count 1000
            
            # Measure memory before
            [System.GC]::Collect()
            $memoryBefore = [System.GC]::GetTotalMemory($false)
            
            $result = Invoke-DataProcessor -InputData $testData
            
            # Measure memory after
            $memoryAfter = [System.GC]::GetTotalMemory($false)
            $memoryUsedMB = [Math]::Round(($memoryAfter - $memoryBefore) / 1MB, 2)
            
            # Should use less than 50MB for 1000 items
            $memoryUsedMB | Should -BeLessThan 50
            Write-Host "Memory used: $memoryUsedMB MB" -ForegroundColor Yellow
        }
    }
    
    Context 'Parallel Processing Tests' {
        It 'Should work with parallel processing' {
            $testData = New-TestData -Count 100
            
            $sequentialResult = Invoke-DataProcessor -InputData $testData -UseParallel:$false
            $parallelResult = Invoke-DataProcessor -InputData $testData -UseParallel
            
            # Both should process all items
            $sequentialResult.ProcessedCount | Should -Be 100
            $parallelResult.ProcessedCount | Should -Be 100
            
            # Results should be the same (order might differ)
            $sequentialResult.Results.Count | Should -Be $parallelResult.Results.Count
            
            Write-Host "Sequential: $($sequentialResult.ItemsPerSecond) items/sec" -ForegroundColor Blue
            Write-Host "Parallel: $($parallelResult.ItemsPerSecond) items/sec" -ForegroundColor Blue
        }
    }
    
    Context 'Error Handling' {
        It 'Should handle empty input' {
            $result = Invoke-DataProcessor -InputData @()
            
            $result.ProcessedCount | Should -Be 0
            $result.Results | Should -BeNullOrEmpty
        }
        
        It 'Should handle single item' {
            $testData = @("SingleItem")
            
            $result = Invoke-DataProcessor -InputData $testData
            
            $result.ProcessedCount | Should -Be 1
            $result.Results | Should -HaveCount 1
        }
    }
    
    Context 'Performance Baseline Tests' {
        It 'Should meet minimum performance baseline' {
            $testData = New-TestData -Count 500
            
            $result = Invoke-DataProcessor -InputData $testData
            
            # Should process at least 100 items per second
            $result.ItemsPerSecond | Should -BeGreaterThan 100
            
            # Should complete within 10 seconds
            $result.ElapsedTime.TotalSeconds | Should -BeLessThan 10
        }
        
        It 'Should show performance comparison' {
            $smallData = New-TestData -Count 100
            $largeData = New-TestData -Count 1000
            
            $smallResult = Invoke-DataProcessor -InputData $smallData
            $largeResult = Invoke-DataProcessor -InputData $largeData
            
            Write-Host "`nPerformance Comparison:" -ForegroundColor Magenta
            Write-Host "Small dataset (100 items): $($smallResult.ItemsPerSecond) items/sec" -ForegroundColor Green
            Write-Host "Large dataset (1000 items): $($largeResult.ItemsPerSecond) items/sec" -ForegroundColor Green
            
            # Both should have reasonable performance
            $smallResult.ItemsPerSecond | Should -BeGreaterThan 50
            $largeResult.ItemsPerSecond | Should -BeGreaterThan 50
        }
    }
}
```

### Step 3: Test Runner

Create `RunLabTests.ps1`:

```powershell
#Requires -Version 7.4
#Requires -Modules Pester

<#
.SYNOPSIS
    Test runner for Lab 4 - Performance Testing
#>

param(
    [switch]$ShowPerformanceDetails
)

Write-Host "🧪 Lab 4: Performance Testing" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

# Configure Pester
$pesterConfig = [PesterConfiguration]::Default
$pesterConfig.Run.Path = "$PSScriptRoot\DataProcessor.Tests.ps1"
$pesterConfig.Run.Passthru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = "$PSScriptRoot\TestResults.xml"

# Run tests
Write-Host "`n🏃 Running performance tests..." -ForegroundColor Yellow
$testResults = Invoke-Pester -Configuration $pesterConfig

# Display results
Write-Host "`n📊 Test Results:" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "Passed: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "Failed: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "Skipped: $($testResults.SkippedCount)" -ForegroundColor Yellow

if ($testResults.FailedCount -gt 0) {
    Write-Host "`n❌ Some tests failed!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✅ All tests passed!" -ForegroundColor Green
}

if ($ShowPerformanceDetails) {
    Write-Host "`n📈 Performance Summary:" -ForegroundColor Magenta
    Write-Host "This lab demonstrated performance testing concepts:" -ForegroundColor White
    Write-Host "• Execution time measurement with Measure-Command" -ForegroundColor Gray
    Write-Host "• Memory usage monitoring" -ForegroundColor Gray
    Write-Host "• Performance baseline validation" -ForegroundColor Gray
    Write-Host "• Parallel vs sequential processing comparison" -ForegroundColor Gray
}

Write-Host "`n🎉 Lab 4 completed successfully!" -ForegroundColor Green
```

## Lab Exercises

### Exercise 1: Basic Performance Testing
1. Run the tests: `.\RunLabTests.ps1`
2. Observe the performance metrics displayed
3. Understand how `Measure-Command` works for timing

### Exercise 2: Memory Monitoring
1. Modify the test to process larger datasets (2000+ items)
2. Watch memory usage and understand when it becomes significant
3. Experiment with different batch sizes

### Exercise 3: Performance Baselines
1. Adjust the performance baseline in the tests
2. Run tests on different machines and compare results
3. Create your own performance assertions

### Exercise 4: Parallel vs Sequential
1. Compare parallel vs sequential processing performance
2. Test with CPU-intensive processing scripts
3. Understand when parallel processing helps

## Key Learning Points

### 1. Basic Performance Testing
```powershell
# Timing
$duration = Measure-Command { 
    # Your code here
}
$duration.TotalMilliseconds | Should -BeLessThan 1000
```

### 2. Memory Monitoring
```powershell
# Memory measurement
$memoryBefore = [System.GC]::GetTotalMemory($false)
# Run your code
$memoryAfter = [System.GC]::GetTotalMemory($false)
$memoryUsed = $memoryAfter - $memoryBefore
```

### 3. Performance Assertions
```powershell
# Performance validation
$result.ItemsPerSecond | Should -BeGreaterThan 100
$result.ElapsedTime.TotalSeconds | Should -BeLessThan 10
```

## Summary

This Lab 4 teaches you:
- ✅ How to measure execution time with `Measure-Command`
- ✅ Memory usage monitoring
- ✅ Creating performance baselines with Should assertions
- ✅ Testing parallel vs sequential processing
- ✅ Building performance test suites

Understanding these fundamentals is key to effective performance testing!

## Next Steps
- Try modifying the processing script to be more CPU-intensive
- Experiment with larger datasets
- Create your own performance benchmarks
- Move on to Lab 5 for testing PowerShell classes

---
**Estimated Time**: 30-45 minutes  
**Difficulty**: Beginner to Intermediate