# Change Trajectory Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a `change-trajectory` skill that evaluates whether a code change (PR, branch diff, or commit range) adds more value than it costs by analyzing seven quality signals and producing a merge recommendation.

**Architecture:** A single `SKILL.md` that takes a changeset identifier (branch, PR number, or commit range), categorizes changed files, runs quality checks on the current state, scores seven signals as IMPROVING/NEUTRAL/DEGRADING/CRITICAL, and emits a structured report with a merge verdict. Developed using the RED-GREEN-REFACTOR methodology from `superpowers:writing-skills`.

**Tech Stack:** Markdown skill file, bash commands (git, ecosystem linters, test runners), optional `gh` CLI for PR context.

---

## File Structure

| File | Purpose |
|---|---|
| `skills/change-trajectory/SKILL.md` | The skill itself |
| `skills/change-trajectory/test-scenarios.md` | RED/GREEN/REFACTOR test scenarios |

---

### Task 1: Write the SKILL.md

**Files:**
- Create: `skills/change-trajectory/SKILL.md`

- [ ] **Step 1: Create the directory**

```bash
mkdir -p /Users/jsoverson/development/src/claude-plugins/skills/change-trajectory
```

- [ ] **Step 2: Write the complete SKILL.md**

Write the following content exactly to `skills/change-trajectory/SKILL.md`:

````markdown
---
name: change-trajectory
description: Use when evaluating whether a code change (PR, branch diff, or commit range) should be merged — determines if it moves the repository toward or away from its quality goals
---

# Change Trajectory Assessment

Evaluate whether a proposed change improves or degrades the repository's quality trajectory. Produces a merge recommendation (RECOMMEND MERGE / MERGE WITH CONDITIONS / HOLD / BLOCK) based on measurable quality signals.

**Announce at start:** "I'm using the change-trajectory skill to assess this change."

If a repo-assessment report exists in `reports/assessment/`, read the most recent one — it establishes baseline quality context for interpreting signal scores.

Execute all steps in order. Do not skip steps.

---

## Step 1 — Identify the Changeset

Determine what is being assessed. Accept any of these forms:
- PR URL or number → use `gh pr diff <number>` for diff and `gh pr view <number>` for description
- Branch name → compare against default branch
- Commit range → use `git diff <base>..<tip>`
- Staged changes → use `git diff --cached`
- No argument → default to comparing HEAD against main/master

```bash
# Identify the default branch:
DEFAULT_BRANCH=$(git remote show origin 2>/dev/null | grep "HEAD branch" | awk '{print $NF}')
[ -z "$DEFAULT_BRANCH" ] && DEFAULT_BRANCH=$(git branch -r | grep -E "origin/(main|master)" | head -1 | sed 's|.*origin/||' | xargs)
[ -z "$DEFAULT_BRANCH" ] && DEFAULT_BRANCH="main"

# Find the merge base (where this branch diverged):
BASE=$(git merge-base HEAD $DEFAULT_BRANCH 2>/dev/null || echo "$DEFAULT_BRANCH")

# Get changed files:
git diff --name-only $BASE..HEAD

# Get summary stats:
git diff --stat $BASE..HEAD | tail -3
```

Record the base ref and changeset description. If a PR number was provided, note the PR title and description — they provide intent context that informs the proportionality judgment in Step 4.

---

## Step 2 — Detect Ecosystems

```bash
find . -maxdepth 3 \( \
  -name "package.json" -o -name "package-lock.json" -o -name "yarn.lock" -o -name "pnpm-lock.yaml" \
  -o -name "requirements.txt" -o -name "pyproject.toml" -o -name "setup.py" -o -name "Pipfile" -o -name "uv.lock" \
  -o -name "go.mod" -o -name "go.sum" \
  -o -name "Cargo.toml" -o -name "Cargo.lock" \
\) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | sort
```

Map indicators to ecosystems (Node.js / Python / Go / Rust). Record every detected ecosystem.

---

## Step 3 — Categorize Changed Files

Classify every file in the changeset into categories. Run these commands using `$BASE` from Step 1:

