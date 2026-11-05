---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.

## Rounds live in files

Write each round to its own file, `docs/questioning/YYYY-MM-DD-slug-round-N.md`, and create the directory if it doesn't exist. The user answers in the file, so each answer stays next to its question and recommendation. Never put the questions in chat. Reply with only the file's path and the number of questions, then stop until the user says they're done.

Format a round file like so:

```md
# <Topic>, Round N: <what this round decides>

<One or two sentences: the session's goal and what the earlier rounds settled.>

Answer under each question and keep the question and recommendation in place. A blank or deleted answer accepts the recommendation.

### RN Q1: <question title>

<Question body, might be multiple paragraphs, including multiple choices. Include the facts behind it, with file paths, so the file makes sense on its own later.>

**Recommended:** <your recommended answer>

**Answer:**

### RN Q2: <question title>

<Question body>

**Recommended:** <your recommended answer>

**Answer:**
```

Number questions continuously across rounds. Word each question so "yes" accepts your recommended answer.

When the user says they're done, re-read the file, because they may have edited more than the answers:

- A blank **Answer:** or a deleted **Answer:** line accepts the recommendation.
- Ask about an ambiguous answer in the next round, quoting it.
- Never rewrite the user's answers. You may mark the round closed, and add a dated note beside an answer if a later round clarified it.

These files are a dated record that outlasts the session. Don't update them after the session ends, except to fix a typo.

If you can't write to the working directory, ask in chat with the same fields and say why.

## The frontier

Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent with a fresh context window to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them and wait.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.
