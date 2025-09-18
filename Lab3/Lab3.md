# Lab 3: Advanced Pester Testing - Mocking and Integration Testing

## Lab Overview

In this lab, you'll learn advanced Pester v5 testing concepts by working with a real PowerShell function that interacts with Active Directory and network operations. You'll master:

- **Mocking external dependencies** (Get-ADComputer, System.Net objects)
- **Unit vs Integration testing strategies**
- **Complex mock scenarios** with parameter filtering
- **Conditional test execution** based on environment
- **Modern Pester v5 syntax** including Should -Invoke

## Prerequisites

- **PowerShell 7.4 or later** (required for .NET 8+ SendPingAsync functionality)
- Pester v5.7.1 or later
- Basic understanding of PowerShell functions
- Active Directory module (for integration tests)
- Lab 1 and Lab 2 completion recommended

> **⚠️ Important**: This lab requires PowerShell 7.4+ due to updates in the .NET 8+ SendPingAsync method. Windows PowerShell 5.1 is not supported and will cause tests to fail.

## Lab Setup

### Step 1: Examine the Target Function

First, let's understand what we're testing. Open `Get-LabComputersSolution.ps1` and examine the function:

```powershell
function Get-LabComputers {
    param([int]$throttleLimit = 100, [int]$timeout = 120, $Computers = ((Get-ADComputer -Filter *).name))
    
    # Check PowerShell version - requires 7.4+ for proper SendPingAsync functionality
    if ($PSVersionTable.PSVersion -lt [Version]'7.4.0') {
        throw "This function requires PowerShell 7.4 or newer due to .NET 8+ SendPingAsync method updates. Current version: $($PSVersionTable.PSVersion)"
    }
    
    # Key behaviors to test:
    # 1. PowerShell version validation (7.4+ required)
    # 2. Filters out current computer
    # 3. Performs async ping operations using .NET 8+ SendPingAsync
    # 4. Returns only responding computers
    # 5. Has default AD integration
}
```

**🎯 Learning Goal**: Identify testable behaviors, external dependencies, and version requirements.

### Step 2: Create Basic Test Structure

Create a new test file or examine the existing one:

```powershell
#Requires -Modules @{ ModuleName="Pester"; MaximumVersion="5.7.1" }

BeforeAll {
    # Dot source the function
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
    
    # Cache function for performance
    $script:function = Get-Command Get-LabComputers
}

Describe 'Get-LabComputers' -Tag 'Unit' {
    # Tests will go here
}
```

**🎯 Learning Goal**: Understand BeforeAll scope and function caching for performance.

## Understanding PowerShell Scoping in Pester

### Why Use `$script:` Scope Modifier?

PowerShell has multiple scopes that determine where variables can be accessed:

- **Global**: Available everywhere (`$global:variable`)
- **Script**: Available throughout the current script file (`$script:variable`)
- **Local**: Available only in current function/block (`$variable` or `$local:variable`)
- **Private**: Available only in current scope, not child scopes (`$private:variable`)

### The Scoping Challenge in Pester

```powershell
BeforeAll {
    # ❌ This creates a LOCAL variable - only available in BeforeAll block
    $function = Get-Command Get-LabComputers
    
    # ✅ This creates a SCRIPT variable - available throughout the test file
    $script:function = Get-Command Get-LabComputers
}

Describe 'MyTests' {
    It 'Should access cached function' {
        # ❌ This will be $null - can't access local variable from BeforeAll
        $function.Parameters | Should -Not -BeNull
        
        # ✅ This works - script scope is accessible across blocks
        $script:function.Parameters | Should -Not -BeNull
    }
}
```

### Pester Block Scoping Rules

1. **BeforeAll/AfterAll**: Runs in its own scope
2. **Describe/Context**: Creates a new scope boundary  
3. **It**: Inherits from parent Describe/Context scope
4. **BeforeEach/AfterEach**: Runs in same scope as It block

### Example Without Script Scope (This Fails)

```powershell
BeforeAll {
    $domainInfo = Get-ADDomain -ErrorAction SilentlyContinue
    $isLabDomain = $domainInfo.NetBIOSName -eq 'CONTOSO'
}

It 'Should check domain' {
    # ❌ These variables are $null - not accessible from BeforeAll scope
    $isLabDomain | Should -BeTrue
}
```

### Example With Script Scope (This Works)

```powershell
BeforeAll {
    $script:domainInfo = Get-ADDomain -ErrorAction SilentlyContinue
    $script:isLabDomain = $script:domainInfo.NetBIOSName -eq 'CONTOSO'
}

It 'Should check domain' {
    # ✅ These variables are accessible - script scope persists
    $script:isLabDomain | Should -BeTrue
}
```

