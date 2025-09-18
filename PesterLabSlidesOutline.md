# Pester Labs – Slide Deck Outline

Purpose: Instructor-facing scaffold. Each section lists suggested slide titles & key bullets. Aim for ~1 idea per slide.

---
## 1. Opening / Framing
Slide: Why Test PowerShell?
- Confidence in change
- Faster feedback loops
- Safer refactors

Slide: Lab Journey Map
- Fundamentals → Design → Isolation → Performance → Objects → Automation → Productivity

Slide: Quick Start Code (Tiny)
- Show failing test → make pass

---
## 2. Fundamentals
Slide: Pester Anatomy
- Describe / Context / It
- Lifecycle hooks

Slide: TDD Loop
- Red → Green → Refactor

Slide: Core 10 Operators
- Recognition over memorization

Slide: Config Progression
- Minimal → Verbose → Coverage

---
## 3. Test Design
Slide: AAA Pattern
- Improves readability
- Easier diffing

Slide: Assertion Strategy
- One behavior focus
- Use -Because for domain intent

Slide: Data-Driven Tests
- -TestCases for variation
- Reduces duplication

---
## 4. Isolation & Mocking
Slide: When to Mock
- External / nondeterministic / slow / destructive / rare

Slide: Mock Basics
- Mock <Command>
- Should -Invoke

Slide: Unit vs Integration
- Fast vs Realism tradeoff

Slide: Mocking Smells
- Over-mocking, brittle filters

---
## 5. Performance & Resources
Slide: Performance Questions
- Is it fast enough?
- Is memory reasonable?

Slide: Timing Pattern
- Measure-Command + threshold

Slide: Parallel vs Sequential
- Show comparative numbers

---
## 6. Classes & State
Slide: What to Test
- Constructor validity
- Property invariants
- State transitions

Slide: Behavior over Implementation
- Avoid asserting private pathways

---
## 7. CI/CD Automation
Slide: Minimal Pipeline
- Install → Run tests

Slide: Expand with Coverage
- Report + gate

Slide: Quality Gates
- Fail fast on coverage / failures

---
## 8. IDE Productivity
Slide: VS Code Integration
- Test Explorer / CodeLens

Slide: Debugging a Test
- Breakpoint in target function

Slide: Auto-Run Strategy
- Enable early, disable for perf

---
## 9. Test Smells
Slide: Common Smells
- Vague names / assertion soup / sleeps

Slide: Refactor Patterns
- Extract setup / table tests

---
## 10. Troubleshooting
Slide: Top Issues
- Not discovering tests
- Mocks not invoked

Slide: Fast Fix Cheats
- Glob / import / filename

---
## 11. Best Practices Checklist
Slide: Checklist Snapshot
- Behavior naming
- Negative tests
- Selective mocks

---
## 12. Practice & Assessment
Slide: Micro Exercises
- Validation, mocks, table tests

Slide: Exit Ticket Prompts
- Behavior explanation
- Coverage threshold

---
## 13. Advanced Topics (Teaser)
Slide: Where Next?
- Custom assertions
- Mutation testing
- Parallel execution

---
## 14. Closing
Slide: Key Takeaways
- Fast, focused, meaningful tests

Slide: Call to Action
- Add 1 test to existing script today

---
Reference: Full summary in PesterLabSummary.md
