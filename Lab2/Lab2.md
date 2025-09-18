# Lab 2: Advanced Pester v5 Testing with Test Driven Development
## Building a Get-EmailAddress Function with Comprehensive Test Coverage

### Learning Objectives
By the end of this lab, you will:
- Master the **Arrange-Act-Assert (AAA)** testing pattern
- Apply **Test Driven Development (TDD)** to complex functions
- Understand advanced Pester v5 best practices and syntax
- Learn proper test structure and organization
- Use the `-Because` operator for meaningful test assertions
- Implement comprehensive parameter validation testing
- Handle pipeline input testing
- Test edge cases and error conditions

### Prerequisites
- Completion of Lab 1 (basic TDD concepts)
- PowerShell 5.1 or PowerShell 7+
- Pester v5.0+ installed
- Understanding of regular expressions (basic level)

---

## Understanding the Arrange-Act-Assert (AAA) Pattern

The **AAA pattern** is the gold standard for writing clear, maintainable tests:

```powershell
It 'Should do something specific' {
    # Arrange - Set up test data and conditions
    $inputData = 'test input'
    $expectedResult = 'expected output'
    
    # Act - Execute the code being tested
    $actualResult = Function-UnderTest -Parameter $inputData
    
    # Assert - Verify the outcome
    $actualResult | Should -Be $expectedResult -Because 'specific reason why this should work'
}
```

### Why Use AAA?
- **Clarity**: Each section has a clear purpose
- **Maintainability**: Easy to understand and modify
- **Debugging**: Problems are easier to isolate
- **Documentation**: Tests serve as living documentation

---

## The Power of the -Because Operator

The `-Because` operator makes test failures meaningful and actionable:

```powershell
# Poor assertion - unclear why it failed
$result | Should -Be $expected

# Good assertion - explains the business logic
$result | Should -Be $expected -Because 'email validation requires proper domain format'
```

### When to Use -Because
- **Complex business rules**: Explain the reasoning behind requirements
- **Edge cases**: Clarify why certain inputs should behave differently  
- **Validation logic**: Explain what makes input valid or invalid
- **Future maintenance**: Help other developers understand intent

---

## Test Structure Best Practices

### 1. Hierarchical Organization
```powershell
Describe 'Function-Name' -Tags @('Unit', 'Integration') {
    Context 'When testing specific scenario' {
        It 'Should behave in expected way' {
            # Test implementation
        }
    }
}
```

### 2. Logical Grouping with Context
- Group related functionality together
- Use descriptive Context names that explain the scenario
- Separate positive and negative test cases
- Group by input types or function modes

### 3. Descriptive Test Names
- Start with "Should" to describe expected behavior
- Be specific about the scenario being tested
- Include the expected outcome

---

## Lab 2: Building Get-EmailAddress Function

### Overview
We'll build a function that:
- Extracts email addresses from text using regex
- Validates email format according to RFC standards
- Handles pipeline input
- Optionally joins results with delimiters
- Filters out invalid patterns
- Removes duplicates

---

## Step 1: Set Up the Test Environment

Create your test file: `Get-EmailAddress.Tests.ps1`

```powershell
#Requires -Modules @{ ModuleName="Pester"; MaximumVersion="5.7.1" }
[CmdletBinding()]
param()

BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
}

Describe 'Get-EmailAddress' -Tag 'Unit' {
    # Tests will go here
}
```

Create your function file: `Get-EmailAddress.ps1`
```powershell
# Start empty for TDD approach
```

---

## Step 2: First Test - Basic Email Extraction (RED)

Apply the AAA pattern to your first test:

```powershell
Context 'When extracting email addresses from text' {
    It 'Should extract valid email addresses from text' {
        # Arrange
        $text = 'Contact john.doe@example.com or jane@test.org for more info'
        
        # Act
        $result = Get-EmailAddress -string $text
        
        # Assert
        $result | Should -HaveCount 2 -Because 'text contains exactly two valid email addresses'
        $result | Should -Contain 'john.doe@example.com' -Because 'first email should be extracted'
        $result | Should -Contain 'jane@test.org' -Because 'second email should be extracted'
    }
}
```

**Run the test** - it should fail because the function doesn't exist yet.

### Why This Test Structure Works
- **Arrange**: Sets up realistic input data
- **Act**: Single line that clearly shows what we're testing
- **Assert**: Multiple specific assertions with clear reasoning
- **-Because**: Explains why each assertion matters

---

## Step 3: Minimal Implementation (GREEN)