## Part 1: Unit Testing with Parameter Validation

### Step 3: Test Function Signature

Add parameter validation tests:

```powershell
Context 'Parameter validation and function signature' {
    It 'Should have all expected parameters with correct types' {
        # Test parameter existence
        $script:function.Parameters.ContainsKey('throttleLimit') | Should -BeTrue
        $script:function.Parameters.ContainsKey('timeout') | Should -BeTrue
        $script:function.Parameters.ContainsKey('Computers') | Should -BeTrue
        
        # Test parameter types
        $script:function.Parameters['throttleLimit'].ParameterType | Should -Be ([int])
        $script:function.Parameters['timeout'].ParameterType | Should -Be ([int])
    }
}
```

**🎯 Learning Goal**: Use reflection to test function metadata without executing the function.

### Step 4: Test Edge Cases

```powershell
Context 'Basic functionality and edge cases' {
    It 'Should handle empty computer list gracefully' {
        $result = Get-LabComputers -Computers @()
        $result | Should -BeNullOrEmpty
    }

    It 'Should filter out current computer when provided in input' {
        $testList = @('NONEXISTENT1', $env:COMPUTERNAME, 'NONEXISTENT2')
        $result = Get-LabComputers -Computers $testList
        $result | Should -Not -Contain $env:COMPUTERNAME
    }
}
```

**🎯 Learning Goal**: Test business logic without external dependencies.

## Part 2: Introduction to Mocking

### Step 5: Understanding Mock Challenges

The Get-LabComputers function has complex dependencies:
- `Get-ADComputer` (Active Directory)
- `New-Object System.Net.NetworkInformation.Ping`
- `Start-Sleep` (timing operations)

**🔍 Challenge**: How do we test without requiring AD or performing actual network operations?

### Step 6: Basic Mock Implementation

```powershell
Context 'Mocked AD Integration Tests' -Tag 'Unit' {
    It 'Should verify default parameter calls Get-ADComputer with correct filter' {
        # Examine the function definition instead of executing it
        $functionDefinition = $script:function.Definition
        $functionDefinition | Should -Match 'Get-ADComputer.*Filter.*\*' -Because 'Default parameter should call Get-ADComputer with Filter *'
    }
}
```

**🎯 Learning Goal**: Sometimes testing the definition is safer than mocking complex scenarios.

### Step 7: Advanced Mock Scenario

Now let's create a comprehensive mock:

```powershell
It 'Should mock Get-ADComputer and demonstrate filtering behavior' {
    # Mock Get-ADComputer to return predictable data
    Mock Get-ADComputer {
        return @(
            [PSCustomObject]@{ Name = 'MOCK-SERVER-01' },
            [PSCustomObject]@{ Name = 'MOCK-SERVER-02' },
            [PSCustomObject]@{ Name = $env:COMPUTERNAME }  # Test filtering
        )
    }
    
    # Mock the complex ping object
    Mock New-Object {
        $mockPing = New-Object PSObject -Property @{
            'SendPingAsync' = {
                param($Computer, $Timeout)
                $mockTask = New-Object PSObject -Property @{
                    'IsCompleted'             = $true
                    'IsCompletedSuccessfully' = ($Computer -like 'MOCK-*')
                    'ComputerName'            = $Computer
                    'Dispose'                 = { }
                }
                Add-Member -InputObject $mockTask -MemberType NoteProperty -Name 'ComputerName' -Value $Computer -Force
                return $mockTask
            }
        }
        return $mockPing
    } -ParameterFilter { $TypeName -eq 'System.Net.NetworkInformation.Ping' }
    
    # Mock sleep to speed up tests
    Mock Start-Sleep { }
    
    # Test the function
    try {
        $null = Get-LabComputers -throttleLimit 5 -timeout 5
        Should -Invoke Get-ADComputer -Times 1 -Exactly
    }
    catch {
        # Even if function fails, verify mock was called
        Should -Invoke Get-ADComputer -Times 1 -Exactly
    }
}
```

**🎯 Learning Goal**: Complex mocking with parameter filters and nested object creation.

### Step 8: Mock Verification Patterns

```powershell
It 'Should demonstrate Get-ADComputer mock integration in isolated test' {
    Mock Get-ADComputer {
        Write-Host "Mock Get-ADComputer called with Filter: $Filter" -ForegroundColor Yellow
        return @(
            [PSCustomObject]@{ Name = 'MOCK-TEST-01' },
            [PSCustomObject]@{ Name = 'MOCK-TEST-02' }
        )
    }
    
    # Test the mock directly
    $mockResult = Get-ADComputer -Filter '*'
    
    # Verify mock behavior
    Should -Invoke Get-ADComputer -Times 1 -Exactly
    $mockResult | Should -HaveCount 2
    $mockResult[0].Name | Should -Be 'MOCK-TEST-01'
}
```

