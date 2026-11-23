# Structured Grilling, Round 2: schema, digest, and TUI

**Closed 2026-11-22.** All recommendations accepted.

Goal: replace the markdown round files of `plugins/engineering/skills/grilling/SKILL.md` with structured Q&A. Round 1 settled these points:
- The format is TOML, with one file per session.
- A blank answer means unanswered.
- Recommendations use letters.
- Answers use two fields, not a parsed string. You expect the TUI to replace hand edits.
- The agent may set `dropped`, and re-ask creates a new question with a `replaces` link.
- Nushell is assumed everywhere, and the agent writes the TOML directly and validates it.
- `grilling` changes in place.
- Evals cover both structure and question content.

A prototype confirmed that nu 0.117 `tui` can run the review UI. It has a table, a preview, key bindings, and a textbox. It also has limits:
- `tui run` needs a real TTY.
- An error inside a hook is silent.
- The textbox keeps its text after a hook runs.
- Single-letter bindings fire only when the textbox is not focused.
- Saving with `open file | merge deep $changes | to toml | save -f file` keeps comments, key order, and `'''` strings.

The prototype is at `/private/tmp/claude-501/-Users-jsoverson-development-src-skills/678d2684-365d-4069-b41d-9e5f84202f7f/scratchpad/p2.nu`.

Answer under each question and keep the question and recommendation in place. A blank or deleted answer accepts the recommendation.

### R2 Q13: Are the two answer fields `choice` and `note`?

The fields:

- `choice`: a letter for a recommendation, or `superseded`, or `reask`, or empty.
- `note`: freeform text.

Derived status:

| choice | note | status |
|---|---|---|
| empty | empty | open |
| `b` | empty | accepted b |
| `b` | text | accepted b, with note |
| empty | text | freeform answer |
| `superseded` | optional reason | superseded |
| `reask` | optional hint | reask |

Alternative: an explicit `status` enum plus `choice` plus `note`. With three fields, you can set a status that contradicts the other two (`status = "open"` with `choice = "b"`).

**Recommended:** Two fields, `choice` and `note`. The scripts derive the status.

**Answer:**

### R2 Q14: Is this the file layout?

```toml
topic = "Structured grilling"
goal = "Replace markdown round files with structured Q&A."

[round.1]
decides = "file format and answer grammar"

[Q13]
round = 2
title = "Two answer fields: choice and note?"
body = '''
Context, facts, file paths.
'''
recommended = "a"          # which rec the agent favors
recs.a = "choice + note"
recs.b = "status + choice + note"
choice = ""
note = ''''''
# agent-only fields, present when used:
# dropped = "Q3 made this moot"
# replaces = "Q7"
```

Questions sit at the top level as `[Q<n>]`, so a grep for `^\[Q13\]` finds one. `recommended` marks the agent's pick among several recs. `[round.N]` holds the one-line purpose that the markdown header used to carry.

**Recommended:** This layout.

**Answer:**

### R2 Q15: What does the digest show?

You want your answers to become high-value context, and answering itself should not add noise. The agent reads only the digest output, which has one block per answered question, like this:

```
Q13 choice + note [a]  -- note: keep status derived
Q14 (freeform) put rounds in a separate file
Q16 superseded  -- by Q13
Q17 reask  -- hint: split into two questions
open: Q18, Q19
dropped: Q20 (Q13 made this moot)
```

Each line holds the question title and the full text of the chosen recommendation or the note. It leaves out bodies and the recommendations you didn't pick. The agent reads the full file only for questions it has to reword (`reask`).

**Recommended:** This format. The agent runs `digest.nu` when you say "done" and does not otherwise read the file.

**Answer:**

### R2 Q16: Do you run the TUI in your own terminal, outside the session?

`tui run` needs a real TTY, and a session-side run would put UI output into the transcript. The agent's reply after each round would be:

```
docs/questioning/2026-11-22-structured-grilling.toml  (6 new questions)
nu plugins/engineering/skills/grilling/scripts/review.nu docs/questioning/2026-11-22-structured-grilling.toml
```

You run the second line in another terminal, answer, then type `done` in the session. Running it with `!` in Claude Code likely fails (no TTY) and would add noise even if it worked.

**Recommended:** You run it in a separate terminal. The agent prints the path, the count, and the exact command.

**Answer:**

### R2 Q17: Is this the TUI key map for v1?

Layout: a question table on the left (id, round, title, status) and a preview on the right (body, lettered recs with the recommended one marked, current choice and note). The table shows open questions first.

Keys while the table has focus:

- `a`-`h`: set `choice` to that letter.
- `enter`: accept the `recommended` rec.
- `s`: superseded.
- `r`: reask.
- `x`: clear the choice and note (back to open).
- `tab` to the note box, type, then `ctrl+s` to save the note, then `esc` to return.
- `q`: quit.

Hooks can't clear the note box, so the textbox may still hold the last note when you move to the next question. A workaround is to load the selected question's note into the box on selection. If `tui` can't do that, the box is used only for typing and the preview shows the saved note.

**Recommended:** This key map. Treat clearing or loading the note box as best effort.

**Answer:**

### R2 Q18: Should the TUI save on every action?

Each key press runs `open file | merge deep {Q13: {choice: "b"}} | to toml | save -f file`. If a crash or `ctrl+c` interrupts the session, no answers are lost. Because each save reads the file again, it doesn't overwrite questions the agent appended while the TUI was open. The alternative, saving once on quit, keeps the file untouched until you finish, but it loses everything if the TUI dies, and hook errors are silent.

**Recommended:** Save on every action, merging into the file as it is on disk.

**Answer:**

### R2 Q19: Should the TUI hide or show agent-dropped questions?

A question with `dropped` set appears in the table with status `dropped (reason)`, sorted after open ones. You can still answer it, which overrides the drop (R1 Q7).

**Recommended:** Show them, sorted last, with the reason in the status column.

**Answer:**

### R2 Q20: What do the manual question-content evals look like?

You asked for evals that test the question content itself, judged by you for now. Proposal for `evals/grilling.yaml`:

- **Structure cases (automated):** a fixed plan prompt. Assertions: `validate.nu` passes on the written file; the reply has only the path, the count, and the command; recs use letters; `recommended` is set.
- **Parsing cases (automated):** a fixture TOML with filled answers, then "done". Assertions: the agent's next round treats blank as open, re-asks `reask` questions with `replaces`, and drops nothing you answered.
- **Content cases (manual):** three or four fixture plans of different shapes, such as a schema migration, a CLI design, or a vague product idea. No assertions; you review the generated questions in `promptfoo view`. Later this could become an LLM rubric (frontier correctness, no question whose answer depends on another open one, facts looked up instead of asked).

**Recommended:** This split, with the content cases unasserted for now.

**Answer:**

### R2 Q21: Should `validate.nu` reject anything beyond parse errors?

Proposed checks:

- Ids are unique and continuous.
- Every question has `round`, `title`, `body`, and at least one rec.
- `recommended` names an existing rec.
- `choice` is empty, a rec letter, `superseded`, or `reask`.
- `replaces` points to an existing question whose choice is `reask`.

It exits non-zero and prints one error per line, so the agent fixes the problems before replying.

**Recommended:** These checks.

**Answer:**