```bash
# Source files (business logic — not tests, not config)
git diff --name-only $BASE..HEAD | grep -E "\.(ts|tsx|js|jsx|mjs|py|go|rs|rb|java|cs|cpp|c|h)$" | grep -vE "(test|spec|__tests__|_test\b)"

# Test files
git diff --name-only $BASE..HEAD | grep -E "(test|spec|__tests__|_test\.)"

# CI/CD config
git diff --name-only $BASE..HEAD | grep -E "(\.github/workflows|\.circleci|\.gitlab-ci|Jenkinsfile|\.travis|azure-pipelines|bitbucket-pipelines)"

# Quality tool configs (linting, types, formatting)
git diff --name-only $BASE..HEAD | grep -E "(\.eslintrc|eslint\.config|tsconfig\.json|tsconfig\.|\.pylintrc|ruff\.toml|\.ruff|pyproject\.toml|\.mypy|pyrightconfig|\.golangci|golangci\.yml|clippy\.toml)"

# Dependency manifests
git diff --name-only $BASE..HEAD | grep -E "(^package\.json$|package-lock\.json|yarn\.lock|pnpm-lock\.yaml|requirements\.txt|Pipfile$|go\.mod$|Cargo\.toml$|Cargo\.lock$)"

# Documentation and other files
git diff --name-only $BASE..HEAD | grep -E "\.(md|rst|txt|yaml|yml|json|toml)$|^docs/" | grep -vE "(\.github/workflows|ci\.yml|package\.json|Cargo\.toml|go\.mod)"
```

Record counts for each category. These inform proportionality judgments in Signal 2.

---

## Step 4 — Score Seven Quality Signals

Score each signal: **IMPROVING** (↑) / **NEUTRAL** (→) / **DEGRADING** (↓) / **CRITICAL** (✗)

Definitions:
- **IMPROVING**: The change leaves this dimension measurably better
- **NEUTRAL**: No material effect on this dimension
- **DEGRADING**: The change makes this dimension worse, but not catastrophically
- **CRITICAL**: The change breaks, removes, or severely weakens this dimension

### Signal 1: Test Suite Health

Run the full test suite on the current working tree:

| Ecosystem | Command |
|---|---|
| Node.js | `npm test 2>&1 \| tail -20` |
| Python | `python -m pytest -q 2>&1 \| tail -20` |
| Go | `go test ./... 2>&1 \| tail -20` |
| Rust | `cargo test 2>&1 \| tail -20` |

| Score | Criterion |
|---|---|
| IMPROVING | New tests were added AND all tests pass |
| NEUTRAL | No new tests, but all existing tests still pass |
| DEGRADING | Tests modified in ways that reduce assertion strength (e.g., assertions commented out, failure cases removed) but suite still passes |
| CRITICAL | Any tests fail after this change; OR test files deleted with no equivalent replacement elsewhere |

If no test suite exists (ecosystem detected but no test runner), score CRITICAL only if this change was supposed to add tests (e.g., the PR description says "adds X feature") — otherwise score NEUTRAL with a note that the repo has no baseline tests.

### Signal 2: Coverage Alignment

Measure the ratio of test changes to source changes:

```bash
# Count added lines in source files (non-test):
SOURCE_FILES=$(git diff --name-only $BASE..HEAD | grep -E "\.(ts|tsx|js|jsx|mjs|py|go|rs)$" | grep -vE "(test|spec)")
SOURCE_ADDED=$([ -n "$SOURCE_FILES" ] && git diff $BASE..HEAD -- $SOURCE_FILES | grep "^+" | grep -v "^+++" | wc -l || echo 0)

# Count added lines in test files:
TEST_FILES=$(git diff --name-only $BASE..HEAD | grep -E "(test|spec|__tests__|_test\.)")
TEST_ADDED=$([ -n "$TEST_FILES" ] && git diff $BASE..HEAD -- $TEST_FILES | grep "^+" | grep -v "^+++" | wc -l || echo 0)

echo "Source lines added: $SOURCE_ADDED"
echo "Test lines added: $TEST_ADDED"
```

