# Changelog

## 1.1.0

Patterns adopted from Anthropic's [knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins) (Apache-2.0):

- **The commands are now skills** (`skills/<name>/SKILL.md`, with `argument-hint`). They are still invoked as `/ship-workflow:<name>`. Their descriptions now carry trigger phrases, so Claude can also use them without a slash command.
- **New `write-pr` skill.** It drafts the commit message and PR body to the contract, and Claude can load it on its own. Side effects stay in `ship-pr`. The first eval run showed the PR contract never fired while it lived only in a user-invoked skill.
- **New `harden-ci-agent` skill**, plus broader trigger descriptions for `feature` and the core skill. The evals showed the gates held whenever a skill loaded, and failed whenever Claude answered without one. The core skill's old description only fired when the user asked to "work like the Claude Code team".
- **`ship-pr` and `setup-repo` are user-invoked only** (`disable-model-invocation: true`). Claude never pushes or writes into a repo on its own initiative.
- **6 named agents:** `code-explorer`, `code-architect`, `bug-hunter`, `rule-checker`, `finding-validator` and `silent-failure-hunter`. Each has `<example>` triggers, a pinned model and a tools allowlist. `feature` and `review-diff` launch them by name.
- **New `customize` skill.** It detects the repo's test and check commands, default branch, sensitive paths and source control, and records them in `.claude/ship-workflow.md`. The other skills read that file.
- **`CONNECTORS.md` and `~~` placeholders.** Every skill works with plain git ("standalone"), and does more with `gh`, `glab` or MCP servers ("supercharged"). GitLab (`glab`) is supported alongside GitHub.
- **Evals** (`plugins/ship-workflow/evals/`): 4 behaviour cases for `claude plugin eval`, with one grader per criterion: the approval gate under deadline pressure, the PR-body contract, review-reply scope, and CI triage hardening. The latest run scored **98% with the plugin and 69% without** (3 runs per arm).
- **Installers.**
  - `init-repo.sh --skills` copies the skills, agents and `CONNECTORS.md` into `.claude/`. `--commands` still works as an alias.
  - `install.sh --skills` installs the workflow skills with a `ship-` prefix, plus the agents.
  - `install.sh` never overwrites an agent or skill that it did not install, and `--uninstall` removes only what it installed.
- **Repository.**
  - A PR template that uses the plugin's own contract.
  - Issue forms, `CONTRIBUTING.md` and `SECURITY.md`.
  - Dependabot for actions.
  - A release workflow that checks the versions against the tag.
  - `actions/checkout` pinned by SHA, in CI and in the CI templates.
- **Tests.** `tests/run.sh` grows from 60 to 74 checks, adding:
  - agent and skill frontmatter;
  - eval structure;
  - agent and connector links;
  - safety claims: no hooks, no MCP, no direct network calls, no credential reads;
  - version and CHANGELOG consistency.

## 1.0.0

- First release.
- Skill `shipping-like-claude-code-team`: the 10-phase loop, the hard gates, the PR, commit and review-reply contracts, and 6 references.
- Commands `feature`, `review-diff`, `ship-pr`, `reply-review` and `setup-repo`.
- CI templates: triage and dedupe workflows, wrapper scripts, the enforcement check and the egress allowlist.
- Installers: plugin marketplace, `install.sh` and `init-repo.sh`.
- `tests/run.sh` with 60 checks, run in CI along with shellcheck and `claude plugin validate`.
