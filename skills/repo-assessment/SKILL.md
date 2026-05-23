---
name: repo-assessment
description: Use when assessing whether a repository has sufficient automated testing, static analysis, security scanning, and CI/CD infrastructure to support automated code auditing without human review
---

# Repository Assessment

Assess whether a repository's automated quality infrastructure is sufficient for trustworthy continuous auditing. Human review is not a reliable quality signal — this assessment determines whether automated systems can substitute for it.

Execute steps in order. Do not backtrack. Produce the report template at the end.

---

## Step 1 — Detect Ecosystems

Run the detection command, then map findings to ecosystems using the table.

```bash
find . -maxdepth 3 \( \
  -name "package.json" -o -name "package-lock.json" -o -name "yarn.lock" -o -name "pnpm-lock.yaml" \
  -o -name "requirements.txt" -o -name "pyproject.toml" -o -name "setup.py" -o -name "Pipfile" -o -name "uv.lock" \
  -o -name "go.mod" -o -name "go.sum" \
  -o -name "Cargo.toml" -o -name "Cargo.lock" \
  -o -name "pom.xml" -o -name "build.gradle" -o -name "build.gradle.kts" \
  -o -name "*.csproj" -o -name "*.sln" \
  -o -name "Gemfile" -o -name "Gemfile.lock" \
\) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | sort
```

| Indicator File(s) | Ecosystem |
|---|---|
| `package.json`, `yarn.lock`, `pnpm-lock.yaml`, `package-lock.json` | Node.js |
| `requirements.txt`, `pyproject.toml`, `setup.py`, `Pipfile`, `uv.lock` | Python |
| `go.mod`, `go.sum` | Go |
| `Cargo.toml`, `Cargo.lock` | Rust |
| `pom.xml`, `build.gradle`, `build.gradle.kts` | Java/JVM |
| `*.csproj`, `*.sln` | .NET |
| `Gemfile`, `Gemfile.lock` | Ruby |

> **Note — Ruby and JVM ecosystems:** Detection only. Step 2 commands cover Node.js, Python, Go, and Rust. For Ruby, Java/JVM, .NET, or other ecosystems, apply the same dimensional framework using the ecosystem's standard toolchain (e.g., `mvn test`, `bundle exec rspec`, `dotnet test`).

Record every detected ecosystem. Repos may have multiple. Run all applicable commands for each detected ecosystem in Step 2.

---

## Step 2 — Score Nine Dimensions

Score each dimension PASS / PARTIAL / FAIL using the criteria in the table. Run the listed commands — do not infer from file presence alone.

### Dimension 1: Unit Tests

**Look for:** `test/`, `tests/`, `__tests__/`, `spec/`, `src/**/*.test.*`, `src/**/*.spec.*`

| Ecosystem | Command |
|---|---|
| Node.js | `npm test 2>&1 \| tail -20` |
| Python | `python -m pytest --collect-only -q 2>&1 \| tail -20` |
| Go | `go test ./... -list '.*' 2>&1 \| tail -20` |
| Rust | `cargo test -- --list 2>&1 \| tail -20` |

| Score | Criterion |
|---|---|
| PASS | Tests exist AND run to completion (exit 0 or known failures, not "no tests found") |
| PARTIAL | Test files exist but runner errors out or no tests collected |
| FAIL | No test files found, or runner reports 0 tests |

### Dimension 2: Integration Tests

**Look for:** `integration/`, `e2e/`, `test/integration/`, `cypress/`, `playwright/`, files named `*.integration.*` or `*.e2e.*`

```bash
find . -maxdepth 4 \( \
  -path "*/integration*" -o -path "*/e2e*" \
  -o -name "*.integration.*" -o -name "*.e2e.*" \
  -o -name "cypress.config.*" -o -name "playwright.config.*" \
\) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | sort
```

| Ecosystem | Command |
|---|---|
| Node.js | `npm run test:integration 2>&1 \| tail -10` (or `test:e2e`) — Note: if the integration/e2e script doesn't exist, score from `find` results only — a missing script name does not mean FAIL. |
| Python | `python -m pytest tests/integration/ -q --collect-only 2>&1 \| tail -10` |
| Go | `go test ./... -tags integration -list '.*' 2>&1 \| tail -10` |
| Rust | `cargo test --test '*' -- --list 2>&1 \| tail -10` |

| Score | Criterion |
|---|---|
| PASS | Dedicated integration/e2e test suite exists and is runnable |
| PARTIAL | Some integration coverage mixed into unit tests but no separate suite |
| FAIL | No integration tests found |

