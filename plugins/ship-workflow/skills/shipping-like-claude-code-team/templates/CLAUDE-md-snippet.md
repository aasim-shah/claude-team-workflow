## Workflows that call Claude

Every job that runs the Claude Code action keeps these protections. Keep them when you add or edit a workflow.

1. It runs on `ubuntu-24.04-firewall`. Its outbound hosts are listed in `.github/egress-firewall.yaml`, which stays `mode: enforce`. Name each host in full, with a comment saying what uses it.
2. It passes `--permission-mode auto` in `claude_args`, on a model that supports auto mode. It sets no other permission mode anywhere: not in a settings input, a `--settings` file or inline JSON.
3. It signs in through workload identity federation, never through a static API key.
4. If users without write access can trigger it, it allows only `./scripts/*.sh` wrappers and disallows `WebFetch,WebSearch,Write,Edit,MultiEdit,NotebookEdit`.
5. Write scripts read the target issue or PR from `$GITHUB_EVENT_PATH`, never from arguments, and the job caps them with `CLAUDE_CODE_SCRIPT_CAPS`.
6. Its `permissions:` block is minimal. Never print tokens or environment variables in logs.

`.github/workflows/workflow-hardening.yml` fails when a job breaks rules 1, 2, 3 or 4. A job that cannot meet a rule goes in the exemption table in `scripts/check_workflow_hardening.py`, with the reason. Do not skip or weaken the check.

## Pull requests

PR bodies have these sections: Summary, What changes for users, Testing (ending with "Not tested:"), Risk, and After merge / Follow-up. Report only results that actually happened. Fix pre-existing problems in their own PR, not in this one.
