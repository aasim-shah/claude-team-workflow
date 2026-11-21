---
description: Answer a PR review comment with evidence, keeping the PR's scope
argument-hint: <PR number> [comment id or quote]
allowed-tools: Bash(gh pr view:*), Bash(gh api:*), Bash(gh issue list:*), Bash(gh search:*), Bash(git log:*), Bash(git diff:*), Read, Grep, Glob, Edit
---

Handle review feedback on PR $ARGUMENTS.

For each comment:
1. **Restate** the claim in one sentence.
2. **Check it in the code.** Read the lines it names, and follow the mechanism (which token, trigger, call path).
3. **Measure it on real data** wherever data exists: runs, issues, logs. Give counts ("in a sample of 26 issues, none has X and 20 have Y").
4. **Decide:**
   - Is it true or false?
   - Did this PR cause it? Compare `git diff <base>...HEAD`.
5. **Act:**
   - If it is true and caused by this PR, fix it here. Make one commit with a why-body.
   - If it is true but predates this PR, do not fix it here. Add it to the PR's Risk or Follow-up section, and say who should own it.
   - If it is false, explain with the evidence.
6. **Draft the reply** in this shape: verdict → mechanism → numbers → what you did. No filler.

Show the user the drafted replies and the edits to the PR description before you post anything.
