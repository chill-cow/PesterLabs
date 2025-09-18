# Lab 1: Test Driven Development with Pester v5
## Writing a ConvertTo-Uppercase Function

### Learning Objectives
By the end of this lab, you will:
- Understand the Test Driven Development (TDD) process
- Write comprehensive Pester v5 tests following best practices
- Implement a PowerShell function driven by tests
- Use proper parameter validation in PowerShell functions
- Understand how to organize and structure Pester tests

### Prerequisites
- PowerShell 5.1 or PowerShell 7+
- Pester v5.0+ installed (`Install-Module -Name Pester -Force -SkipPublisherCheck`)
- Basic understanding of PowerShell functions

### Overview
Test Driven Development (TDD) follows the **Red-Green-Refactor** cycle:
1. **Red**: Write a failing test
2. **Green**: Write minimal code to make the test pass
3. **Refactor**: Improve the code while keeping tests passing

We'll create a `ConvertTo-Uppercase` function that:
- Converts text to uppercase
- Accepts single strings or arrays of strings
- Validates input (only letters and spaces allowed)
- Handles edge cases properly

---

## Step 1: Set Up the Test Environment

Create your test file first: `ConvertToUppercase.Tests.ps1`

```powershell
#Requires -Modules @{ ModuleName="Pester"; MaximumVersion="5.7.1" }
[CmdletBinding()]
param()

# Use the BeforeAll block to load the code to be tested
BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
}

# Use Describe blocks to group related tests
Describe 'ConvertTo-Uppercase' -Tags @('Unit', 'Function') {
    # We'll add our tests here
}
```

Create an empty function file: `ConvertToUppercase.ps1`

```powershell
# This file will contain our function - start empty for TDD
```

---

## Step 2: Write Your First Test (RED)

Add your first test inside the `Describe` block:

```powershell
Describe 'ConvertTo-Uppercase' -Tags @('Unit', 'Function') {
    Context 'When given a single string' {
        It 'Converts to uppercase a lowercase string' {
            ConvertTo-Uppercase -text 'hello' | Should -Be 'HELLO'
        }
    }
}
```

**Run the test** - it should fail because the function doesn't exist yet:
```powershell
Invoke-Pester -Path ".\ConvertToUppercase.Tests.ps1"
```

**Expected Result**: ❌ Test fails - "ConvertTo-Uppercase command not found"

---

## Step 3: Write Minimal Code to Pass (GREEN)

Add the simplest possible function to make the test pass:

```powershell
function ConvertTo-Uppercase {
    param($text)
    $text.ToUpper()
}
```

**Run the test again**:
```powershell
Invoke-Pester -Path ".\ConvertToUppercase.Tests.ps1"
```

**Expected Result**: ✅ Test passes!

---

## Step 4: Add More Tests (RED)

Now add additional tests for different scenarios:

```powershell
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
}
```

**Run the tests** - they should all pass with our current simple implementation.

---

## Step 5: Add Parameter Validation Tests (RED)

Add tests for input validation:

```powershell
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
```

**Run the tests** - the validation tests should fail because we haven't implemented validation yet.

---

## Step 6: Implement Parameter Validation (GREEN)

Update your function to handle validation:

```powershell
function ConvertTo-Uppercase {
    param(
        [ValidatePattern('^[a-zA-Z\s]+$')]
        [ValidateNotNullOrEmpty()]    
        [string[]]$text
    )
    $text.ToUpper()
}
```

**Key Points:**
- `[ValidateNotNullOrEmpty()]` - Ensures the parameter is not null or empty
- `[ValidatePattern('^[a-zA-Z\s]+$')]` - Only allows letters and spaces
- `[string[]]` - Allows both single strings and arrays

**Run the tests** - validation tests should now pass!

---

## Step 7: Add Array Processing Tests (RED)

Add tests for array handling:

```powershell
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
```

**Run the tests** - array tests should pass because `ToUpper()` works on arrays automatically!

---

## Step 8: Add Edge Case Tests (RED)

Add tests for edge cases:

