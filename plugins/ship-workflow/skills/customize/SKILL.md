---
name: customize
description: Tailor ship-workflow to this repository by recording its test and check commands, default branch, sensitive paths, PR sections and model choices in .claude/ship-workflow.md. Trigger with "customize ship-workflow", "set up the workflow for this repo", "configure the team workflow", or when another ship-workflow skill finds no settings file and has to guess commands.
argument-hint: "[what to change]"
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(git remote:*), Bash(git symbolic-ref:*), Bash(git branch:*), Bash(ls:*), Bash(gh label list:*)
---

# /customize

Write or update `.claude/ship-workflow.md`, the one place the other skills read repository-specific values from. Do not rename or edit the plugin's own files.

## 1. Detect (read-only)
Find each value from the repository. Do not ask the user for anything you can read.

| Field | Where to look |
|---|---|
| `default_branch` | `git symbolic-ref refs/remotes/origin/HEAD`, else `main` |
| `source_control` | `git remote -v`: `github`, `gitlab` or `other` |
| `test_command` | the `scripts.test` entry in `package.json`, `Makefile`, `pyproject.toml`, `Cargo.toml`, `go.mod`, or the CI workflow steps |
| `check_commands` | lint, typecheck and build in the same files; any `scripts/check_*` file |
| `sensitive_paths` | auth, payments, migrations, infra and security folders, and CODEOWNERS entries |
| `pr_sections` | `.github/pull_request_template.md` if present, else the default contract |
| `labels` | `gh label list` (GitHub only) |

## 2. Confirm. STOP and wait.
- Show the detected values as a short table.
- Ask **one** batched question covering what you could not detect, plus anything the user asked to change ($ARGUMENTS).
- Give each question a recommended default.

## 3. Write
Write `.claude/ship-workflow.md` in exactly this shape. Keep any notes that already exist below the frontmatter.

```markdown
---
default_branch: main
branch_prefix: claude/
source_control: github
test_command: npm test
check_commands:
  - npm run lint
  - npm run typecheck
sensitive_paths:
  - src/auth/**
  - db/migrations/**
pr_sections: default        # or: template  (use .github/pull_request_template.md)
models:
  gate: haiku
  summary: sonnet
  rules: sonnet
  bugs: opus
  validate_bugs: opus
---

Team notes Claude should know when shipping here (release process, reviewers, deploy windows).
```

## 4. Report
- List the fields you wrote.
- Recommend committing the file, so the whole team gets the same behaviour.
- Say which skills now read it: `feature`, `review-diff` and `ship-pr`.