### Dimension 3: Benchmarks

**Look for:** `bench/`, `benches/`, files named `*.bench.*`, `benchmark*`, `perf/`, `criterion` in Cargo.toml

```bash
find . -maxdepth 4 \( \
  -path "*/bench*" -o -path "*/perf*" \
  -o -name "*.bench.*" -o -name "benchmark*" \
\) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | sort
```

| Ecosystem | Command |
|---|---|
| Node.js | `npm run bench 2>&1 \| tail -10` (or `benchmark`) |
| Python | `python -m pytest --co -q -k bench 2>&1 \| tail -10` |
| Go | `go test ./... -bench=. -benchtime=1x 2>&1 \| tail -20` |
| Rust | `cargo bench --no-run 2>&1 \| tail -10` |

| Score | Criterion |
|---|---|
| PASS | Benchmark suite exists and produces numeric output |
| PARTIAL | Benchmark files exist but no runnable suite or no numeric output |
| FAIL | No benchmark files found |

### Dimension 4: Static Analysis / Linting

**Look for:** `.eslintrc*`, `eslint.config.*`, `.pylintrc`, `ruff.toml`, `.flake8`, `golangci.yml`, `.golangci*`, `clippy.toml`, `.rubocop.yml`

```bash
find . -maxdepth 3 \( \
  -name ".eslintrc*" -o -name "eslint.config.*" \
  -o -name ".pylintrc" -o -name "ruff.toml" -o -name ".flake8" -o -name ".ruff.toml" \
  -o -name ".golangci*" -o -name "golangci.yml" \
  -o -name "clippy.toml" -o -name ".clippy.toml" \
  -o -name ".rubocop.yml" -o -name ".rubocop*" \
\) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | sort
```

| Ecosystem | Command |
|---|---|
| Node.js | `npx eslint . --max-warnings=0 2>&1 \| tail -10` |
| Python | `python -m ruff check . 2>&1 \| tail -10` (fallback: `python -m flake8 . 2>&1 \| tail -10`) |
| Go | `golangci-lint run ./... 2>&1 \| tail -10` (fallback: `go vet ./... 2>&1 \| tail -10`) |
| Rust | `cargo clippy -- -D warnings 2>&1 \| tail -10` |

| Score | Criterion |
|---|---|
| PASS | Linter config exists AND linter runs without "command not found" (Go: requires `golangci-lint` configured — `go vet` alone is not sufficient for PASS) |
| PARTIAL | Linter config exists but not in CI, or only default rules with no config file; Go: `go vet` alone (without `golangci-lint`) scores PARTIAL, not PASS |
| FAIL | No linter config and not referenced in CI |

### Dimension 5: Type Checking

**Look for:** `tsconfig.json`, `tsconfig.*.json`, `mypy.ini`, `pyrightconfig.json`, `.mypy.ini`, `pyproject.toml` with `[tool.mypy]` or `[tool.pyright]`

```bash
find . -maxdepth 3 \( \
  -name "tsconfig.json" -o -name "tsconfig.*.json" \
  -o -name "mypy.ini" -o -name ".mypy.ini" -o -name "pyrightconfig.json" \
\) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | sort
# Also check pyproject.toml for mypy/pyright sections:
grep -l "\[tool\.mypy\]\|\[tool\.pyright\]" pyproject.toml 2>/dev/null
```

| Ecosystem | Command |
|---|---|
| Node.js (TypeScript) | `npx tsc --noEmit 2>&1 \| tail -10` |
| Python (mypy) | `python -m mypy . --ignore-missing-imports 2>&1 \| tail -10` |
| Python (pyright) | `pyright . 2>&1 \| tail -10` |
| Go | `go build ./... 2>&1 \| tail -10` (Go is statically typed by default) |
| Rust | `cargo check 2>&1 \| tail -10` (Rust is statically typed by default) |

| Score | Criterion |
|---|---|
| PASS | Type checker config exists AND runs clean (or with only known errors) |
| PARTIAL | TypeScript/typed Python used but no strict config or not run in CI |
| FAIL | No type checking configured; untyped JavaScript or unannotated Python |

### Dimension 6: Security Scanning

**Look for:** `.github/workflows/` with `audit`, `snyk`, `trivy`, `grype`, `semgrep`; `.snyk`; `trivy.yaml`; SBOM files

