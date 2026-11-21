# Multi-agent pipelines

Three pipelines appear in the public repo. All share one shape:

```
gate → context → parallel workers (different angles) → validate each output → filter → act
```

## Common rules

- **Gate first, with a cheap model.** Stop early if the work is not needed: the item is closed, a draft, trivial, or already handled. Skip work Claude has already done (for example, it already commented).
- **Parallel workers need different angles,** not copies. Give each worker a distinct search strategy, focus or design stance.
- **Pass constraints down.** Every rule that binds the orchestrator goes into each worker's prompt too ("be sure to tell this to your agents, too").
- **Give workers the author's intent.** Each reviewer gets the PR title and description.
- **Validate each finding in its own agent.** The validator gets the claim plus context, and must confirm it with high confidence. Use a top model for logic bugs and a mid model for rule violations.
- **Drop anything not validated.** Accept fewer, real findings over many weak ones. False positives erode trust and waste reviewer time.
- **Act through narrow tools** (scripts), with a fixed output format.

## Pipeline A: diff or PR review

1. **Gate (small model).** Stop if the PR is closed, a draft, trivial or automated, or already reviewed by Claude. Still review PRs that Claude wrote.
2. **Rule files (small model).** Return the paths of the root CLAUDE.md and of every CLAUDE.md in the directories the diff touches. Paths only.
3. **Summary (mid model).** What the PR changes.
4. **Four reviewers in parallel:**
   - 2 × mid model: CLAUDE.md compliance. A rule applies to a file only if that CLAUDE.md is in the file's directory or a parent directory.
   - 2 × top model: bugs. One reads the diff alone and flags only significant bugs it can prove from the diff. The other looks for logic and security problems in the changed code only.
5. **Flag only high-signal issues:**
   - code that will not compile or parse;
   - logic that is wrong whatever the input;
   - a rule broken that you can quote exactly.
6. **Never flag:**
   - pre-existing issues;
   - style;
   - things a linter catches;
   - input-dependent maybes;
   - nitpicks;
   - rules silenced in the code on purpose.
7. **One validator per finding.** Drop the unvalidated ones.
8. **Output.** List the findings, or say "No issues found. Checked for bugs and CLAUDE.md compliance."
9. **Optional `--comment`.**
   - Post one inline comment per unique issue.
   - Add a committable suggestion only when it fully fixes the issue and is under about 6 lines.
   - Link code with a full SHA and a line range that has context before and after (`…/blob/<sha>/path#L4-L7`).

## Pipeline B: duplicate detection

1. Gate: is the issue closed, too broad to dedupe, or already deduped?
2. Summary agent: a summary of the issue.
3. **Five search agents in parallel**, each with different keywords and a different search approach.
4. Filter agent: removes false positives using the summary.
5. If any remain, act through a script that accepts at most 3 numeric issue numbers, checks that each exists, and posts a fixed comment template with a veto window.

## Pipeline C: guided feature development

1. Discovery: todo list, confirm understanding.
2. 2–3 explorer agents in parallel, each returning key files. The orchestrator reads them.
3. Clarifying questions. **Wait.**
4. 2–3 architect agents (minimal, clean, pragmatic). Recommend one. **Wait for the pick.**
5. Implement after approval.
6. 3 reviewer agents in parallel: simplicity and DRY, bugs and correctness, conventions and abstractions. The engineer chooses: fix now, later, or accept.
7. Summary: what was built, decisions made, files changed, next steps.

## Other pattern agents worth having

Each is a narrow specialist, launched when the diff contains that kind of change:
- **silent-failure-hunter**: catch blocks that swallow errors, fallbacks that hide failure, mocks in production paths.
- **type-design-analyzer**: invariants that new types encode or fail to encode.
- **comment-analyzer**: comments that drift from the code.
- **test-analyzer**: whether the tests cover the behaviour the change introduces.
- **simplifier**: runs last, after the review passes.

## Loop pattern (long autonomous work)

A Stop hook blocks the session's exit and feeds the same prompt back. Each pass sees the files and git history from the last one. It ends when the output contains an agreed completion marker, or at `--max-iterations`. Always set the iteration cap. Use it only for tasks with a machine-checkable finish, such as a test suite that passes.

## Agent definition format

```markdown
---
name: silent-failure-hunter
description: Use when a diff adds or changes error handling, catch blocks, fallbacks or retries. <example>Context: … user: "…" assistant: "I'll run silent-failure-hunter on the changes."</example>
tools: Glob, Grep, Read
model: inherit
---
<role, non-negotiable principles, the step-by-step process, the exact output format>
```

The `<example>` blocks in the description teach the orchestrator when to launch the agent.
