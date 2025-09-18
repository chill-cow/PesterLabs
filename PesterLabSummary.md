# Pester Testing Labs

This content is optimized for workshop delivery of Labs 1–7. It introduces concepts progressively, includes notes, quick demos, micro‑exercises, troubleshooting guidance, and exit assessment material.

Focus progression: Foundations → Test Design → Isolation → Performance → Objects → Automation → Productivity.

---

## 0. Quick Start (90‑Second Ramp)
Lets jump right in with a quick example:

```powershell
# 1. Create a test file (MyFunction.Tests.ps1)
Describe 'MyFunction' {
    It 'Returns HELLO when given hello' {
        MyFunction -Text 'hello' | Should -Be 'HELLO'
    }
}

# 2. Run it
Invoke-Pester -Path .\MyFunction.Tests.ps1

# 3. Make it pass (MyFunction.ps1)
function MyFunction { param([string]$Text) $Text.ToUpper() }

# 4. Improve (validation, edge cases) without breaking tests
```

Mental Model Mapping:
- Describe = suite; Context = scenario scope; It = spec (behavior assertion)
- BeforeAll/Each & AfterAll/Each = lifecycle hooks
- Should = assertion DSL
- Invoke-Pester + configuration object = execution harness
- Mocks isolate dependencies so tests stay fast & deterministic

What would we test next?
(Possible areas: validation, arrays, errors.)

---

## 1. Learning Path Map

| Level | Theme | Labs | Core Question | Main Topics | Est. Time |
|-------|-------|------|---------------|-------------------|-----------|
| 1 | Fundamentals | [Lab 1](./Lab1/Lab1.md) | How do I structure a test? | Red‑Green‑Refactor, basic Should | 35–45m |
| 2 | Test Design | [Lab 2](./Lab2/Lab2.md) | How do I write clear, maintainable assertions? | AAA, -Because, edge cases | 45–60m |
| 3 | Isolation | [Lab 3](./Lab3/Lab3.md) | How do I test code with dependencies? | Mocks, integration balance | 50–60m |
| 4 | Performance | [Lab 4](./Lab4/Lab4.md) | Is it fast & resource efficient? | Timing, memory, parallel checks | 30–40m |
| 5 | Objects | [Lab 5](./Lab5/Lab5.md) | How do I test classes & state? | Constructors, methods, invariants | 35–45m |
| 6 | Automation | [Lab 6](./Lab6/Lab6.md) | How do I trust it in CI/CD? | Config, coverage, gates | 45–60m |
| 7 | Productivity | [Lab 7](./Lab7/Lab7.md) | How do I integrate with tooling? | VS Code Test Explorer, debug | 30–40m |

Total Approximate Delivery: 5.5–7.0 hours (excluding independent practice).

---

## 2. Core Fundamentals (Lab 1)

### 2.1 TDD Cycle (Red → Green → Refactor)
```powershell
# RED: failing test first
Describe 'ConvertTo-Uppercase' {
    It 'Uppercases hello' { ConvertTo-Uppercase -Text 'hello' | Should -Be 'HELLO' }
}

# GREEN: minimal code
function ConvertTo-Uppercase { param($Text) $Text.ToUpper() }

# REFACTOR: improve & keep green
function ConvertTo-Uppercase {
    [CmdletBinding()] param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Text )
    process { foreach ($t in $Text) { $t.ToUpper() } }
}
```
Note: Keep first win small & simple. Resist temptation to over-engineer upfront.

### 2.2 Pester Block Anatomy
```powershell
Describe 'Feature' {
    BeforeAll { # once
        . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
    }
    BeforeEach { $script:calc = [Calculator]::new() }
    It 'Adds numbers' { $calc.Add(2,3) | Should -Be 5 }
    AfterEach { Remove-Variable calc -ErrorAction SilentlyContinue }
    AfterAll { # final cleanup }
}
```

### 2.3 Core Operators to Learn First
`-Be`, `-BeExactly`, `-BeOfType`, `-Throw`, `-Contain`, `-HaveCount`, `-Match`, `-BeNullOrEmpty`, `-BeGreaterThan` / `-BeLessThan`, `-BeTrue` / `-BeFalse`.

### 2.4 Operator Matrix (Extended Reference)

| 🧩 Category | Operator(s) | Purpose | Tips / Pitfalls |
|-------------|-------------|---------|-----------------|
| 🔁 Equality | -Be / -BeExactly | Value comparison (insensitive/sensitive) | Use -BeExactly for string invariants |
| 📦 Collections | -HaveCount / -Contain / -AllBe / -AllMatch / -BeIn | Membership & shape | Don’t over‑assert ordering unless required |
| 🧬 Types | -BeOfType / -HaveType | Runtime type validation | Prefer -BeOfType for clarity |
| 🔤 Strings | -Match / -MatchExactly / -BeLike / -BeLikeExactly | Pattern vs wildcard | Regex for validation; wildcard for loose match |
| ∅ Null / Empty | -BeNullOrEmpty / -BeNull | Guard rails | Pair with positive control test |
| 🔢 Numeric | -BeGreaterThan / -BeLessThan / -BeIn / -BeGreaterOrEqual / -BeLessOrEqual | Boundaries / ranges | Express domain intent (min, max) |
| ✅ Boolean | -BeTrue / -BeFalse | Predicate result | Avoid asserting `$true` when richer assertion possible |
| 💥 Exceptions | -Throw (+ type/message) | Error contracts | Always include type or message |
| 📁 Existence | -Exist | Path presence | Clean up in AfterEach |
| 📝 Content | -FileContentMatch | File text patterns | Use sparingly (logs drift) |

### 2.5 Configuration Progression
```powershell
# Minimal
Invoke-Pester -Path .\tests

# Progressive
$cfg = [PesterConfiguration]::Default
$cfg.Run.Path = './tests'
$cfg.Output.Verbosity = 'Detailed'
Invoke-Pester -Configuration $cfg

# Full (adds results + coverage)
$cfg.TestResult.Enabled = $true
$cfg.TestResult.OutputPath = './test-results.xml'
$cfg.CodeCoverage.Enabled = $true
$cfg.CodeCoverage.Path = './src/*.ps1'
Invoke-Pester -Configuration $cfg
```

### 2.6 Parameter & Edge Validation Pattern
```powershell
Context 'Parameter validation' {
    It 'Rejects null' { { ConvertTo-Uppercase -Text $null } | Should -Throw }
    It 'Rejects empty' { { ConvertTo-Uppercase -Text '' } | Should -Throw }
    It 'Accepts letters & spaces' { { ConvertTo-Uppercase -Text 'hello world' } | Should -Not -Throw }
}
```

### 2.7 Micro Exercise (3–5 min)
Write a function `Normalize-Name` that trims + uppercases. Write 3 tests: normal case, leading/trailing spaces, empty input error.

---

## 3. Advanced Test Design (Lab 2)

### 3.1 AAA Pattern (Clarity & Maintainability)
```powershell
It 'Extracts two emails from text' {
    # Arrange
    $text = 'Contact john.doe@example.com or jane@test.org'
    # Act
    $result = Get-EmailAddress -String $text
    # Assert
    $result | Should -HaveCount 2 -Because 'text contains two valid addresses'
}
```
Why: Cognitive segmentation, easier diffing, prevents assertion soup (See Table of Testing Smells towards the end of this document).

### 3.2 Assertion Strategy
Guideline: 1 primary behavioral assertion per test; multiple allowed only when validating facets of a single invariant.

### 3.3 Using `-Because`
Adds domain rationale—improves failure triage.
```powershell
$user.IsLocked | Should -BeTrue -Because 'three consecutive failures should trigger lockout policy'
```

