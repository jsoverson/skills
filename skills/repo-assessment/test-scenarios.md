# Repo Assessment Skill — Test Scenarios

These application scenarios test whether the skill guides a correct, thorough assessment.
Each scenario is run WITHOUT the skill first (RED baseline), then WITH (GREEN verify).

---

## Scenario A: Well-Maintained Skills Library

**Target repo:** `examples/claude-superpowers` (relative to project root)

**Assessment prompt:**
You are assessing whether the repository at /Users/jsoverson/development/src/claude-plugins/examples/claude-superpowers is suitable for automated code auditing. Produce a structured report covering:
1. Test coverage (unit, integration, e2e, benchmarks)
2. Static analysis and linting
3. Security scanning
4. CI/CD pipeline
5. Coverage/benchmark tracking over time
6. Missing infrastructure
7. Overall verdict: suitable or not suitable for automated auditing?

**Expected findings:**
- Has integration tests (tests/claude-code/) that run real Claude sessions
- No unit tests (skills are markdown — not traditionally unit-testable)
- package.json present (Node.js ecosystem)
- May or may not have CI/CD in .github/workflows/
- No coverage tracking config expected
- No benchmarks expected
- Verdict should be: NOT SUITABLE (missing benchmarks, coverage tracking)

---

## Scenario B: Documentation/Schema Repository

**Target repo:** `examples/cursor-plugins` (relative to project root)

**Assessment prompt:**
You are assessing whether the repository at /Users/jsoverson/development/src/claude-plugins/examples/cursor-plugins is suitable for automated code auditing. Produce a structured report covering:
1. Test coverage (unit, integration, e2e, benchmarks)
2. Static analysis and linting
3. Security scanning
4. CI/CD pipeline
5. Coverage/benchmark tracking over time
6. Missing infrastructure
7. Overall verdict: suitable or not suitable for automated auditing?

**Expected findings:**
- Has a validation script (scripts/validate-plugins.mjs)
- No test runner configured
- No static analysis configured
- Primarily documentation (markdown) and JSON schemas
- Verdict should be: NOT SUITABLE (no test suite, no linting, no security scanning)

---

## Scenario C: Minimal/Ambiguous Repo

**Setup before running:**
```bash
mkdir -p /tmp/test-repo-assessment/src /tmp/test-repo-assessment/tests
cd /tmp/test-repo-assessment
git init
echo '{"name":"my-app","version":"1.0.0","scripts":{"test":"echo no tests"}}' > package.json
echo 'def hello(): pass' > src/main.py
touch requirements.txt
git add . && git commit -m "initial"
```

**Assessment prompt:**
You are assessing whether the repository at /tmp/test-repo-assessment is suitable for automated code auditing. Produce a structured report covering:
1. Test coverage (unit, integration, e2e, benchmarks)
2. Static analysis and linting
3. Security scanning
4. CI/CD pipeline
5. Coverage/benchmark tracking over time
6. Missing infrastructure
7. Overall verdict: suitable or not suitable for automated auditing?

**Expected findings:**
- Multiple language indicators (package.json + Python files) — ambiguous ecosystem
- npm test script just echoes — no real tests
- No pytest, ruff, mypy configured
- No CI/CD
- Verdict should be: NOT SUITABLE (essentially everything missing)

---

## Baseline Results (RED Phase — filled in after running WITHOUT skill)

### Scenario A (claude-superpowers) — Baseline
- Date run: (to be filled)
- What agent checked spontaneously:
- What agent missed:
- Report structure (systematic or ad hoc?):
- Key gaps:

### Scenario B (cursor-plugins) — Baseline
- Date run: (to be filled)
- What agent checked spontaneously:
- What agent missed:
- Report structure (systematic or ad hoc?):
- Key gaps:

### Scenario C (temp repo) — Baseline
- Date run: (to be filled)
- What agent checked spontaneously:
- What agent missed:
- Report structure (systematic or ad hoc?):
- Key gaps:

---

## Skill Test Results (GREEN Phase — filled in after running WITH skill)

### Scenario A (claude-superpowers) — With Skill
- Date run: (to be filled)
- Improvement over baseline:
- Still missing:
- Pass/Fail:

### Scenario B (cursor-plugins) — With Skill
- Date run: (to be filled)
- Improvement over baseline:
- Still missing:
- Pass/Fail:

### Scenario C (temp repo) — With Skill
- Date run: (to be filled)
- Improvement over baseline:
- Still missing:
- Pass/Fail:
