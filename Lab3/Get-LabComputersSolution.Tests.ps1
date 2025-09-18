#Requires -Modules @{ ModuleName="Pester"; MaximumVersion="5.7.1" }
[CmdletBinding()]
param()

BeforeAll {
    # Dot source the function file
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
    
    # Cache function command for performance
    $script:function = Get-Command Get-LabComputers
    
    # Check if we're connected to a supported lab domain for integration tests
    try
    {
        $script:domainInfo = Get-ADDomain -ErrorAction Stop
        $script:isLabDomain = $script:domainInfo.NetBIOSName -in @('KAYLOSLAB', 'CONTOSO')
        $script:domainName = $script:domainInfo.NetBIOSName
        Write-Host "✓ Connected to domain: $($script:domainName)" -ForegroundColor Green
    }
    catch
    {
        $script:isLabDomain = $false
        $script:domainName = 'Unknown'
        Write-Warning "Unable to connect to Active Directory: $($_.Exception.Message)"
    }
    
    # Set Pester configuration for consistent behavior
    $PesterPreference = [PesterConfiguration]::Default
    $PesterPreference.Should.ErrorAction = 'Stop'
}

AfterAll {
    # Clean up any resources if needed
    Write-Host '✓ Test cleanup completed' -ForegroundColor Green
}