### 3.4 Data-Driven Test Cases
```powershell
It 'Validates email <Email>' -TestCases @(
    @{ Email='test@example.com'; Expected=$true }
    @{ Email='invalid'; Expected=$false }
) { param($Email,$Expected) (Test-EmailFormat $Email) | Should -Be $Expected }
```

### 3.5 Negative & Boundary Coverage
Checklist: Null / Empty / Too Short / Too Long / Invalid Type / Invalid Pattern / Max Size / Duplicate / Ordering.

### 3.6 Micro Exercise
Refactor a multi-assert test into 2 focused tests (happy vs error path).

---

## 4. Isolation & Mocking (Lab 3)

### 4.1 When to Mock (Decision Matrix)
| 💡 Mock If | Examples | Rationale |
|-----------|----------|-----------|
| 🌐 External system | AD, network ping, REST | Avoid fragility & slowness |
| 🎲 Non-deterministic | Random, time, GUID | Deterministic outcomes |
| ⏱️ Slow / 💲 cost / rate limited | Cloud API, large file IO | Fast feedback loop |
| 🧨 Destructive | Deletes, modifies state | Safety |
| 🧪 Hard to trigger | Error branches, timeouts | Predictability |

Avoid Mocking: Pure functions, simple arithmetic, in-memory transformations.

### 4.2 Basic Mock
```powershell
Mock Get-ADComputer { @(@{Name='SRV1'}, @{Name='SRV2'}) }
It 'Queries AD once' {
    Get-LabComputers | Out-Null
    Should -Invoke Get-ADComputer -Exactly 1
}
```

### 4.3 Conditional Mock Behavior
```powershell
Mock Test-Connection {
    param($ComputerName) $ComputerName -in 'SRV1','SRV2'
} -ParameterFilter { $Quiet -and $Count -eq 1 }
```

### 4.4 Unit vs Integration Side‑by‑Side
```powershell
# Unit (fully isolated)
Describe 'Get-LabComputers (Unit)' {
    BeforeAll { Mock Get-ADComputer { @(@{Name='X'}) }; Mock Test-Connection { $true } }
    It 'Excludes local machine' { Get-LabComputers | Should -Not -Contain $env:COMPUTERNAME }
}

# Integration (real deps, conditional skip)
Describe 'Get-LabComputers (Integration)' -Tag Integration {
    It 'Runs against real AD' -Skip:(-not (Get-Module ActiveDirectory -ListAvailable)) {
        Get-LabComputers -Timeout 5 | Should -BeOfType [array]
    }
}
```

### 4.5 Mocking Smells
| ⚠️ Smell | Symptom | Remedy |
|---------|---------|--------|
| 🧪 Over-mocking | Everything mocked | Allow real logic path |
| 🗂️ Testing mocks | Only verifying calls, no observable output | Assert behavior/result |
| 🎯 Parameter filter mismatch | `Should -Invoke` fails | Log parameters / relax filter |

See Table of Testing Smells towards the end of this document for more patterns.

### 4.6 Micro Exercise
Mock `Get-Date` to freeze time & test an expiration function.

---

## 5. Performance & Resource Testing (Lab 4)

### 5.1 Execution Time Contract
```powershell
$elapsed = Measure-Command { Invoke-DataProcessor -InputData (1..1000) }
$elapsed.TotalSeconds | Should -BeLessThan 5 -Because 'must finish under SLA'
```

### 5.2 Memory Usage Pattern
```powershell
$before = [GC]::GetTotalMemory($false)
Invoke-DataProcessor -InputData (1..5000) | Out-Null
[GC]::Collect(); [GC]::WaitForPendingFinalizers()
$after = [GC]::GetTotalMemory($true)
($after - $before)/1MB | Should -BeLessThan 50
```

### 5.3 Parallel vs Sequential Benchmark
```powershell
$seq = Measure-Command { Invoke-DataProcessor -InputData (1..3000) -UseParallel:$false }
$par = Measure-Command { Invoke-DataProcessor -InputData (1..3000) -UseParallel }
$par.TotalSeconds | Should -BeLessThan ($seq.TotalSeconds * 0.8)
```

### 5.4 Caution
Performance tests can be noisy—tag them `Perf` and run separately unless stable.

### 5.5 Micro Exercise
Add a `-ThrottleLimit` parameter; assert that parallel mode yields fewer elapsed seconds.

---

## 6. Class & Object Testing (Lab 5)

### 6.1 Constructor Validation
```powershell
It 'Creates task with custom due date' {
    $due = (Get-Date).AddDays(10)
    $t = [Task]::new('Title','Desc',$due)
    $t.DueDate.Date | Should -Be $due.Date
}
```

### 6.2 Property Invariants
```powershell
BeforeEach { $task = [Task]::new('Sample','Desc') }
It 'Initial state' {
    $task.IsCompleted | Should -BeFalse
    $task.CreatedDate | Should -BeOfType [datetime]
}
```

### 6.3 Behavioral Methods
```powershell
It 'Marks complete' { $task.Complete(); $task.IsCompleted | Should -BeTrue }
It 'Detects overdue' {
    $task.DueDate = (Get-Date).AddDays(-1)
    $task.IsOverdue() | Should -BeTrue
}
```

### 6.4 State-Based vs Interaction Testing
Prefer asserting state transitions (`IsCompleted changed`) over internal invocation counts.

### 6.5 Micro Exercise
Add `GetStatus()` returning Overdue / Completed / Pending; write 3 tests.

---

## 7. CI/CD Automation (Lab 6)

### 7.1 Minimal Workflow
```yaml
name: tests
on: [push, pull_request]
jobs:
    test:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4
            - name: Setup Pester
                shell: pwsh
                run: Install-Module Pester -Force -MinimumVersion 5.7.1 -SkipPublisherCheck
            - name: Run
                shell: pwsh
                run: |
                    $c = [PesterConfiguration]::Default
                    $c.Run.Path = './tests'
                    Invoke-Pester -Configuration $c
```

### 7.2 Expanded (Coverage + Reporting)
```yaml
            - name: Run Full Suite
                shell: pwsh
                run: |
                    $c = [PesterConfiguration]::Default
                    $c.Run.Path = './tests'
                    $c.Output.Verbosity = 'Detailed'
                    $c.TestResult.Enabled = $true
                    $c.TestResult.OutputPath = 'test-results.xml'
                    $c.CodeCoverage.Enabled = $true
                    $c.CodeCoverage.Path = './src/*.ps1'
                    Invoke-Pester -Configuration $c
            - name: Publish Results
                uses: dorny/test-reporter@v1
                if: always()
                with:
                    path: test-results.xml
                    name: Pester Tests
                    reporter: java-junit
```

### 7.3 Quality Gates
```powershell
$cfg = [PesterConfiguration]::Default
$cfg.Run.Path = './tests'
$cfg.CodeCoverage.Enabled = $true
$cfg.CodeCoverage.Path = './src/*.ps1'
$cfg.CodeCoverage.CoveragePercentTarget = 80
$result = Invoke-Pester -Configuration $cfg
if ($result.FailedCount -gt 0) { throw "Failures: $($result.FailedCount)" }
if ($result.CodeCoverage.CoveragePercent -lt 80) { throw "Coverage too low: $($result.CodeCoverage.CoveragePercent)%" }
```

### 7.4 Test Result Output Formats (NUnit / JUnit)
Pester v5 emits test results via the `TestResult` configuration block. The native supported XML format is `NUnitXml`, which most CI systems (GitHub Actions, Azure Pipelines, Jenkins, GitLab) can ingest directly—often even when they label it “JUnit”. A separate “JUnit” writer is usually unnecessary.

