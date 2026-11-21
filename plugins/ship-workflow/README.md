# ship-workflow

Work with Claude the way the Claude Code team does. It gives you approval-gated feature work, evidence-backed PRs and review replies, multi-agent review with a validator per finding, and hardened Claude-in-CI templates. Unofficial; not affiliated with Anthropic.

## Install

```
/plugin marketplace add aasim-shah/claude-team-workflow
/plugin install ship-workflow@ship-workflow
```

## What's inside

| Skill | Use |
|---|---|
| `/ship-workflow:feature` | Explore, then clarify (waits), then design options (waits), then build test-first, then verify, then review |
| `/ship-workflow:review-diff` | Parallel bug hunters and rule checkers, then one validator per finding |
| `/ship-workflow:write-pr` | Drafts the commit message and PR body to the contract, without pushing |
| `/ship-workflow:ship-pr` | Commit with a why-body, push, and open a PR with a "Not tested" list and a Risk section (user-invoked only) |
| `/ship-workflow:reply-review` | Evidence-backed replies to review comments, scope kept |
| `/ship-workflow:harden-ci-agent` | Designs or reviews any CI job that runs Claude, with 12 required guardrails |
| `/ship-workflow:customize` | Records this repo's test commands and conventions in `.claude/ship-workflow.md` |
| `/ship-workflow:setup-repo` | Copies the skills, agents and CI automation into a repo (user-invoked only) |
| `shipping-like-claude-code-team` | The core loop and its gates. It loads automatically. |

Agents: `code-explorer`, `code-architect`, `bug-hunter`, `rule-checker`, `finding-validator` and `silent-failure-hunter`.

There are no hooks, no MCP servers and no telemetry. See [CONNECTORS.md](CONNECTORS.md) for the optional tools.

Docs: https://github.com/aasim-shah/claude-team-workflow