```powershell
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
    
    It 'Handles single character strings' {
        ConvertTo-Uppercase -text 'a' | Should -Be 'A'
    }
    
    It 'Returns the same string if already uppercase' {
        ConvertTo-Uppercase -text 'ALREADY UPPER' | Should -Be 'ALREADY UPPER'
    }
}
```

**Run the tests** - these should pass with our current implementation!

---

## Step 9: Run All Tests and Verify

Your complete test file should now have all the tests. Run them:

```powershell
Invoke-Pester -Path ".\ConvertToUppercase.Tests.ps1" -Output Detailed
```

**Expected Result**: ✅ All tests should pass!

---

## Step 10: Create a Test Runner (Optional Enhancement)

Create `RunLabTests.ps1` for professional test execution:

```powershell
[CmdletBinding()]
param(
    [switch]$CodeCoverage,
    [string]$OutputPath = $PSScriptRoot
)

# Import Pester
Import-Module Pester -Force

# Create Pester configuration
$config = New-PesterConfiguration
$config.Run.Path = Join-Path $PSScriptRoot "ConvertToUppercase.Tests.ps1"
$config.Run.PassThru = $true
$config.Output.Verbosity = 'Detailed'

# Configure test results
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.TestResult.OutputPath = Join-Path $OutputPath "testresults.xml"

# Configure code coverage if requested
if ($CodeCoverage) {
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = Join-Path $PSScriptRoot "ConvertToUppercase.ps1"
    $config.CodeCoverage.OutputFormat = 'JaCoCo'
    $config.CodeCoverage.OutputPath = Join-Path $OutputPath "coverage.xml"
}

# Run the tests
$testResults = Invoke-Pester -Configuration $config

# Display summary
Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Magenta
Write-Host "Tests Run: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "Passed: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "Failed: $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -gt 0) { 'Red' } else { 'Green' })

# Exit with appropriate code
exit $(if ($testResults.FailedCount -gt 0) { 1 } else { 0 })
```

---

## Final Solution

Your final function should look like this:

```powershell
function ConvertTo-Uppercase {
    param(
        [ValidatePattern('^[a-zA-Z\s]+$')]
        [ValidateNotNullOrEmpty()]    
        [string[]]$text
    )
    $text.ToUpper()
}
```

---

## Key TDD Lessons Learned

### 1. **Write Tests First**
- Tests define the expected behavior
- Forces you to think about requirements upfront
- Provides immediate feedback

### 2. **Start Simple**
- Write the minimal code to pass each test
- Don't over-engineer early
- Let tests drive the complexity

### 3. **Use Proper Pester Syntax**
- Use `{ }` scriptblocks with `Should -Throw` for exception testing
- Use `-BeExactly` for case-sensitive comparisons
- Organize tests with `Context` blocks

### 4. **Parameter Validation is Crucial**
- `[ValidateNotNullOrEmpty()]` prevents null/empty values
- `[ValidatePattern()]` enforces format requirements
- PowerShell handles validation exceptions automatically

### 5. **Test Edge Cases**
- Empty strings, single characters
- Arrays vs single values
- Special characters and spaces
- Already correct input

---

## Exercise Variations

Try these challenges to extend your learning:

1. **Add Pipeline Support**: Make the function accept pipeline input
2. **Add a -PassThru Parameter**: Return original and converted text
3. **Add Cultural Considerations**: Handle international characters
4. **Performance Testing**: Add tests for large arrays
5. **Mock External Dependencies**: Practice mocking if you add file operations

---

## Best Practices Summary

- ✅ Start with failing tests (Red)
- ✅ Write minimal code to pass (Green)
- ✅ Refactor while keeping tests green
- ✅ Use descriptive test names
- ✅ Group related tests with Context blocks
- ✅ Test both positive and negative scenarios
- ✅ Include edge cases in your tests
- ✅ Use appropriate Pester assertions
- ✅ Follow Pester v5 syntax and conventions

**Congratulations!** You've successfully implemented Test Driven Development with Pester v5!