#### 7.4.1 Basic NUnit XML Output
```powershell
$cfg = [PesterConfiguration]::Default
$cfg.Run.Path = './tests'
$cfg.TestResult.Enabled = $true
$cfg.TestResult.OutputFormat = 'NUnitXml'   # (default if omitted when Enabled = $true)
$cfg.TestResult.OutputPath = 'artifacts/test-results.xml'
Invoke-Pester -Configuration $cfg
```

#### 7.4.2 Parallel or Split Runs (Append vs Overwrite)
If you run Pester multiple times (e.g., unit then integration) and want a single combined report, append a simple merge step:
```powershell
# First run
Invoke-Pester -Configuration $cfg | Out-Null

# Modify path for subsequent run then merge afterwards
$cfg.Run.Path = './integration-tests'
Invoke-Pester -Configuration $cfg | Out-Null

# Simple XML concatenation (naïve) – for robust merging use an XML-aware merge
[xml]$a = Get-Content artifacts/test-results.xml
[xml]$b = Get-Content artifacts/test-results.xml  # (second file if separate)
# Example placeholder for proper merge logic
```
Recommendation: Prefer one consolidated `Invoke-Pester` when feasible to avoid merge complexity.

#### 7.4.3 Consuming in CI (GitHub Example)
```yaml
            - name: Run Pester (NUnitXml)
                shell: pwsh
                run: |
                    $c = [PesterConfiguration]::Default
                    $c.Run.Path = './tests'
                    $c.TestResult.Enabled = $true
                    $c.TestResult.OutputPath = 'artifacts/test-results.xml'
                    $c.TestResult.OutputFormat = 'NUnitXml'
                    Invoke-Pester -Configuration $c
            - name: Publish Report
                uses: dorny/test-reporter@v1
                if: always()
                with:
                    path: artifacts/test-results.xml
                    reporter: java-junit   # Accepts Pester's NUnitXml just fine
                    name: Pester Tests
```

#### 7.4.4 “JUnit” vs “NUnit” Clarification
- Many CI adapters parse both formats similarly; using `reporter: java-junit` with Pester’s `NUnitXml` typically works.
- If a tool rejects the file, verify root element names and schema expectations; transformation is rarely needed.

#### 7.4.5 Optional Lightweight Transform (Only If Required)
If a strict consumer insists on classic JUnit `<testsuite>` root without NUnit metadata:
```powershell
[xml]$doc = Get-Content artifacts/test-results.xml
if ($doc.TestRun) {
    $jdoc = New-Object xml
    $suite = $jdoc.CreateElement('testsuite')
    $jdoc.AppendChild($suite) | Out-Null
    foreach ($result in $doc.TestRun.Results.TestSuite.testcase) {
        $import = $jdoc.ImportNode($result,$true)
        $suite.AppendChild($import) | Out-Null
    }
    $jdoc.Save('artifacts/junit-results.xml')
}
```
Use only if your pipeline tooling truly cannot ingest the standard Pester output.

#### 7.4.6 Common Pitfalls
| Symptom | Cause | Fix |
|---------|-------|-----|
| Empty XML file | Wrong working directory | Run from repo root or use absolute OutputPath |
| CI step can’t find file | Path mismatch or artifact step runs before creation | Echo path & list directory before publish |
| Reporter shows 0 tests | Provided wrong format to tool | Choose junit/nunit plugin matching expectations |
| Multiple test runs overwrite | Same OutputPath reused | Use unique name per phase or single consolidated run |

#### 7.4.7 GitLab CI Example
GitLab’s test report ingestion expects JUnit XML, but it accepts Pester’s `NUnitXml` in most cases. If a strict parser version fails, perform the minimal transform outlined above (rare).

`.gitlab-ci.yml` fragment:
```yaml
stages:
    - test

pester_tests:
    stage: test
    image: mcr.microsoft.com/powershell:7.4-alpine
    script:
        - pwsh -NoLogo -NoProfile -Command "Install-Module Pester -Force -MinimumVersion 5.7.1 -SkipPublisherCheck"
        - pwsh -NoLogo -NoProfile -Command "\n$c = [PesterConfiguration]::Default; \n$c.Run.Path = './tests'; \n$c.TestResult.Enabled = $true; \n$c.TestResult.OutputFormat = 'NUnitXml'; \n$c.TestResult.OutputPath = 'test-results/pester-results.xml'; \nInvoke-Pester -Configuration $c; \nif ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }"
    artifacts:
        when: always
        paths:
            - test-results/pester-results.xml
        reports:
            junit: test-results/pester-results.xml
    allow_failure: false
```

Key Notes:
- `when: always` ensures the XML is still uploaded even if tests fail.
- Keep PowerShell one-liner escaped properly or store script in repo for readability.
- Use `allow_failure: false` so pipeline fails on test failures (default, explicit for clarity).
- For large suites, consider splitting unit/integration jobs and letting GitLab merge multiple JUnit reports.

### 7.5 Micro Exercise
Add a matrix (Windows + Linux) and assert tests pass cross‑platform.

---

## 8. IDE Productivity (Lab 7)

### 8.1 Settings Essentials (`.vscode/settings.json`)
```json
{
    "powershell.pester.useLegacyCodeLens": false,
    "powershell.pester.outputVerbosity": "Detailed",
    "testExplorer.useNativeTesting": true,
    "test.defaultGutterClickAction": "run"
}
```

### 8.2 CodeLens & Gutter
“Run | Debug” above Describe/It; right‑click for isolate run.

### 8.3 Debug Path
Set breakpoint in function → Debug a single test → Inspect variables / call stack.

### 8.4 Auto‑Run Strategy
Turn on Test Explorer auto‑run for fast TDD loops; advise disabling during performance tests.

### 8.5 Micro Exercise
Set a breakpoint inside `Divide()` and debug the division-by-zero test.

---

## 9. Test Smells & Refactoring Patterns

| 🧪 Smell | Example | Why It Hurts | Refactor Strategy |
|----------|---------|--------------|-------------------|
| 🏷️ Vague Name | `It 'Works'` | No behavioral intent | Rename: `It 'Uppercases mixed case input'` |
| 🍲 Assertion Soup | 12 unrelated asserts | Hard to localize failure | Split per invariant |
| 🧪 Over‑Mocking | Mocking pure functions | Tests lose value | Keep core logic real |
| 🎯 Brittle Param Filters | Strict Should -Invoke filters | False negatives | Start broad → tighten |
| 🕵️ Hidden Dependency | Needs env var set | Flaky CI | Inject or mock |
| ⏱️ Time Sleeps | `Start-Sleep 5` | Slow & flaky | Mock time / poll condition |
| ♻️ Duplicate Setup | Repeated object creation | Noise, drift | Move to BeforeEach |
| 🔍 Testing Implementation | Internal calls only | Locks design | Assert observable state |

Refactor Pattern Cheat Codes: Extract Setup → Use Data-Driven Cases → Collapse Repeated Assertions → Introduce Helper Assertions.

---

## 10. Troubleshooting Guide

| 🩺 Symptom | Likely Cause | Fast Fix |
|-----------|--------------|---------|
| ❓ `Unable to find type [PesterConfiguration]` | Pester v5 not imported | `Import-Module Pester -MinimumVersion 5` |
| 🔍 Tests not discovered | Wrong filename | Ensure `*.Tests.ps1` suffix |
| 💤 All tests skipped | Tag filter mismatch | Re-run without `-Tag` / `-ExcludeTag` |
| 🎯 Mock not invoked | Parameter filter mismatch | Remove filter; echo params |
| 📄 Coverage file empty | Wrong File Path Pattern | Use `./src/*.ps1` (run from repo root) |
| ⏱️ Flaky timing tests | Real time dependency | Mock/inject clock |
| 🧭 Debugger not hitting | Different process / shell | Use integrated console |

