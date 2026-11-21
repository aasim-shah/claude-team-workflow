# Security

## What the plugin does on your machine

- It registers **no hooks** and ships **no MCP servers**.
- It sends **no telemetry**, and its scripts make no network calls of their own.
- The skills run `git`, and `gh` or `glab` if they are installed. Each skill's `allowed-tools` lists exactly which commands.
- `ship-pr` and `setup-repo` are **user-invoked only** (`disable-model-invocation: true`). Claude never pushes or writes into your repo on its own initiative.
- `install.sh` clones this repository over HTTPS and copies files under `~/.claude`. `init-repo.sh` copies files into the repo you name. It shows a dry run first, and it never overwrites a file without `--force`.

`tests/run.sh` checks the no-hooks, no-MCP, no-network-call and no-credential-read claims on every push.

## The CI templates

The triage and dedupe templates are built for public repositories, where anyone can write the issue text Claude reads. They assume a hostile input. See `references/ci-agents.md` for the 16 layers. Do not remove a layer without adding an exemption, with a reason, to `check_workflow_hardening.py`.

## Reporting a vulnerability

Use [private vulnerability reporting](https://github.com/aasim-shah/claude-team-workflow/security/advisories/new). Do not open a public issue. Expect a first reply within 7 days.
