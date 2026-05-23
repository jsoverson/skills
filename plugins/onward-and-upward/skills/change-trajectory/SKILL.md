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

> **Same-branch detection:** If `$BASE` equals `HEAD` (the changeset is on the default branch itself, e.g., a direct commit to main), the diff will be empty. In this case, set `BASE=HEAD~1` and note in the report that the assessment covers the most recent commit rather than a branch diff.

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

If no test suite exists (ecosystem detected but no test runner), score CRITICAL if new source files with branching logic were added in this changeset — the change added new logic to a project with no way to verify it. Score NEUTRAL if the changeset adds only configuration, documentation, or declaration files.

### Signal 2: Coverage Alignment

Measure the ratio of test changes to source changes:

```bash
# Count added lines in source files (non-test):
SOURCE_ADDED=$(git diff --name-only $BASE..HEAD \
  | grep -E "\.(ts|tsx|js|jsx|mjs|py|go|rs)$" \
  | grep -vE "(test|spec)" \
  | xargs -r git diff $BASE..HEAD -- \
  | grep "^+" | grep -v "^+++" | wc -l || echo 0)

# Count added lines in test files:
TEST_ADDED=$(git diff --name-only $BASE..HEAD \
  | grep -E "(test|spec|__tests__|_test\.)" \
  | xargs -r git diff $BASE..HEAD -- \
  | grep "^+" | grep -v "^+++" | wc -l || echo 0)

echo "Source lines added: $SOURCE_ADDED"
echo "Test lines added: $TEST_ADDED"
```

| Score | Criterion |
|---|---|
| IMPROVING | Test lines added ≥ source lines added (1:1 ratio or better) |
| NEUTRAL | No new source code (pure refactor, config, docs, types-only); OR source additions are only constants/interfaces/type declarations with no branching logic; OR the diff shows only parameter name changes, docstring additions, or comment changes with no new control flow |
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

# Show all removed lines from CI workflows (read the full output to identify removed job steps):
git diff $BASE..HEAD -- .github/workflows/*.yml 2>/dev/null | grep "^-" | grep -v "^---" | head -40

# Look for bypass flags being added:
git diff $BASE..HEAD | grep "^+" | grep -E "(continue-on-error: true|allow-failure|--no-verify|SKIP_TESTS|skip.*test)" | head -10
```

| Score | Criterion |
|---|---|
| IMPROVING | New quality gates added to CI; linting rules strengthened; coverage thresholds raised; new security step added |
| NEUTRAL | No changes to CI or quality configs |
| DEGRADING | CI steps made optional via `continue-on-error: true`; linting rules relaxed or disabled in config |
| CRITICAL | Test, lint, or security steps removed from CI; quality config deleted; `--no-verify` added to CI; coverage threshold lowered or removed |

> **CI step removal detection:** Do not rely solely on the grep output to detect step removal. Read the full workflow diff. A `run:` block that spans multiple lines will show removed command content on lines that do not begin with `run:`. Look for any removed lines that contain test runner invocations (`pytest`, `npm test`, `go test`, `cargo test`) or linter invocations (`eslint`, `ruff`, `golangci-lint`, `clippy`).

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
git diff $BASE..HEAD | grep "^+" | grep -iE "(password|passwd|secret|api.?key|token|private.?key|auth.?key)\s*[:=]\s*['\"][a-zA-Z0-9_\-\.]{10,}['\"]" | grep -viE "(\.example|placeholder|changeme|your[-_]|example[-_]|test[-_]|fake[-_]|dummy|<your|REPLACE|TODO)" | head -10

# Dangerous execution patterns:
git diff $BASE..HEAD | grep "^+" | grep -E "(\beval\s*\(|\bexec\s*\(|shell_exec\s*\(|subprocess\.call[^)]*shell\s*=\s*True|os\.system\s*\(|\bexec\b.*\$)" | head -10

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

[For MERGE WITH CONDITIONS: state the exact change needed before merging — e.g., "Add tests covering the three new code paths in src/parser.py before merging."
For HOLD: list each DEGRADING signal and the specific change required to bring it to NEUTRAL or IMPROVING.
For BLOCK: list each CRITICAL signal and the specific change required to resolve it before re-evaluation.
For RECOMMEND MERGE: write "N/A"]

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
