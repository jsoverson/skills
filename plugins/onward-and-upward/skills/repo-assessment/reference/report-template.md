# Repository Assessment Report Template

Copy this template, fill in each field, and save to `reports/assessment/YYYY-MM-DD-<project>-analysis.md`.

---

# Repository Assessment: [REPO NAME]

Date: [DATE]
Ecosystems: [LIST]
Task runners: [LIST, or "none detected"]

## Quality Infrastructure Summary

Legend: ✓ = PASS  ⚠ = PARTIAL  ✗ = FAIL

| # | Dimension | Status | Task | Evidence |
|---|-----------|--------|------|----------|
| 1 | Unit Tests | [✓/⚠/✗] | [task name or "none"] | [output summary] |
| 2 | Integration Tests | [✓/⚠/✗] | [task name or "none"] | [output summary] |
| 3 | Benchmarks | [✓/⚠/✗] | [task name or "none"] | [output summary] |
| 4 | Static Analysis | [✓/⚠/✗] | [task name or "none"] | [output summary] |
| 5 | Type Checking | [✓/⚠/✗] | [task name or "none"] | [output summary] |
| 6 | Security Scanning | [✓/⚠/✗] | [task name or "none"] | [output summary] |
| 7 | CI/CD Pipeline | [✓/⚠/✗] | — | [file path or "not found"] |
| 8 | Coverage Tracking | [✓/⚠/✗] | [task name or "none"] | [artifact path or "no artifact"] |
| 9 | Benchmark Tracking | [✓/⚠/✗] | — | [CI config reference or "not found"] |

## Missing Infrastructure

List dimensions scored PARTIAL or FAIL, ordered by impact (blocking gaps first).

### [DIMENSION NAME] — [PARTIAL/FAIL]
- **What:** [specific gap]
- **Why:** [consequence for automated auditing]
- **How:** [exact fix — install command, config to add, or CI step to wire]

(repeat for each gap)

## Verdict

**SUITABLE / NOT SUITABLE for automated auditing**

[If NOT SUITABLE: state which conditions are not met]