| Score | Criterion |
|---|---|
| IMPROVING | Test lines added ≥ source lines added (1:1 ratio or better) |
| NEUTRAL | No new source code (pure refactor, config, docs, types-only); OR source additions are only constants/interfaces/type declarations with no branching logic |
| DEGRADING | Source lines added > 3× test lines added AND the new source contains functions/methods with branching logic |
| CRITICAL | Test files deleted with no replacement; test assertions removed without equivalent coverage elsewhere in the suite |

> **Proportionality judgment:** Pure type definitions, constants, and configuration files do not require tests. If the new source code adds logic (conditionals, loops, function calls with side effects), it needs corresponding tests. Apply DEGRADING when new logic goes uncovered.

### Signal 3: Quality Infrastructure Integrity

Inspect changes to CI/CD workflows and quality tool configurations:

```bash
# Show CI/CD diff:
git diff $BASE..HEAD -- .github/workflows/ .circleci/ .gitlab-ci.yml Jenkinsfile .travis.yml 2>/dev/null | head -60

# Show quality config diff:
git diff $BASE..HEAD -- .eslintrc* eslint.config.* tsconfig.json .pylintrc ruff.toml pyproject.toml .golangci* clippy.toml .mypy.ini pyrightconfig.json 2>/dev/null | head -60

# Look specifically for CI steps being removed:
git diff $BASE..HEAD -- .github/workflows/*.yml 2>/dev/null | grep "^-" | grep -E "^\-\s+(run:|uses:|name:)" | head -20

# Look for bypass flags being added:
git diff $BASE..HEAD | grep "^+" | grep -E "(continue-on-error: true|allow-failure|--no-verify|SKIP_TESTS|skip.*test)" | head -10
```

| Score | Criterion |
|---|---|
| IMPROVING | New quality gates added to CI; linting rules strengthened; coverage thresholds raised; new security step added |
| NEUTRAL | No changes to CI or quality configs |
| DEGRADING | CI steps made optional via `continue-on-error: true`; linting rules relaxed or disabled in config |
| CRITICAL | Test, lint, or security steps removed from CI; quality config deleted; `--no-verify` added to CI; coverage threshold lowered or removed |

### Signal 4: Static Analysis Compliance

Run the linter on the full project after the change is applied:

| Ecosystem | Command |
|---|---|
| Node.js | `npx eslint . --max-warnings=0 2>&1 \| tail -20` |
| Python | `python -m ruff check . 2>&1 \| tail -20` (fallback: `python -m flake8 . 2>&1 \| tail -20`) |
| Go | `golangci-lint run ./... 2>&1 \| tail -20` (fallback: `go vet ./... 2>&1 \| tail -20`) |
| Rust | `cargo clippy -- -D warnings 2>&1 \| tail -20` |

```bash
# Check if the diff adds inline suppression comments:
SUPPRESSIONS_ADDED=$(git diff $BASE..HEAD | grep "^+" | grep -cE "(eslint-disable|# noqa|// nolint|#\[allow\(clippy|# type: ignore)" || true)
SUPPRESSIONS_REMOVED=$(git diff $BASE..HEAD | grep "^-" | grep -cE "(eslint-disable|# noqa|// nolint|#\[allow\(clippy|# type: ignore)" || true)
echo "Suppressions added: $SUPPRESSIONS_ADDED, removed: $SUPPRESSIONS_REMOVED"
```

| Score | Criterion |
|---|---|
| IMPROVING | Net reduction in lint violations; inline suppressions removed (removed > added) |
| NEUTRAL | No change in lint violations; linter passes as before |
| DEGRADING | New inline suppressions added (`eslint-disable`, `# noqa`, `// nolint`) without removing old ones; OR linter now produces warnings that were previously absent |
| CRITICAL | Linter fails (non-zero exit) after this change due to new violations; OR linting config deleted or rules critically relaxed |

### Signal 5: Type Safety Trajectory

Check for type degradation patterns in the diff and run the type checker:

```bash
# Count type escapes added:
UNSAFE_ADDED=$(git diff $BASE..HEAD | grep "^+" | grep -cE "(: any\b|as any\b|@ts-ignore|@ts-nocheck|# type: ignore|cast\(Any|Any\))" || true)
UNSAFE_REMOVED=$(git diff $BASE..HEAD | grep "^-" | grep -cE "(: any\b|as any\b|@ts-ignore|@ts-nocheck|# type: ignore|cast\(Any|Any\))" || true)
echo "Type escapes added: $UNSAFE_ADDED, removed: $UNSAFE_REMOVED"
```

