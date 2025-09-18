BeforeAll {
    # Import the module
    . "$PSScriptRoot/../src/StringUtils.ps1"
}

Describe 'String Utilities Tests' {
    
    Context 'Email Validation' {
        It 'Should validate correct email addresses' {
            Test-IsEmail "user@example.com" | Should -Be $true
            Test-IsEmail "test.email+tag@domain.co.uk" | Should -Be $true
            Test-IsEmail "firstname.lastname@company.org" | Should -Be $true
        }
        
        It 'Should reject invalid email addresses' {
            Test-IsEmail "invalid.email" | Should -Be $false
            Test-IsEmail "@domain.com" | Should -Be $false
            Test-IsEmail "user@" | Should -Be $false
            Test-IsEmail "" | Should -Be $false
            Test-IsEmail $null | Should -Be $false
        }
    }
    
    Context 'Phone Number Formatting' {
        It 'Should format 10-digit phone numbers' {
            $result = Format-PhoneNumber "1234567890"
            $result | Should -Be "(123) 456-7890"
        }
        
        It 'Should format 11-digit phone numbers with country code' {
            $result = Format-PhoneNumber "11234567890"
            $result | Should -Be "+1 (123) 456-7890"
        }
        
        It 'Should handle phone numbers with existing formatting' {
            $result = Format-PhoneNumber "(123) 456-7890"
            $result | Should -Be "(123) 456-7890"
        }
        
        It 'Should throw error for invalid phone numbers' {
            { Format-PhoneNumber "123" } | Should -Throw "Invalid phone number format"
            { Format-PhoneNumber "12345678901234" } | Should -Throw "Invalid phone number format"
        }
    }
    
    Context 'Initials Generation' {
        It 'Should generate initials from full name' {
            Get-Initials "John Doe" | Should -Be "JD"
            Get-Initials "Jane Mary Smith" | Should -Be "JMS"
            Get-Initials "Bob" | Should -Be "B"
        }
        
        It 'Should handle edge cases' {
            Get-Initials "" | Should -Be ""
            Get-Initials "  " | Should -Be ""
            Get-Initials "john doe" | Should -Be "JD"  # Should capitalize
        }
        
        It 'Should handle multiple spaces' {
            Get-Initials "John   Doe   Smith" | Should -Be "JDS"
        }
    }
}