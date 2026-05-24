---
name: repo-hardening
description: Use when a repo-assessment report has been produced and the repository needs a concrete, ordered plan to address PARTIAL or FAIL quality infrastructure dimensions
---

# Repository Hardening Plan

Transform a repo-assessment report into an executable implementation plan. Each gap becomes a concrete, ordered task with exact commands, config files, and CI workflow additions. The output plan is compatible with `superpowers:executing-plans` and `superpowers:subagent-driven-development`.

**Announce at start:** "I'm using the repo-hardening skill to generate an implementation plan for the assessed gaps."

---

## Step 1 — Locate the Assessment Report

Search for an existing report:

```bash
# Check the canonical location first:
ls reports/assessment/*.md 2>/dev/null | sort -r | head -5
# Fall back to broad search if not found:
find . -maxdepth 5 -name "*.md" | xargs grep -l "Quality Infrastructure Summary" 2>/dev/null | head -5
```

**If no report file is found:** Look for assessment output in the current conversation. If none exists, tell the user: "No repo-assessment report found. Run the `repo-assessment` skill first, then share or save the report before using this skill."

**Extract from the report:**

- Detected ecosystems (line beginning with "Ecosystems detected:")
- Each dimension row: `| # | Dimension | Status | Evidence | Notes |`
- Each "Missing Infrastructure" section (the `### Dimension — PARTIAL/FAIL` blocks with What/Why/How)

Dimensions scored PASS are excluded from the plan. N/A dimensions are excluded.

---

## Step 2 — Build the Remediation Queue

Order gaps by this priority ladder. FAIL at a given priority outranks PARTIAL at the same level. Skip any dimension that scored PASS.

| Priority | Dimension              | Why this order                                            |
| -------- | ---------------------- | --------------------------------------------------------- |
| 1        | 7 — CI/CD Pipeline     | All other gates are useless without automated enforcement |
| 2        | 1 — Unit Tests         | The baseline signal for everything else                   |
| 3        | 4 — Static Analysis    | Cheapest class of bug prevention                          |
| 4        | 6 — Security Scanning  | Blocking for automated auditing                           |
| 5        | 5 — Type Checking      | Prevents silent contract violations                       |
| 6        | 2 — Integration Tests  | Validates cross-component behavior                        |
| 7        | 8 — Coverage Tracking  | Requires tests to be meaningful                           |
| 8        | 3 — Benchmarks         | Requires working code                                     |
| 9        | 9 — Benchmark Tracking | Requires benchmarks to exist                              |

Note dependencies: Dimension 8 (Coverage Tracking) requires Dimension 1 (Unit Tests) to be in place first. Dimension 9 (Benchmark Tracking) requires Dimension 3 (Benchmarks) first. If both ends of a dependency pair need work, they become a single task.

---

## Step 3 — Write the Plan Document

Save to: `docs/plans/hardening/YYYY-MM-DD-PROJECT-hardening.md` (user preferences override).

Derive the project name and date the same way `repo-assessment` does:

```bash
PROJECT=$(git remote get-url origin 2>/dev/null | sed 's|.*/||; s|\.git$||')
[ -z "$PROJECT" ] && PROJECT=$(basename "$(pwd)")
DATE=$(date +%Y-%m-%d)
mkdir -p docs/plans/hardening
PLAN_PATH="docs/plans/hardening/${DATE}-${PROJECT}-hardening.md"
```

**Every plan must start with this header:**

```markdown
# Repository Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring [REPO NAME]'s quality infrastructure to a level suitable for automated auditing without human review.

**Ecosystems:** [LIST FROM REPORT]

**Gaps addressed (in order):** [e.g., CI/CD Pipeline (FAIL), Unit Tests (FAIL), Static Analysis (PARTIAL)]

**Assessment report:** [file path, or "provided in conversation"]

---
```

Then generate one task per gap using the templates below. Only include tasks for dimensions that scored PARTIAL or FAIL. Adapt commands to the detected ecosystem.

---

## Task Templates

