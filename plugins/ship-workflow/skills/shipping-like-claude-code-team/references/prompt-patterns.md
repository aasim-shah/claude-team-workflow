# Prompt patterns

## Slash commands live in the repo

`.claude/commands/<name>.md` is versioned, reviewed and run identically by people and by CI (`prompt: "/triage-issue REPO: … ISSUE_NUMBER: … EVENT: …"`).

Frontmatter:
```yaml
---
allowed-tools: Bash(./scripts/gh.sh:*), Bash(./scripts/edit-issue-labels.sh:*)
description: Triage GitHub issues by analyzing and applying labels
argument-hint: <issue number>
---
```
- `allowed-tools` names **scripts**, not broad commands.
- Inject live context with `!` backticks: `- Current diff: !`git diff HEAD``. The command runs before the model sees the prompt.
- Use `$ARGUMENTS` for input.

## Structure of a strong command or agent prompt

1. **Role and the single allowed action**, with what is forbidden: "Your only actions are adding or removing labels. Don't post any comments."
2. **Tool list**, with an exact example of each allowed call.
3. **Numbered task**, with branches keyed to observable conditions ("If EVENT is `issues` … If EVENT is `issue_comment` …").
4. **Decision rules**, each with its negative cases spelled out:
   - "Do NOT apply if the user already provided error messages, logs, file paths…"
   - "'+1', 'me too' … are NOT the missing information."
   - "The body text is authoritative. If a dropdown contradicts it, trust the body."
5. **Asymmetric default:** "When in doubt, don't apply a lifecycle label — false positives are worse than missing labels."
6. **Required outcome:** "On new issues always apply exactly one of `bug`, `enhancement`, `question`, `invalid`, `duplicate`."
7. **A false-positive list:** the things not to flag, by name.
8. **The exact output format,** down to link syntax.

## Efficiency lines that cut wasted calls

- "All tools are functional and will work without error. Do not test tools or make exploratory calls."
- "Only call a tool if it is required to complete the task."
- "You MUST do all of the above in a single message." (for commit, push and PR in one shot)
- "Use the wrapper script rather than web fetch or raw gh." Also tell this to the subagents.

## Keep prompts in step with models

When the model changes, re-read every prompt it runs. Real example: Sonnet 5.5 is not offered the todo tools, so "Make a todo list first" was deleted from the dedupe command in the same PR that changed the model.

## Prompts that test an agent

Claude in the engineer's session wrote these as PR review comments, to test the CI agent end to end:

Smoke test:
```
@claude End-to-end check that this PR's workflow works on the firewall runner.
Reply with one short line confirming you started, and nothing else.
Don't edit files, run commands, or push anything.
```

Capability test (proves the permission mode actually works):
```
@claude End-to-end check of auto permission mode on the firewall runner. Please:
1. Run `uname -sr` and `git log -1 --format=%s` with Bash, and give their output.
2. Create a file named `auto-mode-check.txt` in the repository root that holds the line `ok`,
   then run `git status --short` and give its output.
3. Do not commit, push, or change anything else.
Reply with the results only.
```

Shape: one goal line, numbered exact actions each with its observable result, an explicit ban on everything else, and a fixed reply format.

## Prompts the engineer gives Claude

They are short and state the effect. The constraints come from CLAUDE.md and the commands, so the engineer does not retype them.
```
Move the three workflows that call Claude to claude-sonnet-5-5.
```
```
Don't run @claude mentions on pull requests from forks.
```
```
Remove the security-guidance copy here; install it from claude-plugins-official.
```
Claude then explores, finds the hidden constraints, and reports them in the PR (versions affected, behaviour on old clients, follow-ups).

## Writing style they use (prose, docs, PRs)

- One term means one thing everywhere. No synonym rotation.
- Short declarative sentences in active voice. State the effect before the mechanism.
- Every claim is checkable: versions, counts, file paths, issue numbers.
- Say what was not done: "Not run on GitHub." "Not tried with this repository's account."
