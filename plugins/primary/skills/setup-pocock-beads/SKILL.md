---
name: setup-pocock-beads
description: Initialize Beads and configure Matt Pocock's engineering skills to use it as the issue tracker.
disable-model-invocation: true
---

# Setup Pocock Skills with Beads

Run this once from the repository root.

## Process

1. Run:

   ```bash
   bd init --agents-profile minimal
   ```

   Stop and report the error if initialization fails.

2. Follow [`setup-matt-pocock-skills`](../setup-matt-pocock-skills/SKILL.md) from its **Explore** step onward, with one pre-supplied answer:

   - For **Section A — Issue tracker**, select **Other** and specify: **Use Beads (`bd`) for issue tracking. Run `bd prime` for the current workflow instructions and command reference.**
   - Do not ask the Section A question; treat that answer as confirmed.
   - Continue its remaining questions, draft confirmation, edits, and completion report normally.

Setup is complete when `bd init` succeeded and every completion criterion in `setup-matt-pocock-skills` has been met.
