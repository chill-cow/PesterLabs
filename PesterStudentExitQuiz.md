# Pester Labs – Student Exit Quiz

Purpose: Demonstrate comprehension of core testing concepts from Labs 1–7. Complete individually. Estimated time: 10–12 minutes.
Instructions: Unless specified, keep answers concise (1–2 sentences or a short code snippet). Mark multiple‑choice answers with the letter only.

---
## Section A – Multiple Choice (1 point each)
1. Which Pester block most precisely describes a single expected behavior?  
   A. Describe  
   B. Context  
   C. It  
   D. BeforeEach
2. Which Should operator is BEST when asserting a specific string INCLUDING case?  
   A. -Be  
   B. -BeExactly  
   C. -Match  
   D. -BeOfType
3. You should introduce a mock primarily to:  
   A. Make tests longer  
   B. Avoid testing implementation  
   C. Isolate from slow or external dependencies  
   D. Increase code coverage artificially
4. A flaky performance test most likely indicates:  
   A. Test names are unclear  
   B. Unmocked time or environmental variability  
   C. Too many -Because clauses  
   D. Using -BeExactly for integers
5. Which is the clearest test name?  
   A. It 'Works'  
   B. It 'Handles things'  
   C. It 'Uppercases mixed case input'  
   D. It 'Function output'
6. Which scenario should NOT be mocked?  
   A. Pure string transformation function  
   B. REST API call  
   C. Active Directory lookup  
   D. Random GUID generator
7. What does `-Because` improve MOST?  
   A. Raw performance  
   B. Failure diagnostics  
   C. Code coverage  
   D. Operator speed
8. A good boundary test usually includes:  
   A. Only valid middle values  
   B. Only null values  
   C. Minimum, maximum, and just-outside values  
   D. Random unrelated values
9. Which configuration property enables code coverage?  
   A. $cfg.Run.EnableCoverage  
   B. $cfg.CodeCoverage.Enabled  
   C. $cfg.TestResult.Coverage  
   D. Invoke-Pester -Coverage
10. A test that only uses `Should -Invoke` with no output assertions is a smell because:  
    A. Mocks are always wrong  
    B. It validates only interaction, not behavior  
    C. It will never fail  
    D. Should -Invoke is deprecated

---
## Section B – Short Answer (2 points each)
11. Briefly define the AAA pattern and why it helps readability.
12. Provide ONE reason NOT to chase 100% code coverage.
13. Give an example of when you would use `-Throw` together with specifying an exception type or message.
14. Explain the difference between a unit test and an integration test (1 sentence each).
15. State one trigger for adding a mock and one reason to avoid mocking in another case.

---
## Section C – Code Comprehension (3 points each)
16. The following test fails intermittently:
```
It 'Expires sessions after 15 minutes' {
  Start-Sleep -Seconds 2
  (Get-SessionAge -Id 5) | Should -BeGreaterThan 900
}
```
(a) Identify TWO problems. (b) Rewrite a more reliable outline (pseudo / minimal code acceptable).

17. Rewrite this vague test name and split if needed:
```
It 'Processes data' {
  $result = Invoke-Process -Input 5
  $result.Total | Should -Be 10
  $result.ElapsedSeconds | Should -BeLessThan 2
}
```

18. Given:
```
Mock Get-Date { Get-Date '2024-01-01T00:00:00Z' }
It 'Returns overdue when past due date' {
  $t = [Task]::new('Title','Desc',(Get-Date).AddDays(-1))
  $t.IsOverdue() | Should -BeTrue
}
```
Explain why freezing time here improves determinism.

---
## Section D – Applied Snippets (4 points each)
19. Write a single Pester test (Describe + It) that asserts a function `Normalize-Name` trims whitespace and uppercases input `"  john doe "` to `"JOHN DOE"`.

20. Write a configuration snippet that:
- Runs tests in `./tests`
- Enables coverage on `./src/*.ps1`
- Fails if coverage < 80%
(Outline only; not full pipeline.)

---
## Section E – Reflection (Optional Bonus 2 pts)
21. Name one habit you will apply immediately to improve your existing PowerShell scripts using Pester.

---
## Scoring
- Section A: 10 pts
- Section B: 10 pts
- Section C: 9 pts
- Section D: 8 pts
- Bonus: 2 pts
Total (without bonus): 37 pts; with bonus: 39 pts

Rubric: 90%+ Strong mastery | 75–89% Solid | 60–74% Needs reinforcement | <60% Targeted review.

---
## Submission
Return answers as plain text or mark directly in a copy of this file. Keep code answers concise.

Good work today—this exit ticket helps reinforce long-term retention.