Run the type checker:

| Ecosystem | Command |
|---|---|
| Node.js (TypeScript) | `npx tsc --noEmit 2>&1 \| tail -10` (skip if TypeScript not in package.json deps) |
| Python | `python -m mypy . --ignore-missing-imports 2>&1 \| tail -10` (skip if mypy not installed) |
| Go | `go build ./... 2>&1 \| tail -10` |
| Rust | `cargo check 2>&1 \| tail -10` |

| Score | Criterion |
|---|---|
| IMPROVING | Type escapes removed (removed > added); stricter type config enabled; new type annotations added to previously untyped code |
| NEUTRAL | No change in type coverage; type checker passes as before |
| DEGRADING | New `any` types, `@ts-ignore`, or `# type: ignore` added (added > removed); type checker produces new warnings |
| CRITICAL | Type checker fails after this change; type checking disabled in config (`strict: false` added, mypy removed from CI); type config deleted |

If neither TypeScript nor mypy is configured (JavaScript project or unannotated Python), score NEUTRAL and note the limitation.

### Signal 6: Dependency Posture

Check what happened to dependencies:

```bash
# Show all dependency manifest changes:
git diff $BASE..HEAD -- package.json requirements.txt Pipfile go.mod Cargo.toml 2>/dev/null | grep "^[+-]" | grep -v "^[+-][+-][+-]" | head -40

# Count production deps added/removed (Node.js):
DEPS_ADDED=$(git diff $BASE..HEAD -- package.json 2>/dev/null | grep "^+" | grep -v "^+++" | grep -v '"version"\|"name"\|"description"\|devDependencies\|scripts\|engines\|lockfileVersion' | wc -l || echo 0)
```

If dependency manifests changed, run the security audit:

| Ecosystem | Command |
|---|---|
| Node.js | `npm audit --audit-level=high 2>&1 \| tail -20` |
| Python | `pip-audit 2>&1 \| tail -20` |
| Go | `govulncheck ./... 2>&1 \| tail -20` |
| Rust | `cargo audit 2>&1 \| tail -20` |

If no audit tool is available, note the limitation and score based on manifest inspection only.

| Score | Criterion |
|---|---|
| IMPROVING | Dependencies removed (reduced attack surface); known vulnerabilities patched via upgrade; lockfile freshened |
| NEUTRAL | No dependency manifest changes |
| DEGRADING | New dev-only dependencies added (minor, limited blast radius); minor version bumps without security motivation |
| CRITICAL | New production dependencies with known high/critical CVEs (audit fails with new issues introduced by this change); lockfile deleted; package-lock.json diverges from package.json after change |

### Signal 7: Security Posture

Check the diff for security anti-patterns:

```bash
# Hardcoded secrets/credentials (heuristic — not exhaustive):
git diff $BASE..HEAD | grep "^+" | grep -iE "(password|passwd|secret|api.?key|token|private.?key|auth.?key)\s*[:=]\s*['\"][^'\"]{6,}" | grep -viE "(\.example|placeholder|changeme|your[-_]|example[-_]|test[-_]|fake[-_]|dummy|<your|REPLACE|TODO)" | head -10

# Dangerous execution patterns:
git diff $BASE..HEAD | grep "^+" | grep -E "(eval\s*\(|exec\s*\(|shell_exec\s*\(|subprocess\.call[^)]*shell\s*=\s*True|os\.system\s*\(|\bexec\b.*\$)" | head -10

# Security config changes:
git diff $BASE..HEAD -- .snyk trivy.yaml .trivyignore semgrep.yml .semgrep* 2>/dev/null | head -20

# Permissions/auth patterns weakened:
git diff $BASE..HEAD | grep "^+" | grep -iE "(allowAll|skipAuth|bypassAuth|noAuth|publicAccess\s*=\s*true|isAdmin\s*=\s*true)" | head -5
```

