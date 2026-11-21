# ship-workflow

**Work with Claude the way the Claude Code team does.** This is a Claude Code plugin. It packages the engineering loop visible in the public record of [anthropics/claude-code](https://github.com/anthropics/claude-code) into a skill, five slash commands and hardened GitHub Actions templates.

> Unofficial. Not affiliated with or endorsed by Anthropic. Everything here is reconstructed from public PRs, commits and files, and written in our own words. See [Sources](#sources).

## What you get

| Piece | What it does |
|---|---|
| **Skill** `shipping-like-claude-code-team` | Loads automatically when you build a feature, open a PR, answer a review or put Claude in CI. It holds the 10-phase loop, 4 hard gates, the PR, commit and review-reply contracts, and red flags. |
| `/ship-workflow:feature` | Explore, then clarify (**waits**), then design options (**waits**), then build test-first, then verify, then multi-agent review, then report. |
| `/ship-workflow:review-diff` | A small-model gate, CLAUDE.md compliance plus bug hunters in parallel, **one validator per finding**, and high-signal output only. |
| `/ship-workflow:ship-pr` | Branch, commit with a why-body, push, and open a PR with the required sections: Summary, What changes for users, Testing + **Not tested**, Risk, After merge. |
| `/ship-workflow:reply-review` | Checks a reviewer's claim in the code and **on real data**, keeps the PR's scope, and drafts the reply. |
| `/ship-workflow:setup-repo` | Copies the commands and/or the hardened CI automation into the current repo. |
| CI templates | Issue triage and dedupe with 16 safety layers: an egress allowlist, OIDC auth, auto permission mode, wrapper scripts bound to the triggering issue, call caps, validated output, and a check that fails CI when a workflow breaks the rules. |

## Install

**As a plugin (recommended).** In Claude Code:

```
/plugin marketplace add aasim-shah/claude-team-workflow
/plugin install ship-workflow@ship-workflow
```

Restart Claude Code, or run `/reload-plugins`. Update later with `/plugin marketplace update ship-workflow`.

**Without the plugin system:**

```bash
curl -fsSL https://raw.githubusercontent.com/aasim-shah/claude-team-workflow/main/install.sh | bash -s -- --commands
```

This installs the skill into `~/.claude/skills/` and the commands into `~/.claude/commands/` as `/feature`, `/review-diff`, `/ship-pr`, `/reply-review` and `/setup-repo`. Remove them with `bash install.sh --uninstall`.

## Use

```
/ship-workflow:feature add rate limiting to POST /login
```

Claude explores, asks one batched set of questions, and stops. Answer them. Claude then proposes 2–3 designs with a recommendation, and stops again. Pick one. Claude builds it test-first, runs your repo's checks, reviews with several agents, and reports what it did **not** test. It never merges.

```
/ship-workflow:review-diff            # review the working-tree diff
/ship-workflow:review-diff 123 --comment   # review PR #123 and post inline comments
/ship-workflow:ship-pr
/ship-workflow:reply-review 123
```

You don't have to type the commands. Say "build X", "open a PR" or "handle the review comments", and the skill applies the same gates.

## Put Claude in CI (issue triage + dedupe)

```
/ship-workflow:setup-repo --ci
```

or, from a shell:

```bash
bash ~/.claude/plugins/cache/ship-workflow/ship-workflow/*/scripts/init-repo.sh --ci /path/to/repo
```

The installer shows a dry run first, never overwrites a file without `--force`, and adds:

```
.claude/commands/triage-issue.md, dedupe.md   labels only / fixed-template comment, untrusted-input rules
scripts/gh-readonly.sh                        read-only gh allowlist, scoped to the repo
scripts/edit-issue-labels.sh                  issue number from the event payload, unknown labels dropped
scripts/comment-on-duplicates.sh              1–3 verified issues, fixed template, veto window
scripts/check_workflow_hardening.py           fails CI when a Claude job breaks the rules
.github/workflows/claude-issue-triage.yml     triage + dedupe jobs, every layer on
.github/workflows/workflow-hardening.yml      runs the check
.github/egress-firewall.yaml                  network allowlist, mode: enforce
CLAUDE.md                                     the rules, appended once
```

Then do these 4 steps:
1. Set the repo variables `ANTHROPIC_FEDERATION_RULE_ID`, `ANTHROPIC_ORGANIZATION_ID`, `ANTHROPIC_SERVICE_ACCOUNT_ID` and `ANTHROPIC_WORKSPACE_ID` (workload identity federation).
2. Create the labels the triage uses.
3. If you have no `ubuntu-24.04-firewall` runner, change `runs-on` and `FIREWALL_RUNNER` in the check together.
4. After merge, make **Security check for workflows that call Claude** a required status check.

## How it was built and tested

1. Read the public repo: its workflows, slash commands, wrapper scripts, mod sources, 446 changelog releases, and the plugins in its git history.
2. Read the public PRs (#97952, #105270, #105303, #106583, #107768, #111198) and their review threads.
3. Ran baseline scenarios with fresh agents **without** the skill: a feature under deadline pressure, a reviewer's claim, and public-repo CI triage. The failures were recorded: building without approval, claiming CI passed before it ran, no "not tested" list, the model choosing which issue to write to, and no enforcement.
4. Wrote the skill against those failures. Re-ran the same scenarios with extra pressure ("quick please", "just fix it"). Every gate held.
5. `bash tests/run.sh` runs 60 checks:
   - the wrapper scripts against a fake `gh`;
   - the enforcement check against good and deliberately broken workflows;
   - both installers, including dry run, no-overwrite and uninstall;
   - the manifests and the skill frontmatter.

   CI runs it on every push, along with `shellcheck` and `claude plugin validate`.

## Sources

The full list, with file paths and PR numbers, is in [`references/sources.md`](plugins/ship-workflow/skills/shipping-like-claude-code-team/references/sources.md). The upstream repository is "all rights reserved", so no prompts or code are copied from it. Short quotes are attributed.

## Contributing

Issues and PRs are welcome. Run `bash tests/run.sh` before opening one. PR bodies follow the plugin's own contract: Summary, What changes for users, Testing + Not tested, Risk, After merge.

## License

[MIT](LICENSE)
