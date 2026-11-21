# Contributing

## Layout

```
.claude-plugin/marketplace.json          marketplace entry (name, version, source)
plugins/ship-workflow/
  .claude-plugin/plugin.json             manifest + icon
  skills/<name>/SKILL.md                 one folder per skill; frontmatter name must match the folder
  skills/shipping-like-claude-code-team/ core skill: references/ and templates/ (CI automation)
  agents/<name>.md                       subagents; description must contain <example> blocks
  evals/<case>/prompt.md, graders/*.md   behaviour tests run with `claude plugin eval`
  scripts/init-repo.sh                   copies skills, agents and CI templates into a repository
  CONNECTORS.md                          what ~~placeholders mean
install.sh                               install without the plugin system
tests/run.sh                             the deterministic test suite
```

## Before opening a PR

1. Run `bash tests/run.sh` (it needs `jq`, `python3` and `pyyaml`).
2. Run `claude plugin validate .` and `claude plugin validate plugins/ship-workflow --profile directory`.
3. If you changed a skill's or an agent's wording, run the evals before and after the change and compare the scores:
   `claude plugin eval plugins/ship-workflow --runs 3`.
   A new rule needs a new eval case that fails without the rule.
4. Fill in every section of the PR template, including **Not tested**.

## Rules for skills

- The `description` says when to use the skill and gives trigger phrases. It does not summarize the steps.
- Use a recipe or contract (what the output is) for output-shape problems. Use a hard gate plus a rationalization table only for discipline problems.
- If a rule can be enforced by a script, enforce it with a script and keep the prose short.
- Never copy text from repositories whose license forbids it. Paraphrase and cite.

## Releasing

1. Bump the version in `plugin.json`, in the marketplace entry, and in the marketplace `metadata`.
2. Add a `## x.y.z` section to `CHANGELOG.md`.
3. Merge, then run `git tag vX.Y.Z && git push --tags`. The release workflow checks the versions, runs the tests and publishes the release.
