---
name: review-diff
description: High-signal multi-agent code review where every finding is independently validated before it is reported. Trigger with "review this diff", "review PR 123", "check this before I merge", "is this change safe?", or after finishing a feature.
argument-hint: "[PR number or URL] [--comment]"
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git rev-parse:*), Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh pr comment:*), Bash(glab mr view:*), Bash(glab mr diff:*), Read, Grep, Glob, Agent
---

# /review-diff

> Settings: if `.claude/ship-workflow.md` exists, use its `models` values. Placeholders: [CONNECTORS.md](../../CONNECTORS.md).

Review: $ARGUMENTS. With no target, review `git diff HEAD`. For a PR or MR, fetch it through ~~source control (`gh pr diff` or `glab mr diff`).

Give every agent you launch these rules:
- The tools work. Make no exploratory calls.
- Report only **high-signal** issues:
  - code that will not compile or parse;
  - logic that is wrong for every input;
  - a broken CLAUDE.md rule you can quote, where that CLAUDE.md is in the file's directory or a parent.
- Never report these:
  - pre-existing issues;
  - style;
  - things a linter catches;
  - issues that depend on particular input;
  - nitpicks;
  - rules the code silences on purpose.

## Steps
1. **Gate** (small model). For a PR, stop if it is closed, a draft, trivial or automated, or already reviewed by Claude. Still review PRs that Claude wrote.
2. **Rule files** (small model). Return the paths of the root CLAUDE.md and of each CLAUDE.md in the directories the diff touches.
3. **Summary** (mid model). Summarize the change and the author's intent: the PR title and body, or the user's words.
4. **Reviewers, in parallel.** Give each the summary and the intent.
   - 2 × `rule-checker` agents: CLAUDE.md compliance.
   - 2 × `bug-hunter` agents. One reads the diff alone. The other looks for logic and security problems in the changed lines.
   - If the diff touches error handling, also run a `silent-failure-hunter` agent.
5. **Validate.** For each issue, launch one `finding-validator` agent with the issue, the intent and the code. It confirms or rejects the issue with high confidence.
6. **Drop** every issue that was not confirmed.
7. **Output.** List the confirmed issues, most severe first, each as `path:line: issue — why`. If there are none, say exactly: "No issues found. Checked for bugs and CLAUDE.md compliance."
8. **Only if `--comment` was given and the target is a PR:**
   - Post one inline comment per unique issue.
   - Add a committable suggestion only when it fully fixes the issue in 5 lines or fewer.
   - Link code with a full SHA and a line range that has context before and after: `…/blob/<sha>/<path>#L4-L7`.
   - Without the flag, post nothing.
