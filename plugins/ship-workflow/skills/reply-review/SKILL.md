---
name: reply-review
description: Answer pull request review comments with evidence from the code and real data, fixing only what this PR caused. Trigger with "handle the review comments", "reply to the reviewer", "address PR feedback", or a pasted review comment.
argument-hint: "<PR number or URL> [comment id or quote]"
allowed-tools: Bash(gh pr view:*), Bash(gh api:*), Bash(gh issue list:*), Bash(gh search:*), Bash(gh run list:*), Bash(glab mr view:*), Bash(git log:*), Bash(git diff:*), Bash(git blame:*), Read, Grep, Glob, Edit
---

# /reply-review

> Placeholders: [CONNECTORS.md](../../CONNECTORS.md).

Handle review feedback on: $ARGUMENTS. Fetch the comments through ~~source control.

For each comment:
1. **Restate** the claim in one sentence.
2. **Check it in the code.** Read the lines it names. Follow the mechanism: which token, which trigger, which call path.
3. **Measure it on real data** wherever data exists: runs, issues, logs, metrics. Give counts, for example "in a sample of 26 issues, none has X and 20 have Y".
4. **Decide:**
   - Is the claim true or false?
   - Did this PR cause it? Compare `git diff <base>...HEAD`.
5. **Act:**
   - **True, and caused by this PR:** fix it here, in one commit with a why-body.
   - **True, but it predates this PR:** do not fix it here. Add it to the PR's Risk or Follow-up section, and name who should own it.
   - **False:** explain why, with the evidence.
6. **Draft the reply** in this order: verdict, mechanism, numbers, what you did. No filler.

A request to "just fix it" does not widen the scope. Show the user the draft replies and the edits to the PR description **before** you post anything.