```bash
find . -maxdepth 4 \( \
  -name ".snyk" -o -name "trivy.yaml" -o -name ".trivyignore" \
  -o -name "semgrep.yml" -o -name ".semgrep*" \
\) -not -path "*/.git/*" 2>/dev/null | sort
# Check CI for security tooling:
grep -r "audit\|snyk\|trivy\|grype\|semgrep\|dependabot\|renovate" .github/ .circleci/ .gitlab-ci.yml 2>/dev/null | grep -v ".git" | head -20
```

| Ecosystem | Command |
|---|---|
| Node.js | `npm audit --audit-level=high 2>&1 \| tail -20` |
| Python | `pip-audit 2>&1 \| tail -20` (fallback: `safety check 2>&1 \| tail -20`) |
| Go | `govulncheck ./... 2>&1 \| tail -20` |
| Rust | `cargo audit 2>&1 \| tail -20` |

| Score | Criterion |
|---|---|
| PASS | Security scanner runs AND is integrated in CI (Dependabot/Renovate counts) |
| PARTIAL | Scanner available locally but not in CI, or only Dependabot with no active scan |
| FAIL | No security scanning configured; audit command errors with "not found" |

### Dimension 7: CI/CD Pipeline

**Look for:** `.github/workflows/*.yml`, `.gitlab-ci.yml`, `.circleci/config.yml`, `Jenkinsfile`, `.travis.yml`, `azure-pipelines.yml`, `bitbucket-pipelines.yml`

```bash
find . -maxdepth 4 \( \
  -path "*/.github/workflows/*.yml" -o -path "*/.github/workflows/*.yaml" \
  -o -name ".gitlab-ci.yml" \
  -o -path "*/.circleci/config.yml" \
  -o -name "Jenkinsfile" \
  -o -name ".travis.yml" \
  -o -name "azure-pipelines.yml" \
  -o -name "bitbucket-pipelines.yml" \
\) -not -path "*/.git/*" 2>/dev/null | sort
```

For each found CI file, check which steps are automated:

```bash
# Summarize job names in GitHub Actions:
grep -h "^\s*\(name:\|run:\|uses:\)" .github/workflows/*.yml 2>/dev/null | head -40
```

| Score | Criterion |
|---|---|
| PASS | CI config exists AND references at least test + lint steps |
| PARTIAL | CI config exists but only runs build (no test or lint) |
| FAIL | No CI config found |

### Dimension 8: Coverage Tracking Over Time

**Look for:** `.codecov.yml`, `codecov.yml`, `.coveragerc`, `coverage.xml`, `lcov.info`, Coveralls config, SonarCloud config, CI steps that upload coverage

```bash
find . -maxdepth 4 \( \
  -name ".codecov.yml" -o -name "codecov.yml" \
  -o -name ".coveralls.yml" -o -name ".coveragerc" \
  -o -name "sonar-project.properties" \
\) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | sort
# Check CI for coverage upload:
grep -r "codecov\|coveralls\|sonar\|lcov\|coverage upload\|coverage report" .github/ .circleci/ .gitlab-ci.yml 2>/dev/null | grep -v ".git" | head -20
```

| Ecosystem | Command |
|---|---|
| Node.js | `npm test -- --coverage 2>&1 \| tail -20` (or `npx jest --coverage`) |
| Python | `python -m pytest --cov=. --cov-report=term-missing 2>&1 \| tail -20` |
| Go | `go test ./... -coverprofile=coverage.out && go tool cover -func=coverage.out 2>&1 \| tail -10` |
| Rust | `cargo llvm-cov --summary-only 2>&1 \| tail -10` (fallback: `cargo tarpaulin --print-summary 2>&1 \| tail -10`) |

| Score | Criterion |
|---|---|
| PASS | Coverage is measured AND results are uploaded to a tracking service (Codecov, Coveralls, SonarCloud, etc.) in CI |
| PARTIAL | Coverage is measured locally or in CI but not uploaded or trended |
| FAIL | No coverage measurement configured |

### Dimension 9: Benchmark Tracking Over Time

**Look for:** `bencher.yml`, `.bencher/`, Continuous Benchmarking section in CI, `criterion` output stored as artifacts, GitHub Actions benchmark action (`benchmark-action/github-action-benchmark`)

