# Repo Assessment Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a Claude skill that systematically assesses any repository's suitability for automated code auditing, encoding standard tooling knowledge so agents don't need to search.

**Architecture:** A single `SKILL.md` developed via the RED-GREEN-REFACTOR skill-writing methodology. The skill is a reference/technique skill (agents want to use it, not skip it), so testing uses application scenarios — does the agent correctly apply the skill's framework to a real repo? — rather than pressure scenarios. Two test targets from this repo are used: `examples/claude-superpowers` (an established project with integration tests) and `examples/cursor-plugins` (primarily documentation and schemas).

**Tech Stack:** Markdown, YAML frontmatter, Claude Code skill system, `claude` CLI for headless testing

---

## File Map

| File | Role |
|------|------|
| `skills/repo-assessment/SKILL.md` | The deliverable — full assessment framework |
| `skills/repo-assessment/test-scenarios.md` | RED-phase baseline scenarios and results; updated after each test run |

---

### Task 1: Set Up Skill Directory and Write Test Scenarios

**Files:**
- Create: `skills/repo-assessment/SKILL.md` (empty stub for now)
- Create: `skills/repo-assessment/test-scenarios.md`

- [ ] **Step 1: Create the skill directory and stub file**

```bash
mkdir -p /Users/jsoverson/development/src/claude-plugins/skills/repo-assessment
```

Create `skills/repo-assessment/SKILL.md` with only the frontmatter stub:

```markdown
---
name: repo-assessment
description: Use when assessing whether a repository has sufficient automated testing, static analysis, security scanning, and CI/CD infrastructure to support automated code auditing without human review
---

# Repository Assessment

(skill content goes here — do not fill in until RED baseline is complete)
```

- [ ] **Step 2: Write application test scenarios**

Create `skills/repo-assessment/test-scenarios.md` with the following content:

```markdown
# Repo Assessment Skill — Test Scenarios

These application scenarios test whether the skill guides a correct, thorough assessment.
Each scenario is run WITHOUT the skill first (RED baseline), then WITH (GREEN verify).

---

## Scenario A: Well-Maintained Skills Library

**Target repo:** `examples/claude-superpowers` (relative to this repo root)

**Prompt:**
```
IMPORTANT: This is a real task, not a quiz.

You are assessing whether the repository at /Users/jsoverson/development/src/claude-plugins/examples/claude-superpowers is suitable for automated code auditing.

Produce a structured report covering:
1. Test coverage (unit, integration, e2e, benchmarks)
2. Static analysis and linting
3. Security scanning
4. CI/CD pipeline
5. Coverage/benchmark tracking over time
6. Missing infrastructure
7. Overall verdict: suitable or not suitable for automated auditing?

Do not spend more than 15 minutes on this assessment.
```

**What a correct assessment should catch:**
- Has integration tests (`tests/claude-code/`) that run real Claude sessions
- No unit tests (skills are markdown — hard to unit-test)
- No CI/CD file visible (`.github/workflows/` may or may not exist)
- No coverage tracking configuration
- No benchmarks
- No security scanning config
- Package.json present (Node.js ecosystem) → should check for npm scripts
- Overall verdict should be: NOT SUITABLE — missing benchmarks, coverage tracking, and possibly CI/CD

---

## Scenario B: Documentation/Schema Repository

**Target repo:** `examples/cursor-plugins` (relative to this repo root)

**Prompt:**
```
IMPORTANT: This is a real task, not a quiz.

You are assessing whether the repository at /Users/jsoverson/development/src/claude-plugins/examples/cursor-plugins is suitable for automated code auditing.

Produce a structured report covering:
1. Test coverage (unit, integration, e2e, benchmarks)
2. Static analysis and linting
3. Security scanning
4. CI/CD pipeline
5. Coverage/benchmark tracking over time
6. Missing infrastructure
7. Overall verdict: suitable or not suitable for automated auditing?

Do not spend more than 10 minutes on this assessment.
```

**What a correct assessment should catch:**
- Has a validation script (`scripts/validate-plugins.mjs`)
- No test runner configured
- No static analysis beyond validation script
- Primarily documentation (markdown) and JSON schemas
- No CI/CD configuration visible
- Overall verdict should be: NOT SUITABLE — no test suite, no linting, no security scanning

---

## Scenario C: Ambiguous/Unknown Ecosystem

**Target repo:** A temporary repo with mixed signals

**Setup:** Create the temp repo before running:
```bash
mkdir -p /tmp/test-repo-assessment
cd /tmp/test-repo-assessment
git init
mkdir -p tests src
echo '{"name":"my-app","version":"1.0.0","scripts":{"test":"echo no tests"}}' > package.json
echo 'def hello(): pass' > src/main.py
echo 'requirements.txt' > requirements.txt
echo 'x = 1' >> requirements.txt
git add . && git commit -m "initial"
```

**Prompt:**
```
IMPORTANT: This is a real task, not a quiz.