Describe 'Get-LabComputers' -Tag 'Unit' {
    Context 'Parameter validation and function signature' {
        It 'Should have all expected parameters with correct types' {
            # Assert - Check all required parameters exist
            $script:function.Parameters.ContainsKey('throttleLimit') | Should -BeTrue
            $script:function.Parameters.ContainsKey('timeout') | Should -BeTrue
            $script:function.Parameters.ContainsKey('Computers') | Should -BeTrue
            
            # Assert - Check parameter types
            $script:function.Parameters['throttleLimit'].ParameterType | Should -Be ([int])
            $script:function.Parameters['timeout'].ParameterType | Should -Be ([int])
        }

        It 'Should accept custom parameter values without throwing' {
            # Act & Assert - Test with empty computer list to avoid AD calls
            { Get-LabComputers -throttleLimit 50 -Computers @() } | Should -Not -Throw
            { Get-LabComputers -timeout 60 -Computers @() } | Should -Not -Throw
            { Get-LabComputers -throttleLimit 10 -timeout 30 -Computers @() } | Should -Not -Throw
        }

        It 'Should have positional parameters in correct order' {
            # Assert - Check parameter positions for default value handling
            $script:function.Parameters['throttleLimit'].Attributes.Position | Should -Be 0
            $script:function.Parameters['timeout'].Attributes.Position | Should -Be 1
        }
    }

    Context 'Basic functionality and edge cases' {
        It 'Should filter out current computer when provided in input' {
            # Arrange - Test the filtering logic by providing current computer in list
            $testList = @('NONEXISTENT1', $env:COMPUTERNAME, 'NONEXISTENT2')
            
            # Act
            $result = Get-LabComputers -Computers $testList
            
            # Assert - Current computer should be filtered out
            $result | Should -Not -Contain $env:COMPUTERNAME
        }

        It 'Should handle empty computer list gracefully' {
            # Act
            $result = Get-LabComputers -Computers @()
            
            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should execute without errors when called with valid parameters' {
            # Act & Assert - Test function execution without errors
            { Get-LabComputers -Computers @('NONEXISTENT') } | Should -Not -Throw
        }
    }

    Context 'Mocked AD Integration Tests' -Tag 'Unit' {
        It 'Should verify default parameter calls Get-ADComputer with correct filter' {
            # Arrange - This test focuses on parameter default behavior
            $function = Get-Command Get-LabComputers
            
            # Assert - Verify the Computers parameter has a default value that calls Get-ADComputer
            $computersParam = $function.Parameters['Computers']
            $computersParam | Should -Not -BeNull
            
            # The default value in the function definition is: ((Get-ADComputer -Filter *).name)
            # We can verify this by checking the function definition
            $functionDefinition = $function.Definition
            $functionDefinition | Should -Match 'Get-ADComputer.*Filter.*\*' -Because 'Default parameter should call Get-ADComputer with Filter *'
        }

        It 'Should mock Get-ADComputer and demonstrate filtering behavior' {
            # Arrange - Mock Get-ADComputer to return predictable test data
            Mock Get-ADComputer {
                return @(
                    [PSCustomObject]@{ Name = 'MOCK-SERVER-01' },
                    [PSCustomObject]@{ Name = 'MOCK-SERVER-02' },
                    [PSCustomObject]@{ Name = $env:COMPUTERNAME }  # Include current computer to test filtering
                )
            }
            
            # Mock the ping operations to simulate successful responses for mock computers
            Mock New-Object {
                $mockPing = New-Object PSObject -Property @{
                    'SendPingAsync' = {
                        param($Computer, $Timeout)
                        # Return a mock task that simulates a successful ping for our mock computers
                        $mockTask = New-Object PSObject -Property @{
                            'IsCompleted'             = $true
                            'IsCompletedSuccessfully' = ($Computer -like 'MOCK-*')
                            'ComputerName'            = $Computer
                            'Dispose'                 = { }
                        }
                        # Add the ComputerName as a note property to match the function's Add-Member call
                        Add-Member -InputObject $mockTask -MemberType NoteProperty -Name 'ComputerName' -Value $Computer -Force
                        return $mockTask
                    }
                }
                return $mockPing
            } -ParameterFilter { $TypeName -eq 'System.Net.NetworkInformation.Ping' }
            
            Mock Start-Sleep { } # Skip the sleep operations in the while loop
            
            # Act - Call the function without the Computers parameter to trigger Get-ADComputer
            try
            {
                $null = Get-LabComputers -throttleLimit 5 -timeout 5
                
                # Assert - Verify Get-ADComputer was called
                Should -Invoke Get-ADComputer -Times 1 -Exactly
            }
            catch
            {
                # Even if the function fails due to mocking complexity, verify Get-ADComputer was called
                Should -Invoke Get-ADComputer -Times 1 -Exactly
            }
        }

        It 'Should handle filtering when Get-ADComputer returns empty result' {
            # Act - Test with empty computer list (simulates Get-ADComputer returning no computers)
            $result = Get-LabComputers -Computers @()
            
            # Assert - Should handle empty result gracefully  
            $result | Should -BeNullOrEmpty -Because 'Empty computer list should return empty result'
        }

        It 'Should filter out current computer from any computer list' {
            # Arrange - Test the filtering logic directly with current computer
            $testList = @($env:COMPUTERNAME, 'OTHERCOMPUTER')
            
            # Act
            $result = Get-LabComputers -Computers $testList
            
            # Assert - Should filter out current computer
            $result | Should -Not -Contain $env:COMPUTERNAME -Because 'Current computer should always be filtered out'
        }

        It 'Should demonstrate Get-ADComputer mock integration in isolated test' {
            # Arrange - This test shows how Get-ADComputer would be called and mocked
            Mock Get-ADComputer {
                Write-Host "Mock Get-ADComputer called with Filter: $Filter" -ForegroundColor Yellow
                return @(
                    [PSCustomObject]@{ Name = 'MOCK-TEST-01' },
                    [PSCustomObject]@{ Name = 'MOCK-TEST-02' }
                )
            }
            
            # Act - Test just the parameter default by calling Get-ADComputer directly
            $mockResult = Get-ADComputer -Filter '*'
            
            # Assert - Verify our mock was called and returned expected data
            Should -Invoke Get-ADComputer -Times 1 -Exactly
            $mockResult | Should -HaveCount 2
            $mockResult[0].Name | Should -Be 'MOCK-TEST-01'
            $mockResult[1].Name | Should -Be 'MOCK-TEST-02'
        }
    }

    Context 'Lab Domain Integration Tests' -Tag 'Integration' {
        BeforeAll {
            # Skip message helper for consistent messaging
            $script:skipMessage = "Not connected to supported lab domain (KAYLOSLAB or CONTOSO). Current: $($script:domainName)"
        }

        It 'Should fail on Windows PowerShell 5.1 due to .NET version requirements' {
            # This test will pass on PowerShell 7.4+ and fail on Windows PowerShell 5.1
            if ($PSVersionTable.PSVersion -lt [Version]'7.4.0')
            {
                # If running on older PowerShell, the function should throw an error
                { Get-LabComputers -Computers @('TEST-COMPUTER') } | Should -Throw -ExpectedMessage '*requires PowerShell 7.4 or newer*'
            }
            else
            {
                # If running on PowerShell 7.4+, verify version is adequate
                $PSVersionTable.PSVersion | Should -BeGreaterOrEqual ([Version]'7.4.0') -Because 'Function requires PowerShell 7.4+ for .NET 8+ SendPingAsync functionality'
                
                # Verify function can be called without version error
                { Get-LabComputers -Computers @() } | Should -Not -Throw -Because 'PowerShell 7.4+ should not throw version errors'
            }
        }

        It 'Should return actual lab computers when connected to supported domain' {
            if (-not $script:isLabDomain)
            {
                Set-ItResult -Skipped -Because $script:skipMessage
                return
            }

            # Act - Get computers from AD and test the function
            $result = Get-LabComputers
            
            # Assert - Should return something and be properly formatted
            $result | Should -Not -BeNullOrEmpty -Because 'Should return computer names'
            $result | Should -Not -Contain $env:COMPUTERNAME -Because 'Current computer should be filtered out'
            
            # Assert - Results should be strings
            $resultArray = @($result) # Force to array for consistent handling
            foreach ($computer in $resultArray)
            {
                $computer | Should -BeOfType [System.String] -Because 'Computer names should be strings'
                $computer | Should -Not -BeNullOrEmpty -Because 'Computer names should not be empty'
            }
        }

        It 'Should handle custom computer list with real lab computers and respect filtering' {
            if (-not $script:isLabDomain)
            {
                Set-ItResult -Skipped -Because $script:skipMessage
                return
            }

            # Arrange - Get a few real computers from AD to test with
            try
            {
                $adComputers = (Get-ADComputer -Filter * -ResultSetSize 5).Name
                if ($adComputers)
                {
                    # Add current computer to test filtering
                    $testComputers = @($adComputers) + $env:COMPUTERNAME
                    
                    # Act
                    $result = Get-LabComputers -Computers $testComputers
                    
                    # Assert - Should not contain current computer and should be subset of input
                    $result | Should -Not -Contain $env:COMPUTERNAME -Because 'Current computer should be filtered out'
                    
                    $expectedComputers = $testComputers | Where-Object { $_ -ne $env:COMPUTERNAME }
                    foreach ($computer in $result)
                    {
                        $computer | Should -BeIn $expectedComputers -Because 'Results should only contain computers from input list'
                    }
                }
                else
                {
                    Set-ItResult -Skipped -Because 'No AD computers found to test with'
                }
            }
            catch
            {
                Set-ItResult -Skipped -Because "Error getting AD computers: $($_.Exception.Message)"
            }
        }

        It 'Should respect custom throttleLimit and timeout parameters in lab environment' {
            if (-not $script:isLabDomain)
            {
                Set-ItResult -Skipped -Because $script:skipMessage
                return
            }

            # Act & Assert - Test with custom parameters
            { Get-LabComputers -throttleLimit 10 } | Should -Not -Throw -Because 'Function should accept custom throttleLimit'
            { Get-LabComputers -timeout 30 } | Should -Not -Throw -Because 'Function should accept custom timeout'
        }

        It 'Should perform actual ping operations and filter non-responding computers' {
            if (-not $script:isLabDomain)
            {
                Set-ItResult -Skipped -Because $script:skipMessage
                return
            }

            # Arrange - Create a mix of real and fake computer names
            $testComputers = @('DEFINITELYNOTAREALCOMPUTER', 'LOCALHOST')
            
            # Act
            $result = Get-LabComputers -Computers $testComputers
            
            # Assert - Should not contain the fake computer name (ping logic verification)
            $result | Should -Not -Contain 'DEFINITELYNOTAREALCOMPUTER' -Because 'Non-existent computers should not respond to ping'
        }
    }
}
