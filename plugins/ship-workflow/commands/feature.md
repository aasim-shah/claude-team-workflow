---
description: Build a feature with explore → clarify → design → approve → build → verify → review gates
argument-hint: <what the feature should achieve>
---

# Feature: $ARGUMENTS

Work in these phases, in order. Track them in a todo list if that tool is available.

## 1. Explore
- If the area is small, read it yourself. Otherwise launch 2–3 explorer agents in parallel, each with a different angle: similar existing features traced end to end; the architecture of the area; the test approach and extension points.
- Each agent returns findings plus **the 5–10 files most worth reading**. Read those files yourself before going on.
- Note the hidden constraints: version limits, tool or model limits, callers that break, CLAUDE.md rules.

## 2. Clarify. STOP and wait.
List every open point: edge cases, error handling, scope, backward compatibility, performance. Ask them all in one message, each with your recommended default. Do not write code until the user answers. Urgency is not an answer. If the user says "your call", restate your choices and get an explicit yes.

## 3. Design. STOP and wait.
Give 2–3 options: minimal, clean, pragmatic. For each, give a summary, the trade-offs and the concrete code differences. Then give one recommendation with its reason. For large work, run one architect agent per option in parallel. Wait for the user to pick.

## 4. Build
- Write a failing test first where the repo has tests.
- Make one commit per logical step. The subject states the effect; the body says why and names the constraint or issue behind it.
- Follow CLAUDE.md and the existing conventions. Do not touch anything outside the agreed scope. Keep a list of what you deliberately left unchanged.

## 5. Verify
- Run every check the repo has: tests, typecheck, lint, and any script that enforces a CLAUDE.md rule.
- Exercise the edge cases from phase 2 explicitly.
- Write down what you could NOT test (CI, other operating systems, real external calls, older versions).

## 6. Review
Run the `review-diff` command (`/ship-workflow:review-diff`) on the diff, or launch reviewer agents from 3 angles (simplicity, bugs, conventions), then validate each finding with its own agent. Show the user the validated findings. The user chooses: fix now, fix later, or accept.

## 7. Report
Summarize: what was built, the decisions made, the files changed, what was not tested, and the next steps. Offer the `ship-pr` command (`/ship-workflow:ship-pr`). Do not merge.