You are assessing whether the repository at /tmp/test-repo-assessment is suitable for automated code auditing.

Produce a structured report covering:
1. Test coverage (unit, integration, e2e, benchmarks)
2. Static analysis and linting
3. Security scanning
4. CI/CD pipeline
5. Coverage/benchmark tracking over time
6. Missing infrastructure
7. Overall verdict: suitable or not suitable for automated auditing?
```

**What a correct assessment should catch:**
- Multiple language indicators (package.json + Python files) — should identify the ambiguity
- `npm test` script just echoes — no real tests
- No pytest config, no ruff, no mypy
- No CI/CD
- Overall verdict: NOT SUITABLE — everything missing

---

## Baseline Results (RED Phase — fill in after running WITHOUT skill)

### Scenario A (claude-superpowers) — Baseline
- Date run:
- What agent checked:
- What agent missed:
- Report quality (1-5):
- Key gaps in assessment:

### Scenario B (cursor-plugins) — Baseline
- Date run:
- What agent checked:
- What agent missed:
- Report quality (1-5):
- Key gaps in assessment:

### Scenario C (temp repo) — Baseline
- Date run:
- What agent checked:
- What agent missed:
- Report quality (1-5):
- Key gaps in assessment:

---

## Skill Test Results (GREEN Phase — fill in after running WITH skill)

### Scenario A (claude-superpowers) — With Skill
- Date run:
- Improvement over baseline:
- Still missing:

### Scenario B (cursor-plugins) — With Skill
- Date run:
- Improvement over baseline:
- Still missing:

### Scenario C (temp repo) — With Skill
- Date run:
- Improvement over baseline:
- Still missing:
```

- [ ] **Step 3: Commit the scaffold**

```bash
cd /Users/jsoverson/development/src/claude-plugins
git add skills/repo-assessment/
git commit -m "chore: scaffold repo-assessment skill directory and test scenarios"
```

---

### Task 2: RED Phase — Run Baseline Without Skill

**Files:**
- Modify: `skills/repo-assessment/test-scenarios.md` (fill in baseline results)

**Goal:** Watch the agent fail. Document exactly what it checks and misses without the skill. This reveals what the skill must teach.

- [ ] **Step 1: Create the Scenario C temp repo**

```bash
mkdir -p /tmp/test-repo-assessment
cd /tmp/test-repo-assessment
git init
mkdir -p tests src
echo '{"name":"my-app","version":"1.0.0","scripts":{"test":"echo no tests"}}' > package.json
echo 'def hello(): pass' > src/main.py
touch requirements.txt
git add . && git commit -m "initial"
```

- [ ] **Step 2: Run baseline for Scenario A (no skill)**

In a new Claude Code session (headless or interactive) WITHOUT the `repo-assessment` skill loaded, send the Scenario A prompt from `test-scenarios.md`. Record the output.

```bash
cd /Users/jsoverson/development/src/claude-plugins
claude -p "$(cat skills/repo-assessment/test-scenarios.md | grep -A 20 'Scenario A:' | grep -A 15 'Prompt:' | tail -n +2 | head -15)" \
  --allowed-tools=Bash,Read \
  2>&1 | tee /tmp/baseline-scenario-a.txt
```

Note: The exact prompt should be pasted directly rather than extracted via grep — copy from `test-scenarios.md` Scenario A's prompt block and paste manually if running interactively.

- [ ] **Step 3: Run baseline for Scenario B (no skill)**

Same approach using Scenario B prompt. Save output to `/tmp/baseline-scenario-b.txt`.

- [ ] **Step 4: Run baseline for Scenario C (no skill)**

Same approach using Scenario C prompt. Save output to `/tmp/baseline-scenario-c.txt`.

- [ ] **Step 5: Document gaps in test-scenarios.md**