Create the simplest function that makes the test pass:

```powershell
function Get-EmailAddress {
    param(
        [parameter(Mandatory = $true)]
        [string[]]$string
    )
    
    $regex = '\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b'
    $string | Select-String -Pattern $regex -AllMatches |
        ForEach-Object { $_.matches.value }
}
```

**Run the test** - it should now pass!

---

## Step 4: Test Single Email Scenario (RED)

Add a test for single email extraction:

```powershell
It 'Should handle single email address' {
    # Arrange
    $text = 'Email us at support@company.com'
    
    # Act
    $result = Get-EmailAddress -string $text
    
    # Assert
    $result | Should -Be 'support@company.com' -Because 'single email should be returned as string, not array'
}
```

This test might fail depending on how PowerShell handles single-item arrays. This teaches us about PowerShell's array behavior.

---

## Step 5: Test Empty Input Scenarios (RED)

Add comprehensive null/empty testing:

```powershell
It 'Should return empty array when no emails found' {
    # Arrange
    $text = 'This text contains no email addresses'
    
    # Act
    $result = Get-EmailAddress -string $text
    
    # Assert
    $result | Should -BeNullOrEmpty -Because 'no valid emails exist in the input text'
}

It 'Should handle empty string input' {
    # Act
    $result = Get-EmailAddress -string ''
    
    # Assert
    $result | Should -BeNullOrEmpty -Because 'empty string contains no content to parse'
}

It 'Should handle null input' {
    # Act
    $result = Get-EmailAddress -string $null
    
    # Assert
    $result | Should -BeNullOrEmpty -Because 'null input should not cause errors'
}
```

**Run tests** - the null test will likely fail. This drives us to improve our implementation.

---

## Step 6: Implement Robust Input Handling (GREEN)

Update the function to handle edge cases:

```powershell
function Get-EmailAddress {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [string[]]$string
    )
    
    begin {
        $regex = '\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b'
        $EmailAddresses = @()
    }
    
    process {
        if ($string) {
            $EmailAddresses += $string | Select-String -Pattern $regex -AllMatches |
                ForEach-Object { $_.matches.value }
        }
        else {
            Write-Verbose "skipping $string"
        }
    }
    
    end {
        $EmailAddresses
    }
}
```

### Key Implementation Points
- **Pipeline support**: `ValueFromPipeline = $true`
- **Null handling**: `[AllowNull()]` and `[AllowEmptyString()]`
- **Begin/Process/End**: Proper pipeline processing pattern
- **Verbose output**: Helpful for debugging

---

## Step 7: Test Email Format Validation (RED)

Add tests for email format requirements:

```powershell
Context 'When validating email formats' {
    It 'Should extract emails with valid TLD (2+ characters)' {
        # Arrange
        $text = 'Valid: user@domain.com, user@domain.co.uk'
        
        # Act
        $result = Get-EmailAddress -string $text
        
        # Assert
        $result | Should -HaveCount 2 -Because 'both emails have valid TLD formats'
        $result | Should -Contain 'user@domain.com' -Because '.com is a valid TLD'
        $result | Should -Contain 'user@domain.co.uk' -Because '.co.uk is a valid multi-part TLD'
    }

    It 'Should reject emails with single character TLD' {
        # Arrange
        $text = 'Invalid: user@domain.c'
        
        # Act
        $result = Get-EmailAddress -string $text
        
        # Assert
        $result | Should -BeNullOrEmpty -Because 'single character TLD violates email standards'
    }
}
```

These tests should pass with our current regex that requires `{2,}` characters for TLD.

---

## Step 8: Test Advanced Validation Rules (RED)

Add tests for complex validation scenarios:

```powershell
Context 'When filtering invalid email patterns' {
    It 'Should filter out emails with consecutive dots (..)' {
        # Arrange
        $text = 'Invalid: user..name@domain.com'
        
        # Act
        $result = Get-EmailAddress -string $text
        
        # Assert
        $result | Should -BeNullOrEmpty -Because 'consecutive dots should invalidate email'
    }

    It 'Should filter out emails with dot immediately before @ (user.@domain.com)' {
        # Arrange
        $text = 'Invalid: user.@domain.com'
        
        # Act
        $result = Get-EmailAddress -string $text
        
        # Assert
        $result | Should -BeNullOrEmpty -Because 'dot before @ should invalidate email'
    }

    It 'Should filter out emails with local part longer than 64 characters' {
        # Arrange
        $longLocal = 'a' * 65  # 65 characters
        $text = "Invalid: $longLocal@domain.com"
        
        # Act
        $result = Get-EmailAddress -string $text
        
        # Assert
        $result | Should -BeNullOrEmpty -Because 'local part over 64 chars should be invalid'
    }
}
```