### Task: CI/CD Pipeline (Dimension 7 — FAIL)

> Only generate this task if CI/CD scored FAIL. If PARTIAL (CI exists but lacks quality gates), generate a smaller task that adds missing steps to the existing workflow rather than creating a new file.

**Files:**

- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Create the CI workflow directory**

```bash
mkdir -p .github/workflows
```

- [ ] **Step 2: Write the starter workflow**

Choose the template matching the detected ecosystem. If multiple ecosystems are detected, merge the `steps` sections.

**Node.js:**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, master]
  pull_request:

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm test
      - run: npx eslint . --max-warnings=0
      - run: npm audit --audit-level=high
```

**Python:**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, master]
  pull_request:

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: pip install -r requirements.txt
      - run: python -m pytest
      - run: python -m ruff check .
      - run: pip install pip-audit && pip-audit
```

**Go:**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, master]
  pull_request:

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      - run: go test ./...
      - name: golangci-lint
        uses: golangci/golangci-lint-action@v6
      - run: go install golang.org/x/vuln/cmd/govulncheck@latest && govulncheck ./...
```

**Rust:**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, master]
  pull_request:

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: clippy
      - uses: Swatinem/rust-cache@v2
      - run: cargo test
      - run: cargo clippy -- -D warnings
      - run: cargo install cargo-audit && cargo audit
```

- [ ] **Step 3: Verify the workflow file is valid YAML**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))" && echo "Valid YAML"
```

Expected: `Valid YAML`

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add CI workflow with test, lint, and security gates"
```

---

### Task: Unit Tests (Dimension 1 — FAIL)

> Scaffold the test runner and one smoke test to prove the infrastructure works. The goal is a green baseline — not full coverage.

**Files:**

- Create: ecosystem-specific test file (see below)

- [ ] **Step 1: Install the test framework**

| Ecosystem | Command                                                           |
| --------- | ----------------------------------------------------------------- |
| Node.js   | `npm init jest@latest` (accept defaults)                          |
| Python    | `pip install pytest && mkdir -p tests && touch tests/__init__.py` |
| Go        | No install needed; Go has built-in testing                        |
| Rust      | No install needed; Cargo has built-in testing                     |

- [ ] **Step 2: Write one smoke test**

The test verifies the runner works. Replace `<module>` with an actual importable unit.

**Node.js** (`src/__tests__/smoke.test.js` or `.ts`):

```js
test('test runner is wired up', () => {
  expect(true).toBe(true);
});
```

**Python** (`tests/test_smoke.py`):

```python
def test_runner_is_wired_up():
    assert True
```

**Go** (add `_test.go` alongside any existing `.go` file, e.g., `main_test.go`):

```go
package main

import "testing"

func TestRunnerIsWiredUp(t *testing.T) {}
```

**Rust** (add to `src/lib.rs` or `src/main.rs`):

```rust
#[cfg(test)]
mod tests {
    #[test]
    fn runner_is_wired_up() {}
}
```

- [ ] **Step 3: Run the tests and verify they pass**

| Ecosystem | Command                      | Expected             |
| --------- | ---------------------------- | -------------------- |
| Node.js   | `npm test`                   | `Tests: 1 passed`    |
| Python    | `python -m pytest tests/ -v` | `1 passed`           |
| Go        | `go test ./...`              | `ok` on each package |
| Rust      | `cargo test`                 | `test result: ok`    |

- [ ] **Step 4: Commit**

```bash
git add .
git commit -m "test: scaffold test runner with smoke test"
```

---

### Task: Static Analysis / Linting (Dimension 4 — FAIL or PARTIAL)

> If PARTIAL (config exists but not in CI), skip to Step 4.

**Files:**

- Create: linter config file

- [ ] **Step 1: Install and configure the linter**

| Ecosystem | Command                                                                                                   |
| --------- | --------------------------------------------------------------------------------------------------------- |
| Node.js   | `npm init @eslint/config@latest`                                                                          |
| Python    | `pip install ruff`                                                                                        |
| Go        | `brew install golangci-lint` (or `go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest`) |
| Rust      | Built into Cargo; no install needed                                                                       |