Read the three baseline outputs. Fill in the "Baseline Results" section of `skills/repo-assessment/test-scenarios.md` for each scenario. Specifically record:
- What the agent spontaneously checked without guidance
- What it missed entirely (benchmarks? security scanning? coverage tracking over time?)
- Whether it knew standard commands for the ecosystem without being told
- Quality of the report structure (was it systematic or ad hoc?)

- [ ] **Step 6: Commit baseline results**

```bash
cd /Users/jsoverson/development/src/claude-plugins
git add skills/repo-assessment/test-scenarios.md
git commit -m "test: document RED baseline results for repo-assessment"
```

---

### Task 3: GREEN Phase — Write the SKILL.md

**Files:**
- Modify: `skills/repo-assessment/SKILL.md` (replace stub with full skill)

**Write the complete skill based on what the RED baseline revealed was missing.** The skill is a reference/technique skill — its job is to give the agent a complete, systematic framework so nothing falls through the gaps.

- [ ] **Step 1: Write SKILL.md**

Replace the stub content of `skills/repo-assessment/SKILL.md` with:

```markdown
---
name: repo-assessment
description: Use when assessing whether a repository has sufficient automated testing, static analysis, security scanning, and CI/CD infrastructure to support automated code auditing without human review
---

# Repository Assessment

## Overview

Determine whether a repository has the automated quality infrastructure required for trustworthy continuous auditing.

**Core principle:** Human review is not a reliable quality signal. Only automated checks with measurable, trackable outputs qualify as quality assurance. Every dimension below must be present and machine-verifiable for a repository to be suitable for automated auditing.

## Assessment Process

Follow this sequence for every assessment:

1. Detect ecosystem(s)
2. Run standard checks for each dimension
3. Record findings in the report template
4. Produce a verdict with specific gaps and recommendations

---

## Step 1: Detect Ecosystem

Check for these files to identify the tech stack (a repo may have multiple):

| File | Ecosystem |
|------|-----------|
| `package.json` | Node.js / TypeScript |
| `pyproject.toml`, `setup.py`, `requirements.txt` | Python |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `pom.xml`, `build.gradle` | Java / Kotlin |
| `Gemfile` | Ruby |
| `*.csproj`, `*.sln` | C# / .NET |

```bash
# Quick ecosystem detection
ls package.json pyproject.toml setup.py go.mod Cargo.toml pom.xml build.gradle Gemfile 2>/dev/null
```

---

## Step 2: Run Standard Checks Per Dimension

### Dimension 1: Unit Tests

**Look for:** Test files, test directory, test framework config.

```bash
# Node.js
cat package.json | grep -E '"test"|jest|vitest|mocha'
find . -name "*.test.*" -o -name "*.spec.*" | grep -v node_modules | head -10
npx jest --listTests 2>/dev/null || true

# Python
find . -name "test_*.py" -o -name "*_test.py" | grep -v __pycache__ | head -10
cat pyproject.toml 2>/dev/null | grep -A5 '\[tool.pytest'
cat pytest.ini 2>/dev/null || cat setup.cfg 2>/dev/null | grep -A5 '\[tool:pytest'

# Go
find . -name "*_test.go" | grep -v vendor | head -10
go test ./... -list '.*' 2>/dev/null | head -20

# Rust
find . -name "*.rs" | xargs grep -l '#\[test\]' 2>/dev/null | head -10
cat Cargo.toml | grep -A5 '\[\[test\]\]'
```

**Scoring:** PASS = test files exist AND a test command is configured AND tests actually run.

### Dimension 2: Integration Tests

**Look for:** Tests that call external services, databases, or run the full stack.

```bash
# Common patterns
find . -type d -name "integration" -o -name "e2e" -o -name "functional" | grep -v node_modules
grep -r "integration" --include="*.json" --include="*.toml" --include="*.yaml" -l | grep -v node_modules | head -5
```

**Node.js specific:**
```bash
cat package.json | grep -E '"test:integration"|"test:e2e"'
```

**Scoring:** PASS = dedicated integration/e2e test directory exists with test files.

### Dimension 3: Benchmarks

**Look for:** Performance benchmarking configuration or files.

```bash
# Node.js
find . -name "*.bench.*" -o -name "bench.js" | grep -v node_modules | head -5
cat package.json | grep -E '"bench"|"benchmark"'

# Python
find . -name "bench_*.py" -o -name "*_bench.py" | head -5
pip show pytest-benchmark 2>/dev/null

# Go
grep -r 'func Benchmark' --include="*_test.go" . | head -5
go test ./... -bench=. -list '.*' 2>/dev/null | head -10

