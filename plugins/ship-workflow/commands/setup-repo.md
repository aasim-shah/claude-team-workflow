---
description: Copy the team-workflow commands and/or hardened CI automation into this repository
argument-hint: "[--commands] [--ci] [--all] [--force] [--dry-run]"
allowed-tools: Bash(bash:*), Bash(git status:*), Bash(ls:*), Read
---

Set up this repository with ship-workflow files. Arguments: $ARGUMENTS

1. Find the installer:
   - First try `${CLAUDE_PLUGIN_ROOT}/scripts/init-repo.sh`.
   - If that path does not exist, try `~/.claude/skills/shipping-like-claude-code-team/bin/init-repo.sh`, which `install.sh` creates.
   - If neither exists, run `ls -d ~/.claude/plugins/cache/*/ship-workflow/*/scripts/init-repo.sh` and use the newest match.
2. Run it with `--dry-run` plus the user's arguments, against the repository root. Show the user the output.
3. If anything would be skipped or overwritten, or if `--ci` is in the arguments, explain what will change. Then ask before running for real.
4. Run the installer without `--dry-run`.
5. Run `git status --short` and summarize the files added.
6. If `--ci` was used, repeat the installer's "Next steps" for the user. Say plainly that CI has not run yet.
