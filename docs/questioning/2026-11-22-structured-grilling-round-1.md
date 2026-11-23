# Structured Grilling, Round 1: file format and answer grammar

**Closed 2026-11-22.** Follow-ups in round 2.

Goal: replace the freeform markdown round files in `plugins/engineering/skills/grilling/SKILL.md` with a structured Q&A file that a human edits easily, an agent queries cheaply, and a nushell TUI can drive. This round settles the data model. TUI questions wait on a feasibility check of `nu` 0.117's `tui` commands (installed at `/opt/homebrew/bin/nu`), which is running now.

Answer under each question and keep the question and recommendation in place. A blank or deleted answer accepts the recommendation.

### R1 Q1: Use TOML as the file format?

Options:

- **TOML**: each question is a table keyed by id. Multi-line strings use `'''`. Hand-editing is easy; `nu` reads it with `open`. Grep is awkward because the answer sits on a line inside a table, not inside a unique tag.
- **XML**: `<answer_18>...</answer_18>` is trivially greppable, but every edit means matching tags, and multi-line freeform text needs no escaping only if you avoid `<` and `&`.
- **Markdown with fixed markers** (today's format, tightened): `**Answer (Q18):**` lines. Readable, but parsing is regex-only and fragile.
- **YAML / JSON**: rejected in your brief as cumbersome to hand-edit.

Sketch:

```toml
[Q18]
title = "Use TOML as the file format?"
body = '''
Longer context, facts, file paths.
'''
recs.a = "TOML"
recs.b = "XML"
answer = ""
```

Grep for one answer still works with a scoped search (`rg -A20 '^\[Q18\]' | rg '^answer'`), but the agent would normally use a script (Q9).

**Recommended:** TOML, with questions keyed `[Q<n>]`.

**Answer:**

### R1 Q2: One file per session instead of one per round?

Today each round is `docs/questioning/YYYY-MM-DD-slug-round-N.md`. With structured data, one file per session (`docs/questioning/YYYY-MM-DD-slug.toml`) lets the TUI page across all rounds, lets a later question reference an earlier one by id, and makes "which questions are still open" one query. Each question carries `round = N`. The cost: the agent appends to a file the user may have open, so the user must save before saying "done".

**Recommended:** One TOML file per session; each question records its round.

**Answer:**

### R1 Q3: Should a blank answer mean "unanswered" instead of "accept the recommendation"?

Today a blank answer accepts the recommendation. You want to leave questions unanswered on purpose. Both can't be true. If blank means unanswered, accepting takes an explicit token (`a`, or `ok` when there is one recommendation), which the TUI reduces to one keystroke. If blank means accept, there is no way to say "not yet".

**Recommended:** Blank means unanswered. Acceptance is explicit.

**Answer:**

### R1 Q4: Letter recommendations `a`, `b`, `c`?

Letters avoid collision with question numbers, so `Q18: b` reads unambiguously. Numbers would make `18.2` style references possible but blur with question ids.

**Recommended:** Lowercase letters, starting at `a`.

**Answer:**

### R1 Q5: One `answer` string with a parsed leading token?

Grammar for the `answer` field:

- `a` / `b` / ...: pick that recommendation.
- `ok`: accept the only recommendation (error if there are several).
- `superseded`: this question no longer applies.
- `re-ask`: the agent should reword it in the next round.
- `b: <text>` or `re-ask: <text>`: token plus a freeform note ("b, but cap it at 3").
- Anything else: freeform answer.

Alternative: two fields, `status` (enum) and `note` (text). Cleaner to query, but two fields to fill by hand for every question, and the TUI hides that cost anyway.

Risk with one string: a freeform answer that happens to start with `a:`. The parser only treats the token as a keyword when it is exactly a recommendation letter or a keyword, followed by end-of-string or `:`.

**Recommended:** One `answer` string with the grammar above.

**Answer:** two fields. If the TUI is good then users won't edit by hand.

### R1 Q6: What does "I don't want my answers to produce high-value context" mean?

Your brief says: "I don't want my answers to produce high-value context. I don't want it to be difficult to find my answers or which question they pertain to." I read this as: when the agent consumes the round, it should not load the whole file (question bodies, all recommendations) into context. It should load a compact digest, one line per question, such as `Q18 b: cap it at 3` or `Q19 accepted: <rec text>`.

**Recommended:** Yes, that is the meaning. The agent reads answers through a digest script, never the full file.

**Answer:** Yes, i meant I WANT my answers to produce high-value context. I don't the act of answering to introduce noise into the session.

### R1 Q7: May the agent mark questions superseded on its own?

If your answer to Q3 makes Q7 moot, the agent should notice. Options:

- Agent writes a separate field (`dropped = "Q3 answer made this moot"`) and never touches your `answer`. The TUI and digest show it as dropped; you can override by answering anyway.
- Agent only proposes it in the next round as a question.

**Recommended:** Agent writes a separate `dropped` field with a reason. Your `answer` always wins over it.

**Answer:**

### R1 Q8: Does `re-ask` create a new question that links back?

When you answer `re-ask`, the agent writes a new question in the next round with a new id and `replaces = "Q7"`. The old question keeps your `re-ask` answer untouched, preserving the record. The alternative, rewriting Q7 in place, breaks the rule that the agent never rewrites your answers and loses the history.

**Recommended:** New question with a new id and a `replaces` link.

**Answer:**

### R1 Q9: Ship nushell scripts in the skill, with `nu` required only for the TUI?

Proposed `plugins/engineering/skills/grilling/scripts/`:

- `digest.nu <file>`: compact answer list for the agent (Q6).
- `validate.nu <file>`: parse check, unknown rec letters, `ok` with multiple recs.
- `review.nu <file>`: the TUI (scope decided next round).

The file stays plain TOML, so without `nu` the agent can still read it and the user can still edit it in any editor. The skill tells the agent to prefer `digest.nu` when `nu` is on PATH.

**Recommended:** Yes. `nu` is optional for the format, required for the TUI and scripts.

**Answer:** That's fine, but assume nushell is installed everywhere.

### R1 Q10: Does the agent write the TOML directly instead of through a script?

Options:

- Agent writes and appends TOML with its normal file tools. Simple; `validate.nu` catches mistakes.
- Agent calls `add.nu --title ... --rec a=... --rec b=...`. Guarantees structure, but long multi-line bodies through CLI args are awkward.

**Recommended:** Agent writes TOML directly, then runs `validate.nu`.

**Answer:**

### R1 Q11: Change `grilling` in place rather than fork a new skill?

`grill-me` and `grill-with-docs` (`plugins/engineering/skills/`) both delegate to `grilling`, so changing it in place upgrades both. `~/.claude/skills/grilling` currently matches the repo copy. Existing `.md` round files from past sessions stay as they are; the new skill only writes `.toml`.

**Recommended:** Change `grilling` in place; no migration of old files.

**Answer:**

### R1 Q12: Add a promptfoo eval for the new format?

`evals/` has configs for `code-comments`, `user-stories`, `write-gooder`, and routing in `skills.yaml`, none for `grilling`. An eval could assert the agent writes valid TOML with lettered recs and replies with only the path and count, and that it parses a filled-in file correctly (`b: note`, `re-ask`, blank).

**Recommended:** Yes, add `evals/grilling.yaml` covering file writing and answer parsing.

**Answer:** Yes, and some evals that let me test the question content themselves (manually, for now)
