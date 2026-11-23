---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round, each question with lettered recommendations and the one you favour. Then wait for the user's answers before the next round.

## The session file

The whole session lives in one TOML file, `docs/questioning/YYYY-MM-DD-slug.toml`. Create the directory if it doesn't exist. Never put the questions in chat. The scripts below live in this skill's `scripts/` directory and run with `nu`.

```toml
topic = "Cache layer"
goal = "Decide how the API caches responses."

[round.1]
decides = "cache store and invalidation"

[Q1]
round = 1
title = "Use Redis as the cache store?"
body = '''
Facts behind the question, with file paths, so the file makes sense on its own later.
'''
recommended = "a"
recs.a = "Redis"
recs.b = "In-process LRU"
choice = ""
note = ""
```

- Number questions `Q1`, `Q2`, ... continuously across rounds; each records its `round`, and each round gets a `[round.N]` table saying what it decides.
- Recs are single letters `a`-`h`. `recommended` names the one you favour; give one rec when there is one sensible answer.
- `choice` and `note` belong to the user. Write them empty and never change them. `choice` is a rec letter, `superseded`, `reask`, or empty; `note` is freeform. Both empty means the question is open.
- Two fields are yours: `dropped = "<reason>"` on an open question an answer made moot, and `replaces = "Q<n>"` on a question that rewords one the user marked `reask`. A user answer on a dropped question wins over the drop.

## Each round

1. Append the round's questions and its `[round.N]` table to the file.
2. Run `nu <skill-dir>/scripts/validate.nu <file>` and fix every error it prints until it prints `ok`.
3. Reply with only the file path, the number of new questions, and the command that opens the answering UI, with absolute paths, for the user to run in their own terminal:
   `nu <skill-dir>/scripts/review.nu <file>`
   Then stop until the user says they're done.

## When the user is done

Run `nu <skill-dir>/scripts/digest.nu <file>`. The digest is your view of the answers: one line per answered question, then the open and dropped ids. Read the full question only for those marked `reask`.

- A `[letter]` line accepts that rec; a note after `--` qualifies it.
- `(freeform)` is the user's own answer in place of the recs.
- `superseded` retires the question.
- `reask`: write a new question in the next round with `replaces` pointing at it, reworded using the note.
- `open` questions stay in the file as they are; the UI lists them first next time.
- Quote an ambiguous answer back in a new question in the next round.
- Mark questions `dropped` that an answer made moot.

The file is a dated record that outlasts the session. After the session ends, edit it only to fix a typo.

If you can't write to the working directory, ask in chat with the same fields and say why.

## The frontier

Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent with a fresh context window to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them and wait.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.