---

## 11. Best Practices Checklist
```
[ ] Tests describe observable behavior (not implementation details)
[ ] One focused behavior per It (or cohesive invariant cluster)
[ ] AAA pattern visible (comments or spacing)
[ ] Includes negative & boundary tests
[ ] External dependencies mocked selectively
[ ] No sleeps / timing hacks in unit tests
[ ] Uses -Because for non-obvious assertions
[ ] Configuration centralized (no duplicated ad-hoc options)
[ ] Coverage tracked for critical paths (not chasing 100%)
[ ] Fast feedback (<5s unit suite) maintained
```

---

## 12. Practice Set (Optional Class Exercises)

| Exercise | Goal | Time |
|----------|------|------|
| Write failing test for new formatter | Reinforce RED start | 5m |
| Add validation (null / empty / pattern) | Negative path practice | 6m |
| Introduce mock for network call | Isolation skill | 8m |
| Convert multi-assert test to table test | Data-driven refactor | 7m |
| Add performance guard | Non-functional awareness | 6m |
| Add coverage & threshold to config | Quality gate thinking | 5m |

---

## 13. Exit Assessment (Optional)
Test your understanding by completing these tasks:
1. Write a test using -Because meaningfully.
2. Identify one test smell from earlier code and refactor it.
3. Explain when NOT to mock (one sentence).
4. Add a coverage threshold to a config snippet.
5. Show a failing boundary case you added that previously passed silently.

Scoring Rubric (quick):
- 5 = Ready for independent application
- 3–4 = Minor reinforcement needed
- 0–2 = Schedule review / pairing

---

## 14. Advanced Topics (Pointers Only)
| 🚀 Topic | Why It Matters | Next Step |
|---------|----------------|-----------|
| 🧩 Custom Assertion Functions | Domain expressiveness | Wrap recurring patterns |
| 🏗️ Testing DSC / Infrastructure | Declarative validation | Semantic resource tests |
| 🧵 Parallel Test Execution | Suite speed | Tag segmentation & isolation audit |
| 🧬 Mutation Testing | Assertion robustness | Explore Stryker concepts |
| 📜 Contract / API Schema Validation | Change detection | Schema snapshot testing |

---

## 15. Lab Reference Mapping
| Section in This Guide | Origin Lab Sections (Links) |
|-----------------------|-----------------------------|
| Fundamentals / Operators | [Lab 1](./Lab1/Lab1.md) |
| Test Design / AAA / Data Cases | [Lab 2](./Lab2/Lab2.md) |
| Mocking / Integration Boundary | [Lab 3](./Lab3/Lab3.md) |
| Performance & Resources | [Lab 4](./Lab4/Lab4.md) |
| Class/Object Testing | [Lab 5](./Lab5/Lab5.md) |
| CI/CD Automation / Gates | [Lab 6](./Lab6/Lab6.md) |
| IDE Productivity | [Lab 7](./Lab7/Lab7.md) |

---

## 16. Minimal vs Full Example Recap
```powershell
# Minimal smoke run
Invoke-Pester -Path .\tests

# Full (CI)
$cfg = [PesterConfiguration]::Default
$cfg.Run.Path = './tests'
$cfg.Output.Verbosity = 'Detailed'
$cfg.TestResult.Enabled = $true
$cfg.TestResult.OutputPath = './test-results.xml'
$cfg.CodeCoverage.Enabled = $true
$cfg.CodeCoverage.Path = './src/*.ps1'
Invoke-Pester -Configuration $cfg
```

---

## 17. Content Flow Suggestion
1. Quick Start (5m)
2. Fundamentals & Operators (25m)
3. Break (5m)
4. Test Design + Data Cases (25m)
5. Mocking & Integration (30m)
6. Performance + Classes (25m)
7. CI/CD + IDE (30m)
8. Practice + Exit Ticket (20m)

Adjust times based on audience familiarity.

---

---

## 18. Glossary (Quick Reference)
| Term | Definition |
|------|------------|
| AAA | Arrange, Act, Assert – structuring a test for clarity |
| AfterAll / AfterEach | Cleanup hooks (suite once / per test) |
| Assertion | Statement verifying expected behavior (via Should) |
| Boundary Test | Validates edge limits (min, max, off‑by‑one) |
| Code Coverage | % of executed lines during test run (heuristic, not goal) |
| Context | Logical grouping within a Describe for scenario clarity |
| Deterministic | Produces same output for same input consistently |
| Describe | Top-level grouping of related behaviors |
| Fixture | Shared setup state for a suite (created in BeforeAll / BeforeEach) |
| Idempotent | Operation yielding same result even when repeated |
| Invariant | Condition expected to hold true across executions/states |
| Mock | Substituted implementation of a dependency for isolation |
| Mutant (Mutation Testing) | Intentional code change to test assertion strength |
| Red-Green-Refactor | TDD loop: fail first -> pass -> improve |
| Should Operator | DSL keyword performing an assertion (e.g., -Be, -Throw) |
| Test Smell | Pattern indicating maintainability or reliability issue |
| TDD | Test-Driven Development methodology |
| Unit Test | Tests a small unit (function/class) in isolation |
| Integration Test | Exercises real dependencies collaboratively |
| Tag | Metadata label enabling selective test execution |
| Quality Gate | Automated pass/fail threshold (coverage %, failures) |

---

**End of Workshop Edition**


### Test Driven Development (TDD) Cycle

The foundation of all testing - the **Red-Green-Refactor** cycle:

```powershell
# 1. RED - Write a failing test first
Describe 'ConvertTo-Uppercase' {
    It 'Converts lowercase string to uppercase' {
        ConvertTo-Uppercase -text 'hello' | Should -Be 'HELLO'
    }
}

# 2. GREEN - Write minimal code to pass
function ConvertTo-Uppercase {
    param($text)
    $text.ToUpper()
}

# 3. REFACTOR - Improve while keeping tests passing
function ConvertTo-Uppercase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Text
    )
    process {
        foreach ($item in $Text) {
            $item.ToUpper()
        }
    }
}
```

### Pester v5 Core Commands and Structure

Essential Pester v5 commands for organizing and executing tests:

#### Test Organization Commands

```powershell
# Describe - Top-level test container (required)
Describe 'Function or Feature Name' {
    # All tests for this function/feature go here
}

# Context - Logical grouping within Describe (optional but recommended)
Context 'When testing specific scenario' {
    # Related tests go here
}

# It - Individual test case (required)
It 'Should behave in expected way' {
    # Single test assertion
}
```

#### Setup and Teardown Commands

```powershell
# BeforeAll - Runs once before all tests in the block
BeforeAll {
    # Load modules, import functions, set up test environment
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
    $script:testData = @('item1', 'item2', 'item3')
}

# BeforeEach - Runs before each individual test
BeforeEach {
    # Set up fresh test state for each test
    $script:calculator = [Calculator]::new()
    $script:tempFile = New-TemporaryFile
}

# AfterEach - Runs after each individual test (cleanup)
AfterEach {
    # Clean up test resources
    if ($script:tempFile -and (Test-Path $script:tempFile)) {
        Remove-Item $script:tempFile -Force
    }
}

# AfterAll - Runs once after all tests in the block
AfterAll {
    # Final cleanup
    Remove-Module TestModule -Force -ErrorAction SilentlyContinue
}
```