**Run tests** - these will fail because we haven't implemented the additional filtering.

---

## Step 9: Implement Advanced Filtering (GREEN)

Update the function to include advanced validation:

```powershell
end {
    $EmailAddresses = $EmailAddresses | Select-Object -Unique
    
    # Extra filtering for RFC compliance
    $EmailAddresses = $EmailAddresses | Where-Object { 
        $_ -notlike '*..*' -and                    # No consecutive dots
        $_ -notlike '*.@.*' -and                   # No dot-at-dot pattern
        $_ -notmatch '\.@|@\.' -and                # No dots adjacent to @
        $_.Split('@')[0].length -le 64             # Local part <= 64 chars
    }
    
    $EmailAddresses
}
```

**Run tests** - advanced validation tests should now pass!

---

## Step 10: Test Delimiter Functionality (RED)

Add tests for the delimiter feature:

```powershell
Context 'When using delimiter functionality' {
    It 'Should join emails with semicolon delimiter' {
        # Arrange
        $text = 'Contact john@example.com or jane@test.org'
        
        # Act
        $result = Get-EmailAddress -string $text -Delimiter ';'
        
        # Assert
        $result | Should -Be 'john@example.com;jane@test.org' -Because 'delimiter should join multiple emails'
    }

    It 'Should return single email without delimiter when only one email' {
        # Arrange
        $text = 'Contact support@company.com'
        
        # Act
        $result = Get-EmailAddress -string $text -Delimiter ';'
        
        # Assert
        $result | Should -Be 'support@company.com' -Because 'single email needs no delimiter'
    }
}
```

---

## Step 11: Implement Delimiter Feature (GREEN)

Add the delimiter parameter and logic:

```powershell
param(
    [parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [AllowEmptyString()]
    [AllowNull()]
    [string[]]$string,
    [string]$Delimiter
)

# In the end block:
end {
    $EmailAddresses = $EmailAddresses | Select-Object -Unique
    $EmailAddresses = $EmailAddresses | Where-Object { 
        $_ -notlike '*..*' -and 
        $_ -notlike '*.@.*' -and 
        $_ -notmatch '\.@|@\.' -and 
        $_.Split('@')[0].length -le 64 
    }

    if ($Delimiter) { 
        $EmailAddresses -join $Delimiter
    }
    else {
        $EmailAddresses
    }
}
```

---

## Step 12: Test Pipeline Functionality (RED)

Add comprehensive pipeline tests:

```powershell
Context 'When processing pipeline input' {
    It 'Should accept pipeline input from array of strings' {
        # Arrange
        $textArray = @(
            'First email: john@example.com',
            'Second email: jane@test.org',
            'Third email: bob@company.net'
        )
        
        # Act
        $result = $textArray | Get-EmailAddress
        
        # Assert
        $result | Should -HaveCount 3 -Because 'each string should contribute one email'
        $result | Should -Contain 'john@example.com' -Because 'first string email should be found'
        $result | Should -Contain 'jane@test.org' -Because 'second string email should be found'
        $result | Should -Contain 'bob@company.net' -Because 'third string email should be found'
    }

    It 'Should handle empty strings in pipeline gracefully' {
        # Arrange
        $textArray = @('', $null, 'user@domain.com', '')
        
        # Act
        $result = $textArray | Get-EmailAddress
        
        # Assert
        $result | Should -HaveCount 1 -Because 'only non-empty string contains valid email'
        $result | Should -Be 'user@domain.com' -Because 'empty/null strings should be skipped'
    }
}
```

---

## Step 13: Test Parameter Validation (RED)

Add tests to verify function parameters are correctly configured:

```powershell
Context 'When validating function parameters' {
    BeforeAll {
        $function = Get-Command Get-EmailAddress
    }

    It 'Should have mandatory string parameter' {
        # Act
        $stringParam = $function.Parameters['string']
        $mandatoryAttribute = $stringParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
        
        # Assert
        $mandatoryAttribute.Mandatory | Should -BeTrue -Because 'string parameter should be mandatory'
    }

    It 'Should accept pipeline input for string parameter' {
        # Act
        $stringParam = $function.Parameters['string']
        $pipelineAttribute = $stringParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
        
        # Assert
        $pipelineAttribute.ValueFromPipeline | Should -BeTrue -Because 'string parameter should accept pipeline input'
    }
}
```