| Score | Criterion |
|---|---|
| IMPROVING | Security hardening added (input validation, auth checks, output encoding); known-vulnerable dependency removed or patched; security scanner added |
| NEUTRAL | No security-relevant changes detected by the checks above |
| DEGRADING | Security config suppressions added (`.trivyignore` entries); security-sensitive code paths modified without clear rationale in PR description |
| CRITICAL | Credentials or secrets visible in the diff; known dangerous patterns added (unsanitized `eval`, `shell=True` on external input, auth bypass flags); security scanner removed from CI or config |

---

## Step 5 — Compute Verdict

Apply this decision tree in order (first matching rule wins):

1. **BLOCK** — if ANY signal is CRITICAL
2. **HOLD** — if 2 or more signals are DEGRADING
3. **MERGE WITH CONDITIONS** — if exactly 1 signal is DEGRADING; state the specific condition inline
4. **RECOMMEND MERGE** — if all signals are NEUTRAL or IMPROVING

---

## Step 6 — Fill Report Template

```
# Change Trajectory Assessment: [CHANGESET]

Date: [DATE]
Changeset: [branch/PR/commit range — e.g., feat/my-feature vs main, PR #42]
Ecosystems detected: [LIST]
Files changed: [N source, M test, K CI/quality-config, J dependency, L other]
Base repo-assessment: [path to most recent report, or "none found"]

## Quality Signal Summary

Legend: ↑ = IMPROVING  → = NEUTRAL  ↓ = DEGRADING  ✗ = CRITICAL

| # | Signal | Direction | Evidence | Notes |
|---|---|---|---|---|
| 1 | Test Suite Health | [↑/→/↓/✗] | [command output summary] | [one line] |
| 2 | Coverage Alignment | [↑/→/↓/✗] | [source lines added: N, test lines added: M] | [one line] |
| 3 | Quality Infrastructure | [↑/→/↓/✗] | [files changed or "no CI/config changes"] | [one line] |
| 4 | Static Analysis | [↑/→/↓/✗] | [linter output summary] | [one line] |
| 5 | Type Safety | [↑/→/↓/✗] | [type checker output or escape counts] | [one line] |
| 6 | Dependency Posture | [↑/→/↓/✗] | [deps added/removed/audited] | [one line] |
| 7 | Security Posture | [↑/→/↓/✗] | [patterns found or "none detected"] | [one line] |

## Critical Findings

[List each CRITICAL signal with specific evidence. If none: "No critical findings."]

## Conditions Required for Merge

[For MERGE WITH CONDITIONS only: state the exact change needed before merging — e.g., "Add tests covering the three new code paths in src/parser.py before merging." For other verdicts, write: "N/A"]

## Verdict

**[RECOMMEND MERGE / MERGE WITH CONDITIONS / HOLD / BLOCK]**

[One paragraph: what does this change do to the project's quality trajectory? Name the strongest positive and negative signals. Reference the engineering principles (test coverage, type safety, security posture) where relevant. Be specific about what the change accomplishes and what it costs.]
```

---

## Step 7 — Save the Report

```bash
PROJECT=$(git remote get-url origin 2>/dev/null | sed 's|.*/||; s|\.git$||')
[ -z "$PROJECT" ] && PROJECT=$(basename "$(pwd)")
DATE=$(date +%Y-%m-%d)
CHANGESET=$(git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's|/|-|g' || echo "unknown")
mkdir -p reports/change-trajectory
REPORT_PATH="reports/change-trajectory/${DATE}-${PROJECT}-${CHANGESET}.md"
```

Write the filled report template to `$REPORT_PATH`.

Output: `Report saved to $REPORT_PATH`
````

- [ ] **Step 3: Verify the file was written correctly**

```bash
head -5 /Users/jsoverson/development/src/claude-plugins/skills/change-trajectory/SKILL.md
```

Expected output:
```
---
name: change-trajectory
description: Use when evaluating whether a code change (PR, branch diff, or commit range) should be merged — determines if it moves the repository toward or away from its quality goals
---
```

- [ ] **Step 4: Commit**

```bash
cd /Users/jsoverson/development/src/claude-plugins
git add skills/change-trajectory/SKILL.md
git commit -m "feat: add change-trajectory skill scaffold"
```