#### Test Execution Commands

```powershell
# Basic test execution
Invoke-Pester

# Run specific test file
Invoke-Pester -Path ".\MyFunction.Tests.ps1"

# Run with detailed output
Invoke-Pester -Path ".\MyFunction.Tests.ps1" -Output Detailed

# Run tests with specific tags
Invoke-Pester -Tag 'Unit', 'Fast'

# Exclude tests with specific tags
Invoke-Pester -ExcludeTag 'Slow', 'Integration'
```

#### Pester v5 Configuration Object

```powershell
# Modern Pester v5 configuration approach
$config = [PesterConfiguration]::Default

# Basic configuration
$config.Run.Path = './tests'
$config.Output.Verbosity = 'Detailed'
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = './test-results.xml'

# Code coverage configuration
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = './src/*.ps1'
$config.CodeCoverage.OutputPath = './coverage.xml'

# Execute with configuration
Invoke-Pester -Configuration $config
```

### Core Should Operators

List of Pester v5 assertion operators:

#### Equality Operators

```powershell
# Basic equality
$result | Should -Be 'expected'              # Loose equality
$result | Should -BeExactly 'Expected'       # Case-sensitive equality
$result | Should -Not -Be 'unexpected'       # Negation

# Numeric comparisons
$number | Should -BeGreaterThan 10
$number | Should -BeGreaterOrEqual 10
$number | Should -BeLessThan 100
$number | Should -BeLessOrEqual 100
$number | Should -BeIn @(1, 2, 3, 4, 5)     # Value in collection
```

#### Type and Null Operators

```powershell
# Type validation
$result | Should -BeOfType [string]
$result | Should -BeOfType [System.DateTime]
$object | Should -HaveType 'System.Collections.Hashtable'

# Null and empty testing
$result | Should -BeNullOrEmpty
$result | Should -Not -BeNullOrEmpty
$result | Should -BeNull
$result | Should -Not -BeNull
```

#### Collection Operators

```powershell
# Collection testing
$array | Should -HaveCount 5
$array | Should -Contain 'specific item'
$array | Should -Not -Contain 'missing item'
$array | Should -BeIn $largerArray

# All items match condition
$numbers | Should -AllBe { $_ -gt 0 }        # All positive numbers
$strings | Should -AllMatch '^[A-Z]'        # All start with capital
```

#### String Operators

```powershell
# Pattern matching
$text | Should -Match 'regex pattern'
$text | Should -MatchExactly 'case-sensitive pattern'
$text | Should -Not -Match 'absent pattern'

# String content
$string | Should -BeLike '*partial*'
$string | Should -BeLikeExactly '*Partial*'
$string | Should -FileContentMatch 'pattern'  # For file content
```

#### Boolean and Logic Operators

```powershell
# Boolean testing
$result | Should -BeTrue
$result | Should -BeFalse
$result | Should -Not -BeTrue

# Existence testing
$path | Should -Exist                        # File/folder exists
$path | Should -Not -Exist
```

#### Exception Testing

```powershell
# Exception assertion
{ Get-Process 'NonExistentProcess' } | Should -Throw
{ Get-Process 'NonExistentProcess' } | Should -Throw -ExpectedMessage '*Cannot find*'
{ Get-Process 'NonExistentProcess' } | Should -Throw -ExceptionType 'System.Management.Automation.ActionPreferenceStopException'

# No exception expected
{ Get-Date } | Should -Not -Throw
```

#### Custom Operators with -Because

```powershell
# All operators support -Because for meaningful error messages
$result | Should -Be 'expected' -Because 'the function should handle this specific input correctly'
$array | Should -HaveCount 3 -Because 'all three items should be processed'
{ $function.call() } | Should -Throw -Because 'invalid parameters should cause an error'
```

### Advanced Should Usage Patterns

#### Multiple Assertions

```powershell
It 'Should validate all properties' {
    $user = Get-User -Id 123
    
    # Multiple related assertions
    $user.Name | Should -Not -BeNullOrEmpty -Because 'user must have a name'
    $user.Email | Should -Match '\w+@\w+\.\w+' -Because 'email must be valid format'
    $user.Created | Should -BeOfType [DateTime] -Because 'creation date must be DateTime'
    $user.IsActive | Should -BeTrue -Because 'new users should be active by default'
}
```

#### Pipeline Assertions

```powershell
It 'Should process array correctly' {
    $numbers = 1..5
    
    # Pipeline assertion
    $numbers | ConvertTo-String | Should -All -Match '^\d+$' -Because 'all should be numeric strings'
}
```

#### Parameterized Assertions

```powershell
It 'Should validate email format for <Email>' -TestCases @(
    @{ Email = 'test@example.com'; Expected = $true }
    @{ Email = 'invalid.email'; Expected = $false }
    @{ Email = '@domain.com'; Expected = $false }
) {
    param($Email, $Expected)
    
    $result = Test-EmailFormat -Email $Email
    $result | Should -Be $Expected -Because "email '$Email' validation should return $Expected"
}
```

### Test Tags and Organization

```powershell
# Tag usage for test organization
Describe 'Get-User Function' -Tag @('Unit', 'UserManagement', 'Fast') {
    Context 'When user exists' -Tag 'HappyPath' {
        It 'Should return user object' -Tag 'Critical' {
            # Test implementation
        }
    }
    
    Context 'When user does not exist' -Tag 'ErrorHandling' {
        It 'Should throw meaningful error' -Tag 'Critical' {
            # Test implementation
        }
    }
}

# Run only critical tests
Invoke-Pester -Tag 'Critical'

# Run everything except slow tests
Invoke-Pester -ExcludeTag 'Slow', 'Integration'
```

### Basic Test Structure

Essential Pester v5 syntax and organization:

```powershell
#Requires -Modules @{ ModuleName="Pester"; MaximumVersion="5.7.1" }

BeforeAll {
    # Load code under test
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
}

Describe 'Function Name' -Tags @('Unit', 'Function') {
    Context 'When testing specific scenario' {
        It 'Should behave in expected way' {
            # Test assertion here
            $result | Should -Be $expected
        }
    }
}
```

### Parameter Validation Testing Examples

Real-world parameter validation patterns from the labs:

```powershell
Context 'Parameter validation' {
    It 'Should throw when parameter is null' {
        { ConvertTo-Uppercase -text $null } | Should -Throw -Because 'null input is not valid'
    }
    
    It 'Should throw when parameter is empty' {
        { ConvertTo-Uppercase -text '' } | Should -Throw -Because 'empty string is not valid'
    }
    
    It 'Should throw error on number input' {
        { ConvertTo-Uppercase -text 123 } | Should -Throw -Because 'numbers are not allowed'
    }
    
    It 'Should throw error on input with numbers' {
        { ConvertTo-Uppercase -text 'hello123' } | Should -Throw -Because 'mixed alphanumeric not allowed'
    }
    
    It 'Should throw error with special characters' {
        { ConvertTo-Uppercase -text 'hello@world' } | Should -Throw -Because 'special characters not allowed'
    }
    
    It 'Should accept input with only letters and spaces' {
        { ConvertTo-Uppercase -text 'hello world' } | Should -Not -Throw -Because 'letters and spaces are valid'
    }
}
```

### Array and Pipeline Testing

Testing functions that handle arrays and pipeline input:

```powershell
Context 'When given an array of strings' {
    It 'Should convert each string in the array to uppercase' {
        # Arrange
        $input = @('hello', 'world')
        $expected = @('HELLO', 'WORLD')
        
        # Act & Assert
        ConvertTo-Uppercase -text $input | Should -BeExactly $expected
    }
    
    It 'Should handle mixed case array elements' {
        # Arrange
        $testInput = @('HeLLo', 'WoRLd', 'test')
        $expected = @('HELLO', 'WORLD', 'TEST')
        
        # Act & Assert
        ConvertTo-Uppercase -text $testInput | Should -BeExactly $expected
    }
    
    It 'Should accept pipeline input' {
        # Arrange
        $testStrings = @('hello', 'world')
        
        # Act & Assert
        $result = $testStrings | ConvertTo-Uppercase
        $result | Should -HaveCount 2 -Because 'pipeline input should be processed'
    }
}
```

### Edge Case Testing Patterns

Edge case testing strategies:

```powershell
Context 'Edge cases' {
    It 'Should handle single space' {
        ConvertTo-Uppercase -text ' ' | Should -Be ' '
    }
    
    It 'Should handle multiple spaces' {
        ConvertTo-Uppercase -text '   ' | Should -Be '   '
    }
    
    It 'Should handle strings with leading and trailing spaces' {
        ConvertTo-Uppercase -text ' hello world ' | Should -Be ' HELLO WORLD '
    }
    
    It 'Should handle single character strings' {
        ConvertTo-Uppercase -text 'a' | Should -Be 'A'
    }
    
    It 'Should return same string if already uppercase' {
        ConvertTo-Uppercase -text 'ALREADY UPPER' | Should -Be 'ALREADY UPPER'
    }
    
    It 'Should handle empty array input' {
        $result = ConvertTo-Uppercase -text @()
        $result | Should -BeNullOrEmpty
    }
}
```

### Test Execution and Reporting

Professional test execution with Pester v5 configuration:

```powershell
# Create comprehensive test runner script
[CmdletBinding()]
param(
    [switch]$CodeCoverage,
    [string]$OutputPath = $PSScriptRoot
)

# Import Pester v5
Import-Module Pester -Force

# Create Pester configuration object
$config = [PesterConfiguration]::Default
$config.Run.Path = Join-Path $PSScriptRoot "*.Tests.ps1"
$config.Run.PassThru = $true
$config.Output.Verbosity = 'Detailed'

# Configure test results
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.TestResult.OutputPath = Join-Path $OutputPath "testresults.xml"

# Configure code coverage if requested
if ($CodeCoverage) {
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = Join-Path $PSScriptRoot "*.ps1"
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
```

### Legacy vs Modern Pester Syntax

Understanding the differences between Pester v4 and v5:

```powershell
# ❌ Pester v4 (Legacy) - Avoid
Assert-MockCalled Get-Process -Exactly 1
$result | Should Be 'expected'
New-PesterOption -IncludeVSCodeMarker

# ✅ Pester v5 (Modern) - Use This
Should -Invoke Get-Process -Exactly 1
$result | Should -Be 'expected'
[PesterConfiguration]::Default
```

---

## 🎯 Advanced Testing Patterns (Lab 2)

### Arrange-Act-Assert (AAA) Pattern

The gold standard for clear, maintainable tests:

```powershell
It 'Should extract valid email addresses from text' {
    # Arrange - Set up test data and conditions
    $text = 'Contact john.doe@example.com or jane@test.org'
    $expectedEmails = @('john.doe@example.com', 'jane@test.org')
    
    # Act - Execute the function under test
    $result = Get-EmailAddress -string $text
    
    # Assert - Verify the outcome with meaningful messages
    $result | Should -HaveCount 2 -Because 'text contains exactly two valid email addresses'
    $result | Should -Contain 'john.doe@example.com' -Because 'first email should be extracted'
    $result | Should -Contain 'jane@test.org' -Because 'second email should be extracted'
}
```

### Parameter Validation Testing

Comprehensive testing of function parameters and validation:

```powershell
Context 'Parameter validation' {
    It 'Should throw when string parameter is null' {
        { Get-EmailAddress -string $null } | Should -Throw -Because 'null input is not valid'
    }
    
    It 'Should throw when string parameter is empty' {
        { Get-EmailAddress -string '' } | Should -Throw -Because 'empty string is not valid'
    }
    
    It 'Should accept pipeline input' {
        $testStrings = @('test@example.com', 'another@test.org')
        $result = $testStrings | Get-EmailAddress
        $result | Should -HaveCount 2 -Because 'pipeline input should be processed'
    }
}
```

### Edge Case Testing

Testing boundary conditions and unusual inputs:

```powershell
Context 'Edge cases and special scenarios' {
    It 'Should handle text with no email addresses' {
        $result = Get-EmailAddress -string 'No emails here just text'
        $result | Should -BeNullOrEmpty -Because 'text without emails should return empty'
    }
    
    It 'Should handle multiple emails on same line' {
        $text = 'user1@test.com user2@test.com user3@test.com'
        $result = Get-EmailAddress -string $text
        $result | Should -HaveCount 3 -Because 'all emails should be extracted'
    }
    
    It 'Should remove duplicate email addresses' {
        $text = 'test@example.com and test@example.com again'
        $result = Get-EmailAddress -string $text
        $result | Should -HaveCount 1 -Because 'duplicates should be removed'
    }
}
```

---

## 🔧 Mocking & Integration Testing (Lab 3)

### Understanding Mocking

Mocking isolates your code from external dependencies:

```powershell
BeforeAll {
    # Mock external dependencies
    Mock Get-ADComputer {
        return @(
            @{ Name = 'SERVER01' },
            @{ Name = 'SERVER02' },
            @{ Name = 'WORKSTATION01' }
        )
    }
}

Context 'When testing with mocked dependencies' {
    It 'Should call Get-ADComputer with correct filter' {
        Get-LabComputers -timeout 30
        
        # Verify the mock was called correctly
        Should -Invoke Get-ADComputer -Exactly 1 -ParameterFilter {
            $Filter -eq '*'
        }
    }
}
```

### Advanced Mock Scenarios

Complex mocking with parameter filtering and conditional behavior:

```powershell
BeforeAll {
    # Mock with conditional responses
    Mock Test-Connection {
        param($ComputerName, $Count, $Quiet)
        
        # Return true for specific computers, false for others
        switch ($ComputerName) {
            'SERVER01' { return $true }
            'SERVER02' { return $true }
            default { return $false }
        }
    } -ParameterFilter { $Quiet -eq $true -and $Count -eq 1 }
}

It 'Should only return responding computers' {
    $result = Get-LabComputers -Computers @('SERVER01', 'SERVER02', 'OFFLINE01')
    
    $result | Should -HaveCount 2 -Because 'only responding computers should be returned'
    $result | Should -Contain 'SERVER01'
    $result | Should -Contain 'SERVER02'
    $result | Should -Not -Contain 'OFFLINE01'
}
```

### Unit vs Integration Testing

Understanding when to mock vs when to test real integrations:

```powershell
# Unit Test - Mock all external dependencies
Describe 'Get-LabComputers Unit Tests' {
    BeforeAll {
        Mock Get-ADComputer { return @(@{Name='TEST01'}) }
        Mock Test-Connection { return $true }
    }
    
    It 'Should filter current computer' {
        $result = Get-LabComputers
        $result | Should -Not -Contain $env:COMPUTERNAME
    }
}

# Integration Test - Test with real dependencies
Describe 'Get-LabComputers Integration Tests' -Tag 'Integration' {
    It 'Should work with real Active Directory' -Skip:(-not (Get-Module ActiveDirectory -ListAvailable)) {
        $result = Get-LabComputers -timeout 10
        $result | Should -BeOfType [array]
    }
}
```

---

## ⚡ Performance Testing (Lab 4)

### Execution Time Testing

