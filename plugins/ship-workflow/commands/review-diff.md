---
description: High-signal multi-agent review of the current diff or a PR
argument-hint: "[PR number] [--comment]"
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git rev-parse:*), Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh pr comment:*), Read, Grep, Glob, Agent
---

Review $ARGUMENTS. With no PR number, review `git diff HEAD`.

Tell every agent you launch these rules too:
- The tools work. Make no exploratory or test calls.
- Report only high-signal issues:
  - code that will not compile or parse;
  - logic that is wrong for every input;
  - a broken CLAUDE.md rule you can quote, where that CLAUDE.md is in the file's directory or a parent.
- Never report:
  - pre-existing issues;
  - style;
  - things a linter catches;
  - issues that depend on particular input;
  - nitpicks;
  - rules the code silences on purpose.

Steps:
1. **Gate** (agent, `model: haiku`). For a PR, stop if it is closed, a draft, trivial or automated, or already reviewed by Claude. Still review PRs that Claude wrote.
2. **Rule files** (agent, `model: haiku`). Return the paths of the root CLAUDE.md and of each CLAUDE.md in the directories the diff touches.
3. **Summary** (agent, `model: sonnet`). Summarize the change and the author's intent (PR title and body).
4. **Four reviewers in parallel.** Give each the summary and the intent.
   - 2 × `model: sonnet`: CLAUDE.md compliance.
   - 1 × `model: opus`: obvious bugs visible in the diff alone.
   - 1 × `model: opus`: logic and security problems in the changed lines only.
   Each returns a list of issues: file, line, description and reason.
5. **Validate.** For each issue, launch one agent with the issue, the intent and the code (`opus` for bugs, `sonnet` for rules). It confirms or rejects with high confidence.
6. **Drop** every unconfirmed issue.
7. **Output.** List the confirmed issues, most severe first. If there are none, say exactly: "No issues found. Checked for bugs and CLAUDE.md compliance."
8. **Only if `--comment` was given and this is a PR:**
   - Post one comment per unique issue.
   - Add a committable suggestion only when it fully fixes the issue in 5 lines or fewer.
   - Link code as `https://github.com/<owner>/<repo>/blob/<full sha>/<path>#L<start>-L<end>`, with one line of context before and after.
   - Without the flag, post nothing.