- [ ] **Step 2: Create the config file**

**Python** (append to `pyproject.toml`, or create it):

```toml
[tool.ruff]
select = ["E", "F", "I"]
line-length = 88
```

**Go** (`.golangci.yml` in repo root):

```yaml
linters:
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - unused
```

**Node.js:** The `npm init @eslint/config@latest` wizard generates the config interactively.

**Rust:** No config file needed; Clippy uses `-- -D warnings` flag.

- [ ] **Step 3: Run the linter and fix any errors**

| Ecosystem | Command                         |
| --------- | ------------------------------- |
| Node.js   | `npx eslint . --max-warnings=0` |
| Python    | `python -m ruff check . --fix`  |
| Go        | `golangci-lint run ./...`       |
| Rust      | `cargo clippy -- -D warnings`   |

Fix all reported errors before proceeding.

- [ ] **Step 4: Add linting to CI** (if not already present)

Add this step to the `quality` job in `.github/workflows/ci.yml`:

| Ecosystem | Step to add                                                               |
| --------- | ------------------------------------------------------------------------- |
| Node.js   | `- run: npx eslint . --max-warnings=0`                                    |
| Python    | `- run: python -m ruff check .`                                           |
| Go        | (already covered by `golangci/golangci-lint-action` in the CI task above) |
| Rust      | `- run: cargo clippy -- -D warnings`                                      |

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "chore: add linter config and CI lint gate"
```

---

### Task: Security Scanning (Dimension 6 — FAIL or PARTIAL)

> If PARTIAL (scanner runs locally but not in CI), skip to Step 3.

- [ ] **Step 1: Install the security scanner**

| Ecosystem | Command                                               |
| --------- | ----------------------------------------------------- |
| Node.js   | Built into npm; no install needed                     |
| Python    | `pip install pip-audit`                               |
| Go        | `go install golang.org/x/vuln/cmd/govulncheck@latest` |
| Rust      | `cargo install cargo-audit`                           |

- [ ] **Step 2: Run a baseline scan**

| Ecosystem | Command                        |
| --------- | ------------------------------ |
| Node.js   | `npm audit --audit-level=high` |
| Python    | `pip-audit`                    |
| Go        | `govulncheck ./...`            |
| Rust      | `cargo audit`                  |

If vulnerabilities are found, address them (upgrade deps, add `npm audit fix`, etc.) before adding to CI.

- [ ] **Step 3: Add security scanning to CI**

Add this step to `.github/workflows/ci.yml` inside the `quality` job:

| Ecosystem | Step to add                                                                       |
| --------- | --------------------------------------------------------------------------------- |
| Node.js   | `- run: npm audit --audit-level=high`                                             |
| Python    | `- run: pip install pip-audit && pip-audit`                                       |
| Go        | `- run: go install golang.org/x/vuln/cmd/govulncheck@latest && govulncheck ./...` |
| Rust      | `- run: cargo install cargo-audit && cargo audit`                                 |

- [ ] **Step 4: Commit**

```bash
git add .
git commit -m "ci: add security scanning gate"
```

---

### Task: Type Checking (Dimension 5 — FAIL or PARTIAL)

> Skip if the ecosystem is Go or Rust (statically typed by default, already covered by `go build`/`cargo check`). For Node.js: only do this task if the project already uses TypeScript — do not introduce TypeScript to a plain JavaScript project. For Python: install mypy.

- [ ] **Step 1: Install and configure the type checker**

**Node.js (TypeScript projects only):**

```bash
# Verify TypeScript is already a dependency:
cat package.json | grep '"typescript"'
# If present, just ensure tsconfig.json exists:
npx tsc --init  # only if tsconfig.json is missing
```

**Python:**

```bash
pip install mypy
```

- [ ] **Step 2: Create / update type checker config**

**Python** (append to `pyproject.toml`):

```toml
[tool.mypy]
python_version = "3.12"
ignore_missing_imports = true
strict = false
```

**Node.js — tighten an existing `tsconfig.json`** (add these compiler options if absent):

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true
  }
}
```

