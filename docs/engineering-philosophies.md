description: These are company engineering philosophies and principles that guide our architecture, code, and culture.

---

# **Engineering Philosophies and Principles**

## **As engineers, we prioritize:**

- **Delivering user value over designing perfect systems** _Users don’t care about code or code
  quality. We are OK buying – not building – and maintaining – not refactoring – if we can provide
  value without impeding progress._
- **Statelessness and immutability over mutable, stateful patterns** _State is important, but we
  strive to isolate and minimize it. When long-lived, mutable state is unavoidable, we ensure it is
  exposed for traceability and testing._
- **Platforms over fit-for-purpose systems** _While it is faster to build bespoke software for a
  single need, we value building flexible platforms we can iterate on top of to accelerate
  innovation over time._
- **Pure, functional patterns over object-oriented design** _While object oriented design can model
  complex domains, we emphasize transforming data with deterministic, testable, and composable logic
  over modeling behavior._
- **Deterministic behavior over implicit variability** _While randomness and concurrency have their
  place, we confine nondeterminism to the edges and minimize the impact of variability before
  regaining determinism._

## **Principles Behind the Engineering Manifesto**

We follow these principles to guide our architecture, our code, and our culture:

- **Simplicity first**
  The simplest solution that works is the right starting point.
- **Empathize with users, don’t blame them** Users push boundaries, expose edge cases, and reveal
  what actually matters. We never blame users for confusion, mistakes, or unexpected usage.
- **Bend, don’t break.** Have options, not immovable opinions. There is never one right answer,
  approach, or tool. There are only options with pros and cons.
- **Users are all that matters** If no one’s complaining about your software, no one’s using it.
  Focus on what users care about, not what you care about.
- **Defense in depth** Few perfect defenses exist. Design security features as composable layers.
  Focus on what the layers _do_ , not what they _don’t_ .
- **Do no harm**
  It doesn’t matter how perfect our security product is if we take a customer down.
- **Composition over inheritance** Build small, focused pieces that combine freely instead of rigid
  hierarchies that calcify over time.
- **Data flows forward** Treat data as a stream, not a possession; transformations are transparent,
  not hidden in side effects.
- **State is a liability** Every bit of state carries a cost. Make state explicit, minimize it, and
  centralize it.
- **Automation over repetition**
  Manual processes are technical debt that compromise agility.
- **Immutability is integrity** Once something is known, it should stay known to aid determinism and
  testability.
- **Pure functions eliminate ambiguity**
  Write functions and systems that rely only on their input.
- **Observability over optimism** Design for insight, not assumption. Metrics, logs, and traces are
  part of the architecture, not afterthoughts.
- **Change should be safe** Refactoring, deployment, and rollback should be routine, not risky.
  Safety is speed. Types, tests, versioning, and automation enable safety.
- **Failures are expected, not exceptional** Design for resilience. Assume components fail, networks
  falter, and humans err.

### **In summary**

We build **systems that can be reasoned about, trusted, and evolved** . We value
**clarity, predictability, and composability** over convenience and single-purpose software. We
design systems that are **easy to reason about** , **hard to break** , and **graceful under change**
.
