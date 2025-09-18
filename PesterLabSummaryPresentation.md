---
marp: true
theme: pester-dark
paginate: true
_comment: If theme not found, pass --theme ./themes/pester-dark.css to marp CLI
---
# Pester Testing Labs – Presentation Edition

Streamlined variant for slide oriented live delivery. One code block per slide, dark‑theme friendly (no oversized blocks, reduced density). For full detail: [Teaching Edition](./PesterLabSummary.md) · [Handout](./PesterLabSummary-Handout.md)

---
## Slide 0 – Quick Start Snapshot  [↩ Full](./PesterLabSummary.md#0-quick-start)
Concept anchors: Describe / It / Should / Red→Green→Refactor
```powershell
Describe 'ConvertTo-Uppercase' {
  It 'Uppercases hello' { ConvertTo-Uppercase 'hello' | Should -Be 'HELLO' }
}
function ConvertTo-Uppercase { param($Text) $Text.ToUpper() }
```

---
## Slide 1 – Learning Path  [↩ Full](./PesterLabSummary.md#1-learning-path-map)
1 Fundamentals → 2 Test Design → 3 Isolation → 4 Performance → 5 Objects → 6 Automation → 7 Productivity

---
## Slide 2A – Fundamentals: Block Anatomy  [↩ Full](./PesterLabSummary.md#2-core-fundamentals-lab-1)
Describe / Context / It / BeforeAll / BeforeEach / AfterEach / AfterAll
```powershell
Describe 'Calculator' {
  BeforeAll { . ./Calculator.ps1 }
  BeforeEach { $calc = [Calculator]::new() }
  It 'Adds numbers' { $calc.Add(2,3) | Should -Be 5 }
}
```

---
## Slide 2B – Fundamentals: Config Evolution  [↩ Full](./PesterLabSummary.md#2-core-fundamentals-lab-1)
Core operator set: -Be, -BeExactly, -BeOfType, -Throw, -Contain, -HaveCount, -Match, -BeNullOrEmpty, -BeGreaterThan, -BeTrue/-BeFalse
```powershell
$cfg = [PesterConfiguration]::Default
$cfg.Run.Path = './tests'
$cfg.TestResult.Enabled = $true
$cfg.TestResult.OutputPath = './test-results.xml'
Invoke-Pester -Configuration $cfg
```

---
## Slide 3A – Test Design: AAA Pattern  [↩ Full](./PesterLabSummary.md#3-advanced-test-design-lab-2)
AAA (Arrange / Act / Assert) clarifies intent
```powershell
It 'Extracts two emails' {
  # Arrange
  $text = 'john@a.com jane@b.org'
  # Act
  $r = Get-EmailAddress -String $text
  # Assert
  $r | Should -HaveCount 2
}
```

---
## Slide 3B – Test Design: Data-Driven  [↩ Full](./PesterLabSummary.md#3-advanced-test-design-lab-2)
Use -TestCases to collapse repetitive tests
```powershell
It 'Validates email <Email>' -TestCases @(
  @{ Email='ok@x.com'; Expected=$true }
  @{ Email='bad';   Expected=$false }
) { param($Email,$Expected) (Test-EmailFormat $Email) | Should -Be $Expected }
```

---
## Slide 4A – Isolation & Mocking Basics  [↩ Full](./PesterLabSummary.md#4-isolation--mocking-lab-3)
Mock external / nondeterministic / slow / destructive / rare
```powershell
Mock Get-ADComputer { @(@{Name='SRV1'},@{Name='SRV2'}) }
It 'Queries AD once' {
  Get-LabComputers | Out-Null
  Should -Invoke Get-ADComputer -Exactly 1
}
```

---
## Slide 4B – Isolation: Unit vs Integration  [↩ Full](./PesterLabSummary.md#4-isolation--mocking-lab-3)
Tag separation keeps fast feedback & realism layering
```powershell
Describe 'Get-LabComputers' -Tag Unit { # mocks }
Describe 'Get-LabComputers' -Tag Integration { # real deps }
```

---
## Slide 5A – Performance: Timing Contract  [↩ Full](./PesterLabSummary.md#5-performance--resource-testing-lab-4)
Keep perf tests isolated (tag Perf)
```powershell
$elapsed = Measure-Command { Invoke-DataProcessor -InputData (1..2000) }
$elapsed.TotalSeconds | Should -BeLessThan 3
```

---
## Slide 5B – Performance: Parallel Benefit  [↩ Full](./PesterLabSummary.md#5-performance--resource-testing-lab-4)
Compare sequential vs parallel speed
```powershell
$seq = Measure-Command { Invoke-ProcessData -Parallel:$false }
$par = Measure-Command { Invoke-ProcessData -Parallel }
$par.TotalSeconds | Should -BeLessThan ($seq.TotalSeconds * 0.8)
```