Measuring and validating function performance:

```powershell
Context 'Performance benchmarks' {
    It 'Should complete within acceptable time limits' {
        $testData = 1..1000
        
        # Measure execution time
        $executionTime = Measure-Command {
            $result = Invoke-DataProcessor -InputData $testData -BatchSize 100
        }
        
        # Assert performance requirements
        $executionTime.TotalSeconds | Should -BeLessThan 5 -Because 'function should complete within 5 seconds'
        $result | Should -HaveCount 1000 -Because 'all items should be processed'
    }
}
```

### Memory Usage Monitoring

Testing memory efficiency and leak detection:

```powershell
It 'Should not consume excessive memory' {
    # Get baseline memory
    $beforeMemory = [GC]::GetTotalMemory($false)
    
    # Execute function with large dataset
    $largeData = 1..10000
    $result = Invoke-DataProcessor -InputData $largeData
    
    # Force garbage collection
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    $afterMemory = [GC]::GetTotalMemory($true)
    
    # Calculate memory usage
    $memoryUsed = ($afterMemory - $beforeMemory) / 1MB
    $memoryUsed | Should -BeLessThan 50 -Because 'function should not use more than 50MB'
}
```

### Parallel Processing Testing

Validating concurrent execution and thread safety:

```powershell
Context 'Parallel processing' {
    It 'Should be faster with parallel processing for large datasets' {
        $largeData = 1..5000
        
        # Test sequential processing
        $sequentialTime = Measure-Command {
            Invoke-DataProcessor -InputData $largeData -UseParallel:$false
        }
        
        # Test parallel processing
        $parallelTime = Measure-Command {
            Invoke-DataProcessor -InputData $largeData -UseParallel:$true
        }
        
        # Parallel should be significantly faster
        $parallelTime.TotalSeconds | Should -BeLessThan ($sequentialTime.TotalSeconds * 0.8) -Because 'parallel processing should be at least 20% faster'
    }
}
```

---

## 📦 Class Testing (Lab 5)

### Constructor Testing

Validating object instantiation and initialization:

```powershell
Describe 'Task Class Tests' {
    Context 'Constructor Tests' {
        It 'Should create task with title and description' {
            # Arrange & Act
            $task = [Task]::new('Test Task', 'Test Description')
            
            # Assert
            $task.Title | Should -Be 'Test Task'
            $task.Description | Should -Be 'Test Description'
            $task.IsCompleted | Should -Be $false
            $task.Id | Should -BeGreaterThan 0
        }
        
        It 'Should create task with custom due date' {
            # Arrange
            $customDate = (Get-Date).AddDays(14)
            
            # Act
            $task = [Task]::new('Test Task', 'Test Description', $customDate)
            
            # Assert
            $task.DueDate.Date | Should -Be $customDate.Date
        }
    }
}
```

### Property Validation Testing

Testing property behavior and constraints:

```powershell
Context 'Property Tests' {
    BeforeEach {
        $script:task = [Task]::new('Sample Task', 'Sample Description')
    }
    
    It 'Should have correct property types' {
        $task.Id | Should -BeOfType [int]
        $task.Title | Should -BeOfType [string]
        $task.IsCompleted | Should -BeOfType [bool]
        $task.CreatedDate | Should -BeOfType [datetime]
    }
    
    It 'Should have creation date close to current time' {
        $timeDiff = (Get-Date) - $task.CreatedDate
        $timeDiff.TotalSeconds | Should -BeLessThan 5 -Because 'creation date should be recent'
    }
}
```

### Method Behavior Testing

Testing class methods and business logic:

```powershell
Context 'Method Tests' {
    BeforeEach {
        $script:task = [Task]::new('Test Task', 'Test Description')
    }
    
    It 'Should mark task as completed' {
        # Arrange - task starts incomplete
        $task.IsCompleted | Should -Be $false
        
        # Act
        $task.Complete()
        
        # Assert
        $task.IsCompleted | Should -Be $true
    }
    
    It 'Should detect overdue tasks' {
        # Arrange - set due date in the past
        $task.DueDate = (Get-Date).AddDays(-1)
        
        # Act & Assert
        $task.IsOverdue() | Should -BeTrue -Because 'task due date is in the past'
    }
}
```

---

## 🔄 CI/CD Integration (Lab 6)

### GitHub Actions Workflow

Automated testing across multiple platforms:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        powershell: ['7.4.0']
    
    runs-on: ${{ matrix.os }}
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Install PowerShell
      shell: bash
      run: |
        if [ "${{ matrix.os }}" == "ubuntu-latest" ]; then
          sudo apt-get update
          sudo apt-get install -y wget apt-transport-https software-properties-common
          source /etc/os-release
          wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
          sudo dpkg -i packages-microsoft-prod.deb
          sudo apt-get update
          sudo apt-get install -y powershell
        fi
    
    - name: Install Pester
      shell: pwsh
      run: |
        Install-Module Pester -Force -MinimumVersion 5.7.1 -SkipPublisherCheck
    
    - name: Run Tests
      shell: pwsh
      run: |
        $config = [PesterConfiguration]::Default
        $config.Run.Path = './tests'
        $config.Output.Verbosity = 'Detailed'
        $config.TestResult.Enabled = $true
        $config.TestResult.OutputPath = './test-results.xml'
        $config.CodeCoverage.Enabled = $true
        $config.CodeCoverage.Path = './src/*.ps1'
        Invoke-Pester -Configuration $config
```

### Test Result Reporting

Publishing test results and coverage:

```yaml
    - name: Publish Test Results
      uses: dorny/test-reporter@v1
      if: always()
      with:
        name: Pester Tests (${{ matrix.os }})
        path: test-results.xml
        reporter: java-junit
    
    - name: Upload Coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml
        flags: unittests
        name: codecov-umbrella
```

### Quality Gates

Implementing automated quality checks:

```powershell
# Quality gate configuration
$config = [PesterConfiguration]::Default
$config.Run.Path = './tests'
$config.Output.Verbosity = 'Detailed'
$config.TestResult.Enabled = $true
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.CoveragePercentTarget = 80  # Require 80% coverage

$result = Invoke-Pester -Configuration $config

# Fail build if quality gates not met
if ($result.FailedCount -gt 0) {
    throw "Tests failed: $($result.FailedCount) failed tests"
}

if ($result.CodeCoverage.CoveragePercent -lt 80) {
    throw "Coverage too low: $($result.CodeCoverage.CoveragePercent)% (minimum: 80%)"
}
```

---

## 🛠️ IDE Integration (Lab 7)

### VS Code Test Explorer Setup

Configuring VS Code for optimal Pester testing experience:

```json
// .vscode/settings.json
{
    "powershell.pester.useLegacyCodeLens": false,
    "powershell.pester.outputVerbosity": "Detailed",
    "testExplorer.useNativeTesting": true,
    "powershell.integratedConsole.showOnStartup": false,
    "files.associations": {
        "*.Tests.ps1": "powershell"
    },
    "test.defaultGutterClickAction": "run"
}
```

### CodeLens Integration

Running tests directly from code editor:

```powershell
# CodeLens appears above each test block
Describe 'Calculator Tests' {          # <- "Run Tests" | "Debug Tests"
    It 'Should add numbers' {          # <- "Run Test" | "Debug Test"
        $calc = [Calculator]::new()
        $result = $calc.Add(2, 3)
        $result | Should -Be 5
    }
}
```

### Test Discovery and Navigation

Automatic test organization in Test Explorer:

```
Test Explorer View:
├── 📁 Calculator.Tests.ps1
│   ├── 📁 Calculator Class Tests
│   │   ├── 📁 Basic Operations
│   │   │   ├── ✅ Should add two numbers correctly
│   │   │   ├── ✅ Should subtract two numbers correctly
│   │   │   └── ✅ Should multiply two numbers correctly
│   │   └── 📁 Division Operations
│   │       ├── ✅ Should divide two numbers correctly
│   │       └── ❌ Should throw error when dividing by zero
└── 📁 StringUtils.Tests.ps1
    └── 📁 String Utilities Tests
        ├── 📁 Email Validation
        └── 📁 Phone Number Formatting
