# Pester Labs – Exit Quiz (Answer Key)

## Section A – Multiple Choice
1. C (It specifies a single behavior)
2. B (-BeExactly enforces case-sensitive string equality)
3. C (Isolation from slow/external dependencies)
4. B (Environmental or time variability not controlled)
5. C (Clear behavioral intent)
6. A (Pure function shouldn’t be mocked; test real logic)
7. B (Improves failure diagnostics/context)
8. C (Covers edges + out-of-range)
9. B ($cfg.CodeCoverage.Enabled)
10. B (Only interaction validated; missing observable behavior)

## Section B – Short Answer
11. AAA = Arrange (setup), Act (execute), Assert (verify). It isolates phases for clarity and reduces cognitive load.
12. Coverage can incentivize superficial tests; high % does not guarantee meaningful behavioral validation.
13. When verifying an input validation error: `{ Add-User -Name $null } | Should -Throw -ExceptionType [System.ArgumentException]` ensures contract.
14. Unit test: isolates a small unit (function/class) with dependencies mocked. Integration test: exercises multiple real components working together.
15. Mock when dependency is slow/external/nondeterministic; avoid when function is pure and deterministic (mocking adds noise).

## Section C – Code Comprehension
16. (a) Problems: Uses real time (sleep); assertion expects >900 seconds after only 2s; fragile. (b) Rewrite: Mock/Get-Date or inject clock; or compute expiry based on fixed start.
Example outline:
```
Mock Get-Date { Get-Date '2024-01-01T00:00:00Z' }
$start = Get-Date
# Simulate 16 minutes elapsed
Mock Get-Date { Get-Date '2024-01-01T00:16:00Z' }
(It.IsExpired(15)) | Should -BeTrue
```
17. Original mixes two behaviors (result value & performance). Split:
```
It 'Doubles input 5 to 10' { (Invoke-Process -Input 5).Total | Should -Be 10 }
It 'Processes input 5 under 2s' {
  $elapsed = Measure-Command { Invoke-Process -Input 5 | Out-Null }
  $elapsed.TotalSeconds | Should -BeLessThan 2
}
```
18. Freezing time removes dependence on current system clock; ensures overdue logic evaluates deterministically for reproducible results.

## Section D – Applied Snippets
19.
```
Describe 'Normalize-Name' {
  It 'Trims and uppercases' {
    Normalize-Name '  john doe ' | Should -Be 'JOHN DOE'
  }
}
```
20.
```
$cfg = [PesterConfiguration]::Default
$cfg.Run.Path = './tests'
$cfg.CodeCoverage.Enabled = $true
$cfg.CodeCoverage.Path = './src/*.ps1'
$result = Invoke-Pester -Configuration $cfg
if ($result.CodeCoverage.CoveragePercent -lt 80) {
  throw "Coverage too low: $($result.CodeCoverage.CoveragePercent)%"
}
```

## Section E – Reflection (Sample Answers)
21. Examples: Adopt AAA pattern; add boundary test per new function; introduce selective mocks; add coverage gate for critical module.

## Scoring Guidance
- Partial credit: Award 1/2 on short answers missing rationale.
- Code: Must express correct intent; minor syntax mistakes acceptable if conceptually sound.
- Reflection: Credit if actionable & specific.

## Common Mistakes to Watch
- Using -Be instead of -BeExactly for case-sensitive requirement.
- Mocking pure utility functions.
- Combining performance + functional assertions in one test.
- Chasing 100% coverage without assessing value.

End of Answer Key.
