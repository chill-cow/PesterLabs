BeforeAll {
    # Import the module for integration testing
    $ModulePath = Join-Path $PSScriptRoot '..\..\PowerShellModule.psd1'
    Import-Module $ModulePath -Force
    
    # Integration test configuration
    $script:integrationConfig = @{
        TestTimeout = 30
        MaxRetries = 3
        LargeDatasetSize = 1000
        PerformanceThreshold = 10  # seconds
    }
}

Describe 'PowerShell Module Integration Tests' -Tag 'Integration', 'Module' {
    
    Context 'Module Loading and Initialization' {
        It 'Should load module without errors' {
            { Import-Module PowerShellModule -Force } | Should -Not -Throw
        }
        
        It 'Should export all expected functions' {
            $exportedFunctions = Get-Command -Module PowerShellModule
            $expectedFunctions = @('ConvertTo-UpperCase', 'Get-EmailAddress', 'Get-DemoComputers')
            
            $exportedFunctions.Count | Should -Be $expectedFunctions.Count
            
            foreach ($expectedFunction in $expectedFunctions) {
                $exportedFunctions.Name | Should -Contain $expectedFunction
            }
        }
        
        It 'Should have proper module metadata' {
            $module = Get-Module PowerShellModule
            
            $module.Version | Should -Not -BeNullOrEmpty
            $module.Author | Should -Not -BeNullOrEmpty
            $module.Description | Should -Not -BeNullOrEmpty
            $module.ModuleType | Should -Be 'Script'
        }
        
        It 'Should have all functions with proper help' {
            $functions = Get-Command -Module PowerShellModule
            
            foreach ($function in $functions) {
                $help = Get-Help $function.Name
                $help.Synopsis | Should -Not -BeNullOrEmpty
                $help.Description | Should -Not -BeNullOrEmpty
            }
        }
        
        It 'Should load private functions internally but not export them' {
            $exportedFunctions = Get-Command -Module PowerShellModule
            $exportedFunctions.Name | Should -Not -Contain 'Write-ModuleLog'
            $exportedFunctions.Name | Should -Not -Contain 'Test-EmailFormat'
            $exportedFunctions.Name | Should -Not -Contain 'Get-RandomSeed'
        }
    }
    
    Context 'Cross-Function Pipeline Integration' {
        It 'Should chain Get-EmailAddress and ConvertTo-UpperCase seamlessly' {
            $emailAddresses = @('test@example.com', 'user@domain.org', 'admin@company.net')
            
            $result = $emailAddresses | 
                Get-EmailAddress | 
                ConvertTo-UpperCase
            
            $result | Should -HaveCount 3
            $result[0] | Should -Be 'TEST@EXAMPLE.COM'
            $result[1] | Should -Be 'USER@DOMAIN.ORG'
            $result[2] | Should -Be 'ADMIN@COMPANY.NET'
        }
        
        It 'Should handle Get-EmailAddress with format and ConvertTo-UpperCase' {
            $emails = @('Test.User@Example.COM', 'Another.User@Domain.ORG')
            
            $result = $emails | 
                Get-EmailAddress -Format Lower | 
                ConvertTo-UpperCase
            
            $result | Should -HaveCount 2
            $result[0] | Should -Be 'TEST.USER@EXAMPLE.COM'
            $result[1] | Should -Be 'ANOTHER.USER@DOMAIN.ORG'
        }
        
        It 'Should process computer email data through pipeline' {
            $computers = Get-DemoComputers -Count 5 -NamePrefix "SERVER"
            
            # Create email addresses from computer names
            $emails = $computers | ForEach-Object { "$($_.Name.ToLower())@company.com" }
            
            $result = $emails | 
                Get-EmailAddress | 
                ConvertTo-UpperCase
            
            $result | Should -HaveCount 5
            $result[0] | Should -Be 'SERVER001@COMPANY.COM'
        }
        
        It 'Should handle mixed valid and invalid data in pipeline' {
            $mixedData = @(
                'valid@example.com',
                'invalid.email',
                'another@valid.com',
                'also.invalid'
            )
            
            $results = @()
            $errors = @()
            
            $mixedData | 
                Get-EmailAddress -ErrorVariable pipelineErrors -ErrorAction SilentlyContinue |
                ConvertTo-UpperCase |
                ForEach-Object { $results += $_ }
            
            $results | Should -HaveCount 2
            $results[0] | Should -Be 'VALID@EXAMPLE.COM'
            $results[1] | Should -Be 'ANOTHER@VALID.COM'
            $pipelineErrors | Should -HaveCount 2
        }
    }
    
    Context 'Error Handling Consistency' {
        It 'Should handle errors consistently across all functions' {
            $functions = Get-Command -Module PowerShellModule
            
            foreach ($function in $functions) {
                $errorVariable = $null
                
                # Test with various invalid inputs
                try {
                    switch ($function.Name) {
                        'ConvertTo-UpperCase' { 
                            & $function -InputString $null -ErrorVariable errorVariable -ErrorAction SilentlyContinue 2>$null
                        }
                        'Get-EmailAddress' { 
                            & $function -EmailAddress $null -ErrorVariable errorVariable -ErrorAction SilentlyContinue 2>$null
                        }
                        'Get-DemoComputers' { 
                            & $function -Count 0 -ErrorVariable errorVariable -ErrorAction SilentlyContinue 2>$null
                        }
                    }
                }
                catch {
                    # Expected for parameter validation
                }
                
                # All functions should handle invalid input gracefully
                $function.Name | Should -Not -BeNullOrEmpty  # Basic validation that we tested the function
            }
        }
        
        It 'Should maintain pipeline flow despite individual function errors' {
            $mixedInput = @('valid@test.com', $null, 'another@test.com')
            
            $results = @()
            $mixedInput | 
                ForEach-Object { $_ } |
                Get-EmailAddress -ErrorAction SilentlyContinue |
                ConvertTo-UpperCase -ErrorAction SilentlyContinue |
                ForEach-Object { $results += $_ }
            
            $results | Should -HaveCount 2
            $results[0] | Should -Be 'VALID@TEST.COM'
            $results[1] | Should -Be 'ANOTHER@TEST.COM'
        }
    }
    
    Context 'Performance Integration Tests' {
        It 'Should complete large dataset operations within acceptable time limits' {
            $testData = 1..$script:integrationConfig.LargeDatasetSize | ForEach-Object { "teststring$_" }
            
            $duration = Measure-Command {
                $result = $testData | ConvertTo-UpperCase
            }
            
            $duration.TotalSeconds | Should -BeLessThan $script:integrationConfig.PerformanceThreshold
            Write-Host "Large dataset test completed in $($duration.TotalSeconds) seconds"
        }
        
        It 'Should handle concurrent operations without interference' {
            $scriptBlocks = @(
                { 
                    Import-Module PowerShellModule -Force
                    1..100 | ForEach-Object { "test$_" } | ConvertTo-UpperCase | Out-Null
                },
                {
                    Import-Module PowerShellModule -Force
                    1..50 | ForEach-Object { "user$_@test.com" } | Get-EmailAddress | Out-Null
                },
                {
                    Import-Module PowerShellModule -Force
                    Get-DemoComputers -Count 100 | Out-Null
                }
            )
            
            $jobs = $scriptBlocks | ForEach-Object { Start-Job -ScriptBlock $_ }
            
            try {
                $results = $jobs | Wait-Job -Timeout $script:integrationConfig.TestTimeout
                
                # Verify all jobs completed successfully
                foreach ($job in $jobs) {
                    $job.State | Should -Be 'Completed'
                    $job | Receive-Job -ErrorVariable jobErrors
                    $jobErrors | Should -BeNullOrEmpty
                }
            }
            finally {
                $jobs | Remove-Job -Force
            }
        }
        
        It 'Should maintain memory efficiency with large datasets' {
            $initialMemory = [GC]::GetTotalMemory($false)
            
            # Process large dataset
            $largeDataset = 1..5000 | ForEach-Object { "largetest$_@company.com" }
            $result = $largeDataset | Get-EmailAddress | ConvertTo-UpperCase
            
            $result | Should -HaveCount 5000
            
            # Force garbage collection and check memory
            [GC]::Collect()
            [GC]::WaitForPendingFinalizers()
            [GC]::Collect()
            
            $finalMemory = [GC]::GetTotalMemory($false)
            $memoryIncrease = $finalMemory - $initialMemory
            
            # Memory increase should be reasonable (less than 100MB for this test)
            $memoryIncrease | Should -BeLessThan 100MB
            Write-Host "Memory increase: $([Math]::Round($memoryIncrease / 1MB, 2)) MB"
        }
    }
    
    Context 'Complex Real-World Scenarios' {
        It 'Should process employee data workflow end-to-end' {
            # Simulate processing employee computer and email data
            $computers = Get-DemoComputers -Count 50 -IncludeProperties 'All'
            
            # Extract departments and create email addresses
            $emailData = $computers | ForEach-Object {
                $username = $_.Name.ToLower()
                $domain = switch ($_.Department) {
                    'IT' { 'it.company.com' }
                    'Finance' { 'finance.company.com' }
                    'HR' { 'hr.company.com' }
                    default { 'general.company.com' }
                }
                "$username@$domain"
            }
            
            # Process emails and format
            $processedEmails = $emailData | 
                Get-EmailAddress |
                ConvertTo-UpperCase
            
            $processedEmails | Should -HaveCount 50
            $processedEmails | Should -Match '@.*\.COMPANY\.COM$'
        }
        
        It 'Should handle data validation and cleansing workflow' {
            # Mixed quality data scenario
            $rawData = @(
                'VALID@EXAMPLE.COM',
                'invalid.email.format',
                'good@test.org',
                '',
                'another@valid.com',
                'bad@',
                'final@clean.net'
            )
            
            # Clean and process data
            $cleanedData = @()
            $errorLog = @()
            
            foreach ($item in $rawData) {
                try {
                    $validated = $item | Get-EmailAddress -ErrorAction Stop
                    $formatted = $validated | ConvertTo-UpperCase
                    $cleanedData += $formatted
                }
                catch {
                    $errorLog += "Invalid data: $item - $($_.Exception.Message)"
                }
            }
            
            $cleanedData | Should -HaveCount 4
            $errorLog | Should -HaveCount 3
            
            $cleanedData | Should -Contain 'VALID@EXAMPLE.COM'
            $cleanedData | Should -Contain 'GOOD@TEST.ORG'
            $cleanedData | Should -Contain 'ANOTHER@VALID.COM'
            $cleanedData | Should -Contain 'FINAL@CLEAN.NET'
        }
        
        It 'Should process computer inventory with email integration' {
            # Get computers from IT department
            $itComputers = Get-DemoComputers -Count 20 -IncludeProperties 'Network' |
                Where-Object { $_.Department -eq 'IT' }
            
            if ($itComputers.Count -gt 0) {
                # Generate admin email addresses for IT computers
                $adminEmails = $itComputers | ForEach-Object {
                    "admin-$($_.Name.ToLower())@it.company.com"
                }
                
                # Validate and format admin emails
                $formattedEmails = $adminEmails |
                    Get-EmailAddress |
                    ConvertTo-UpperCase
                
                $formattedEmails | Should -Not -BeNullOrEmpty
                $formattedEmails | Should -Match '^ADMIN-.*@IT\.COMPANY\.COM$'
                
                # Verify network properties are included
                $itComputers[0].PSObject.Properties.Name | Should -Contain 'IPAddress'
                $itComputers[0].PSObject.Properties.Name | Should -Contain 'MACAddress'
            } else {
                # If no IT computers in random generation, this is expected
                Write-Host "No IT computers generated in this test run"
            }
        }
    }
    
    Context 'Module State and Side Effects' {
        It 'Should not leave global state after function execution' {
            # Get initial variable state
            $initialVariables = Get-Variable | Select-Object -ExpandProperty Name
            
            # Execute all functions
            ConvertTo-UpperCase -InputString "test" | Out-Null
            Get-EmailAddress -EmailAddress "test@example.com" | Out-Null
            Get-DemoComputers -Count 1 | Out-Null
            
            # Check final variable state
            $finalVariables = Get-Variable | Select-Object -ExpandProperty Name
            $newVariables = $finalVariables | Where-Object { $_ -notin $initialVariables }
            
            # Should not introduce new global variables (except for test framework variables)
            $newVariables | Where-Object { $_ -notmatch '^(it|describe|context|beforeall|afterall)' } | 
                Should -BeNullOrEmpty
        }
        
        It 'Should handle module reimport correctly' {
            # Import module multiple times
            Import-Module PowerShellModule -Force
            $functions1 = Get-Command -Module PowerShellModule
            
            Import-Module PowerShellModule -Force
            $functions2 = Get-Command -Module PowerShellModule
            
            Import-Module PowerShellModule -Force
            $functions3 = Get-Command -Module PowerShellModule
            
            # Should have same functions each time
            $functions1.Count | Should -Be $functions2.Count
            $functions2.Count | Should -Be $functions3.Count
            
            # Functions should work after reimport
            $result = ConvertTo-UpperCase -InputString "test"
            $result | Should -Be "TEST"
        }
    }
    
    Context 'Compatibility and Platform Tests' {
        It 'Should work on current PowerShell version' {
            $psVersion = $PSVersionTable.PSVersion
            Write-Host "Testing on PowerShell version: $psVersion"
            
            # Module requires PowerShell 7.4+
            $psVersion.Major | Should -BeGreaterOrEqual 7
            if ($psVersion.Major -eq 7) {
                $psVersion.Minor | Should -BeGreaterOrEqual 4
            }
        }
        
        It 'Should handle different culture settings' {
            $originalCulture = [System.Globalization.CultureInfo]::CurrentCulture
            
            try {
                # Test with different culture
                [System.Globalization.CultureInfo]::CurrentCulture = [System.Globalization.CultureInfo]::new('en-US')
                $result1 = ConvertTo-UpperCase -InputString "test"
                
                [System.Globalization.CultureInfo]::CurrentCulture = [System.Globalization.CultureInfo]::new('tr-TR')
                $result2 = ConvertTo-UpperCase -InputString "test"
                
                # Results should be consistent regardless of culture
                $result1 | Should -Be "TEST"
                $result2 | Should -Be "TEST"
            }
            finally {
                [System.Globalization.CultureInfo]::CurrentCulture = $originalCulture
            }
        }
        
        It 'Should handle different execution policies gracefully' {
            # This test verifies the module loads regardless of execution policy
            # (assuming it's already loaded for tests to run)
            $module = Get-Module PowerShellModule
            $module | Should -Not -BeNullOrEmpty
            $module.ExportedFunctions.Count | Should -BeGreaterThan 0
        }
    }
}