---

### Task 2: Write test-scenarios.md

**Files:**
- Create: `skills/change-trajectory/test-scenarios.md`

- [ ] **Step 1: Write the test scenarios file**

Write the following content to `skills/change-trajectory/test-scenarios.md`:

````markdown
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

## Scenario B: Silent Debt — Logic Without Tests (Expected: HOLD)

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

**Expected verdict:** HOLD (2+ DEGRADING would be required; with only 1 DEGRADING, the expected verdict is MERGE WITH CONDITIONS — see note below)

> **Note for GREEN phase:** If Signal 1 scores NEUTRAL rather than DEGRADING, there is only 1 DEGRADING signal (Coverage Alignment), which means the verdict should be MERGE WITH CONDITIONS. Adjust expected verdict to MERGE WITH CONDITIONS with condition: "Add tests covering divide, power, and factorial before merging — including edge cases (divide by zero, negative exponents, factorial of 0)."

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

This scenario renames a variable and updates a docstring — no logic changes.

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

This scenario adds a file that contains what appears to be a hardcoded API key.

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
- Signal 7 (Security Posture): CRITICAL — hardcoded API key pattern detected in diff

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

1. The skill announces itself at start
2. Each of the seven signals is explicitly scored
3. The verdict matches the expected verdict
4. Critical findings section is present and accurate when signals are CRITICAL
5. Conditions are stated precisely when verdict is MERGE WITH CONDITIONS
6. The report is saved to `reports/change-trajectory/`

---

## REFACTOR: Gaps to Watch For

During GREEN phase testing, watch for these common gaps that will require skill refinement:

1. **Overly aggressive coverage check** — If the skill scores DEGRADING on Scenario D (pure refactor), the proportionality logic in Signal 2 is too broad. Tighten the "no new branching logic" exception.

2. **Credential detection false positives** — If the skill scores CRITICAL on Scenario D for the `TIMEOUT_SECONDS = 30` value, the secret pattern regex is too broad. The regex must require the value to be ≥6 characters and alphanumeric (not just a number).

3. **CI diff false negatives** — If the skill scores NEUTRAL on Scenario C instead of CRITICAL, the CI diff analysis is not detecting step removal. Check that the `grep "^-"` command is correctly parsing YAML step removal vs. whitespace-only changes.

4. **Missed test failure in Scenario B** — If the skill scores IMPROVING on Signal 1 for Scenario B (silent debt), the test runner output interpretation is incorrect — Scenario B adds no tests, so the score should be NEUTRAL not IMPROVING.
````

- [ ] **Step 2: Verify the file was written**

```bash
wc -l /Users/jsoverson/development/src/claude-plugins/skills/change-trajectory/test-scenarios.md
```

Expected: More than 200 lines.

- [ ] **Step 3: Commit**

```bash
cd /Users/jsoverson/development/src/claude-plugins
git add skills/change-trajectory/test-scenarios.md
git commit -m "test: add change-trajectory test scenarios for RED-GREEN-REFACTOR"
```

---

### Task 3: Register the Skill

**Files:**
- Create: symlink `~/.claude/skills/change-trajectory → <repo>/skills/change-trajectory`

- [ ] **Step 1: Create the symlink**

```bash
ln -sf /Users/jsoverson/development/src/claude-plugins/skills/change-trajectory ~/.claude/skills/change-trajectory
```

- [ ] **Step 2: Verify the symlink resolves**

```bash
ls -la ~/.claude/skills/change-trajectory/SKILL.md
```

Expected: Shows the symlink pointing to the repo file.

- [ ] **Step 3: Verify the skill appears to Claude Code**

In a new Claude Code session (or by checking skill discovery), confirm `change-trajectory` appears in the skills list. The description should read: "Use when evaluating whether a code change (PR, branch diff, or commit range) should be merged — determines if it moves the repository toward or away from its quality goals"

---

### Task 4: RED Phase Testing

**Purpose:** Establish a baseline of how a capable LLM behaves WITHOUT the skill.

- [ ] **Step 1: Set up the test repository**

Run the setup block from test-scenarios.md § "Setup: Creating a Test Repository":

