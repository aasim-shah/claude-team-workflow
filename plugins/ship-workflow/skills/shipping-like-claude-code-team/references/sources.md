# Sources (public, anthropics/claude-code, read 2026-11-21)

The actual chat transcripts are private: the session links need the owner's login. Everything below is public record.

## Pull requests (gh pr view <n> --repo anthropics/claude-code)

| PR | What it shows |
|---|---|
| #97952 | Security hardening built by Claude in 7 commits. The session posts `@claude` test prompts as review comments. Includes the PR body's "After merge" step. |
| #106583 | Model upgrade. Prompt edited for the new model's tools. Honest Risk section. Review reply backed by a 26-issue data sample. Branch `claude/…`. |
| #111198 | Requested from a project thread (`Human: @login`, "Requested by"). Tests edge cases (deleted fork). "Not run on GitHub." Runs the repo's enforcement check. |
| #105303 | Migration with a "Merge order" line, user impact per client version, and a matrix of versions tested. |
| #105270 | Removal with old- and new-client behaviour verified, plus a docs follow-up. |
| #107768 | 23 minutes from open to merge. `Claude-Session:` trailer. Test plan states what CI does not cover. |

## Files

- `CLAUDE.md`: the security rules for workflows that call Claude.
- `.claude/commands/triage-issue.md`, `dedupe.md`, `commit-push-pr.md`
- `.github/workflows/claude.yml`, `claude-issue-triage.yml`, `claude-dedupe-issues.yml`, `workflow-hardening.yml`, `sweep.yml`, `auto-close-duplicates.yml`
- `.github/egress-firewall.yaml`, `.github/scripts/check_workflow_hardening.py`
- `scripts/gh.sh`, `edit-issue-labels.sh`, `comment-on-duplicates.sh`, `issue-lifecycle.ts`, `sweep.ts`, `auto-close-duplicates.ts`
- `mods/README.md`, `mods/*/hooks`, `mods/*/tests`
- Removed plugins in history: `git show 10a5141^:plugins/feature-dev/commands/feature-dev.md`. Also `plugins/pr-review-toolkit/`, `plugins/ralph-wiggum/` and `plugins/hookify/` at the same commit, and `git show aef1f31^:plugins/code-review/commands/code-review.md`.

## Numbers

- Last 200 commits: 184 bots, 11 authored by Claude, and the rest by humans, most of them co-authored with Claude.
- 446 releases in the changelog. About 20 in the 30 days to 2026-11-20. About 23 bullets per release. "Fixed" bullets outnumber "Added" about 6:1.

The repo's license is "all rights reserved". This skill paraphrases; quotes are short and attributed. Read the originals at the paths above.
