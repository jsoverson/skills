---
name: user-stories
description: Capture and sharpen what a project's users want and why. Use when a decision about intent or a desired outcome is made or discovered, when writing or editing `docs/user-stories/`, or when asked to write user stories.
---

# User Stories

A user story records intent that must hold true regardless of architecture: what a persona wants, and why. A later reader uses the why to judge trade-offs the story's author never saw.

This skill is for changing the stories. Reading them for context is a habit any skill can do.

## Story form

```md
As a [persona], I want [outcome], so that [why].
```

- One outcome per bullet, in one or two sentences.
- Write from the persona's view of the product, with glossary terms where the persona would use them. `docs/agents/domain.md` names the glossary's path.
- Name the outcome. Mechanisms and module names belong in the code or an ADR.
- The `so that` clause says what the persona gains. Reject a clause that repeats the want.

| Weak | Why it fails | Strong |
| --- | --- | --- |
| As a shopper, I want a Redis-backed cart, so that it is fast. | Names a mechanism | As a shopper, I want my cart to survive closing the app, so that I can finish a purchase later without rebuilding it. |
| As a shopper, I want to save my cart, so that my cart is saved. | The why repeats the want | As a shopper, I want to save my cart, so that I can compare prices elsewhere and come back. |
| As a shopper, I want checkout to be easy. | No why, and nothing could violate it | As a shopper, I want to pay without creating an account, so that a one-time purchase takes no setup. |

## The gate

Record a story only when all four are true:

1. **Outcome**: another architecture could satisfy it. If only one architecture could, it is an ADR candidate: call the Skill tool with "domain-modeling".
2. **Someone wants it**: you can name the persona who would notice if it broke.
3. **Breakable**: you can describe a concrete scenario that violates it.
4. **Not a default**: a future agent or developer could plausibly decide the other way.

Unbuilt intent qualifies. A story needs no code behind it.

## Files

Each persona has one file, `docs/user-stories/[persona].md`, named by role in kebab-case. Create the directory and each file when its first story exists.

```md
# Shopper

People buying from the store, usually on a phone and often between other tasks.

- As a shopper, I want my cart to survive closing the app, so that I can finish a purchase later without rebuilding it.
- As a shopper buying a gift, I want prices left off the packing slip, so that the recipient doesn't learn what I paid.
```

Open with one or two sentences on who this person is and what they use the product for. Add subheadings once clusters of stories appear.

### Personas are few

Most projects need about three personas. Past three, a new one is rare, because excess personas split one person's wants across files and add little.

Put a variation in how someone uses the product in the role phrase of an existing persona's story, as in "As a shopper buying a gift". Create a new file only when a story can't be truthfully written from any existing persona's view. Apply this test even when the user asks for the new persona: show them the story under the closest existing persona, and create the file only if they still want it after seeing that.

## Who may write a story

- **Stated by the user**: write it inline, and quote the bullet in your reply so the user can correct it.
- **Inferred by you** from code, a spec, or a conversation: propose the wording, and write it after the user confirms. Code shows what happens to be true, which may be an accident nobody wanted.

## Moves

Use these whenever a want comes up:

- **Ask why until you reach an outcome.** When the user names a solution ("add a pause button"), ask what they want it for. Record the reason.
- **Remove the mechanism.** Rewrite until another architecture could satisfy the sentence.
- **Probe with a violating scenario.** Invent a case that satisfies the literal words and breaks the intent, and ask whether it is acceptable.
- **Check against existing stories**, across all personas, since two personas' wants can conflict. Surface a conflict directly: "Contradicts [persona]'s user story: [user story], how should we reword the desired outcome?"
- **Check against the code.** If the code contradicts a stated want, say so. Either the story or the code is wrong, and the user decides which.

## Modes

### Capture

A decision about intent came up during other work.

1. Run the moves until the want passes the gate. If it fails, say which test failed and record nothing.
2. Write or propose it, according to who stated it.
3. Go back to the other work.

Done when the story is written, awaiting confirmation, or rejected by the gate.

### Generate

The user asked for stories on a feature or area.

1. Read the glossary, the ADRs, specs for the area, and all existing stories.
2. Identify the personas the area touches, starting from the existing ones.
3. Draft candidates for each persona, and run every draft through the gate.
4. Present the drafts. All of them are inferred, so write only the ones the user confirms.

Done when every persona has been considered and every draft has been accepted, reworded, or rejected.

## Lifecycle

A story states current intent. When the intent changes, edit the bullet in place, and when it dies, delete the bullet. Git holds the old wording.

A bullet is only the sentence: IDs, statuses, and built or unbuilt markers stay out, and acceptance criteria and progress belong in the issue tracker. Cite a story by quoting it.
