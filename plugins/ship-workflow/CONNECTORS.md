# Connectors

## How tool references work

Skill files use `~~category` as a placeholder for whatever tool fills that role in your setup. For example, `~~source control` means GitHub (through `gh`), GitLab (through `glab`), or an MCP server for either.

ship-workflow ships **no MCP servers and no hooks**. Every skill works **standalone** with `git` and your test runner, and does more when the tools below are available.

| Category | Placeholder | Used for | Works with |
|---|---|---|---|
| Source control | `~~source control` | Fetching PR diffs, opening PRs, reading review comments | `gh` CLI (GitHub), `glab` CLI (GitLab), any source-control MCP server |
| CI/CD | `~~CI/CD` | Reading run results after a push; hosting the triage automation | GitHub Actions (the templates target it), others by hand |
| Project tracker | `~~project tracker` | Pulling a ticket's acceptance criteria into `/feature` | Linear, Jira, Asana MCP servers |
| Chat | `~~chat` | Optional: posting a PR link when shipping | Slack, Teams MCP servers |

## Setting your tools

Run `/ship-workflow:customize`. It detects your source control from `git remote -v` and records it in `.claude/ship-workflow.md`, along with your test and check commands.
