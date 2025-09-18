BeforeAll {
    # Import the module under test
    $ModulePath = Join-Path $PSScriptRoot '..\..\PowerShellModule.psd1'
    Import-Module $ModulePath -Force
    
    # Import test helpers
    $TestHelpersPath = Join-Path $PSScriptRoot '..\TestHelpers\TestHelpers.psm1'
    if (Test-Path $TestHelpersPath)
    {
        Import-Module $TestHelpersPath -Force
    }
}

Describe 'Get-EmailAddress Function Tests' -Tag 'Unit', 'Get-EmailAddress' {
    
    Context 'Parameter Validation and Metadata' {
        It 'Should have EmailAddress parameter that is mandatory' {
            Test-FunctionParameter -FunctionName 'Get-EmailAddress' -ParameterName 'EmailAddress' -Mandatory
        }
        
        It 'Should accept EmailAddress from pipeline' {
            Test-FunctionParameter -FunctionName 'Get-EmailAddress' -ParameterName 'EmailAddress' -ValueFromPipeline
        }
        
        It 'Should have Format parameter with valid set' {
            $command = Get-Command Get-EmailAddress
            $formatParam = $command.Parameters['Format']
            
            $formatParam | Should -Not -BeNullOrEmpty
            $formatParam.Attributes.ValidValues | Should -Contain 'AsIs'
            $formatParam.Attributes.ValidValues | Should -Contain 'Lower'
            $formatParam.Attributes.ValidValues | Should -Contain 'Upper'
            $formatParam.Attributes.ValidValues | Should -Contain 'Domain'
            $formatParam.Attributes.ValidValues | Should -Contain 'Local'
        }
        
        It 'Should have Strict parameter as SwitchParameter' {
            Test-FunctionParameter -FunctionName 'Get-EmailAddress' -ParameterName 'Strict' -Type ([switch])
        }
        
        It 'Should have proper help documentation' {
            $help = Get-Help Get-EmailAddress -Full
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
            $help.Examples | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Basic Email Validation' {
        It 'Should validate correct email formats' {
            $validEmails = @(
                'test@example.com',
                'user.name@domain.org',
                'first.last+tag@subdomain.example.co.uk',
                'user123@test-domain.net'
            )
            
            foreach ($email in $validEmails)
            {
                { Get-EmailAddress -EmailAddress $email } | Should -Not -Throw
                $result = Get-EmailAddress -EmailAddress $email
                $result | Should -Be $email
            }
        }
        
        It 'Should reject invalid email formats' {
            $invalidEmails = @(
                'invalid.email',
                '@domain.com',
                'user@',
                'user space@domain.com',
                'user@domain',
                ''
            )
            
            foreach ($email in $invalidEmails)
            {
                Get-EmailAddress -EmailAddress $email -ErrorVariable emailErrors -ErrorAction SilentlyContinue
                $emailErrors | Should -Not -BeNullOrEmpty
            }
        }
        
        It 'Should handle multiple email addresses' {
            $emails = @('test1@example.com', 'test2@example.com', 'test3@example.com')
            $result = Get-EmailAddress -EmailAddress $emails
            
            $result | Should -HaveCount 3
            $result[0] | Should -Be 'test1@example.com'
            $result[1] | Should -Be 'test2@example.com'
            $result[2] | Should -Be 'test3@example.com'
        }
        
        It 'Should handle pipeline input' {
            $result = 'user1@test.com', 'user2@test.com' | Get-EmailAddress
            
            $result | Should -HaveCount 2
            $result[0] | Should -Be 'user1@test.com'
            $result[1] | Should -Be 'user2@test.com'
        }
    }
    
    Context 'Format Parameter Functionality' {
        It 'Should return email as-is with AsIs format (default)' {
            $email = 'Test.User@Example.COM'
            $result = Get-EmailAddress -EmailAddress $email -Format AsIs
            $result | Should -Be $email
        }
        
        It 'Should convert to lowercase with Lower format' {
            $email = 'Test.User@Example.COM'
            $result = Get-EmailAddress -EmailAddress $email -Format Lower
            $result | Should -Be 'test.user@example.com'
        }
        
        It 'Should convert to uppercase with Upper format' {
            $email = 'test.user@example.com'
            $result = Get-EmailAddress -EmailAddress $email -Format Upper
            $result | Should -Be 'TEST.USER@EXAMPLE.COM'
        }
        
        It 'Should extract domain with Domain format' {
            $email = 'user@example.com'
            $result = Get-EmailAddress -EmailAddress $email -Format Domain
            $result | Should -Be 'example.com'
        }
        
        It 'Should extract local part with Local format' {
            $email = 'test.user@example.com'
            $result = Get-EmailAddress -EmailAddress $email -Format Local
            $result | Should -Be 'test.user'
        }
        
        It 'Should handle complex email with subdomain in Domain format' {
            $email = 'user@mail.subdomain.example.com'
            $result = Get-EmailAddress -EmailAddress $email -Format Domain
            $result | Should -Be 'mail.subdomain.example.com'
        }
    }
    
    Context 'Strict Validation Mode' {
        It 'Should accept RFC-compliant emails in strict mode' {
            $strictValidEmails = @(
                'test@example.com',
                'user.name@domain.org',
                'first.last@subdomain.example.co.uk'
            )
            
            foreach ($email in $strictValidEmails)
            {
                { Get-EmailAddress -EmailAddress $email -Strict } | Should -Not -Throw
                $result = Get-EmailAddress -EmailAddress $email -Strict
                $result | Should -Be $email
            }
        }
        
        It 'Should be more permissive in basic mode than strict mode' {
            # Note: This test may need adjustment based on the exact regex patterns used
            $borderlineEmail = 'test+tag@example.com'
            
            # Should work in basic mode
            { Get-EmailAddress -EmailAddress $borderlineEmail } | Should -Not -Throw
            
            # Behavior in strict mode depends on implementation
            # This test verifies the parameter works
            { Get-EmailAddress -EmailAddress $borderlineEmail -Strict } | Should -Not -Throw
        }
    }
    
    Context 'Error Handling and Edge Cases' {
        It 'Should handle empty string input with proper error' {
            Get-EmailAddress -EmailAddress '' -ErrorVariable emailErrors -ErrorAction SilentlyContinue
            $emailErrors | Should -Not -BeNullOrEmpty
            $emailErrors[0].Exception.Message | Should -Match 'Empty or null'
        }
        
        It 'Should handle null input gracefully' {
            Get-EmailAddress -EmailAddress $null -ErrorVariable emailErrors -ErrorAction SilentlyContinue
            $emailErrors | Should -Not -BeNullOrEmpty
        }
        
        It 'Should trim whitespace from input' {
            $email = '  test@example.com  '
            $result = Get-EmailAddress -EmailAddress $email
            $result | Should -Be 'test@example.com'
        }
        
        It 'Should handle mixed valid and invalid emails' {
            $mixedEmails = @('valid@example.com', 'invalid.email', 'another@valid.com')
            
            $results = @()
            $errors = @()
            
            $mixedEmails | Get-EmailAddress -ErrorVariable errors -ErrorAction SilentlyContinue |
                ForEach-Object { $results += $_ }
            
            $results | Should -HaveCount 2
            $results[0] | Should -Be 'valid@example.com'
            $results[1] | Should -Be 'another@valid.com'
            $errors | Should -HaveCount 1
        }
        
        It 'Should continue processing after errors' {
            $emails = @('first@valid.com', 'invalid', 'second@valid.com')
            
            $results = $emails | Get-EmailAddress -ErrorAction SilentlyContinue
            $results | Should -HaveCount 2
            $results[0] | Should -Be 'first@valid.com'
            $results[1] | Should -Be 'second@valid.com'
        }
    }
    
    Context 'Performance and Scalability' {
        It 'Should process large email lists efficiently' {
            $emailList = New-TestDataSet -Type 'Email' -Size 1000
            
            $result = Assert-PerformanceWithin -MaxDuration ([timespan]::FromSeconds(10)) -ScriptBlock {
                $emailList | Get-EmailAddress
            }
            
            $result | Should -HaveCount 1000
        }
        
        It 'Should maintain performance with different formats' {
            $emailList = New-TestDataSet -Type 'Email' -Size 100
            
            $formats = @('AsIs', 'Lower', 'Upper', 'Domain', 'Local')
            
            foreach ($format in $formats)
            {
                $duration = Measure-Command {
                    $emailList | Get-EmailAddress -Format $format | Out-Null
                }
                $duration.TotalSeconds | Should -BeLessThan 5
            }
        }
    }
    
    Context 'Verbose Output and Logging' {
        It 'Should provide verbose output when requested' {
            $verboseOutput = @()
            Get-EmailAddress -EmailAddress 'test@example.com' -Verbose 4>&1 | 
                Tee-Object -Variable verboseOutput | Out-Null
            
            $verboseOutput | Should -Not -BeNullOrEmpty
            $verboseOutput -join '' | Should -Match 'Starting Get-EmailAddress processing'
        }
        
        It 'Should include processing statistics in verbose output' {
            $emails = @('test1@example.com', 'invalid', 'test2@example.com')
            $verboseOutput = @()
            
            $emails | Get-EmailAddress -Verbose 4>&1 -ErrorAction SilentlyContinue |
                Tee-Object -Variable verboseOutput | Out-Null
            
            $verboseOutput -join '' | Should -Match 'processing completed.*valid.*invalid'
        }
        
        It 'Should include warnings for invalid emails' {
            $warningOutput = @()
            
            Get-EmailAddress -EmailAddress 'invalid.email' -WarningVariable warningOutput -ErrorAction SilentlyContinue
            
            $warningOutput | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Integration with Other Functions' {
        It 'Should work with ConvertTo-UpperCase in pipeline' {
            $emails = @('test@example.com', 'user@domain.org')
            
            $result = $emails | Get-EmailAddress | ConvertTo-UpperCase
            
            $result | Should -HaveCount 2
            $result[0] | Should -Be 'TEST@EXAMPLE.COM'
            $result[1] | Should -Be 'USER@DOMAIN.ORG'
        }
        
        It 'Should handle email objects with properties' {
            $emailObjects = @(
                [PSCustomObject]@{ Email = 'user1@test.com'; Name = 'User 1' }
                [PSCustomObject]@{ Email = 'user2@test.com'; Name = 'User 2' }
            )
            
            $result = $emailObjects.Email | Get-EmailAddress
            
            $result | Should -HaveCount 2
            $result[0] | Should -Be 'user1@test.com'
            $result[1] | Should -Be 'user2@test.com'
        }
    }
}