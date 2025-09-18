BeforeAll {
    # Import the module
    . "$PSScriptRoot/../src/Calculator.ps1"
}

Describe 'Calculator Class Tests' {
    BeforeEach {
        $script:calc = New-Calculator
    }
    
    Context 'Basic Operations' {
        It 'Should add two numbers correctly' {
            $result = $calc.Add(5, 3)
            $result | Should -Be 8
        }
        
        It 'Should subtract two numbers correctly' {
            $result = $calc.Subtract(10, 4)
            $result | Should -Be 6
        }
        
        It 'Should multiply two numbers correctly' {
            $result = $calc.Multiply(7, 8)
            $result | Should -Be 56
        }
        
        It 'Should handle negative numbers' {
            $calc.Add(-5, 3) | Should -Be -2
            $calc.Subtract(-10, -4) | Should -Be -6
            $calc.Multiply(-3, 4) | Should -Be -12
        }
    }
    
    Context 'Division Operations' {
        It 'Should divide two numbers correctly' {
            $result = $calc.Divide(15, 3)
            $result | Should -Be 5
        }
        
        It 'Should handle decimal division' {
            $result = $calc.Divide(7, 2)
            $result | Should -Be 3.5
        }
        
        It 'Should throw error when dividing by zero' {
            { $calc.Divide(10, 0) } | Should -Throw 'Cannot divide by zero'
        }
    }
    
    Context 'Advanced Operations' {
        It 'Should calculate power correctly' {
            $calc.Power(2, 3) | Should -Be 8
            $calc.Power(5, 2) | Should -Be 25
            $calc.Power(10, 0) | Should -Be 1
        }
        
        It 'Should handle fractional exponents' {
            $result = $calc.Power(9, 0.5)
            $result | Should -Be 3
        }
    }
}