**🎯 Learning Goal**: Isolated mock testing and verification patterns.

## Part 3: Integration Testing

### Step 9: Environment Detection

```powershell
BeforeAll {
    # Check environment for integration tests
    try {
        $script:domainInfo = Get-ADDomain -ErrorAction Stop
        $script:isLabDomain = $script:domainInfo.NetBIOSName -in @('KAYLOSLAB', 'CONTOSO')
        $script:domainName = $script:domainInfo.NetBIOSName
        Write-Host "✓ Connected to domain: $($script:domainName)" -ForegroundColor Green
    }
    catch {
        $script:isLabDomain = $false
        $script:domainName = 'Unknown'
        Write-Warning "Unable to connect to Active Directory: $($_.Exception.Message)"
    }
}
```

**🎯 Learning Goal**: Conditional test execution based on environment availability.

### 🔍 Deep Dive: Why Script Scope is Critical Here

Notice how we use `$script:` for all variables that need to persist beyond the BeforeAll block:

```powershell
# ❌ Common Mistake - These variables won't be accessible in tests
BeforeAll {
    $domainInfo = Get-ADDomain        # Local scope only
    $isLabDomain = $true              # Local scope only
}

It 'Test domain connection' {
    $isLabDomain | Should -BeTrue     # ❌ $isLabDomain is $null here!
}

# ✅ Correct Approach - Script scope persists across blocks
BeforeAll {
    $script:domainInfo = Get-ADDomain     # Script scope - accessible everywhere
    $script:isLabDomain = $true           # Script scope - accessible everywhere
}

It 'Test domain connection' {
    $script:isLabDomain | Should -BeTrue  # ✅ Works correctly!
}
```

**Key Rule**: Any variable created in BeforeAll that you need in tests MUST use `$script:` scope.

### Step 10: Integration Test Patterns

```powershell
Context 'Lab Domain Integration Tests' -Tag 'Integration' {
    BeforeAll {
        $script:skipMessage = "Not connected to supported lab domain (KAYLOSLAB or CONTOSO). Current: $($script:domainName)"
    }

    It 'Should return actual lab computers when connected to supported domain' {
        if (-not $script:isLabDomain) {
            Set-ItResult -Skipped -Because $script:skipMessage
            return
        }

        # Test with real AD
        $result = Get-LabComputers
        
        # Verify results
        $result | Should -Not -BeNullOrEmpty -Because 'Should return computer names'
        $result | Should -Not -Contain $env:COMPUTERNAME -Because 'Current computer should be filtered out'
        
        # Type verification
        $resultArray = @($result)
        foreach ($computer in $resultArray) {
            $computer | Should -BeOfType [System.String] -Because 'Computer names should be strings'
        }
    }
}
```

**🎯 Learning Goal**: Graceful test skipping and real environment testing.

### Step 11: PowerShell Version Requirement Testing

```powershell
It 'Should fail on Windows PowerShell 5.1 due to .NET version requirements' {
    # This test demonstrates version-aware testing patterns
    if ($PSVersionTable.PSVersion -lt [Version]'7.4.0') {
        # If running on older PowerShell, the function should throw an error
        { Get-LabComputers -Computers @('TEST-COMPUTER') } | Should -Throw -ExpectedMessage '*requires PowerShell 7.4 or newer*'
    } else {
        # If running on PowerShell 7.4+, verify version is adequate
        $PSVersionTable.PSVersion | Should -BeGreaterOrEqual ([Version]'7.4.0') -Because 'Function requires PowerShell 7.4+ for .NET 8+ SendPingAsync functionality'
        
        # Verify function can be called without version error
        { Get-LabComputers -Computers @() } | Should -Not -Throw -Because 'PowerShell 7.4+ should not throw version errors'
    }
}
```

**🎯 Learning Goal**: Version-aware testing that validates requirements and fails gracefully on unsupported platforms.

### Step 12: Mixed Testing Scenarios

```powershell
It 'Should perform actual ping operations and filter non-responding computers' {
    if (-not $script:isLabDomain) {
        Set-ItResult -Skipped -Because $script:skipMessage
        return
    }

    # Mix real and fake computers
    $testComputers = @('DEFINITELYNOTAREALCOMPUTER', 'LOCALHOST')
    $result = Get-LabComputers -Computers $testComputers
    
    # Verify ping logic works
    $result | Should -Not -Contain 'DEFINITELYNOTAREALCOMPUTER' -Because 'Non-existent computers should not respond to ping'
}
```