# Rust
cat Cargo.toml | grep -A3 '\[\[bench\]\]'
find . -name "*.rs" | xargs grep -l '#\[bench\]' 2>/dev/null | head -5
```

**Scoring:** PASS = benchmark files exist AND a benchmark command is configured.

### Dimension 4: Static Analysis / Linting

**Look for:** Linter config files and lint scripts.

```bash
# Node.js
ls .eslintrc* .eslintignore eslint.config.* biome.json .prettierrc* 2>/dev/null
cat package.json | grep -E '"lint"|"check"'

# Python
ls .ruff.toml ruff.toml pyproject.toml .flake8 .pylintrc mypy.ini 2>/dev/null
cat pyproject.toml 2>/dev/null | grep -E '\[tool.ruff\]|\[tool.mypy\]|\[tool.pylint\]'

# Go
which staticcheck golangci-lint 2>/dev/null
ls .golangci.yml .golangci.yaml 2>/dev/null

# Rust
cat Cargo.toml | grep -E 'clippy'
```

**Scoring:** PASS = linter is configured AND a lint command exists in scripts/Makefile.

### Dimension 5: Type Checking

```bash
# TypeScript
ls tsconfig.json tsconfig.*.json 2>/dev/null
cat package.json | grep -E '"typecheck"|"tsc"'
npx tsc --noEmit 2>&1 | tail -5

# Python
which mypy 2>/dev/null
cat pyproject.toml 2>/dev/null | grep -A5 '\[tool.mypy\]'
cat mypy.ini 2>/dev/null

# Go — type-checked by compiler, always present if `go build` is configured
go build ./... 2>&1 | head -5

# Rust — type-checked by compiler
cargo check 2>&1 | tail -5
```

**Scoring:** PASS = type checking is configured and produces output (for interpreted languages); compilers count as passing for Go/Rust.

### Dimension 6: Security Scanning

**Look for:** Dependency audit and SAST tools.

```bash
# Node.js
npm audit --json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'vulnerabilities: {d[\"metadata\"][\"vulnerabilities\"]}')" 2>/dev/null || npm audit 2>/dev/null | tail -5

# Python
pip-audit 2>/dev/null || safety check 2>/dev/null | tail -5
which bandit 2>/dev/null && bandit -r . --severity-level medium 2>&1 | tail -5

# Go
which gosec 2>/dev/null && gosec ./... 2>&1 | tail -10
which govulncheck 2>/dev/null && govulncheck ./... 2>&1 | tail -5

