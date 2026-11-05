# ADR Format

ADRs live in `docs/adr/` and use sequential numbering: `0001-slug.md`, `0002-slug.md`, etc.

Create the `docs/adr/` directory lazily: only when the first ADR is needed.

## Template

```md
# {Short title of the decision}

{1-3 sentences: what's the context, what did we decide, and why.}
```

That's it. An ADR can be a single paragraph. The value is in recording *that* a decision was made and *why*, not in filling out sections.

## Optional sections

Only include these when they add genuine value. Most ADRs won't need them.

- **Status** line (`accepted` or `provisional`): a provisional ADR is in force but may still change, and states the condition that would reopen it
- **Considered Options**: only when the rejected alternatives are worth remembering
- **Consequences**: only when non-obvious downstream effects need to be called out

## Numbering

Scan `docs/adr/` for the highest existing number and increment by one. Never reuse a number, so gaps are normal.

## Current truth

An ADR states the current decision. When a decision changes, edit its ADR in place, and when a decision dies, delete its ADR. Git holds the old wording. Don't write amendment sections, "amended by" or "superseded by" lines, or chains of ADRs that must be read together.

## When to offer an ADR

All five of these must be true:

1. **Architecture**: another architecture couldn't satisfy the same statement. "A sentient can satisfy its desires and still die of an unmet need" is a product requirement, because many designs could deliver it. "Opinion is derived from memories and never stored" is architecture
2. **Built**: code depends on it today. An intention for unbuilt work is direction, and goes in the project's plan
3. **Hard to reverse**: the cost of changing your mind later is meaningful
4. **Surprising without context**: a future reader will look at the code and wonder "why on earth did they do it this way?"
5. **The result of a real trade-off**: there were genuine alternatives and you picked one for specific reasons

If a decision is easy to reverse, skip it: you'll just reverse it. If it's not surprising, nobody will wonder why. If there was no real alternative, there's nothing to record beyond "we did the obvious thing."

### What qualifies

- **Architectural shape.** "We're using a monorepo." "The write model is event-sourced, the read model is projected into Postgres."
- **Integration patterns between contexts.** "Ordering and Billing communicate via domain events, not synchronous HTTP."
- **Technology choices that carry lock-in.** Database, message bus, auth provider, deployment target. Not every library: just the ones that would take a quarter to swap out.
- **Boundary and scope decisions.** "Customer data is owned by the Customer context; other contexts reference it by ID only." The explicit no-s are as valuable as the yes-s.
- **Deliberate deviations from the obvious path.** "We're using manual SQL instead of an ORM because X." Anything where a reasonable reader would assume the opposite. These stop the next engineer from "fixing" something that was deliberate.
- **Constraints not visible in the code.** "We can't use AWS because of compliance requirements." "Response times must be under 200ms because of the partner API contract."
- **Rejected alternatives when the rejection is non-obvious.** If you considered GraphQL and picked REST for subtle reasons, record it; otherwise someone will suggest GraphQL again in six months.