```bash
mkdir -p /tmp/ct-test-repo/src /tmp/ct-test-repo/tests
cd /tmp/ct-test-repo
git init
git checkout -b main

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
```

- [ ] **Step 2: Set up Scenario A branch**

```bash
cd /tmp/ct-test-repo
git checkout -b scenario-a

cat >> src/calculator.py << 'EOF'

def multiply(a: int, b: int) -> int:
    return a * b
EOF

cat >> tests/test_calculator.py << 'EOF'

def test_multiply():
    assert multiply(2, 3) == 6
    assert multiply(0, 5) == 0
EOF

from src.calculator import add, subtract, multiply
# (Update the import at the top of test_calculator.py)
sed -i '' 's/from src.calculator import add, subtract/from src.calculator import add, subtract, multiply/' tests/test_calculator.py

git add -A
git commit -m "feat: add multiply function with tests"
```

- [ ] **Step 3: Run RED baseline on Scenario A**

Open a Claude Code session in `/tmp/ct-test-repo` WITHOUT the change-trajectory skill available. Run this prompt:

```
I'm on the scenario-a branch. Compare it against main and tell me whether this change should be merged and why.
```

Record the response. Key observations to document:
- Does it run systematic checks?
- Does it score any signals formally?
- Does it produce a structured report?
- Is the verdict justified with evidence?

The expected baseline: An ad-hoc response that may check git diff but lacks the structured seven-signal analysis the skill provides.

- [ ] **Step 4: Set up Scenario C branch and run RED baseline**

```bash
cd /tmp/ct-test-repo
git checkout main
git checkout -b scenario-c

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

Run in a Claude Code session WITHOUT the skill:

```
I'm on the scenario-c branch. Compare it against main and tell me whether this change should be merged and why.
```

Expected baseline: May detect the CI change but unlikely to score it CRITICAL or produce a formal BLOCK verdict.

- [ ] **Step 5: Document RED phase gaps**

After running both RED sessions, document the gaps between expected and actual behavior in a comment at the top of `test-scenarios.md`. These gaps justify the skill.

---

### Task 5: GREEN Phase Testing

**Purpose:** Verify the skill produces correct output for each scenario.

- [ ] **Step 1: Verify skill is registered**

```bash
ls -la ~/.claude/skills/change-trajectory/SKILL.md
```

Expected: Symlink to the repo file, exists and readable.

- [ ] **Step 2: Run Scenario A with skill (RECOMMEND MERGE)**

In a new Claude Code session in `/tmp/ct-test-repo` on the `scenario-a` branch:

```
Assess the current branch (scenario-a) against main using the change-trajectory skill.
```

Expected output must include:
- Announcement: "I'm using the change-trajectory skill to assess this change."
- Signal table with all 7 rows scored
- Signal 1: ↑ (IMPROVING) — new tests added, all pass
- Signal 2: ↑ (IMPROVING) — test lines ≥ source lines
- Signals 3–7: → (NEUTRAL)
- Verdict: **RECOMMEND MERGE**

- [ ] **Step 3: Run Scenario C with skill (BLOCK)**

In a new Claude Code session in `/tmp/ct-test-repo` on the `scenario-c` branch:

```
Assess the current branch (scenario-c) against main using the change-trajectory skill.
```

Expected output must include:
- Signal 3 (Quality Infrastructure): ✗ (CRITICAL) — test step removed from CI
- Critical Findings section with specific evidence of the removed `python -m pytest` step
- Verdict: **BLOCK**

- [ ] **Step 4: Set up and run Scenario B (MERGE WITH CONDITIONS)**

```bash
cd /tmp/ct-test-repo
git checkout main
git checkout -b scenario-b

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

Run in Claude Code on `scenario-b`:

```
Assess the current branch (scenario-b) against main using the change-trajectory skill.
```

Expected: Signal 2 DEGRADING, all others NEUTRAL, Verdict: MERGE WITH CONDITIONS with explicit condition about missing tests.

- [ ] **Step 5: Set up and run Scenario E (BLOCK via security)**

