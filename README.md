<p align="center"><img src="plugins/ship-workflow/.claude-plugin/icon.png" width="96" alt=""></p>

# ship-workflow

**Work with Claude the way the Claude Code team does.** This is a Claude Code plugin. It packages the engineering loop visible in the public record of [anthropics/claude-code](https://github.com/anthropics/claude-code) as:
- 9 skills;
- 6 review and design agents;
- 4 behaviour evals;
- hardened GitHub Actions templates.

[![CI](https://github.com/aasim-shah/claude-team-workflow/actions/workflows/ci.yml/badge.svg)](https://github.com/aasim-shah/claude-team-workflow/actions/workflows/ci.yml) [![Release](https://img.shields.io/github/v/release/aasim-shah/claude-team-workflow)](https://github.com/aasim-shah/claude-team-workflow/releases) [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

> Unofficial. Not affiliated with or endorsed by Anthropic. It is reconstructed from public PRs, commits and files, and written in our own words. See [Sources](#sources).

## Quick start

```
/plugin marketplace add aasim-shah/claude-team-workflow
/plugin install ship-workflow@ship-workflow
/reload-plugins
/ship-workflow:customize
/ship-workflow:feature add rate limiting to POST /login
```

`customize` records your repo's test commands and conventions, once. `feature` then:
1. Explores the code.
2. Asks one batched set of questions, and **stops** for your answers.
3. Proposes 2–3 designs with a recommendation, and **stops** for your pick.
4. Builds test-first and runs your checks.
5. Reviews with several agents.
6. Tells you what it did **not** test.

It never merges.

## The loop

```
 you ask ─► explore ─► clarify ─► design ─► build ─► verify ─► review ─► PR ─► reply ─► human merges
            agents     ■ wait     ■ wait    tests    your      agents +   Not     evidence
                                            first    checks    validator  tested  + scope
                                                               per        + Risk
                                                               finding
```

| Skill | When | Gates it enforces |
|---|---|---|
| `/ship-workflow:feature` | "build X", "implement this ticket", anything touching auth, data or a public API | No code before answers; no build before you pick a design; "ship today" is not approval |
| `/ship-workflow:review-diff` | "review this", "check before I merge" | Only high-signal issues; each finding confirmed by a separate validator agent |
| `/ship-workflow:write-pr` | "write the PR description", "draft a commit message" | Drafts text only. The PR body has Summary, What changes for users, Testing + **Not tested**, Risk, After merge |
| `/ship-workflow:ship-pr` | Only when you ask (never on its own) | The PR body has Summary, What changes for users, Testing + **Not tested**, Risk, After merge; it never writes "CI passed" before CI runs |
| `/ship-workflow:reply-review` | "handle the review comments" | It checks the claim in the code **and on real data**; "just fix it" does not widen the PR |
| `/ship-workflow:harden-ci-agent` | "Claude triage issues", "AI bot in GitHub Actions" | 12 required guardrails; the model never chooses which issue it writes to; closing only by deterministic code after a human veto window |
| `/ship-workflow:customize` | First run in a repo | Detects first, asks once, writes `.claude/ship-workflow.md` |
| `/ship-workflow:setup-repo` | Only when you ask | Dry run first, no overwrite without `--force` |
| `shipping-like-claude-code-team` | Loads by itself | The 10 phases, 4 hard gates, the contracts, a rationalization table, red flags |

**Agents** (launched by the skills, or by you):

| Agent | Model | Job |
|---|---|---|
| `code-explorer` | sonnet | Traces one angle end to end, returns the 5–10 key files |
| `code-architect` | opus | One design per stance: minimal, clean or pragmatic |
| `bug-hunter` | opus | Bugs it can prove, in changed lines only |
| `rule-checker` | sonnet | CLAUDE.md violations it can quote |
| `finding-validator` | opus | Confirms or rejects one finding |
| `silent-failure-hunter` | sonnet | Swallowed errors and hidden fallbacks |

## Make it yours

The plugin works **standalone** with `git` and your test runner. It does more ("**supercharged**") when `gh`, `glab` or MCP servers are available (see [CONNECTORS.md](plugins/ship-workflow/CONNECTORS.md)). Run `/ship-workflow:customize` to record your setup in `.claude/ship-workflow.md`, and commit that file so the whole team gets the same behaviour:

```yaml
---
default_branch: main
source_control: github
test_command: npm test
check_commands: [npm run lint, npm run typecheck]
sensitive_paths: [src/auth/**, db/migrations/**]   # always get the design gate
models: { gate: haiku, rules: sonnet, bugs: opus }
---
```

## Share it with your team

Commit the skills and agents into a repository, so everyone who clones it gets them, plugin or not:

```
/ship-workflow:setup-repo --skills
```

## Put Claude in CI (issue triage + dedupe)

```
/ship-workflow:setup-repo --ci
```

This adds triage and dedupe jobs built for **public repos with hostile issue text**:
- Wrapper scripts read the target issue from the event payload, never from the model.
- Call caps limit how many writes a run can make.
- Labels are validated, and comments use a fixed template.
- An egress allowlist blocks other hosts.
- Auth uses short-lived OIDC tokens.
- The permission mode is `auto`.
- A check fails CI when a workflow drops any of these. The full list is in [`ci-agents.md`](plugins/ship-workflow/skills/shipping-like-claude-code-team/references/ci-agents.md).

Afterwards, set the 4 `ANTHROPIC_*` repo variables, create the labels, and make the hardening check a required status check.

## Install without the plugin system

```bash
curl -fsSL https://raw.githubusercontent.com/aasim-shah/claude-team-workflow/main/install.sh | bash -s -- --skills
```

This installs the core skill, the workflow skills as `/ship-feature`, `/ship-review-diff` and so on, and the agents. It never overwrites files it did not install. Remove everything with `bash install.sh --uninstall`.

## Safety

No hooks, no MCP servers, no telemetry, and no network calls from the shipped scripts. `ship-pr` and `setup-repo` run only when you invoke them. Each skill lists its exact `allowed-tools`. `tests/run.sh` enforces these claims on every push. See [SECURITY.md](SECURITY.md).

## How it is tested

| Layer | What | Where |
|---|---|---|
| Deterministic | 74 checks: wrapper scripts against a fake `gh`, the hardening check against good and broken workflows, both installers (dry run, no overwrite, uninstall), frontmatter, links, the safety claims, versions | `bash tests/run.sh`, run in CI |
| Lint and validate | `shellcheck`; `claude plugin validate`, including `--profile directory` | CI |
| Behaviour | 4 evals, each run with and without the plugin: the approval gate under deadline pressure, the PR-body contract, review-reply scope, and CI triage hardening | `claude plugin eval plugins/ship-workflow` |

**Latest eval run** (Claude Code 2.1.328, 3 runs per arm, one LLM grader per criterion):

| Case | With plugin | Without |
|---|---|---|
| Approval gate ("ship it today, keep it quick") | 91% | 66% |
| PR body: Not tested, Risk, why | 100% | 50% |
| Review reply: evidence, scope kept under "just fix it" | 100% | 77% |
| CI triage on a public repo: 6 guardrails | 100% | 77% |
| **Overall** | **98%** | **69%** |

Reproduce it with `claude plugin eval plugins/ship-workflow --runs 3`.

The skill was written test-first. Baseline agents without it built without approval, claimed CI passed before it ran, and let the model choose which issue to write to. The same scenarios run with the skill held every gate.

## Sources

- **anthropics/claude-code:** its workflows, slash commands, wrapper scripts, mod sources and changelog, plus PRs #97952, #105270, #105303, #106583, #107768 and #111198. That repo is "all rights reserved", so nothing is copied from it. See [`sources.md`](plugins/ship-workflow/skills/shipping-like-claude-code-team/references/sources.md).
- **anthropics/knowledge-work-plugins** (Apache-2.0): its plugin conventions, namely skills as commands, `CONNECTORS.md` with `~~` placeholders, standalone vs supercharged, agent frontmatter with `<example>` triggers, and customization.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). PRs follow the plugin's own template.

## License

[MIT](LICENSE)