# Rust
cargo audit 2>/dev/null | tail -5
```

**Also check for CI-integrated scanning:**
```bash
grep -r "audit\|snyk\|trivy\|grype\|semgrep\|codeql" .github/workflows/ .gitlab-ci.yml 2>/dev/null | head -5
```

**Scoring:** PASS = dependency audit runs AND produces machine-readable output. BONUS = SAST tool configured.

### Dimension 7: CI/CD Pipeline

**Look for:** CI configuration files.

```bash
# GitHub Actions
ls .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null
cat .github/workflows/*.yml 2>/dev/null | grep -E "^(on:|name:|jobs:)" | head -20

# Others
ls .gitlab-ci.yml .circleci/config.yml Jenkinsfile .travis.yml azure-pipelines.yml 2>/dev/null
```

**Check what CI runs:**
```bash
# Verify CI runs tests (not just linting)
grep -l "test\|pytest\|jest\|go test\|cargo test" .github/workflows/*.yml 2>/dev/null
```

**Scoring:** PASS = CI config exists AND it runs at minimum: tests + linting + security scan.

### Dimension 8: Coverage Tracking Over Time

**Look for:** Coverage configuration and reporting to an external service.

```bash
# Config files
ls .coveragerc codecov.yml .codecov.yml .nycrc coverage/.nycrc 2>/dev/null
cat package.json | grep -E '"coverage"|"nyc"'
cat pyproject.toml 2>/dev/null | grep -A5 '\[tool.coverage'

# CI integration
grep -r "codecov\|coveralls\|sonarcloud\|lcov" .github/workflows/ .gitlab-ci.yml 2>/dev/null | head -5
```

**Scoring:** PASS = coverage is collected AND reported to an external tracking service (codecov, coveralls, etc.).

### Dimension 9: Benchmark Tracking Over Time

**Look for:** Benchmark results stored and compared across runs.

```bash
grep -r "benchmark\|perf\|bench" .github/workflows/ .gitlab-ci.yml 2>/dev/null | head -5
ls benchmarks/ bench/ perfs/ 2>/dev/null
```

**Scoring:** PASS = benchmarks run in CI AND results are compared against a baseline (e.g., github-action-benchmark, bencher.dev, or stored artifact).

---

## Step 3: Produce Assessment Report

Use this template for every report:

```
## Repository Assessment: [repo-name]

**Assessed:** [date]
**Ecosystems detected:** [list]

### Dimension Results

| Dimension | Status | Evidence | Notes |
|-----------|--------|----------|-------|
| Unit tests | ✓/✗/⚠ | [command/file found] | [what was missing or incomplete] |
| Integration tests | ✓/✗/⚠ | | |
| Benchmarks | ✓/✗/⚠ | | |
| Static analysis | ✓/✗/⚠ | | |
| Type checking | ✓/✗/⚠ | | |
| Security scanning | ✓/✗/⚠ | | |
| CI/CD pipeline | ✓/✗/⚠ | | |
| Coverage tracking | ✓/✗/⚠ | | |
| Benchmark tracking | ✓/✗/⚠ | | |

Legend: ✓ = present and configured | ✗ = absent | ⚠ = partially present

### Missing Infrastructure (Priority Order)

List each ✗ and ⚠ item with:
- **What's missing:** specific tool or config
- **Why it matters:** what automated auditing can't do without it
- **How to add it:** exact command or config snippet

### Verdict

**SUITABLE / NOT SUITABLE for automated auditing**

A repository is SUITABLE only if ALL of the following are present:
- Unit tests with coverage reporting
- Static analysis configured and passing
- CI/CD pipeline running tests + linting
- Coverage tracked over time

Everything else is recommended but not a blocker.

**Blockers:** [list any SUITABLE-blocking gaps]
**Recommendations:** [list non-blocking improvements]
```

---

## Common Gaps and Fixes

| Gap | Fix |
|-----|-----|
| No test script in package.json | Add `"test": "jest"` to scripts; install jest |
| Tests exist but no coverage | Add `--coverage` flag; configure lcov reporter |
| No CI pipeline | Add `.github/workflows/ci.yml` with test + lint jobs |
| No security scanning in CI | Add `npm audit --audit-level=high` or `pip-audit` step |
| Coverage collected but not tracked | Add codecov action + `codecov.yml` |
| Benchmarks exist but not in CI | Add bench step; store artifact; compare against baseline |
```

- [ ] **Step 2: Verify the SKILL.md renders correctly (word count check)**

```bash
wc -w /Users/jsoverson/development/src/claude-plugins/skills/repo-assessment/SKILL.md
# Target: under 1000 words for the frontmatter; full skill can be longer since it's a reference
```

- [ ] **Step 3: Commit the skill draft**

```bash
cd /Users/jsoverson/development/src/claude-plugins
git add skills/repo-assessment/SKILL.md
git commit -m "feat: write repo-assessment skill GREEN draft"
```

---

### Task 4: GREEN Phase — Run Scenarios With Skill and Verify

**Files:**
- Modify: `skills/repo-assessment/test-scenarios.md` (fill in GREEN results)

**Goal:** Confirm the skill closes the gaps found in the RED baseline.

- [ ] **Step 1: Install the skill locally for testing**

The skill needs to be accessible to Claude Code during the test sessions. Copy it to the personal skills directory:

```bash
cp -r /Users/jsoverson/development/src/claude-plugins/skills/repo-assessment \
  ~/.claude/skills/repo-assessment
```

Verify it appears in the skill list:
```bash
ls ~/.claude/skills/
# Should show: repo-assessment
```

- [ ] **Step 2: Run Scenario A with skill**

In a Claude Code session WITH the `repo-assessment` skill available, send the Scenario A prompt. The agent should:
1. Invoke the `repo-assessment` skill (check session transcript for `Skill` tool call)
2. Run the ecosystem detection commands
3. Check all 9 dimensions
4. Produce a report matching the template

```bash
# Run headless session — must run from this plugin repo so skill loads
cd /Users/jsoverson/development/src/claude-plugins
claude -p "$(grep -A 20 'Prompt:' skills/repo-assessment/test-scenarios.md | head -15)" \
  --allowed-tools=Bash,Read,Skill \
  2>&1 | tee /tmp/green-scenario-a.txt
```

Expected: Report covers all 9 dimensions; agent invokes the skill.

- [ ] **Step 3: Run Scenario B with skill**

Same for Scenario B. Save to `/tmp/green-scenario-b.txt`.

- [ ] **Step 4: Run Scenario C with skill**

Same for Scenario C. Ensure `/tmp/test-repo-assessment` still exists (re-run setup from Task 2 Step 1 if needed).

- [ ] **Step 5: Compare outputs and document**

Read both baseline and skill-assisted outputs. Fill in the "Skill Test Results" section of `skills/repo-assessment/test-scenarios.md`. For each scenario record:
- Which gaps from the baseline are now covered?
- What (if anything) is still missed despite the skill?
- Is the report format matching the template?

- [ ] **Step 6: Commit GREEN results**

```bash
cd /Users/jsoverson/development/src/claude-plugins
git add skills/repo-assessment/test-scenarios.md
git commit -m "test: document GREEN verification results for repo-assessment"
```

---

### Task 5: REFACTOR Phase — Close Gaps Found in Testing

**Files:**
- Modify: `skills/repo-assessment/SKILL.md` (patch specific gaps)

This task only runs if Task 4 reveals gaps. If all three scenarios passed completely, skip to Task 6.

- [ ] **Step 1: Identify gaps from Task 4 results**

For each gap found (dimension the agent missed, command that didn't work, unclear instruction):
1. Note the exact gap
2. Identify where in the skill it should be addressed
3. Draft the specific fix

- [ ] **Step 2: Patch SKILL.md**

For each gap, edit the relevant section of `skills/repo-assessment/SKILL.md`. Common fixes:
- Missing ecosystem: add detection pattern and commands to the Dimension tables
- Unclear scoring: tighten the PASS criteria
- Missing common gap: add row to the "Common Gaps and Fixes" table
- Template unclear: revise report template section

- [ ] **Step 3: Re-run affected scenarios**

Re-run only the scenarios that revealed the gap. Verify the agent now handles them correctly.

- [ ] **Step 4: Commit refactored skill**

```bash
cd /Users/jsoverson/development/src/claude-plugins
git add skills/repo-assessment/SKILL.md skills/repo-assessment/test-scenarios.md
git commit -m "refactor: close gaps found in repo-assessment GREEN testing"
```

---

### Task 6: Final Verification and Deployment Notes

**Files:**
- Modify: `skills/repo-assessment/SKILL.md` (add deployment note at bottom if needed)
- Modify: `CLAUDE.md` (update to mention the new skill)

- [ ] **Step 1: Final self-review against requirements**

Read `requirements/repo-assessment.md` and check each requirement against the skill:

| Requirement | Addressed by |
|-------------|-------------|
| Comprehensive test suite check (unit, integration, benchmarks) | Dimensions 1-3 |
| Static analysis and security checks | Dimensions 4-6 |
| Documentation on how to run checks | Step 2 command blocks |
| Tracking results over time | Dimensions 8-9 |
| Standard commands without searching | Ecosystem-specific command tables |
| Identify what is missing + recommendations | Report template "Missing Infrastructure" + "Common Gaps" |
| Determine suitability verdict | "Verdict" section with explicit SUITABLE criteria |

If any requirement is not addressed, add it to the skill before proceeding.

- [ ] **Step 2: Verify frontmatter is valid**

```bash
head -5 /Users/jsoverson/development/src/claude-plugins/skills/repo-assessment/SKILL.md
# Must show: ---  /  name: repo-assessment  /  description: Use when...
```

Check description length (max 1024 chars total frontmatter):
```bash
python3 -c "
import re
content = open('skills/repo-assessment/SKILL.md').read()
fm = re.search(r'^---\n(.*?)\n---', content, re.DOTALL)
if fm:
    print(f'Frontmatter length: {len(fm.group(0))} chars (max 1024)')
"
```

- [ ] **Step 3: Update CLAUDE.md**

Add a note to `/Users/jsoverson/development/src/claude-plugins/CLAUDE.md` under the repo-assessment section indicating the skill is now at `skills/repo-assessment/SKILL.md` and can be installed via:
```bash
cp -r skills/repo-assessment ~/.claude/skills/
```

- [ ] **Step 4: Final commit**

```bash
cd /Users/jsoverson/development/src/claude-plugins
git add skills/repo-assessment/ CLAUDE.md
git commit -m "feat: complete repo-assessment skill — RED-GREEN-REFACTOR cycle done"
```
