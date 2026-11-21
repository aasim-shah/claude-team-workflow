---
name: write-pr
description: Draft a commit message and pull request description that follow the PR contract, without committing or pushing anything. Trigger with "write the PR description", "draft a commit message", "what should the PR say", "write up this change for review", or whenever you are about to write a PR body or commit message.
argument-hint: "[what changed, or nothing to read the diff]"
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Read, Grep, Glob
---

# /write-pr

Draft text only. To commit, push and open the PR as well, the user runs `ship-pr`.

Input: $ARGUMENTS. If it is empty, read `git diff HEAD` and `git log --oneline -10`. If facts are missing (what ran, which versions), write `[brackets]` for the user to fill in. Do not invent them.

## Commit message (REQUIRED shape)

```
<imperative subject that states the effect>

<why: the problem or constraint that forced this change; cite issues as owner/repo#123>
<merge precondition, if any>
```

## PR description (REQUIRED sections, in this order; write "None" if a section is empty)

```markdown
## Summary
<what changed; a before → after table if there are several targets>

## What changes for users
<behaviour per surface or version, migrations, anything that breaks>

## Testing
<only what actually ran, where, and on which versions>
Not tested:
- CI (not run yet)            ← always present until CI has run
- <real external systems, other OS/versions, production-like load…>

## Risk
<the concrete real-world effect if this is wrong (e.g. duplicate charges, lockouts, data loss)
 and what will be watched after merge>

## After merge / Follow-up
<manual steps for humans; problems found but not fixed here>
```

## Checks before you hand it over
- Every claim in Testing is something the user said ran, or something you ran yourself.
- "Not tested" lists CI, plus at least one real-world gap.
- Risk names an effect a user or customer would notice. "Might have bugs" does not count.
- The commit body says why, not only what.
