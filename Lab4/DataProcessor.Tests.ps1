BeforeAll {
    # Import the function
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
    
    # Test data generator
    function New-TestData
    {
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
            $testData = @('SingleItem')
            
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