```

### Debugging Integration

Setting breakpoints and debugging tests:

```powershell
# Set breakpoint in source code
function Divide([double] $a, [double] $b) {
    if ($b -eq 0) {              # <- Breakpoint here
        throw "Cannot divide by zero"
    }
    return $a / $b
}

# Debug test will stop at breakpoint
It 'Should throw error when dividing by zero' {
    { $calc.Divide(10, 0) } | Should -Throw "Cannot divide by zero"
}
```

### Continuous Testing

Auto-run tests on file changes:

```powershell
# Tests automatically run when files are saved
# Immediate feedback in Test Explorer
# Failed tests appear in Problems panel
# Coverage gutters show tested/untested lines
```

---

## 🎯 Key Takeaways

### Testing Progression

1. **Start Simple** - Basic TDD with Lab 1 fundamentals
2. **Add Structure** - AAA pattern and comprehensive assertions from Lab 2
3. **Isolate Dependencies** - Mocking and integration strategies from Lab 3
4. **Measure Performance** - Execution time and memory testing from Lab 4
5. **Test Objects** - Class and method testing from Lab 5
6. **Automate Everything** - CI/CD pipelines from Lab 6
7. **Enhance Productivity** - IDE integration from Lab 7

### Best Practices Summary

```powershell
# 1. Use descriptive test names
It 'Should convert lowercase string to uppercase when given valid input' { }

# 2. Follow AAA pattern
It 'Should extract email addresses' {
    # Arrange
    $input = 'Contact test@example.com for help'
    
    # Act
    $result = Get-EmailAddress -String $input
    
    # Assert
    $result | Should -Contain 'test@example.com'
}

# 3. Use meaningful assertions with -Because
$result | Should -Be 'EXPECTED' -Because 'function should handle this specific case'

# 4. Group related tests with Context
Context 'When testing edge cases' {
    # Related edge case tests here
}

# 5. Mock external dependencies
Mock Get-ADComputer { return @(@{Name='TEST'}) }

# 6. Test both positive and negative scenarios
It 'Should work with valid input' { }
It 'Should throw with invalid input' { }

# 7. Use tags for test organization
Describe 'Function' -Tag @('Unit', 'Fast', 'Critical') { }
```

### Testing Hierarchy

- **Unit Tests** - Fast, isolated, mocked dependencies
- **Integration Tests** - Real dependencies, slower, more realistic
- **Performance Tests** - Measure speed and memory usage
- **End-to-End Tests** - Full system testing in CI/CD
- **Interactive Testing** - IDE integration for development workflow

This progression from basic TDD concepts to advanced CI/CD integration and IDE productivity tools provides a solid foundation for PowerShell testing mastery.

---

## 🧪 Avoiding Common Test Smells

The following table summarizes frequent test design anti-patterns ("test smells"), why they hurt maintainability, and what to do instead. Use it as a review checklist during refactors and code reviews.

| Test Smell | Description | Why It Hurts | Preferred Remedy / Refactor Pattern |
|------------|-------------|--------------|--------------------------------------|
| Assertion Roulette | A test method has multiple undocumented assertions, making it unclear which one fails and why, reducing readability and maintainability. | Slows triage; increases cognitive load. | Add `-Because` messages, split into focused tests (1 invariant), or use descriptive helper assertions. |
| Conditional Test Logic | Tests include conditional statements (e.g., if/else) that change behavior or expected outcomes, leading to non-deterministic results and missed defects. | Masks failures; creates hidden branches. | Remove logic; parametrize with `-TestCases`; skip only for environment preconditions. |
| Constructor Initialization | Using a test class constructor (or global script body) for setup instead of explicit lifecycle hooks. | Hidden coupling, unclear lifecycle. | Use `BeforeAll` / `BeforeEach`; keep setup explicit, minimal. |
| Default Test | Leftover template tests (e.g., ExampleUnitTest) not removed or renamed. | Noise; attracts unrelated assertions. | Delete or rename with purpose; resist turning into a catch‑all. |
| Duplicate Assert | Re-testing the same condition in one test (often copy/paste). | Redundant noise; hides missing coverage. | Remove duplicates; consolidate or split distinct behaviors. |
| Eager Test | A single test invokes multiple system behaviors (many method calls). | Hard to localize failure; brittle. | Decompose into scenario-focused tests; assert one behavioral contract. |
| Empty Test | A test body with no executable statements. | False sense of coverage. | Delete or implement; fail deliberately if placeholder. |
| Exception Handling | Manually catching exceptions instead of using framework assertion. | Obscures failure semantics. | Use `{ } | Should -Throw -ErrorId/-Message` directly. |
| General Fixture | Setup creates objects most tests don't use. | Wasteful; hides intent; increases maintenance. | Narrow fixture; build only what's needed per test (Factory/Builder if repeated). |
| Ignored Test | Permanently skipped/ignored tests lingering in suite. | Test rot; stale expectations. | Track with backlog item; either fix, delete, or re-enable with justification. |
| Lazy Test | Multiple tests call the exact same method with trivial variations but assert little. | Superficial coverage illusion. | Collapse into data-driven cases with meaningful assertion expansion. |
| Magic Number Test | Hardcoded numbers without domain meaning. | Poor readability; fragile on spec change. | Replace with named constants or variables that express intent. |
| Mystery Guest | Test relies on external resource (file/DB/network) without mocking. | Flaky; slow; environment-dependent. | Mock boundary, inject dependency, or provide in-memory test double. |
| Redundant Print | Leftover Write-Host / logging used for debugging. | Noise in output; hides real failures. | Remove or convert to assertion; use diagnostics only when needed. |
| Redundant Assertion | Assertions that are always true/false (e.g., `Should -BeTrue` on `$true`). | Adds no value; hides missing assertions. | Delete or replace with meaningful invariant check. |
| Resource Optimism | Assumes resource exists (file, secret, module) without validation. | Unpredictable failures; misleading pass/fail. | Add explicit precondition guard or mock resource. |
| Sensitive Equality | Comparing via `ToString()` output. | Brittle to formatting changes. | Implement explicit structural comparison or domain equality function. |
| Sleepy Test | Uses `Start-Sleep` to wait for async completion. | Slow & race-prone; nondeterministic. | Poll with timeout, or await task completion/mocks. |
| Unknown Test | No assertions or vague name ('Test1'). | Intent unclear; can't maintain. | Rename descriptively and add meaningful assertion—or remove. |

### Quick Remediation Flow
1. Detect smell during review.
2. Classify (readability, determinism, isolation, performance, redundancy).
3. Apply smallest safe refactor (split test, extract helper, introduce mock, add assertions).
4. Re-run suite; ensure coverage did not regress.

### Automation Tip
Integrate a periodic "test hygiene" review—treat this table like a linter checklist. Add meta-tests or scripts to:
- Fail build if placeholder / empty tests found.
- Warn on `Start-Sleep` outside approved helpers.
- Flag tests containing multiple `Should` without `-Because`.

---

**Next Action:** Pick 2–3 candidate smells in your current suite and schedule a cleanup pass—small improvements compound.
