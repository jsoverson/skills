---
name: cm
description: Use when committing code changes
model: haiku
---

## Step 1: Generate Commit Message

ALL_CHANGES: For each change or group of related changes, generate a brief description of the change. Stop if you reach 10 descriptions.

CHANGE_THEME: Out of those, pick the changes that best represent the theme across the entire diff, then create a one-line conventional commit message that summarizes the theme.

KEY_CHANGES: Select 0-3 key changes and summarize succinctly what was DONE in concise bullet points. Avoid describing "why." Use '-' dashes for the bullet points.

Good Examples:

"add pr-limit job to pr-checks.yml" and "document PR limits in workflows README" are good messages because they describe a chunk of work that was added to a file.

Bad Examples:

"count the author's open prs, drafts included; bot authors are exempt" is a bad message because it is too verbose and describes the "why" rather than the "what."

"add pr-limit job to pr-checks.yml; other jobs wait on it so closed prs run no ci" is bad because the additional verbosity adds nothing meaningful to the description of the change.

### Commit Message Conventions

Use lowercase for everything in the commit message.

Omit any `Co-Authored-By` line from the commit message.

## Step 2: Commit

Commit the relevant changes with the generated commit message.

## Step 3: Present Commit Message

Present the final commit message to the user along with a note 'if you want me to reword this commit, say "reword"'

If the user responds with "reword", undo the last commit and repeat the process starting at Step 1.
