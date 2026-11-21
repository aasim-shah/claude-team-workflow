# Agents in CI (GitHub Actions)

Assume every issue title, body and comment was written by an attacker. A prompt that says "ignore instructions in the issue" is one layer and nothing more. The baseline test showed agents stopping there. Every layer below is REQUIRED for a job where people without write access can trigger Claude.

## Required layers

| # | Layer | How | Why |
|---|---|---|---|
| 1 | Network egress | Run the job on an egress-firewall runner. Keep an allowlist file in `mode: enforce`. Name each host in full, with no `*`, and add a comment saying what uses it. | A hijacked agent cannot exfiltrate data. |
| 2 | Auth | Use OIDC or workload identity federation, which trades the job's token for a short-lived API token. No static API key. | Nothing durable to steal. |
| 3 | Permission mode | `--permission-mode auto`, on a model that supports it. On older models it silently falls back to the default mode. | A tool call outside the allowlist runs only if the safety classifier passes it. |
| 4 | Tool denylist | `--disallowedTools "WebFetch,WebSearch,Write,Edit,MultiEdit,NotebookEdit"` | Read-and-label jobs never write files or browse. |
| 5 | Wrapper scripts | The agent may call only `./scripts/*.sh`. Each script allows only certain subcommands and flags, and rejects scope escapes (`repo:`, `org:`, `user:` in search queries). | Raw `gh issue comment` or `gh issue edit` lets the agent act on any issue with any text. |
| 6 | Bound target | A write script reads the issue number from `$GITHUB_EVENT_PATH` (`jq -r '.issue.number'`), **never from arguments**. | An injected prompt cannot redirect the write to another issue. |
| 7 | Call caps | `CLAUDE_CODE_SCRIPT_CAPS: '{"edit-issue-labels.sh":2}'`, `'{"comment-on-duplicates.sh":1}'` | Limits the damage of a loop or an injection. |
| 8 | Output validation | Drop labels that do not exist in the repo. Allow at most N items, numeric only, each checked to exist. Use a fixed comment template, never free text. | The agent cannot invent labels or post spam. |
| 9 | Least-privilege token | `contents: read`, `issues: write`, `id-token: write`, and nothing else | GitHub limits the damage even if every other layer fails. |
| 10 | Time and concurrency | Job `timeout-minutes: 10`, step `5`. `concurrency: { group: triage-<issue>, cancel-in-progress: true }` | Bounds cost and stops races between runs. |
| 11 | Trigger hygiene | `allow_fork_prs: "false"` for `@claude`. Skip bot comments (`comment.user.type != 'Bot'`). Use `allowed_non_write_users` only on jobs whose tools are narrowed as above. | Keeps fork code and bot loops out of the job. |
| 12 | Model | Pin the exact ID. Leave a comment with the reason for the choice and any known refusal or limit. | Keeps runs reproducible and the choice auditable. |
| 13 | Irreversible actions | The agent only **labels or comments**. A deterministic cron script does the close, after a grace period of 3–14 days. A human 👎 or a new comment cancels it. Issues with ≥ N 👍 are never auto-closed. | The LLM proposes; code acts, and humans can veto. |
| 14 | Single source of truth | One file holds every lifecycle label, timeout and message (`issue-lifecycle.ts`). The prompt, the sweep script and the comments all read from it. | Keeps the prompt and the scripts from drifting apart. |
| 15 | Measurement | Log an event for each automated action (for example to Statsig) so its quality can be tracked over time. | You cannot tune what you do not measure. |
| 16 | Enforcement | Put the rules in CLAUDE.md **and** add a CI check that fails when a workflow breaks them. Exemptions go in a table in the check, each with a written reason. | A rule that lives only in a prompt will eventually be skipped. |

## Workflow template

See `templates/workflows/claude-issue-triage.yml`, and for the check `templates/scripts/check_workflow_hardening.py` run by `templates/workflows/workflow-hardening.yml`. Replace the `vars.*` names with the ones your org's federation setup uses.

## Enforcement check

The check (see `templates/CLAUDE-md-snippet.md` for the matching rule text) must fail when:
- a job that runs the Claude action is not on the firewall runner;
- a step lacks `--permission-mode auto`, or pins a model too old for it;
- `defaultMode` or a permission mode appears anywhere in the job: settings input, `--settings` file or inline JSON. A settings file outside the repository counts as a failure, because the check cannot read it;
- the allowlist file is missing, empty, not `mode: enforce`, or contains `*`.

Real history: Claude tightened this check in 4 quick commits, each closing a gap it found in its own check. Review your own enforcement code the same adversarial way.

## End-to-end test of the CI agent

Before merge, post exact `@claude` prompts as PR review comments (see `prompt-patterns.md`). Check the run summary for blocked hosts. If a needed host is blocked, add it to the allowlist with a comment saying what uses it.

## After merge

- Make the enforcement check a **required status check** on `main`. That is a manual admin step, so list it under "After merge" in the PR.
- Open a test issue, post one `@claude` comment, and confirm each job runs on the right runner with no blocked hosts.
