# Pester Labs – Printable Handout (Condensed)

This handout distills the Teaching Edition for learner reference. Code blocks abbreviated; see full summary for detail.

---
## Quick Start
Describe->Context->It. Use Should for assertions.
Example flow: Write failing test -> minimal implementation -> refactor safely.

Minimal pattern:
Describe 'Thing' { It 'Does X' { Command | Should -Be Expected } }

---
## TDD Loop
Red -> Green -> Refactor. Keep first test tiny.

---
## Core Block Anatomy
Describe (group) / Context (scenario) / It (spec) / BeforeAll/Each / AfterAll/Each.

---
## Core 10 Operators
-Be, -BeExactly, -BeOfType, -Throw, -Contain, -HaveCount, -Match, -BeNullOrEmpty, -BeGreaterThan, -BeTrue/-BeFalse.

---
## Operator Categories 
Equality (-Be / -BeExactly) | Collections (-HaveCount / -Contain / -AllBe) | Types (-BeOfType) | Strings (-Match) | Null (-BeNullOrEmpty) | Numeric (-BeGreaterThan) | Exceptions (-Throw) | Existence (-Exist).

---
## Configuration Progression
Invoke-Pester -Path ./tests
Use [PesterConfiguration] for coverage, test results, verbosity.

---
## Assertion Design
AAA pattern. One primary behavior per test. Use -Because for rationale.
Data-driven: -TestCases for variance.

---
## Edge & Negative Cases
Null, empty, invalid format, boundary, duplicates, ordering.

---
## Mocking (When)
External systems, non-deterministic, slow/costly, destructive, hard-to-trigger states.
Avoid mocking pure logic.

Smells: Over-mocking, verifying only calls, brittle parameter filters.

---
## Performance
Measure-Command for timing. Memory via [GC]::GetTotalMemory(). Tag perf tests (Perf) to isolate.
Parallel vs sequential: assert speedup threshold.

---
## Class Testing
Constructors (valid/invalid), property invariants, state transitions (Complete, Overdue), derived status methods.
Prefer behavior over internal call verification.

---
## CI/CD Essentials
Matrix OS runs, coverage, fail on test failures, enforce coverage threshold where valuable.
Minimal vs full configuration: start simple, scale intentionally.

---
## VS Code Productivity
Test Explorer discovery, CodeLens Run/Debug, breakpoint single test, auto-run for TDD, disable for perf tests.

---
## Test Smells 
What to avoid to keep your tests from stinking?
Vague names, assertion soup, over-mocking, brittle filters, hidden deps, sleeps, duplicate setup, implementation assertions, etc.

When writing tests, aim for the FIRST principles (Fast, Independent, Repeatable, Self-Validating, Timely) to avoid them.


---
## Troubleshooting Quick Fixes
No [PesterConfiguration] -> Import module.
Tests undiscovered -> filename *.Tests.ps1.
Mocks not invoked -> loosen parameter filter.
Coverage empty -> path/glob mismatch.
Linux-only failure -> path case / line endings.

---
## Best Practices Checklist 
[ ] Behavior-focused names
[ ] Clear AAA layout
[ ] Includes boundaries & negatives
[ ] Selective mocking only
[ ] -Because on non-obvious asserts
[ ] Centralized configuration
[ ] Fast unit suite (<5s)

---
## Practice Prompts
1. Add validation test then implement.
2. Introduce mock for external call.
3. Refactor multi-assert into table tests.
4. Add coverage config + threshold.
5. Add performance guard test.

---
## Exit Assessment Prompts
- Provide test with -Because.
- Identify and refactor smell.
- Explain when not to mock.
- Add coverage threshold snippet.
- Demonstrate boundary test.

---
## Glossary 
AAA (Arrange/Act/Assert), Invariant (always true condition), Mock (stand-in dependency), Tag (selective execution), Quality Gate (auto threshold), TDD (test-first cycle).

---
Original Labs: 1 Fundamentals | 2 Test Design | 3 Mocking | 4 Performance | 5 Classes | 6 CI/CD | 7 IDE.

Full workshop edition: PesterLabSummary.md
