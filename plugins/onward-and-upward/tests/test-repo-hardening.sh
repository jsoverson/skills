#!/usr/bin/env bash
# Test: repo-hardening skill generates correct plans from assessment reports
#
# Framework: RED-GREEN per testing-skills-with-subagents.md
#
# What we test (the behaviors that distinguish the skill from untrained output):
#   1. Priority order      — CI/CD task appears before security scanning
#   2. PASS excluded       — no unit test task when dim 1 scored PASS
#   3. PARTIAL targeted    — no ESLint install when lint is PARTIAL (only CI wiring)
#   4. Correct ecosystem   — npm/Node.js commands, not pip/cargo
#   5. Plan file written   — docs/plans/hardening/*.md exists after the run
#
# RED phase:   Run without --plugin-dir. No skill loaded. Agent likely gets
#              order wrong, may include PASS dims, won't know PARTIAL distinction.
# GREEN phase: Run with --plugin-dir. Skill loaded. All assertions should pass.
#
# Usage:
#   bash test-repo-hardening.sh            # GREEN (skill loaded, default)
#   PHASE=red bash test-repo-hardening.sh  # RED  (no skill, baseline)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
HELPERS="$REPO_ROOT/examples/claude-superpowers/tests/claude-code/test-helpers.sh"

if [ ! -f "$HELPERS" ]; then
    echo "ERROR: test-helpers.sh not found at $HELPERS"
    echo "       Run this test from the repo root or adjust the path."
    exit 1
fi
source "$HELPERS"

PHASE="${PHASE:-green}"

echo "========================================"
echo " Test: repo-hardening skill"
echo " Phase: $PHASE"
echo " Plugin: $PLUGIN_DIR"
echo "========================================"
echo ""

# ---------------------------------------------------------------------------
# Synthetic assessment report
#
# Designed to produce clear assertions:
#   Dim 1 (Unit Tests)       ✓ PASS   → must NOT appear in plan
#   Dim 4 (Static Analysis)  ⚠ PARTIAL → targeted CI-wiring only, no install
#   Dim 6 (Security Scanning) ✗ FAIL  → full task with npm audit
#   Dim 7 (CI/CD Pipeline)   ✗ FAIL   → full task; must appear FIRST (priority 1)
# ---------------------------------------------------------------------------
REPORT='# Repository Assessment: example-app

Date: 2026-05-23
Ecosystems: Node.js
Task runners: npm scripts (package.json)

## Quality Infrastructure Summary

Legend: ✓ = PASS  ⚠ = PARTIAL  ✗ = FAIL

| # | Dimension | Status | Task | Evidence |
|---|-----------|--------|------|----------|
| 1 | Unit Tests | ✓ | test | 34 passed, 0 failed |
| 2 | Integration Tests | ✗ | none | no task |
| 3 | Benchmarks | ✗ | none | no task |
| 4 | Static Analysis | ⚠ | lint | exits 0 locally; not present in CI |
| 5 | Type Checking | ✗ | none | plain JavaScript project |
| 6 | Security Scanning | ✗ | none | no task |
| 7 | CI/CD Pipeline | ✗ | — | no .github/workflows directory |
| 8 | Coverage Tracking | ✗ | none | no task |
| 9 | Benchmark Tracking | ✗ | — | no benchmark tracking in CI |

## Missing Infrastructure

### CI/CD Pipeline — FAIL
- **What:** No CI config exists (.github/workflows/ is absent)
- **Why:** Without CI, no quality gates are automatically enforced on PRs
- **How:** Create .github/workflows/ci.yml with test, lint, and audit steps

### Security Scanning — FAIL
- **What:** No npm audit task or equivalent
- **Why:** Undetected high-severity vulnerabilities block automated auditing
- **How:** Add `"audit": "npm audit --audit-level=high"` to package.json scripts

### Static Analysis — PARTIAL
- **What:** ESLint is installed and `npm run lint` passes, but no CI step runs it
- **Why:** Lint errors introduced in PRs go undetected
- **How:** Add `- run: npm run lint` to the CI workflow quality job

### Integration Tests — FAIL
- **What:** No integration test suite
- **Why:** Cross-component behavior is untested
- **How:** Create test/integration/ with at least one real boundary test

### Coverage Tracking — FAIL
- **What:** No coverage measurement or persistence
- **Why:** Coverage regressions are invisible
- **How:** Add coverage step to CI; persist to etc/coverage git metadata branch