**🎯 Learning Goal**: Testing actual business logic with real dependencies.

## Part 4: Modern Pester v5 Syntax

### Step 13: Should -Invoke vs Assert-MockCalled

**Legacy Syntax (Pester v4):**
```powershell
Assert-MockCalled Get-ADComputer -Times 1 -Exactly
```

**Modern Syntax (Pester v5):**
```powershell
Should -Invoke Get-ADComputer -Times 1 -Exactly
```

**🎯 Learning Goal**: Modern syntax provides better integration with Should assertion pipeline.

### Step 14: Advanced Assertion Patterns

```powershell
# Multiple assertion types in one test
$result | Should -Not -BeNullOrEmpty
$result | Should -BeOfType [System.String]
$result | Should -Not -Contain $env:COMPUTERNAME
Should -Invoke Get-ADComputer -Times 1 -Exactly
```

**🎯 Learning Goal**: Combining different assertion types for comprehensive validation.

## Part 5: Test Organization and Best Practices

### Step 15: Tag-Based Test Execution

Run different test suites:

```powershell
# Run only unit tests (fast, no dependencies)
Invoke-Pester -Path "Get-LabComputersSolution.Tests.ps1" -Tag "Unit"

# Run only integration tests (requires AD)
Invoke-Pester -Path "Get-LabComputersSolution.Tests.ps1" -Tag "Integration"

# Run all tests
Invoke-Pester -Path "Get-LabComputersSolution.Tests.ps1"
```

**🎯 Learning Goal**: Organize tests by execution requirements and dependencies.

### Step 16: Performance Considerations

```powershell
BeforeAll {
    # Cache expensive operations
    $script:function = Get-Command Get-LabComputers
    
    # Set Pester configuration
    $PesterPreference = [PesterConfiguration]::Default
    $PesterPreference.Should.ErrorAction = 'Stop'
}

AfterAll {
    # Clean up resources
    Write-Host '✓ Test cleanup completed' -ForegroundColor Green
}
```

**🎯 Learning Goal**: Optimize test performance and ensure proper cleanup.

## Lab Exercises

### Exercise 1: Create Your Own Mock
Create a mock for a function that calls `Get-Process`. Test both the mock and the actual function behavior.

### Exercise 2: Integration Test Design
Design integration tests for a function that reads from the registry. Include environment detection and graceful skipping.

### Exercise 3: Parameter Filter Mastery
Create a mock with multiple parameter filters that behave differently based on input values.

### Exercise 4: Error Scenario Testing
Test how your function handles errors from mocked dependencies (e.g., Get-ADComputer throwing an exception).

### Exercise 5: Version Requirement Testing 🎯
**Objective**: Create version-aware tests for functions with platform requirements

```powershell
function Test-ModernFeature {
    param([string]$InputData)
    
    # This function requires PowerShell 7.2+ for some modern .NET feature
    if ($PSVersionTable.PSVersion -lt [Version]'7.2.0') {
        throw "This function requires PowerShell 7.2 or newer for modern .NET features. Current version: $($PSVersionTable.PSVersion)"
    }
    
    # Function logic here...
    return "Processed: $InputData"
}
```

**Your Task**: 
1. Create integration tests that validate the version requirement
2. Test both the error case (older PowerShell) and success case (newer PowerShell)
3. Use conditional logic to make tests pass on both old and new versions
4. Include meaningful error message validation

**Bonus**: Add a unit test that checks for the version validation without actually calling the function.

### Exercise 6: Scoping Challenge 🎯
**Objective**: Fix the broken scoping in this test and understand why it fails

```powershell
# ❌ This test has scoping issues - fix them!
BeforeAll {
    $connectionString = "Server=localhost;Database=Test"
    $expectedUsers = @('Alice', 'Bob', 'Charlie')
    $isConnected = $true
}

Describe 'Database Tests' {
    Context 'Connection Tests' {
        It 'Should have valid connection string' {
            $connectionString | Should -Not -BeNullOrEmpty
        }
        
        It 'Should be connected to database' {
            $isConnected | Should -BeTrue
        }
    }
    
    Context 'User Tests' {
        It 'Should have expected users' {
            $expectedUsers | Should -HaveCount 3
            $expectedUsers[0] | Should -Be 'Alice'
        }
    }
}
```

**Your Task**: 
1. Identify why the variables will be $null in the tests
2. Fix the scoping using the appropriate scope modifier
3. Explain which scope modifier you chose and why

**Hint**: All variables created in BeforeAll need what scope modifier to be accessible in It blocks?

## Key Takeaways

1. **Mocking Strategy**: Mock at the boundary of your function's control
2. **Test Isolation**: Unit tests should not depend on external resources
3. **Integration Balance**: Some tests need real dependencies for confidence
4. **Environment Awareness**: Design tests that work across different environments
5. **Modern Syntax**: Use Pester v5 Should -Invoke for consistency
6. **Performance**: Cache expensive operations and clean up properly
7. **Version Requirements**: Test platform requirements and handle version incompatibilities gracefully

## Troubleshooting Guide

### Common Issues:

1. **Mock Not Called**: Check parameter filters and ensure the mocked command is actually executed
2. **Integration Test Failures**: Verify environment prerequisites (AD connectivity, permissions)
3. **Complex Object Mocking**: Break down complex objects into simpler mock structures
4. **Timing Issues**: Mock time-dependent operations like Start-Sleep
5. **Variable Scoping Issues**: The most common Pester problem!
6. **PowerShell Version Errors**: Function requires PowerShell 7.4+ for .NET 8+ SendPingAsync functionality

### 🚨 Scoping Troubleshooting

**Problem**: Variables are $null in tests even though they're set in BeforeAll

```powershell
# ❌ This creates scoping issues
BeforeAll {
    $testData = @('Server1', 'Server2')  # Local scope - lost after BeforeAll
    $mockResult = 'Success'              # Local scope - lost after BeforeAll
}

It 'Should use test data' {
    $testData | Should -HaveCount 2      # ❌ $testData is $null here!
    $mockResult | Should -Be 'Success'   # ❌ $mockResult is $null here!
}
```

**Solution**: Always use script scope for shared variables

```powershell
# ✅ This works correctly
BeforeAll {
    $script:testData = @('Server1', 'Server2')  # Script scope - persists
    $script:mockResult = 'Success'              # Script scope - persists
}

It 'Should use test data' {
    $script:testData | Should -HaveCount 2      # ✅ Works!
    $script:mockResult | Should -Be 'Success'   # ✅ Works!
}
```

**Quick Check**: If you see `$null` values in tests for variables that should exist, check your scoping!

### 🚨 Version Requirement Troubleshooting

**Problem**: Function throws "requires PowerShell 7.4 or newer" error

```powershell
# ❌ This will fail on Windows PowerShell 5.1 or PowerShell 7.0-7.3
PS> Get-LabComputers
Exception: This function requires PowerShell 7.4 or newer due to .NET 8+ SendPingAsync method updates. Current version: 5.1.19041.4046
```

**Solutions**:

1. **Upgrade PowerShell** (Recommended):
   ```powershell
   # Check current version
   $PSVersionTable.PSVersion
   
   # Download PowerShell 7.4+ from GitHub releases
   # https://github.com/PowerShell/PowerShell/releases
   ```

2. **Version-Aware Testing**:
   ```powershell
   It 'Should handle version requirements appropriately' {
       if ($PSVersionTable.PSVersion -lt [Version]'7.4.0') {
           # Test that the function correctly rejects old versions
           { Get-LabComputers -Computers @('TEST') } | Should -Throw -ExpectedMessage '*requires PowerShell 7.4 or newer*'
       } else {
           # Test that the function works on supported versions
           { Get-LabComputers -Computers @() } | Should -Not -Throw
       }
   }
   ```

3. **Environment Detection**:
   ```powershell
   BeforeAll {
       $script:isModernPowerShell = $PSVersionTable.PSVersion -ge [Version]'7.4.0'
       if (-not $script:isModernPowerShell) {
           Write-Warning "Running on PowerShell $($PSVersionTable.PSVersion). Some tests will validate error conditions."
       }
   }
   ```

**Why PowerShell 7.4+ is Required**: The function uses .NET 8+ SendPingAsync method improvements that are not available in older versions.

### Debug Commands:

```powershell
# Check mock history
Get-MockHistory

# Verbose test output
Invoke-Pester -Path "test.ps1" -Output Detailed

# Debug specific test
Invoke-Pester -Path "test.ps1" -FullName "*specific test name*" -Output Diagnostic
```

## Next Steps

- **Lab 4**: Performance testing with large datasets
- **Lab 5**: Testing PowerShell classes and advanced OOP concepts
- **Lab 6**: CI/CD integration with automated testing

---

**Lab Completion Time**: 60-90 minutes  
**Difficulty Level**: Intermediate to Advanced  
**Prerequisites**: Labs 1-2, Basic PowerShell knowledge
