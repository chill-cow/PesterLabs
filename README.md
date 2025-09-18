# Pester Labs Index

Central hub for the Pester Testing Labs (Labs 1–7) plus teaching and assessment resources.

## 📚 Core Resources
| Resource | Purpose |
|----------|---------|
| [Main Workshop Content](./PesterLabSummary.md) | Full workshop guide  |
| [Printable Handout](./PesterLabSummary-Handout.md) | Learner quick reference (condensed) |
| [Cheat Sheet](./PesterCheatSheet.md) | Printable rapid reference: lifecycle, operators, mocks, smells checklist |
| [Slide Deck Outline](./PesterLabSlidesOutline.md) | Instructor slide scaffold |
| [Exit Quiz](./PesterStudentExitQuiz.md) | Student assessment (download & complete) |
| [Quiz Answer Key](./PesterStudentExitQuiz-Answers.md) | Quiz solutions |

## 🧪 Individual Labs
<!-- LABS_TABLE_START -->
| Lab | Focus | File |
|-----|-------|------|
| 1 | Fundamentals & TDD | [Lab 1](./Lab1/Lab1.md) |
| 2 | Test Design & AAA & Data Cases | [Lab 2](./Lab2/Lab2.md) |
| 3 | Mocking & Isolation Strategy | [Lab 3](./Lab3/Lab3.md) |
| 4 | Performance & Resource Testing | [Lab 4](./Lab4/Lab4.md) |
| 5 | Class / Object State Testing | [Lab 5](./Lab5/Lab5.md) |
| 6 | CI/CD Integration & Quality Gates | [Lab 6](./Lab6/Lab6.md) |
| 7 | VS Code Test Explorer & Productivity | [Lab 7](./Lab7/Lab7.md) |
<!-- LABS_TABLE_END -->

## 🧭 Suggested Learning Flow
1. Skim the Handout and Cheat Sheet
2. Complete Labs 1–3 sequentially
3. Tackle Labs 4–5 (non-functional & objects) based on interest
4. Integrate automation (Lab 6)
5. Finish with IDE productivity (Lab 7)
6. Take Exit Quiz

## 🛠 Recommended Environment
- PowerShell 7.4+
- Pester 5.7.1+
- VS Code + PowerShell extension (latest)

## 🏁 Quick Invocation Examples
```powershell
# Minimal run
Invoke-Pester -Path ./tests

# With configuration
$cfg = [PesterConfiguration]::Default
$cfg.Run.Path = './tests'
$cfg.CodeCoverage.Enabled = $true
$cfg.CodeCoverage.Path = './src/*.ps1'
Invoke-Pester -Configuration $cfg
```

## 🧪 Tag Usage (If Adopted Later)
- Unit tests: `-Tag Unit`
- Integration tests: `-Tag Integration`
- Performance tests: `-Tag Perf`

Run selective: `Invoke-Pester -Tag Unit` or exclude: `Invoke-Pester -ExcludeTag Perf`

## ✅ Best Practices Snapshot
- Behavior-focused test names
- One main assertion (or cohesive invariant set)
- Use `-Because` for intent
- Mock only external / nondeterministic / slow
- Keep unit suite fast (<5s ideal)
- Track coverage pragmatically (not performative 100%)

## 🧩 Contributing / Extending
| Extension Idea | Description |
|----------------|-------------|
| Add Lab 8 | Snapshot / contract testing patterns |
| Add Mutation Demo | Explore assertion strength |
| Add Parallel Execution Guide | Safe segmentation strategies |
| Add Helpers Module | Custom assertions & fixtures |

## 📄 Versioning
Current bundle version: v0.1 (initial index creation)


---
Happy testing! Build confidence one focused assertion at a time.