## Verdict

NOT SUITABLE for automated auditing

Blocking gaps: CI/CD Pipeline (FAIL), Security Scanning (FAIL)
'

# ---------------------------------------------------------------------------
# Test setup: temp project with report pre-written
# ---------------------------------------------------------------------------
TEST_PROJECT=$(create_test_project)
echo "Test project: $TEST_PROJECT"
trap "cleanup_test_project $TEST_PROJECT" EXIT

cd "$TEST_PROJECT"
git init --quiet
git config user.email "test@test.com"
git config user.name "Test"
git commit --allow-empty -m "init" --quiet

mkdir -p reports/assessment
echo "$REPORT" > reports/assessment/2026-05-23-example-app-analysis.md

cat > package.json <<'EOF'
{
  "name": "example-app",
  "version": "1.0.0",
  "scripts": {
    "test": "jest",
    "lint": "eslint . --max-warnings=0"
  }
}
EOF

PROMPT='An assessment report for this Node.js project is at reports/assessment/2026-05-23-example-app-analysis.md. It shows the project is NOT SUITABLE.

Use the repo-hardening skill to generate a hardening implementation plan from that report. Follow the skill exactly: read the report first, respect the priority order, and distinguish between FAIL (full task) and PARTIAL (targeted fix only).

Write the plan to docs/plans/hardening/ and print a summary of what tasks were included and in what order.'

OUTPUT_FILE="$TEST_PROJECT/claude-output.txt"

# ---------------------------------------------------------------------------
# Run Claude
# ---------------------------------------------------------------------------
echo "Running Claude (phase: $PHASE)..."
echo "======================================================================="

if [ "$PHASE" = "green" ]; then
    timeout 300 claude -p "$PROMPT" \
        --plugin-dir "$PLUGIN_DIR" \
        --permission-mode bypassPermissions \
        2>&1 | tee "$OUTPUT_FILE" || {
        echo ""
        echo "======================================================================="
        echo "EXECUTION FAILED (exit code: $?)"
        exit 1
    }
else
    # RED phase: no plugin dir — no skill loaded
    timeout 300 claude -p "$PROMPT" \
        --permission-mode bypassPermissions \
        2>&1 | tee "$OUTPUT_FILE" || {
        echo ""
        echo "======================================================================="
        echo "EXECUTION FAILED (exit code: $?)"
        exit 1
    }
fi

echo "======================================================================="
echo ""