```bash
find . -maxdepth 4 \( \
  -name "bencher.yml" -o -name ".bencher.yml" -o -path "*/.bencher/*" \
\) -not -path "*/.git/*" 2>/dev/null | sort
# Check CI for benchmark tracking:
grep -r "bencher\|benchmark-action\|continuous.bench\|gh-pages.*bench\|store.*bench\|bench.*artifact" .github/ .circleci/ .gitlab-ci.yml 2>/dev/null | grep -v ".git" | head -20
```

| Score | Criterion |
|---|---|
| PASS | Benchmarks run in CI AND results are stored or compared across runs (Bencher, GitHub Pages, artifact history, or regression alerts) |
| PARTIAL | Benchmarks exist and run in CI but results are discarded (no history) |
| FAIL | No benchmark tracking in CI |

---

## Step 3 — Fill Report Template

Use this template exactly. Replace every `[PLACEHOLDER]` with findings. Do not omit sections.

```
# Repository Assessment: [REPO NAME]

Date: [DATE]
Ecosystems detected: [LIST ALL]

## Quality Infrastructure Summary

Legend: ✓ = PASS  ⚠ = PARTIAL  ✗ = FAIL

| # | Dimension | Status | Evidence | Notes |
|---|---|---|---|---|
| 1 | Unit Tests | [✓/✗/⚠] | [file or command output] | [one line] |
| 2 | Integration Tests | [✓/✗/⚠] | [file or command output] | [one line] |
| 3 | Benchmarks | [✓/✗/⚠] | [file or command output] | [one line] |
| 4 | Static Analysis | [✓/✗/⚠] | [file or command output] | [one line] |
| 5 | Type Checking | [✓/✗/⚠] | [file or command output] | [one line] |
| 6 | Security Scanning | [✓/✗/⚠] | [file or command output] | [one line] |
| 7 | CI/CD Pipeline | [✓/✗/⚠] | [file or command output] | [one line] |
| 8 | Coverage Tracking | [✓/✗/⚠] | [file or command output] | [one line] |
| 9 | Benchmark Tracking | [✓/✗/⚠] | [file or command output] | [one line] |

## Missing Infrastructure

List only dimensions scored PARTIAL or FAIL, ordered by impact (blocking gaps first).

### [DIMENSION NAME] — [PARTIAL/FAIL]
- **What:** [specific gap]
- **Why:** [consequence for automated auditing]
- **How:** [exact fix command or config to add]

(repeat for each gap)

## Verdict

**SUITABLE / NOT SUITABLE for automated auditing**

Criteria for SUITABLE (ALL must be true):
- Dimension 1 (Unit Tests): PASS
- Dimension 4 (Static Analysis): PASS
- Dimension 6 (Security Scanning): PASS or PARTIAL
- Dimension 7 (CI/CD Pipeline): PASS
- No more than 1 dimension scored FAIL

If NOT SUITABLE, state the blocking gaps (FAIL scores on dimensions 1, 4, 6, or 7, or more than 1 total FAIL).
```

---

## Step 4 — Common Gaps Quick Reference

| Gap | Fix Command / Config |
|---|---|
| No Node.js unit tests | `npm init jest@latest` |
| No Python unit tests | `pip install pytest && mkdir tests && touch tests/__init__.py` |
| No Go tests | Create `*_test.go` file with `func TestXxx(t *testing.T)` |
| No Rust tests | Add `#[cfg(test)] mod tests { ... }` to `src/lib.rs` |
| No ESLint config | `npm init @eslint/config@latest` |
| No Python linter | `pip install ruff && echo -e '[tool.ruff]\nselect = ["E", "F"]' >> pyproject.toml` |
| No golangci-lint | `brew install golangci-lint && golangci-lint run` |
| No Clippy config | `cargo clippy -- -D warnings` (add to CI) |
| No TypeScript types | `npm install --save-dev typescript && npx tsc --init` |
| No mypy | `pip install mypy && mypy . --ignore-missing-imports` |
| No npm security audit in CI | Add `npm audit --audit-level=high` to CI workflow |
| No pip-audit in CI | `pip install pip-audit` then add `pip-audit` to CI |
| No govulncheck in CI | `go install golang.org/x/vuln/cmd/govulncheck@latest` then add to CI |
| No cargo-audit in CI | `cargo install cargo-audit` then add `cargo audit` to CI |
| No CI pipeline | Create `.github/workflows/ci.yml` with test + lint jobs |
| No coverage tracking | Add Codecov: `pip install codecov` or `npm i -D @codecov/webpack-plugin`; add upload step in CI |
| No benchmark tracking | Add `benchmark-action/github-action-benchmark` to CI workflow |
