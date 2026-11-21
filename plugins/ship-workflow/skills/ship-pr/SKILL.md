---
name: ship-pr
description: Branch, commit with a why-body, push, and open a pull request whose body follows the PR contract (Summary, What changes for users, Testing + Not tested, Risk, After merge). Run only when the user asks to commit, push, or open a PR.
argument-hint: "[short topic]"
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git switch:*), Bash(git checkout -b:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(gh pr create:*), Bash(glab mr create:*)
---

# /ship-pr

> Settings: if `.claude/ship-workflow.md` exists, use its `branch_prefix`, `default_branch` and `pr_sections`. Placeholders: [CONNECTORS.md](../../CONNECTORS.md).

## Context
- Status: !`git status --short`
- Branch: !`git branch --show-current`
- Diff: !`git diff HEAD`
- Recent commits: !`git log --oneline -10`

## Task
1. If the current branch is the default branch, create `<branch_prefix><topic>`. The default prefix is `claude/`. The topic is $ARGUMENTS, or one you derive from the diff.
2. Stage only the files that belong to this change. Never stage secrets, `.env` files or build output. If the diff holds two unrelated changes, stop and ask.
3. Commit:
   - The subject states the effect in the imperative mood.
   - The body says **why** and names the constraint or issue behind it. Cite outside facts (`see owner/repo#123`).
   - Give the merge precondition if there is one.
   - End with the co-author trailer. Add `Claude-Session: <url>` if you know the session link.
4. Push with `-u`.
5. Write the PR body with the `write-pr` skill's contract (Summary, What changes for users, Testing + Not tested, Risk, After merge / Follow-up). Open the PR or MR through ~~source control (`gh pr create` or `glab mr create`).

Write only results that actually happened. CI has not run yet, so it belongs under "Not tested". **Do not merge.** Report the PR link.
