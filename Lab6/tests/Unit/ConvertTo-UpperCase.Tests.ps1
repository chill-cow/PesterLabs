BeforeAll {
    # Import the module under test
    $ModulePath = Join-Path $PSScriptRoot '..\..\PowerShellModule.psd1'
    Import-Module $ModulePath -Force
    
    # Import test helpers
    $TestHelpersPath = Join-Path $PSScriptRoot '..\TestHelpers\TestHelpers.psm1'
    if (Test-Path $TestHelpersPath) {
        Import-Module $TestHelpersPath -Force
    }
}

Describe 'ConvertTo-UpperCase Function Tests' -Tag 'Unit', 'ConvertTo-UpperCase' {
    
    Context 'Parameter Validation and Metadata' {
        BeforeAll {
            $Command = Get-Command ConvertTo-UpperCase
        }
        
        It 'Should have InputString parameter that is mandatory' {
            Test-FunctionParameter -FunctionName 'ConvertTo-UpperCase' -ParameterName 'InputString' -Mandatory
        }
        
        It 'Should accept InputString from pipeline' {
            Test-FunctionParameter -FunctionName 'ConvertTo-UpperCase' -ParameterName 'InputString' -ValueFromPipeline
        }
        
        It 'Should have PassThru parameter as SwitchParameter' {
            Test-FunctionParameter -FunctionName 'ConvertTo-UpperCase' -ParameterName 'PassThru' -Type ([switch])
        }
        
        It 'Should have proper CmdletBinding attributes' {
            $Command.CmdletBinding | Should -BeTrue
        }
        
        It 'Should have proper help documentation' {
            $help = Get-Help ConvertTo-UpperCase -Full
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
            $help.Examples | Should -Not -BeNullOrEmpty
        }
        
        It 'Should have proper parameter sets' {
            $Command.ParameterSets | Should -HaveCount 2
            $Command.ParameterSets.Name | Should -Contain 'Default'
            $Command.ParameterSets.Name | Should -Contain 'PassThru'
        }
    }
    
    Context 'Basic String Conversion Functionality' {
        It 'Should convert single lowercase string to uppercase' {
            $result = ConvertTo-UpperCase -InputString "hello world"
            $result | Should -Be "HELLO WORLD"
        }
        
        It 'Should convert multiple strings to uppercase' {
            $result = ConvertTo-UpperCase -InputString @("hello", "world", "test")
            $result | Should -HaveCount 3
            $result[0] | Should -Be "HELLO"
            $result[1] | Should -Be "WORLD"
            $result[2] | Should -Be "TEST"
        }
        
        It 'Should handle pipeline input correctly' {
            $result = "hello", "world" | ConvertTo-UpperCase
            $result | Should -HaveCount 2
            $result[0] | Should -Be "HELLO"
            $result[1] | Should -Be "WORLD"
        }
        
        It 'Should handle empty strings without error' {
            $result = ConvertTo-UpperCase -InputString ""
            $result | Should -Be ""
        }
        
        It 'Should handle whitespace-only strings' {
            $result = ConvertTo-UpperCase -InputString "   "
            $result | Should -Be "   "
        }
        
        It 'Should preserve already uppercase strings' {
            $result = ConvertTo-UpperCase -InputString "ALREADY UPPER"
            $result | Should -Be "ALREADY UPPER"
        }
    }
    
    Context 'PassThru Functionality' {
        It 'Should return custom object with PassThru switch' {
            $result = ConvertTo-UpperCase -InputString "hello" -PassThru
            
            $result | Should -BeOfType [PSCustomObject]
            $result.PSTypeNames | Should -Contain 'ConvertTo-UpperCase.Result'
            $result.Original | Should -Be "hello"
            $result.Converted | Should -Be "HELLO"
            $result.ProcessedAt | Should -BeOfType [DateTime]
        }
        
        It 'Should return multiple objects with PassThru and multiple inputs' {
            $result = "hello", "world" | ConvertTo-UpperCase -PassThru
            
            $result | Should -HaveCount 2
            $result[0].Original | Should -Be "hello"
            $result[0].Converted | Should -Be "HELLO"
            $result[1].Original | Should -Be "world"
            $result[1].Converted | Should -Be "WORLD"
        }
        
        It 'Should include timestamp in PassThru results' {
            $beforeTime = Get-Date
            $result = ConvertTo-UpperCase -InputString "test" -PassThru
            $afterTime = Get-Date
            
            $result.ProcessedAt | Should -BeGreaterOrEqual $beforeTime
            $result.ProcessedAt | Should -BeLessOrEqual $afterTime
        }
    }
    
    Context 'Edge Cases and Error Handling' {
        It 'Should handle mixed case strings correctly' {
            $result = ConvertTo-UpperCase -InputString "MiXeD cAsE sTrInG"
            $result | Should -Be "MIXED CASE STRING"
        }
        
        It 'Should handle special characters and numbers' {
            $result = ConvertTo-UpperCase -InputString "hello@world.com123!"
            $result | Should -Be "HELLO@WORLD.COM123!"
        }
        
        It 'Should handle Unicode characters' {
            $result = ConvertTo-UpperCase -InputString "café résumé naïve"
            $result | Should -Be "CAFÉ RÉSUMÉ NAÏVE"
        }
        
        It 'Should handle very long strings' {
            $longString = "a" * 10000
            $result = ConvertTo-UpperCase -InputString $longString
            $result | Should -Be ("A" * 10000)
        }
        
        It 'Should handle null input gracefully' {
            # Test null handling through the warning system
            $result = ConvertTo-UpperCase -InputString $null -WarningVariable warnings -WarningAction SilentlyContinue
            $warnings | Should -Not -BeNullOrEmpty
            $result | Should -Be ""
        }
    }
    
    Context 'Performance and Scalability' {
        It 'Should process large datasets efficiently' {
            $testData = New-TestDataSet -Type 'Medium' -Size 1000
            
            $result = Assert-PerformanceWithin -MaxDuration ([timespan]::FromSeconds(5)) -ScriptBlock {
                $testData | ConvertTo-UpperCase
            }
            
            $result | Should -HaveCount 1000
            $result[0] | Should -Match '^TESTDATA1 '
        }
        
        It 'Should maintain consistent performance across multiple calls' {
            $testData = New-TestDataSet -Type 'Small' -Size 100
            $durations = @()
            
            # Run multiple iterations to check consistency
            for ($i = 0; $i -lt 5; $i++) {
                $duration = Measure-Command {
                    $testData | ConvertTo-UpperCase | Out-Null
                }
                $durations += $duration.TotalMilliseconds
            }
            
            # Check that performance is consistent (standard deviation < 50% of mean)
            $mean = ($durations | Measure-Object -Average).Average
            $stdDev = [Math]::Sqrt(($durations | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)
            
            ($stdDev / $mean) | Should -BeLessThan 0.5
        }
    }
    
    Context 'Verbose and Logging Output' {
        It 'Should produce verbose output when requested' {
            $verboseOutput = @()
            ConvertTo-UpperCase -InputString "test" -Verbose 4>&1 | Tee-Object -Variable verboseOutput | Out-Null
            
            $verboseOutput | Should -Not -BeNullOrEmpty
            $verboseOutput -join '' | Should -Match "Starting ConvertTo-UpperCase processing"
            $verboseOutput -join '' | Should -Match "Completed processing"
        }
        
        It 'Should include conversion details in verbose output' {
            $verboseOutput = @()
            ConvertTo-UpperCase -InputString "hello" -Verbose 4>&1 | Tee-Object -Variable verboseOutput | Out-Null
            
            $verboseOutput -join '' | Should -Match "Converted.*hello.*HELLO"
        }
    }
    
    Context 'Type System Integration' {
        It 'Should work with objects that have string properties' {
            $objects = @(
                [PSCustomObject]@{ Name = "test1"; Value = "hello" }
                [PSCustomObject]@{ Name = "test2"; Value = "world" }
            )
            
            $result = $objects.Value | ConvertTo-UpperCase
            $result | Should -HaveCount 2
            $result[0] | Should -Be "HELLO"
            $result[1] | Should -Be "WORLD"
        }
        
        It 'Should handle string arrays correctly' {
            $stringArray = [string[]]@("one", "two", "three")
            $result = ConvertTo-UpperCase -InputString $stringArray
            
            $result | Should -HaveCount 3
            $result[0] | Should -Be "ONE"
            $result[1] | Should -Be "TWO"
            $result[2] | Should -Be "THREE"
        }
    }
}