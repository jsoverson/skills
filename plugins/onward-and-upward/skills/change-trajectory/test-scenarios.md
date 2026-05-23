# Change Trajectory Skill — Test Scenarios

These scenarios test whether the skill correctly identifies quality-improving, quality-neutral, and quality-degrading changes.
Each scenario is run WITHOUT the skill first (RED baseline), then WITH the skill loaded (GREEN verify).

---

## Setup: Creating a Test Repository

All scenarios use a temporary git repo with a minimal Python project. Run once before all scenarios:

```bash
mkdir -p /tmp/ct-test-repo/src /tmp/ct-test-repo/tests
cd /tmp/ct-test-repo
git init
git checkout -b main

# Create a minimal Python project
cat > src/calculator.py << 'EOF'
def add(a: int, b: int) -> int:
    return a + b

def subtract(a: int, b: int) -> int:
    return a - b
EOF

cat > tests/test_calculator.py << 'EOF'
from src.calculator import add, subtract

def test_add():
    assert add(2, 3) == 5

def test_subtract():
    assert subtract(5, 3) == 2
EOF

cat > pyproject.toml << 'EOF'
[tool.ruff]
select = ["E", "F"]

[tool.mypy]
python_version = "3.12"
ignore_missing_imports = true
EOF

mkdir -p .github/workflows
cat > .github/workflows/ci.yml << 'EOF'
name: CI
on: [push, pull_request]
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: pip install pytest ruff mypy
      - run: python -m pytest
      - run: python -m ruff check .
      - run: python -m mypy . --ignore-missing-imports
EOF

git add -A
git commit -m "initial: baseline Python project with CI"

# Create a feature branch for each scenario:
git checkout -b scenario-a
git checkout main
git checkout -b scenario-b
git checkout main
git checkout -b scenario-c
git checkout main
git checkout -b scenario-d
git checkout main
git checkout -b scenario-e
git checkout main
git checkout main
```

---

## Scenario A: Gold Standard — Feature with Tests (Expected: RECOMMEND MERGE)

This scenario adds a new function with full test coverage — the ideal contribution.

**Setup:**
```bash
cd /tmp/ct-test-repo
git checkout scenario-a

cat >> src/calculator.py << 'EOF'

def multiply(a: int, b: int) -> int:
    return a * b
EOF

cat >> tests/test_calculator.py << 'EOF'

def test_multiply():
    assert multiply(2, 3) == 6
    assert multiply(0, 5) == 0
    assert multiply(-1, 4) == -4
EOF

git add -A
git commit -m "feat: add multiply function with tests"
```

**Assessment prompt:**
```
Assess the current branch (scenario-a) against main using the change-trajectory skill.
```

**Expected signals:**
- Signal 1 (Test Suite Health): IMPROVING — new tests added, all pass
- Signal 2 (Coverage Alignment): IMPROVING — test lines added ≥ source lines added
- Signal 3 (Quality Infrastructure): NEUTRAL — no CI/config changes
- Signal 4 (Static Analysis): NEUTRAL — no lint violations
- Signal 5 (Type Safety): NEUTRAL — types maintained
- Signal 6 (Dependency Posture): NEUTRAL — no deps changed
- Signal 7 (Security Posture): NEUTRAL — no security-relevant changes

**Expected verdict:** RECOMMEND MERGE

---

## Scenario B: Silent Debt — Logic Without Tests (Expected: MERGE WITH CONDITIONS)

This scenario adds multiple functions with business logic but no tests.

**Setup:**
```bash
cd /tmp/ct-test-repo
git checkout scenario-b

cat >> src/calculator.py << 'EOF'

def divide(a: float, b: float) -> float:
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b

def power(base: float, exp: int) -> float:
    result = 1.0
    for _ in range(abs(exp)):
        result *= base
    return result if exp >= 0 else 1.0 / result

def factorial(n: int) -> int:
    if n < 0:
        raise ValueError("Factorial undefined for negative numbers")
    if n == 0:
        return 1
    return n * factorial(n - 1)
EOF

git add -A
git commit -m "feat: add divide, power, and factorial functions"
```

**Assessment prompt:**
```
Assess the current branch (scenario-b) against main using the change-trajectory skill.
```

**Expected signals:**
- Signal 1 (Test Suite Health): NEUTRAL — no new tests but existing tests still pass
- Signal 2 (Coverage Alignment): DEGRADING — ~25 source lines added, 0 test lines (>3:1 ratio, new functions have branching logic)
- Signal 3 (Quality Infrastructure): NEUTRAL — no CI changes
- Signal 4 (Static Analysis): NEUTRAL — code is clean
- Signal 5 (Type Safety): NEUTRAL — types maintained
- Signal 6 (Dependency Posture): NEUTRAL — no deps changed
- Signal 7 (Security Posture): NEUTRAL — no security concerns

**Expected verdict:** MERGE WITH CONDITIONS — condition: "Add tests covering divide, power, and factorial before merging — including edge cases (divide by zero, negative exponents, factorial of 0)."

---

## Scenario C: Infrastructure Attack — CI Step Removed (Expected: BLOCK)

This scenario removes the test step from CI, eliminating the quality gate.

**Setup:**
```bash
cd /tmp/ct-test-repo
git checkout scenario-c

cat > .github/workflows/ci.yml << 'EOF'
name: CI
on: [push, pull_request]
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: pip install ruff mypy
      - run: python -m ruff check .
      - run: python -m mypy . --ignore-missing-imports
EOF

git add -A
git commit -m "ci: simplify CI workflow"
```

