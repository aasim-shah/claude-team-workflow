---
description: Branch, commit, push and open a PR whose body follows the PR contract
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git switch:*), Bash(git checkout -b:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(gh pr create:*)
---

## Context
- Status: !`git status --short`
- Branch: !`git branch --show-current`
- Diff: !`git diff HEAD`
- Recent commits: !`git log --oneline -10`

## Task
1. If the current branch is the default branch, create `claude/<short-topic>`.
2. Stage only the files that belong to this change. Never stage secrets, `.env` files or build output. If the diff holds two unrelated changes, stop and ask.
3. Commit:
   - The subject states the effect in the imperative mood.
   - The body says why and names the constraint or issue behind it. Cite outside facts (`see owner/repo#123`), and give the merge precondition if there is one.
   - End with the co-author trailer, and add `Claude-Session: <url>` if you know the session link.
4. Push with `-u`.
5. Open the PR with `gh pr create`. The body has exactly these sections, each one filled in, with "None" if empty:

```
## Summary
## What changes for users
## Testing
<what ran, where, on which versions>
Not tested: <list — CI, OS, real external calls, older versions>
## Risk
<effects in the real world if this is wrong; what will be watched after merge>
## After merge / Follow-up
```

Write only results that actually happened. CI has not run yet, so put it under "Not tested". Do not merge.
