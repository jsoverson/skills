# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repository contains Jarrod's personal Claude plugin development workspace: plans, specs, requirements, example plugins, and skills under development.

New skills being developed for personal use live in `plugins/wip/`. Completed skills are in `plugins/primary/`.

## Engineering Philosophy

Core philosophy is documented in `docs/engineering-philosophies.md`. The key principles that guide all work here:

- **Functional over object-oriented** — pure functions, deterministic behavior, no hidden side effects
- **Minimal centralized state** — state is a liability; isolate and minimize it
- **Composability over inheritance** — small focused pieces that combine freely
- **Declarative over imperative** — code that describes what, not how
- **Simplicity first** — the simplest solution that works is the right starting point
- **Code itself is a liability** — minimize it; buy/maintain rather than build/refactor when value delivery is equivalent

## Skill Development

Skills being developed here live in `skills/<skill-name>/SKILL.md`. Reference/upstream skills live in `examples/claude-superpowers/skills/<skill-name>/SKILL.md`. Each skill requires:
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
docs/
  engineering-philosophies.md  # Core engineering principles
  plans/                       # Implementation plans (YYYY-MM-DD-<feature>.md)
requirements/                  # Specs for skills under development
skills/                        # Skills developed in this repo (symlinked to ~/.claude/skills/)
  repo-assessment/SKILL.md     # Completed: repo auditing suitability assessment
examples/
  claude-superpowers/          # Superpowers plugin (reference implementation)
    skills/                    # All skills (SKILL.md per skill)
    hooks/                     # Claude Code session hooks
    tests/claude-code/         # Integration test scripts and helpers
    .claude-plugin/plugin.json # Plugin metadata
  cursor-plugins/              # Cursor plugin examples and schemas
```

## Repo Assessment Skill

The completed skill is at `skills/repo-assessment/SKILL.md`.

For live development iteration, symlink instead of copying:
```bash
ln -s $(pwd)/skills/repo-assessment ~/.claude/skills/repo-assessment
```

The skill was developed following the RED-GREEN-REFACTOR methodology documented in `skills/repo-assessment/test-scenarios.md`. Baseline testing (RED phase), skill writing (GREEN phase), and gap closing (REFACTOR phase) are all documented there.

The skill assesses nine dimensions: unit tests, integration tests, benchmarks, static analysis, type checking, security scanning, CI/CD pipeline, coverage tracking, and benchmark tracking. It includes ecosystem-specific commands for Node.js, Python, Go, and Rust.