---
## Slide 5C – Performance: Memory Snapshot  [↩ Full](./PesterLabSummary.md#5-performance--resource-testing-lab-4)
Simplified memory delta check
```powershell
$b = [GC]::GetTotalMemory($false)
Invoke-DataProcessor (1..5000) | Out-Null
[GC]::Collect(); $a = [GC]::GetTotalMemory($true)
($a-$b)/1MB | Should -BeLessThan 50
```

---
## Slide 6 – Class / Object Testing  [↩ Full](./PesterLabSummary.md#6-class--object-testing-lab-5)
State transitions > internal calls
```powershell
$task = [Task]::new('Title','Desc')
It 'Completes' { $task.Complete(); $task.IsCompleted | Should -BeTrue }
It 'Overdue when past due date' {
  $task.DueDate = (Get-Date).AddDays(-1)
  $task.IsOverdue() | Should -BeTrue
}
```

---
## Slide 7A – CI/CD: Minimal Run  [↩ Full](./PesterLabSummary.md#7-cicd-automation-lab-6)
Smallest useful pipeline fragment
```yaml
- name: Run Pester
  shell: pwsh
  run: |
    $c = [PesterConfiguration]::Default
    $c.Run.Path = './tests'
    Invoke-Pester -Configuration $c
```

---
## Slide 7B – CI/CD: Quality Gate  [↩ Full](./PesterLabSummary.md#7-cicd-automation-lab-6)
Coverage as signal (not vanity)
```powershell
$c = [PesterConfiguration]::Default
$c.Run.Path = './tests'
$c.CodeCoverage.Enabled = $true
$c.CodeCoverage.Path = './src/*.ps1'
$r = Invoke-Pester -Configuration $c
if ($r.CodeCoverage.CoveragePercent -lt 80) { throw 'Coverage gate fail' }
```

---
## Slide 8 – IDE Productivity  [↩ Full](./PesterLabSummary.md#8-ide-productivity-lab-7)
Test Explorer discovery • CodeLens run/debug • Gutter quick-run • Breakpoints inside function under test • Tag selective execution

---
## Slide 9 – Troubleshooting Snapshot  [↩ Full](./PesterLabSummary.md#10-troubleshooting-guide)
| Issue | Fix |
|-------|-----|
| `[PesterConfiguration]` missing | Import-Module Pester v5 |
| Tests undiscovered | Ensure *.Tests.ps1 suffix |
| Mock not invoked | Relax / inspect parameter filter |
| Empty coverage | Correct glob + run repo root |
| Flaky timing | Mock clock / remove sleeps |

---
## Slide 10A – Invocation: Minimal  [↩ Full](./PesterLabSummary.md#16-minimal-vs-full-example-recap)
```powershell
Invoke-Pester -Path ./tests
```

---
## Slide 10B – Invocation: Full Config  [↩ Full](./PesterLabSummary.md#16-minimal-vs-full-example-recap)
```powershell
$cfg = [PesterConfiguration]::Default
$cfg.Run.Path = './tests'
$cfg.CodeCoverage.Enabled = $true
$cfg.CodeCoverage.Path = './src/*.ps1'
Invoke-Pester -Configuration $cfg
```

---
## Slide 11 – Best Practice Highlights  [↩ Full](./PesterLabSummary.md#11-best-practices-checklist)
Behavioral names • One primary behavior • Use -Because when non-obvious • Mock external / nondeterministic only • Fast unit loop (<5s) • Coverage as heuristic

---
## Slide 12 – Advanced Pointers  [↩ Full](./PesterLabSummary.md#14-advanced-topics-pointers-only)
Custom assertions • Parallel execution • Mutation testing • API contract validation

---
## Slide 13 – Lab Mapping  [↩ Full](./PesterLabSummary.md#15-original-lab-reference-mapping)
| Area | Lab |
|------|-----|
| Fundamentals | 1 |
| Design Patterns | 2 |
| Mocking / Isolation | 3 |
| Performance | 4 |
| Classes | 5 |
| CI/CD | 6 |
| IDE Productivity | 7 |

---
## Slide 14 – Glossary (Concise)  [↩ Full](./PesterLabSummary.md#18-glossary-quick-reference)
AAA • Describe • It • Mock • Invariant • Quality Gate • TDD

---
## Slide 15 – References & Resources  [↩ Full](./PesterLabSummary.md#17-teaching-flow-suggestion)
| Topic | Link |
|-------|------|
| Pester Docs | https://pester.dev |
| Pester GitHub | https://github.com/pester/Pester |
| PowerShell Docs | https://learn.microsoft.com/powershell |
| VS Code PowerShell Ext | https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell |
| GitHub Actions (PowerShell) | https://learn.microsoft.com/azure/devops/pipelines/ecosystems/powershell |
| Code Coverage Guidance | https://learn.microsoft.com/dotnet/core/testing/unit-testing-code-coverage |
| Mocking Concepts Recap | https://pester.dev/docs/usage/mock |

---
## Slide 16 – Closing
Key theme: Fast, focused, deterministic tests amplify confidence in change.

---
End of Presentation Edition (Slide Deck Variant)