**Assessment prompt:**
```
Assess the current branch (scenario-c) against main using the change-trajectory skill.
```

**Expected signals:**
- Signal 1 (Test Suite Health): NEUTRAL — tests still pass locally
- Signal 2 (Coverage Alignment): NEUTRAL — no source changes
- Signal 3 (Quality Infrastructure): CRITICAL — the `python -m pytest` step was removed from CI
- Signal 4 (Static Analysis): NEUTRAL
- Signal 5 (Type Safety): NEUTRAL
- Signal 6 (Dependency Posture): NEUTRAL
- Signal 7 (Security Posture): NEUTRAL

**Expected verdict:** BLOCK (Signal 3 is CRITICAL)

---

## Scenario D: Pure Refactor — Rename Without Logic Change (Expected: RECOMMEND MERGE)

This scenario renames parameters and adds docstrings — no logic changes.

**Setup:**
```bash
cd /tmp/ct-test-repo
git checkout scenario-d

cat > src/calculator.py << 'EOF'
"""Arithmetic operations module."""

def add(first: int, second: int) -> int:
    """Return the sum of two integers."""
    return first + second

def subtract(first: int, second: int) -> int:
    """Return the difference of two integers."""
    return first - second
EOF

git add -A
git commit -m "refactor: rename parameters a/b to first/second, add docstrings"
```

**Assessment prompt:**
```
Assess the current branch (scenario-d) against main using the change-trajectory skill.
```

**Expected signals:**
- Signal 1 (Test Suite Health): NEUTRAL — tests still pass (signatures compatible)
- Signal 2 (Coverage Alignment): NEUTRAL — source lines modified but no new logic (pure declaration change)
- Signal 3 (Quality Infrastructure): NEUTRAL
- Signal 4 (Static Analysis): NEUTRAL
- Signal 5 (Type Safety): NEUTRAL — types maintained
- Signal 6 (Dependency Posture): NEUTRAL
- Signal 7 (Security Posture): NEUTRAL

**Expected verdict:** RECOMMEND MERGE

---

## Scenario E: Security Regression — Hardcoded Credential (Expected: BLOCK)

This scenario adds a file containing a hardcoded API key.

**Setup:**
```bash
cd /tmp/ct-test-repo
git checkout scenario-e

cat > src/config.py << 'EOF'
# Configuration for external API
API_ENDPOINT = "https://api.example.com/v1"
API_KEY = "sk-1a2b3c4d5e6f7g8h9i0j"
TIMEOUT_SECONDS = 30
EOF

git add -A
git commit -m "feat: add external API configuration"
```

**Assessment prompt:**
```
Assess the current branch (scenario-e) against main using the change-trajectory skill.
```

**Expected signals:**
- Signal 1 (Test Suite Health): NEUTRAL
- Signal 2 (Coverage Alignment): NEUTRAL (config file with no branching logic)
- Signal 3 (Quality Infrastructure): NEUTRAL
- Signal 4 (Static Analysis): NEUTRAL
- Signal 5 (Type Safety): NEUTRAL
- Signal 6 (Dependency Posture): NEUTRAL
- Signal 7 (Security Posture): CRITICAL — hardcoded API key pattern detected in diff (`API_KEY = "sk-1a2b3c4d5e6f7g8h9i0j"` matches the credential heuristic)

**Expected verdict:** BLOCK (Signal 7 is CRITICAL)

---

## RED Phase Baseline (run WITHOUT skill)

For each scenario, run the assessment prompt in a Claude Code session where the change-trajectory skill is NOT available. The expected behavior without the skill:
- No structured seven-signal analysis
- No IMPROVING/NEUTRAL/DEGRADING/CRITICAL scoring
- No standardized report template
- Verdict (if given) is ad-hoc and inconsistent across scenarios

Document the baseline output to compare against GREEN phase results.

---

## GREEN Phase Verification (run WITH skill)

After the skill is registered (symlinked to `~/.claude/skills/change-trajectory`), re-run each scenario and verify:

1. The skill announces itself at start: "I'm using the change-trajectory skill to assess this change."
2. Each of the seven signals is explicitly scored with ↑/→/↓/✗
3. The verdict matches the expected verdict for each scenario
4. Critical Findings section is present and accurate when signals are CRITICAL
5. Conditions are stated precisely when verdict is MERGE WITH CONDITIONS
6. The report is saved to `reports/change-trajectory/`

---

## REFACTOR: Gaps to Watch For

During GREEN phase testing, watch for these common gaps that will require skill refinement:

1. **Overly aggressive coverage check** — If the skill scores DEGRADING on Scenario D (pure refactor), the proportionality logic in Signal 2 is too broad. Tighten the "no new branching logic" exception in the NEUTRAL criterion.

2. **Credential detection false positives** — If the skill scores CRITICAL for `TIMEOUT_SECONDS = 30` in Scenario D or E, the secret pattern regex is matching numeric values. The regex requires alphanumeric strings of 10+ characters, so a plain integer should not match.

3. **CI diff false negatives** — If the skill scores NEUTRAL on Scenario C instead of CRITICAL, the CI diff analysis is not detecting step removal. Verify that the `grep "^-"` command correctly parses YAML step removal.

4. **Signal 1 misscored on Scenario B** — If the skill scores IMPROVING on Signal 1 for Scenario B (silent debt), the test runner output interpretation is incorrect — Scenario B adds no tests, so the score should be NEUTRAL.
