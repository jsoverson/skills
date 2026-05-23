# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repository contains Jarrod's personal Claude plugin development workspace: plans, specs, requirements, and example plugins. The primary example is the Superpowers plugin (`examples/claude-superpowers/`), which serves as a reference implementation and source of reusable skills.

The active work-in-progress is a **repo-assessment** skill, specified in `requirements/repo-assessment.md`.

## Engineering Philosophy

Core philosophy is documented in `docs/engineering-philosophies.md`. The key principles that guide all work here:

- **Functional over object-oriented** — pure functions, deterministic behavior, no hidden side effects
- **Minimal centralized state** — state is a liability; isolate and minimize it
- **Composability over inheritance** — small focused pieces that combine freely
- **Declarative over imperative** — code that describes what, not how
- **Simplicity first** — the simplest solution that works is the right starting point
- **Code itself is a liability** — minimize it; buy/maintain rather than build/refactor when value delivery is equivalent

## Skill Development

Skills live in `examples/claude-superpowers/skills/<skill-name>/SKILL.md`. Each skill requires:
- YAML frontmatter with `name` (letters/numbers/hyphens only) and `description` (starts with "Use when...", triggering conditions only — never summarize the skill's workflow in the description)
- Written in third person (injected into system prompts)
- Tested via RED-GREEN-REFACTOR cycle using the `superpowers:writing-skills` skill

**Critical CSO rule:** The description field must describe ONLY when to trigger the skill, never what it does. Skills whose descriptions summarize their workflow get bypassed — agents follow the description instead of reading the full skill.

## Integration Testing (Superpowers plugin)

Integration tests run actual Claude Code sessions in headless mode:

```bash
cd examples/claude-superpowers/tests/claude-code
./test-subagent-driven-development-integration.sh
```

Requirements:
- Claude Code must be installed and available as `claude`
- Local dev marketplace must be enabled: `"superpowers@superpowers-dev": true` in `~/.claude/settings.json`
- Must run FROM the superpowers directory (not from temp dirs) for skills to load

Analyze token usage from any session:
```bash
python3 examples/claude-superpowers/tests/claude-code/analyze-token-usage.py ~/.claude/projects/<project-dir>/<session-id>.jsonl
```

## Repo Structure

```
docs/                          # Engineering philosophies and principles
requirements/                  # Specs for skills under development
  repo-assessment.md           # Active: spec for the repo-assessment skill
examples/
  claude-superpowers/          # Superpowers plugin (reference implementation)
    skills/                    # All skills (SKILL.md per skill)
    hooks/                     # Claude Code session hooks
    tests/claude-code/         # Integration test scripts and helpers
    .claude-plugin/plugin.json # Plugin metadata
  cursor-plugins/              # Cursor plugin examples and schemas
```

## Repo Assessment Skill (Active Development)

The skill being developed assesses repositories for automated auditing suitability. Key criteria from `requirements/repo-assessment.md`:

- Does the repo have comprehensive automated tests (unit, integration, benchmarks)?
- Does it have static analysis and security checks?
- Does it track coverage, benchmark results, and static analysis over time?
- Does it have clear documentation on how to run all checks?

Relevant precedent skills to study: `requesting-code-review`, `receiving-code-review`, `verification-before-completion`, `writing-plans` (all in `examples/claude-superpowers/skills/`).