- [ ] **Step 3: Run the type checker clean**

| Ecosystem | Command                                     | Expected                   |
| --------- | ------------------------------------------- | -------------------------- |
| Node.js   | `npx tsc --noEmit`                          | No output (exit 0)         |
| Python    | `python -m mypy . --ignore-missing-imports` | `Success: no issues found` |

Fix any reported errors.

- [ ] **Step 4: Add to CI**

| Ecosystem | Step to add to `ci.yml`                            |
| --------- | -------------------------------------------------- |
| Node.js   | `- run: npx tsc --noEmit`                          |
| Python    | `- run: python -m mypy . --ignore-missing-imports` |

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "chore: add type checking and CI gate"
```

---

### Task: Integration Tests (Dimension 2 — FAIL or PARTIAL)

> PARTIAL means coverage exists mixed in unit tests. FAIL means none at all. For PARTIAL, skip to Step 3 and focus on creating the separate suite structure.

**Files:**

- Create: `tests/integration/` (Python/Go) or `test/integration/` (Node.js) directory
- Create: one representative integration test

- [ ] **Step 1: Create the integration test directory**

```bash
# Node.js:
mkdir -p test/integration

# Python:
mkdir -p tests/integration && touch tests/integration/__init__.py

# Go:
mkdir -p integration

# Rust:
mkdir -p tests
```

- [ ] **Step 2: Write one integration test that exercises a real boundary**

The test should cross at least one real boundary (file I/O, network call, database, subprocess). For a library with no external dependencies, use end-to-end invocation of the public API from the outside. A smoke test that just returns `true` is not an integration test.

Replace the example below with something real for this codebase. Read `src/` or `lib/` to find the top-level public entry point before writing this test.

**Python** (`tests/integration/test_api_integration.py`):

```python
import subprocess
import sys

def test_cli_entry_point_exits_cleanly():
    result = subprocess.run(
        [sys.executable, "-m", "<your_package>", "--help"],
        capture_output=True
    )
    assert result.returncode == 0
```

**Node.js** (`test/integration/cli.test.js`):

```js
const { execSync } = require('child_process');

test('CLI entry point exits cleanly', () => {
  const result = execSync('node . --help', { encoding: 'utf8' });
  expect(result).toBeTruthy();
});
```

- [ ] **Step 3: Run the integration test**

| Ecosystem | Command                                     | Expected |
| --------- | ------------------------------------------- | -------- |
| Node.js   | `npm test -- --testPathPattern=integration` | 1 passed |
| Python    | `python -m pytest tests/integration/ -v`    | 1 passed |
| Go        | `go test ./integration/...`                 | ok       |
| Rust      | `cargo test --test '*'`                     | ok       |

- [ ] **Step 4: Add to CI as a separate job** (optional but recommended)

Adding a separate `integration` job in CI makes it visible when integration breaks while unit tests still pass:

```yaml
integration:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    # ... setup steps same as quality job ...
    - run: <integration test command from Step 3>
```

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "test: add integration test suite"
```

---

### Task: Coverage Tracking (Dimension 8 — FAIL or PARTIAL)

> Requires Dimension 1 (Unit Tests) to be PASS before this task is meaningful. If unit tests were just added in this plan, this task runs after that task completes.
>
> PARTIAL means coverage is measured but not persisted. FAIL means it's not measured at all.

**Files:**

- Modify: `.github/workflows/ci.yml`

- [ ] **Step 1: Run coverage locally to establish a baseline**

| Ecosystem | Command                                                                        |
| --------- | ------------------------------------------------------------------------------ |
| Node.js   | `npm test -- --coverage`                                                       |
| Python    | `python -m pytest --cov=. --cov-report=term-missing`                           |
| Go        | `go test ./... -coverprofile=coverage.out && go tool cover -func=coverage.out` |
| Rust      | `cargo install cargo-llvm-cov && cargo llvm-cov --summary-only`                |

Note the current percentage. This is the floor — CI should warn (not fail) if it drops below this.

- [ ] **Step 2: Create the git metadata branch for history**

```bash
# Run once to create the orphan branch:
git checkout --orphan etc/coverage
git rm -rf .
git commit --allow-empty -m "init coverage history"
git checkout -  # return to your working branch
```

Verify:

```bash
git branch -a | grep etc/coverage
```

Expected: `etc/coverage` appears in the list.

- [ ] **Step 3: Add coverage measurement and persistence to CI**

Add these steps to `.github/workflows/ci.yml` in the `quality` job, after the test step:

**Node.js:**

```yaml
- run: npm test -- --coverage --coverageReporters=lcov
- name: Store coverage history
  run: |
    git config user.email "ci@github"
    git config user.name "CI"
    git fetch origin etc/coverage:etc/coverage 2>/dev/null || true
    git worktree add /tmp/cov-meta etc/coverage
    cp coverage/lcov.info "/tmp/cov-meta/$(date +%Y-%m-%d)-$(git rev-parse --short HEAD).info"
    git -C /tmp/cov-meta add -A
    git -C /tmp/cov-meta commit -m "coverage: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    git push origin etc/coverage
    git worktree remove /tmp/cov-meta
```

**Python:**

```yaml
- run: python -m pytest --cov=. --cov-report=xml
- name: Store coverage history
  run: |
    git config user.email "ci@github"
    git config user.name "CI"
    git fetch origin etc/coverage:etc/coverage 2>/dev/null || true
    git worktree add /tmp/cov-meta etc/coverage
    cp coverage.xml "/tmp/cov-meta/$(date +%Y-%m-%d)-$(git rev-parse --short HEAD).xml"
    git -C /tmp/cov-meta add -A
    git -C /tmp/cov-meta commit -m "coverage: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    git push origin etc/coverage
    git worktree remove /tmp/cov-meta
```

**Go:**

```yaml
- run: go test ./... -coverprofile=coverage.out
- name: Store coverage history
  run: |
    git config user.email "ci@github"
    git config user.name "CI"
    git fetch origin etc/coverage:etc/coverage 2>/dev/null || true
    git worktree add /tmp/cov-meta etc/coverage
    cp coverage.out "/tmp/cov-meta/$(date +%Y-%m-%d)-$(git rev-parse --short HEAD).out"
    git -C /tmp/cov-meta add -A
    git -C /tmp/cov-meta commit -m "coverage: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    git push origin etc/coverage
    git worktree remove /tmp/cov-meta
```

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add coverage measurement and git metadata branch persistence"
```

---

### Task: Benchmarks (Dimension 3 — FAIL or PARTIAL)

> Only generate this task if the project has performance-sensitive code worth tracking. If this is a CLI tool, configuration library, or other non-performance-critical project, note this and skip the task — not every project needs benchmarks.

**Files:**

- Create: `bench/` (Node.js/Python) or `benches/` (Rust) directory

- [ ] **Step 1: Install the benchmark library**

| Ecosystem | Command                                                      |
| --------- | ------------------------------------------------------------ |
| Node.js   | `npm install --save-dev benchmark`                           |
| Python    | `pip install pytest-benchmark`                               |
| Go        | Built in; no install needed                                  |
| Rust      | Add to `Cargo.toml`: `[dev-dependencies]\ncriterion = "0.5"` |

- [ ] **Step 2: Write one representative benchmark**

Choose the hottest path in the codebase — the function called most or with the largest input. Read the source before writing this.

**Python** (`bench/test_bench.py`):

```python
def test_bench_hot_path(benchmark):
    result = benchmark(lambda: your_function(sample_input))
    assert result is not None
```

**Go** (add to an existing `_test.go` or create `bench_test.go`):

```go
func BenchmarkHotPath(b *testing.B) {
    for i := 0; i < b.N; i++ {
        hotPath()
    }
}
```

**Rust** (`benches/hot_path.rs`):

```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};
use your_crate::hot_path;