```bash
cd /tmp/ct-test-repo
git checkout main
git checkout -b scenario-e

cat > src/config.py << 'EOF'
API_ENDPOINT = "https://api.example.com/v1"
API_KEY = "sk-1a2b3c4d5e6f7g8h9i0j"
TIMEOUT_SECONDS = 30
EOF

git add -A
git commit -m "feat: add external API configuration"
```

Run in Claude Code on `scenario-e`:

```
Assess the current branch (scenario-e) against main using the change-trajectory skill.
```

Expected: Signal 7 CRITICAL, Verdict: BLOCK with credential pattern in Critical Findings.

- [ ] **Step 6: Run Scenario D (RECOMMEND MERGE, pure refactor)**

```bash
cd /tmp/ct-test-repo
git checkout main
git checkout -b scenario-d

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
git commit -m "refactor: rename parameters, add docstrings"
```

Run in Claude Code on `scenario-d`:

```
Assess the current branch (scenario-d) against main using the change-trajectory skill.
```

Expected: All signals NEUTRAL, Verdict: RECOMMEND MERGE. Confirm Signal 2 is NOT scored DEGRADING (parameter rename is not new logic).

---

### Task 6: REFACTOR Phase — Address Gaps

**Purpose:** Fix any issues found in GREEN phase testing.

- [ ] **Step 1: Review GREEN phase results against expected outcomes**

For each scenario, compare actual skill output to the expected signals and verdict from test-scenarios.md. Document any mismatches.

- [ ] **Step 2: Fix false positives in coverage alignment (if Scenario D fails)**

If Signal 2 scores DEGRADING on Scenario D (pure refactor), the issue is in the Signal 2 scoring criteria. The fix is to tighten the NEUTRAL criterion to explicitly include parameter renaming and docstring-only changes.

In `skills/change-trajectory/SKILL.md`, locate the Signal 2 NEUTRAL criterion:
```
| NEUTRAL | No new source code (pure refactor, config, docs, types-only); OR source additions are only constants/interfaces/type declarations with no branching logic |
```

If this doesn't catch the rename scenario, add: "OR the diff shows only parameter name changes, docstring additions, or comment changes with no new control flow"

- [ ] **Step 3: Fix credential false positives (if Scenario D is flagged for TIMEOUT_SECONDS)**

If Signal 7 triggers on `TIMEOUT_SECONDS = 30`, the regex is matching numeric values. Fix by tightening the value pattern:

In SKILL.md Signal 7, update the credentials check command to require alphanumeric strings of 10+ chars (not numbers):

Change:
```bash
git diff $BASE..HEAD | grep "^+" | grep -iE "(password|passwd|secret|api.?key|token|private.?key|auth.?key)\s*[:=]\s*['\"][^'\"]{6,}"
```

To:
```bash
git diff $BASE..HEAD | grep "^+" | grep -iE "(password|passwd|secret|api.?key|token|private.?key|auth.?key)\s*[:=]\s*['\"][a-zA-Z0-9_\-\.]{10,}['\"]"
```

- [ ] **Step 4: Re-run failing scenarios after fixes**

Re-run any scenario that produced incorrect output. Verify it now matches the expected verdict.

- [ ] **Step 5: Commit all SKILL.md refinements**

```bash
cd /Users/jsoverson/development/src/claude-plugins
git add skills/change-trajectory/SKILL.md
git commit -m "refactor: tighten change-trajectory signal criteria based on GREEN phase testing"
```

---

## Verification

After all tasks complete, confirm:

1. `skills/change-trajectory/SKILL.md` exists and passes YAML frontmatter check (name and description fields present)
2. `skills/change-trajectory/test-scenarios.md` exists with 5 scenarios
3. Symlink at `~/.claude/skills/change-trajectory` resolves correctly
4. All 5 GREEN phase scenarios produce the expected verdict

```bash
# Verify frontmatter:
head -5 /Users/jsoverson/development/src/claude-plugins/skills/change-trajectory/SKILL.md

# Verify scenario count:
grep "^## Scenario" /Users/jsoverson/development/src/claude-plugins/skills/change-trajectory/test-scenarios.md | wc -l
# Expected: 5

# Verify symlink:
ls -la ~/.claude/skills/change-trajectory/
```