---

## Step 14: Test Complex Scenarios

Add comprehensive real-world tests:

```powershell
Context 'When processing complex email scenarios' {
    It 'Should extract multiple emails from complex text' {
        # Arrange
        $text = @'
Dear Team,

Please contact the following people:
- John Doe: john.doe+work@company-name.co.uk
- Jane Smith: j.smith123@university.edu
- Bob Wilson: bob_wilson@non-profit.org

For support, email: support@help-desk.com or backup@site.net

Best regards,
Admin Team
'@
        
        # Act
        $result = Get-EmailAddress -string $text
        
        # Assert
        $result | Should -HaveCount 5 -Because 'complex text contains exactly five valid emails'
        $result | Should -Contain 'john.doe+work@company-name.co.uk' -Because 'plus signs and hyphens are valid in emails'
        $result | Should -Contain 'j.smith123@university.edu' -Because 'numbers and dots are valid in local part'
    }
}
```

---

## Advanced Testing Concepts

### 1. Testing Verbose Output
```powershell
It 'Should write verbose message when skipping null/empty strings' {
    # Arrange & Act
    $verboseOutput = Get-EmailAddress -string $null -Verbose 4>&1
    
    # Assert
    $verboseOutput | Should -Match "skipping" -Because 'verbose mode should explain what is being skipped'
}
```

### 2. Testing with Mock Objects
```powershell
It 'Should handle regex errors gracefully' {
    # Arrange
    Mock Select-String { throw "Regex error" } -ModuleName $null
    
    # Act & Assert
    { Get-EmailAddress -string "test@example.com" } | Should -Throw -Because 'regex errors should be propagated'
}
```

### 3. Performance Testing
```powershell
It 'Should handle very long input strings' {
    # Arrange
    $longText = "a" * 10000 + " test@example.com " + "b" * 10000
    
    # Act
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = Get-EmailAddress -string $longText
    $stopwatch.Stop()
    
    # Assert
    $result | Should -Be 'test@example.com' -Because 'email should be found regardless of string length'
    $stopwatch.ElapsedMilliseconds | Should -BeLessThan 1000 -Because 'performance should remain reasonable'
}
```

---

## Key Learning Points

### 1. Test Structure Best Practices
- **Use meaningful Context names** that describe the scenario
- **Group related tests logically** by functionality or input type
- **Follow AAA pattern consistently** for clarity and maintainability
- **Write descriptive test names** that explain expected behavior

### 2. The -Because Operator
- **Explains business logic** behind assertions
- **Helps with debugging** when tests fail
- **Documents requirements** for future developers
- **Makes test intent clear** even to non-technical stakeholders

### 3. Advanced Pester Features
- **Parameter validation testing** ensures function contracts
- **Pipeline testing** verifies PowerShell integration
- **Mock testing** isolates units under test
- **Performance testing** ensures scalability
- **Verbose output testing** validates user experience

### 4. TDD Benefits Realized
- **Requirements clarity**: Tests define exactly what the function should do
- **Regression protection**: Changes that break existing functionality are caught immediately
- **Design improvement**: Writing tests first leads to better function design
- **Documentation**: Tests serve as executable specifications

---

## Running Your Complete Test Suite

```powershell
# Run all tests
Invoke-Pester -Path ".\Get-EmailAddress.Tests.ps1" -Output Detailed

# Run specific contexts
Invoke-Pester -Path ".\Get-EmailAddress.Tests.ps1" -FullName "*validation*"

# Run with code coverage
Invoke-Pester -Path ".\Get-EmailAddress.Tests.ps1" -CodeCoverage ".\Get-EmailAddress.ps1"
```

---

## Final Implementation Review

Your complete function should now:
- ✅ Extract emails using robust regex
- ✅ Handle pipeline input correctly  
- ✅ Validate email formats according to RFC standards
- ✅ Filter out invalid patterns
- ✅ Support delimiter functionality
- ✅ Remove duplicates
- ✅ Handle null/empty input gracefully
- ✅ Provide verbose output for debugging

---

## Conclusion

You've successfully applied:
- **Test Driven Development** methodology
- **Arrange-Act-Assert** pattern for clear test structure
- **-Because operator** for meaningful assertions
- **Advanced Pester v5** features and best practices
- **Comprehensive test coverage** including edge cases
- **Professional test organization** and documentation

This approach scales to any PowerShell function development and ensures robust, maintainable code with comprehensive test coverage!