fn bench_hot_path(c: &mut Criterion) {
    c.bench_function("hot_path", |b| b.iter(|| hot_path(black_box(input))));
}

criterion_group!(benches, bench_hot_path);
criterion_main!(benches);
```

Also add to `Cargo.toml`:

```toml
[[bench]]
name = "hot_path"
harness = false
```

- [ ] **Step 3: Run the benchmark and capture baseline output**

| Ecosystem | Command                                       |
| --------- | --------------------------------------------- |
| Node.js   | `node bench/index.js`                         |
| Python    | `python -m pytest bench/ --benchmark-only -v` |
| Go        | `go test ./... -bench=. -benchtime=1x`        |
| Rust      | `cargo bench`                                 |

Record the output — this is your performance baseline.

- [ ] **Step 4: Commit**

```bash
git add .
git commit -m "bench: add benchmark suite with baseline measurements"
```

---

### Task: Benchmark Tracking (Dimension 9 — FAIL or PARTIAL)

> Requires Dimension 3 (Benchmarks) to be PASS first.
>
> Mirrors the coverage tracking pattern exactly — uses `etc/benchmarks` orphan branch.

- [ ] **Step 1: Create the git metadata branch**

```bash
git checkout --orphan etc/benchmarks
git rm -rf .
git commit --allow-empty -m "init benchmark history"
git checkout -
```

- [ ] **Step 2: Add benchmark persistence to CI**

Add to `.github/workflows/ci.yml`:

```yaml
- name: Run benchmarks
  run: <benchmark command from Benchmarks task Step 3>
  # Redirect output to a file, e.g.:
  # go test ./... -bench=. > bench.txt
- name: Store benchmark history
  run: |
    git config user.email "ci@github"
    git config user.name "CI"
    git fetch origin etc/benchmarks:etc/benchmarks 2>/dev/null || true
    git worktree add /tmp/bench-meta etc/benchmarks
    cp <benchmark output file> "/tmp/bench-meta/$(date +%Y-%m-%d)-$(git rev-parse --short HEAD).txt"
    git -C /tmp/bench-meta add -A
    git -C /tmp/bench-meta commit -m "bench: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    git push origin etc/benchmarks
    git worktree remove /tmp/bench-meta
```

Replace `<benchmark output file>` and `<benchmark command>` with the ecosystem-specific values from the Benchmarks task.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add benchmark tracking via git metadata branch"
```

---

## Step 4 — Closing Section

Add this to the end of the plan:

```markdown
---

## Verification

After all tasks complete, run the repo-assessment skill again to confirm all targeted dimensions now score PASS.

Expected re-assessment result:

- All dimensions that were PARTIAL or FAIL should now be PASS (or PARTIAL if a dimension was FAIL and this plan only addressed part of it)
- Verdict should change from NOT SUITABLE to SUITABLE (if blocking gaps were all addressed)
```

---

## Step 5 — Self-Review Before Saving

Before saving the plan, check:

1. **Gap coverage:** Can you point to a task for every PARTIAL/FAIL dimension from the report? List any missed.
2. **Ecosystem specificity:** Every command and config matches the detected ecosystem — no generic placeholders.
3. **Dependency order:** Coverage Tracking task appears after Unit Tests. Benchmark Tracking appears after Benchmarks.
4. **No placeholders:** No "TBD", "TODO", "your package name", or "implement as needed" without a concrete example or explicit instruction to the implementer to substitute.

Fix inline. No need to re-review.

---

## Step 6 — Save and Offer Execution

Save the completed plan to `$PLAN_PATH` (derived in Step 3).

Then offer:

**"Plan complete and saved to `docs/plans/hardening/<filename>.md`. Two execution options:**

**1. Subagent-Driven (recommended)** — fresh subagent per task, review between tasks

**2. Inline Execution** — execute tasks in this session with checkpoints

**Which approach?"**

- If Subagent-Driven: use `superpowers:subagent-driven-development`
- If Inline Execution: use `superpowers:executing-plans`
