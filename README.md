# Jarrod's Claude Plugins

This repo contains Jarrod's claude plugins, plans, specs, examples, and notes.

Jarrod's plugins are designed to be used with the claude superpowers framework, and are focused on code quality assessment, code review, and automated auditing.

## Repo Hardening prompt

```
Run repo-assessment to generate an analysis, then use repo-hardening to write the plan. Stop before executing it.
```

```
Execute the hardening plan at docs/plans/<filename>.md using superpowers:subagent-driven-development.
```
