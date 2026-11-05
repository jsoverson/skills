---
name: code-comments
description: Use when considering whether to add a comment in source code.
user-invocable: false
---

You're trying to write a comment.

Code comments are inherently problematic. They often become outdated, misleading, or serve as a crutch for unclear code. Only in rare, justified cases should they survive scrutiny.

## Only proceed if:

- you need to document non-obvious behavior forced by an external dependency, reported issue, platform, vendor, or protocol we cannot reshape.
- you need to add a comment to suppress a linter or compiler warning, and the suppression is justified by a compelling edge case or faulty rule.
- you need to add a link to an RFC, github issue, jira issue, or documentation that should be referenced in the future.

## Critical law

Never comment what code can say on its own.

## Required Audit Steps

1. List all the comments
2. Justify keeping the comment.

- If your comment simply describes what the code does, delete it.
- If your comment does not describe unique or unintuitive context or rationale, delete it.
- If you could change the code to be more clear, do so and delete the comment.

3. Remove any comments that can't be justified.