# ---------------------------------------------------------------------------
# Session transcript location (for skill-invocation check)
# Claude normalizes the project path (real path, / → -)
# ---------------------------------------------------------------------------
TEST_PROJECT_REAL=$(cd "$TEST_PROJECT" && pwd -P)
SESSION_DIR="$HOME/.claude/projects/$(echo "$TEST_PROJECT_REAL" | sed 's|[^a-zA-Z0-9]|-|g')"
SESSION_FILE=$(ls -t "$SESSION_DIR"/*.jsonl 2>/dev/null | head -1 || true)

# ---------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------
echo "=== Verification ==="
echo ""

FAILED=0

# 1. Skill was invoked (GREEN only — RED has no skill to invoke)
if [ "$PHASE" = "green" ]; then
    echo "Test 1: repo-hardening skill was invoked..."
    if [ -z "$SESSION_FILE" ] || [ ! -f "$SESSION_FILE" ]; then
        echo "  [WARN] Could not locate session transcript in $SESSION_DIR"
        echo "         Skipping skill-invocation check"
    elif grep -qE '"skill"\s*:\s*"(onward-and-upward:)?repo-hardening"' "$SESSION_FILE"; then
        echo "  [PASS] Skill invoked"
    else
        echo "  [FAIL] repo-hardening skill not found in session transcript"
        echo "         Session: $SESSION_FILE"
        FAILED=$((FAILED + 1))
    fi
    echo ""
fi

# 2. CI/CD task present (dim 7 is FAIL — must produce a full task)
echo "Test 2: CI/CD task generated..."
if grep -qiE "\.github/workflows|github actions|ci\.yml|CI.*workflow" "$OUTPUT_FILE"; then
    echo "  [PASS] CI/CD task present"
else
    echo "  [FAIL] No CI/CD task found — dim 7 is FAIL and must be in the plan"
    FAILED=$((FAILED + 1))
fi
echo ""

# 3. Security scanning task present (dim 6 is FAIL)
echo "Test 3: Security scanning task generated..."
if grep -qiE "npm audit|security scan|audit.*level" "$OUTPUT_FILE"; then
    echo "  [PASS] Security scanning task present"
else
    echo "  [FAIL] No security scanning task found — dim 6 is FAIL"
    FAILED=$((FAILED + 1))
fi
echo ""

# 4. CI/CD appears BEFORE security scanning (priority order: CI=1, Security=4)
echo "Test 4: CI/CD task appears before security scanning (priority order)..."
if assert_order "$OUTPUT_FILE" \
    "\.github/workflows\|github actions\|ci\.yml" \
    "npm audit\|security scan" \
    "CI before security in output" 2>/dev/null; then
    echo "  [PASS] Priority order correct"
else
    # assert_order already prints FAIL, just count it
    FAILED=$((FAILED + 1))
fi
echo ""

# 5. Unit test task NOT present (dim 1 is PASS — must be excluded from plan)
echo "Test 5: No unit test task for dim 1 (PASS)..."
if grep -qiE "scaffold.*test|smoke test|npm init jest|jest@latest|test runner.*wired" "$OUTPUT_FILE"; then
    echo "  [FAIL] Unit test scaffolding found — dim 1 scored PASS and must be excluded"
    FAILED=$((FAILED + 1))
else
    echo "  [PASS] No unit test task (correctly excluded)"
fi
echo ""

# 6. No ESLint install for lint (dim 4 is PARTIAL — only CI wiring, not full install)
echo "Test 6: No full ESLint install for PARTIAL lint dimension..."
if grep -qiE "npm init @eslint|install.*eslint|eslint.*install" "$OUTPUT_FILE"; then
    echo "  [FAIL] ESLint install found — dim 4 is PARTIAL; only CI wiring is needed"
    FAILED=$((FAILED + 1))
else
    echo "  [PASS] No ESLint install (PARTIAL correctly handled)"
fi
echo ""

# 7. Correct ecosystem: Node.js commands present, not other ecosystems
echo "Test 7: Node.js ecosystem commands (not Python/Go/Rust)..."
has_npm=$(grep -cqiE "npm|node" "$OUTPUT_FILE" && echo yes || echo no)
has_wrong=$(grep -qiE "pip.audit|cargo audit|govulncheck|python -m pytest|go test" "$OUTPUT_FILE" && echo yes || echo no)

if [ "$has_wrong" = "yes" ]; then
    echo "  [FAIL] Non-Node.js ecosystem commands found in output"
    FAILED=$((FAILED + 1))
else
    echo "  [PASS] No wrong-ecosystem commands"
fi
echo ""

# 8. Plan file written to docs/plans/hardening/
echo "Test 8: Plan file written to docs/plans/hardening/..."
if ls docs/plans/hardening/*.md 2>/dev/null | grep -q .; then
    PLAN_FILE=$(ls docs/plans/hardening/*.md | head -1)
    echo "  [PASS] Plan file written: $PLAN_FILE"

    # Bonus: check plan file itself for CI before security
    echo ""
    echo "Test 8a: Plan file contains CI task..."
    if grep -qiE "\.github/workflows|ci\.yml|github actions" "$PLAN_FILE"; then
        echo "  [PASS] CI task present in plan file"
    else
        echo "  [FAIL] CI task missing from plan file"
        FAILED=$((FAILED + 1))
    fi

    echo ""
    echo "Test 8b: Plan file excludes unit test scaffold..."
    if grep -qiE "npm init jest|jest@latest|smoke test.*wired" "$PLAN_FILE"; then
        echo "  [FAIL] Unit test scaffold in plan file — dim 1 is PASS"
        FAILED=$((FAILED + 1))
    else
        echo "  [PASS] No unit test scaffold in plan file"
    fi
else
    echo "  [FAIL] No plan file found in docs/plans/hardening/"
    FAILED=$((FAILED + 1))
fi
echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "========================================"
echo " Test Summary"
echo " Phase: $PHASE"
echo "========================================"
echo ""

if [ "$PHASE" = "red" ]; then
    echo "RED phase: failures above indicate the skill IS needed to get this right."
    echo "If all passed without the skill, the test scenarios need to be tightened."
    echo ""
fi

if [ $FAILED -eq 0 ]; then
    echo "STATUS: PASSED"
    exit 0
else
    echo "STATUS: FAILED ($FAILED assertion(s) failed)"
    echo ""
    echo "Full output: $OUTPUT_FILE"
    exit 1
fi
