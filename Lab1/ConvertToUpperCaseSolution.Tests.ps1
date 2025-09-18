#Requires -Modules @{ ModuleName="Pester"; MaximumVersion="5.7.1" }
[CmdletBinding()]
param()
#Ensure Pester module is installed
#Enable advanced Function/Script functionality with empty param block and CmdletBinding attribute

#Use the BeforeAll block to load the code to be tested
BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
}

# Use Describe blocks to group related tests
Describe 'ConvertTo-Uppercase' -Tags @('Unit', 'Function') {
    
    #Use Context blocks to group related tests within a Describe block
    Context 'When given a single string' {
        It 'Converts to uppercase a lowercase string' {
            ConvertTo-Uppercase -text 'hello' | Should -Be 'HELLO'
        }
        
        It 'Converts to uppercase a string with mixed case' {
            ConvertTo-Uppercase -text 'HeLLoWoRLd' | Should -BeExactly 'HELLOWORLD'
        }
        
        It 'Preserves spaces in the string' {
            ConvertTo-Uppercase -text 'hello world' | Should -Be 'HELLO WORLD'
        }
        
        It 'Handles single character strings' {
            ConvertTo-Uppercase -text 'a' | Should -Be 'A'
        }
        
        It 'Returns the same string if already uppercase' {
            ConvertTo-Uppercase -text 'ALREADY UPPER' | Should -Be 'ALREADY UPPER'
        }
    }
    
    Context 'When given an array of strings' {
        It 'Converts each string in the array to uppercase' {
            ConvertTo-Uppercase -text @('hello', 'world') | Should -BeExactly @('HELLO', 'WORLD')
        }
        
        It 'Handles mixed case array elements' {
            $testInput = @('HeLLo', 'WoRLd', 'test')
            $expected = @('HELLO', 'WORLD', 'TEST')
            ConvertTo-Uppercase -text $testInput | Should -BeExactly $expected
        }
        
        It 'Handles array with spaces in elements' {
            $testInput = @('hello world', 'foo bar')
            $expected = @('HELLO WORLD', 'FOO BAR')
            ConvertTo-Uppercase -text $testInput | Should -BeExactly $expected
        }
    }
    
    Context 'Parameter validation' {
        It 'Throws an error on null input' {
            { ConvertTo-Uppercase -text $null } | Should -Throw
        }
        
        It 'Throws Error on an empty string' {
            { ConvertTo-Uppercase -text '' } | Should -Throw
        }
        It 'Throws an error on number input' {
            { ConvertTo-Uppercase -text 123 } | Should -Throw
        }
        
        It 'Throws an error on input with numbers' {
            { ConvertTo-Uppercase -text 'hello123' } | Should -Throw
        }
        
        It 'Throws an error on input with special characters' {
            { ConvertTo-Uppercase -text 'hello@world' } | Should -Throw
        }
        
        It 'Accepts input with only letters and spaces' {
            { ConvertTo-Uppercase -text 'hello world' } | Should -Not -Throw
        }
    }
    
    Context 'Edge cases' {
        It 'Handles single space' {
            ConvertTo-Uppercase -text ' ' | Should -Be ' '
        }
        
        It 'Handles multiple spaces' {
            ConvertTo-Uppercase -text '   ' | Should -Be '   '
        }
        
        It 'Handles strings with leading and trailing spaces' {
            ConvertTo-Uppercase -text ' hello world ' | Should -Be ' HELLO WORLD '
        }
    }
}

