# Repo Assessment

This claude skill or plugin should assess a repository and determine whether or not it is a good baseline for automated auditing.

## Jarrod's Philosophy Bullet Points

- There is no meaningful difference between human-generated code and AI-generated code.
- Human review of code is not a meaningful measure of code quality.
- A project must have substantial unit tests, integration tests, benchmarks, static analysis, security analysis, and other automated checks to be a good baseline for automated auditing.

## Jarrod's engineering philosophies

- Functional design is superior to object-oriented design.
- Minimal, centralized state is superior to global, mutable state.
- Pure functions (functions that always produce the same output for the same input and have no side effects) are superior to impure functions.
- Declarative code is superior to imperative code.
- Code itself is a liability, and should be minimized as much as possible.
- Composability and modularity are crucial for building complex systems.
- Code should be easy to test.

## Core engineering philosophy

The document at docs/engineering-philosophies.md outlines the core engineering philosophies that guide our work.

## Existing precedent

_examples/claude-superpowers/skills/requesting-code-review/_

This skill does a good job at assessing code quality.

_examples/claude-superpowers/skills/receiving-code-review/_

This skill does a good job at receiving code review feedback and providing actionable next steps.

_examples/claude-superpowers/skills/verification-before-completion_

This skill does a good job at verifying work before claiming completion.

_examples/claude-superpowers/skills/writing-plans_

I've found this skill to be a good example at assessing a problem, breaking it down into steps, and writing a plan to solve it without writing code.

_examples/cursor-plugins/cursor-team-kit/skills/thermo-nuclear-code-quality-review_

I haven't used this skill yet, but it gets good reviews from users and seems to be focused on code quality review, which is relevant to this repo assessment skill.

## Assessment Criteria

- Does the repository have a comprehensive suite of automated tests (unit, integration, etc.)?
- Does the repository have automated static analysis and security checks?
- Does the repository have benchmarks to measure performance?
- Does the repository have clear documentation on how to run tests and checks?
- Does the repository track code coverage, benchmark results, and static analysis results over time?

## Standards

- Understanding how to run tests, benchmarks, and static analysis is crucial for assessing the suitability of a repository for automated auditing. This skill must describe standard ways of running these checks and finding their output. The skill should not have to search for them.
- The skill should be able to analyze the repository structure and identify where tests, benchmarks, and static analysis results are located. It should also be able to interpret the results of these checks to determine the overall health and quality of the codebase.
- This skill should report what is missing from the repository in terms of tests, benchmarks,static analysis, structure, and machine-readable documentation or schemas, and provide recommendations for improvement based on best practices in software development and security.

## Conclusion

A repository that meets these criteria would be a good baseline for automated auditing, as it has the necessary infrastructure to support continuous assessment of code quality and security.

This skill must be able to analyze a repository and provide a detailed report on its suitability for automated auditing based on the criteria outlined above.
