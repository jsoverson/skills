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
- No CI/CD workflow files (.github/ exists but no workflows/ directory)
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
- Contains multiple plugin example subdirectories (agent-compatibility, cli-for-agent, continual-learning, create-plugin, cursor-sdk, cursor-team-kit, docs-canvas, orchestrate, pr-review-canvas, ralph-loop, teaching, etc.) plus JSON schemas and README
- Verdict should be: NOT SUITABLE (no test suite, no linting, no security scanning)

---

## Scenario C: Minimal/Ambiguous Repo

**Setup before running:**
```bash
mkdir -p /tmp/test-repo-assessment/src /tmp/test-repo-assessment/tests
git -C /tmp/test-repo-assessment init
echo '{"name":"my-app","version":"1.0.0","scripts":{"test":"echo no tests"}}' > /tmp/test-repo-assessment/package.json
echo 'def hello(): pass' > /tmp/test-repo-assessment/src/main.py
touch /tmp/test-repo-assessment/requirements.txt
git -C /tmp/test-repo-assessment add .
git -C /tmp/test-repo-assessment commit -m "initial"
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

- Date run: 2026-05-23
- What agent checked spontaneously: All 7 dimensions; file tree, test files (JS, shell, .mjs), .github/ for CI, package.json, linting config filenames, YAML files. Identified 5 deterministic test suites and 2 LLM-dependent test suites.
- What agent missed: Did not run npm audit or check for vulnerabilities. Did not check specific coverage config files (.nycrc, codecov.yml). Did not check for benchmark tracking integrations (bencher.dev, github-action-benchmark). Did not verify tests actually pass.
- Report structure: Systematic — covered all 7 requested dimensions in order, gave priority-ordered missing infrastructure list.
- Key gaps: No explicit commands run (knowledge-based), no standardized pass/fail criteria per dimension, coverage/benchmark config files not checked.

### Scenario B (cursor-plugins) — Baseline

- Date run: 2026-05-23
- What agent checked spontaneously: All 7 dimensions; full file tree, .github/workflows/, CI workflow file in detail, orchestrate/scripts subdirectory (found tests), biome.json, tsconfig.json.
- What agent missed: Did not check for Dependabot config. Did not check coverage config files. Did not run any commands to verify what tools are installed. Did not assess depth of test coverage beyond file inspection.
- Report structure: Systematic — covered all 7 dimensions with clear section headers. Prose-heavy but organized.
- Key gaps: Discovered the repo is more complex than expected (has a real test suite in orchestrate/scripts). Inconsistent report format compared to Scenario A output. No standardized pass/fail criteria.

**Pattern observed across both baselines:**
1. Agents naturally cover all major dimensions when explicitly prompted for them
2. Agents do NOT run verification commands (npm audit, pip-audit, etc.) — they infer from file presence
3. Agents do NOT check specific coverage/benchmark tracking config files
4. Report format varies — narrative vs structured depending on agent style
5. No consistent SUITABLE/NOT SUITABLE criteria used; agents infer from gestalt assessment
6. Agents identify the primary ecosystem well but may miss multi-ecosystem signals

The skill must provide: (1) explicit run commands per ecosystem, (2) coverage/benchmark config file checklists, (3) a standardized report template, and (4) explicit SUITABLE criteria.

### Scenario C (temp repo) — Baseline
- Date run: (to be filled)
- What agent checked spontaneously:
- What agent missed:
- Report structure (systematic or ad hoc?):
- Key gaps:

---

## Skill Test Results (GREEN Phase — filled in after running WITH skill)

**Pass criteria:** Agent's report covers all 7 prompt items, applies the skill's assessment framework systematically, and verdict matches expected findings.

### Scenario A (claude-superpowers) — With Skill
- Date run: 2026-05-23
- Improvement over baseline: Skill directed `npm audit`, `npx eslint .`, and `npx tsc --noEmit` — none of which the RED baseline ran. Confirmed ENOLOCK (missing lockfile) as a security signal, confirmed no ESLint config via migration error, confirmed no TypeScript toolchain. All 9 dimensions scored with explicit evidence from commands. Standardized SUITABLE criteria applied unambiguously.
- Still missing: Skill does not anticipate the `npx tsc` stub-package false output when TypeScript is absent; ENOLOCK is not called out as distinct from "command not found"; no guidance on tests in subdirectories only (PARTIAL vs FAIL boundary unclear).
- Report structure: Systematic — 9-row scored table, ordered Missing Infrastructure section, explicit SUITABLE/NOT SUITABLE verdict block.
- Pass/Fail: PASS

### Scenario B (cursor-plugins) — With Skill
- Date run: 2026-05-23
- Improvement over baseline: Ecosystem detection explicitly confirmed zero ecosystem files — forced the assessor to handle a "no ecosystem" case cleanly. Security grep confirmed no Dependabot. Coverage and benchmark tracking finds confirmed absence of config files explicitly. Consistent report structure identical to Scenario A output.
- Still missing: Skill has no "no ecosystem detected" path — assessor must apply judgment when Step 1 returns empty. No guidance for JSON/schema-only repos that have no executable code. CI PARTIAL vs PASS line could be clearer for custom validation scripts.
- Report structure: Systematic — identical 9-row table format as Scenario A, ordered gaps, explicit verdict block.
- Pass/Fail: PASS

### Scenario C (temp repo) — With Skill
- Date run: (to be filled)
- Improvement over baseline:
- Still missing:
- Report structure (systematic or ad hoc?):
- Pass/Fail:
