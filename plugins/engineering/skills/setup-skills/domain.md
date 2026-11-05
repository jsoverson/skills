# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`GLOSSARY.md`** at the repo root, or
- **`GLOSSARY-MAP.md`** at the repo root if it exists: it points at one `GLOSSARY.md` per context. Read each one relevant to the topic.
- **`docs/adr/`**: read ADRs that touch the area you're about to work in. In multi-context repos, also check `src/<context>/docs/adr/` for context-scoped decisions.
- **`docs/user-stories/`**: read the intent behind decisions that must hold true regardless of architecture.

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. The `/domain-modeling` and `/user-stories` skills create them lazily when terms, decisions, or intent actually get resolved. `/grill-with-docs` reaches both, and `/improve-codebase-architecture` reaches `/domain-modeling`.

## File structure

Single-context repo (most repos):

```
/
├── GLOSSARY.md
├── docs/adr/
│   ├── 0001-event-sourced-orders.md
│   └── 0002-postgres-for-write-model.md
├── docs/user-stories/
│   ├── plugin-developer.md
│   ├── end-user.md
│   └── [persona].md
└── src/
```

Multi-context repo (presence of `GLOSSARY-MAP.md` at the root):

```
/
├── GLOSSARY-MAP.md
├── docs/adr/                          ← system-wide decisions
├── docs/user-stories/
└── src/
    ├── ordering/
    │   ├── GLOSSARY.md
    │   └── docs/adr/                  ← context-specific decisions
    └── billing/
        ├── GLOSSARY.md
        └── docs/adr/
```

## What an ADR is here

An ADR records an architecture decision that code built today depends on, as a current truth. When a decision changes, edit the ADR in place, and when it dies, delete it. Numbers are never reused, so gaps are expected. Status is `accepted` or `provisional`, and a provisional ADR says what would reopen it.

## What a user story is here

A user story is an informal, natural-language description of a software feature written from an end user's perspective. It explains what the user wants and why. A "user" is flexible: a persona can be a developer, a tester, a designer, an actual end user using and interacting with the product, or a type of end user that uses the product a different way.

Sometimes they are easy to describe in advance, and sometimes they emerge at decision points in a development journey.

When an important decision about the intent or desired outcome is made or discovered, identify the persona it falls under and record it as a bullet point under `docs/user-stories/[persona].md`.

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `GLOSSARY.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal: either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag conflicts

If your output contradicts an existing ADR or user story, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 (event-sourced orders), but worth reopening because…_
> _Contradicts [persona]'s user story: [user story], how should we reword the desired outcome?_
