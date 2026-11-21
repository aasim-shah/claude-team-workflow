---
name: feature
description: Use before writing implementation code for any requested feature or non-trivial fix, even when the user is in a hurry ("ship it today", "keep it quick"). It runs explore → clarify → design → approve → build → verify → review with stop-and-wait gates. Trigger with "build X", "add X to Y", "add rate limiting / auth / caching", "implement this ticket", or any change touching auth, data, security, a public API, or more than a couple of files.
argument-hint: "<what the feature should achieve>"
---

# /feature

> Settings: if `.claude/ship-workflow.md` exists, read it first. Use its test and check commands, its sensitive paths and its model choices. Placeholders like `~~source control` are explained in [CONNECTORS.md](../../CONNECTORS.md).

Build: $ARGUMENTS

```
STANDALONE (always works)              SUPERCHARGED (when connected)
  git + your test runner                 ~~source control: PR, CI status, linked issues
  explorer / architect / reviewer agents ~~project tracker: pull the ticket's acceptance criteria
```

Work through the phases in order. Track them in a todo list if that tool is available.

## 1. Explore
- If the area is small, read it yourself. Otherwise launch 2–3 `code-explorer` agents in parallel, each with a different angle:
  - similar existing features, traced end to end;
  - the architecture of the area;
  - the tests and extension points.
- Each returns findings plus the 5–10 files most worth reading. **Read those files yourself.**
- Note the hidden constraints: version or tool limits, callers that break, CLAUDE.md rules, and the sensitive paths from settings.

## 2. Clarify. STOP and wait.
- List every open point: edge cases, error handling, scope, backward compatibility, performance.
- Ask them all in **one** message. Give each point your recommended default.
- Do not write code until the user answers. Urgency ("ship today", "quick") is not an answer.
- If the user says "your call", restate your choices and get an explicit yes.

## 3. Design. STOP and wait.
- Give 2–3 options: **minimal**, **clean** and **pragmatic**. For each, show a summary, the trade-offs and the concrete code differences.
- End with **one recommendation and its reason**.
- For large work, run one `code-architect` agent per option in parallel.
- Wait for the user to pick.

The trivial-change exception: skip phases 2 and 3 only when there is one obvious design **and** the change touches no auth, security, data, public API or sensitive path.

## 4. Build
- Write a failing test first where the repo has tests.
- Make one commit per logical step. The subject states the effect. The body says **why** and names the constraint or issue behind it.
- Follow CLAUDE.md and the existing conventions. Keep a list of what you deliberately left unchanged.

## 5. Verify
- Run every check the repo has: tests, typecheck, lint, and any script that enforces a CLAUDE.md rule.
- Exercise the edge cases from phase 2 explicitly.
- Write down what you could **not** test: CI, other operating systems, real external calls, older versions.

## 6. Review
Run the `review-diff` skill, then show the user the validated findings. The user chooses for each one: fix now, fix later, or accept.

## 7. Report
- Summarize what was built, the decisions made, the files changed, what was **not tested**, and the next steps.
- Offer the `ship-pr` skill. **Do not merge.**
