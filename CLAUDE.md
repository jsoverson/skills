# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repository holds Jarrod's Claude plugins and the evals for their skills.

## Engineering Philosophy

- **Functional over object-oriented**: pure functions, deterministic behavior, no hidden side effects
- **Minimal centralized state**: state is a liability, so isolate and minimize it
- **Composability over inheritance**: small focused pieces that combine freely
- **Declarative over imperative**: code that describes what, not how
- **Simplicity first**: the simplest solution that works is the right starting point
- **Code itself is a liability**: minimize it, and buy or maintain rather than build or refactor when value delivery is equivalent

## Skill Development

Each skill lives in `plugins/<plugin>/skills/<skill-name>/SKILL.md`, with YAML frontmatter holding `name` (letters, numbers, and hyphens only) and `description`.

Follow the `writing-for-agents` skill. A description states what the skill is and lists its trigger branches. A user-invoked skill sets `disable-model-invocation: true`.

Skills call each other by bare name ("call the Skill tool with `grilling`"), so a skill's dependencies belong in the same plugin.

## Evals

Evals use promptfoo, one config per skill in `evals/`, with routing cases in `evals/skills.yaml`:

```bash
mise run eval                                  # skills.yaml
cd evals && npx promptfoo eval -c <file>.yaml  # one config
```

## Repo Structure

```
.claude-plugin/marketplace.json  # plugin registry
plugins/
  primary/                       # general skills
  engineering/                   # engineering workflow skills, forked from mattpocock/skills
evals/                           # promptfoo configs
```
