# Pester Testing Cheat Sheet

## 1. File & Naming Conventions
Function: `Get-Thing.ps1`  Test: `Get-Thing.Tests.ps1`
Keep one primary subject per test file. Use `Describe` for the unit under test, `Context` for scenario grouping, `It` for a single behavioral assertion.

## 2. Block Lifecycle
| Block       | Runs                               | Scope Guidance |
|-------------|------------------------------------|----------------|
| BeforeAll   | Once per Describe/Context          | Use `$script:` for values reused in tests |
| BeforeEach  | Before every It                    | Keep fast / isolated setup |
| It          | A single behavior expectation      | One logical invariant |
| AfterEach   | After every It                     | Cleanup transient artifacts |
| AfterAll    | Once after suite                   | Dispose / remove temp resources |

## 3. Core Execution Patterns
```powershell
Invoke-Pester -Path .\tests                # Run all
Invoke-Pester -Tag Unit                     # Filter by tag
Invoke-Pester -ExcludeTag Slow              # Exclude
$cfg = [PesterConfiguration]::Default; $cfg.Run.Path = 'tests'; Invoke-Pester -Configuration $cfg
```

## 4. Assertion Essentials (Should)
| Category  | Operators |
|-----------|-----------|
| Equality  | -Be, -BeExactly |
| Types     | -BeOfType, -HaveType |
| Collections | -Contain, -HaveCount, -AllBe, -AllMatch, -BeIn |
| Strings   | -Match, -MatchExactly, -BeLike, -BeLikeExactly |
| Numeric   | -BeGreaterThan, -BeLessThan, -BeGreaterOrEqual, -BeLessOrEqual |
| Null/Empty| -BeNull, -BeNullOrEmpty |
| Boolean   | -BeTrue, -BeFalse |
| Exceptions| -Throw (add -ErrorId / -ExceptionType / -Message) |
| Invocation| -Invoke (mock verification) |

Tip: Use `-Because` to document intent.

## 5. AAA Pattern (Arrange / Act / Assert)
```powershell
It 'Parses two emails' {
  # Arrange
  $text = 'a@test.com b@test.org'
  # Act
  $result = Get-Emails -Text $text
  # Assert
  $result | Should -HaveCount 2 -Because 'Two valid addresses expected'
}
```

## 6. Mocking Basics
```powershell
Mock Get-ADUser { @{SamAccountName='Demo'} }
It 'Calls AD once' {
  Get-UserInfo | Out-Null
  Should -Invoke Get-ADUser -Times 1 -Exactly
}

# Parameter filtering
Mock Invoke-RestMethod { '{"ok":true}' } -ParameterFilter { $Method -eq 'Get' -and $Uri -match 'status' }
```
Guidelines: Mock only external / nondeterministic / slow dependencies. Assert outcome, not just call counts.

## 7. Tags & Suite Organization
| Tag Type     | Example         | Purpose |
|--------------|-----------------|---------|
| Scope        | Unit, Integration |
| Risk         | Critical, Smoke |
| Speed        | Fast, Slow      |
| Category     | AD, API, IO     |

Usage: `Describe 'Thing' -Tag @('Unit','Fast')` then filter with `-Tag` or `-ExcludeTag`.

## 8. Version & Environment Guards
```powershell
if ($PSVersionTable.PSVersion -lt [Version]'7.4.0') {
  It 'Version requirement enforced' {
    { Get-ModernFeature } | Should -Throw '*requires PowerShell 7.4*'
  }
}
```
Skip vs Fail: Use `Set-ItResult -Skipped -Because 'Not on lab domain'` for unavailable infrastructure, throw for unsupported runtime.

## 9. Structuring Test Data
| Pattern        | Use Case | Example |
|----------------|----------|---------|
| Inline cases   | Small matrix | `-TestCases @(@{In=1;Out=2})` |
| Data builder   | Complex objects | Helper function creating objects |
| External file  | Large sets | Import CSV / JSON (only if stable) |

## 10. Common Refactor Patterns
| Problem | Refactor |
|---------|----------|
| Repeated setup | Move to BeforeEach / factory function |
| Many asserts | Split into focused tests |
| Sleep usage | Replace with polling loop or mock async dependency |
| Large fixture | Inline only needed subset per test |

## 11. Top Test Smells (Rapid Reference)
| Smell | Fix |
|-------|-----|
| Assertion Roulette | One invariant per test; add -Because |
| Conditional Logic | Parameterize with -TestCases |
| General Fixture | Build only what you assert on |
| Sleepy Test | Poll or await; do not `Start-Sleep` |
| Mystery Guest | Mock external IO (files, AD, network) |
| Magic Number | Replace with named variable/constant |
| Redundant Print | Remove; rely on assertions |
| Empty / Unknown Test | Delete or implement intent |
| Eager Test | Decompose into scenario-specific tests |

## 12. Fast Feedback Checklist
[ ] All tests green
[ ] Unit suite < 5s
[ ] No skipped tests without ticket
[ ] No `Start-Sleep` in unit tests
[ ] Mocks only at system boundaries
[ ] Each failure message actionable

## 13. Minimal Pester Configuration Template
```powershell
$cfg = [PesterConfiguration]::Default
$cfg.Run.Path = 'tests'
$cfg.Output.Verbosity = 'Normal'
$cfg.TestResult.Enabled = $true
$cfg.TestResult.OutputPath = 'artifacts/test-results.xml'
Invoke-Pester -Configuration $cfg
```

## 14. Helpful Commands
```powershell
Get-Command -Module Pester -Name *Mock*
Get-MockHistory | Format-Table
Invoke-Pester -Output Detailed
Invoke-Pester -PassThru | Select FailedCount, PassedCount
```

## 15. When to Add Integration Tests
Typically only when you need to validate:
- Schema contracts (AD, REST, DB)
- Authentic connectivity & permissions
- Serialization / deserialization edge cases
- Performance characteristics of real components
- External Dependencies
- End-to-end workflows

## 16. Exit Criteria for "Done"
| Dimension | Exit Condition |
|-----------|----------------|
| Behavior  | Core paths + edge + failure modes covered |
| Isolation | External dependencies mocked in unit tests |
| Clarity   | Test names read as specifications |
| Stability | No flakiness over multiple runs |
| Performance | Suite time acceptable / budgeted |
| Maintainability | No unresolved smells |

---

