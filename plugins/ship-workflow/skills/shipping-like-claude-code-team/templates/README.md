# Templates

CI and repository templates. Copy them with the installer (below) rather than by hand. Each one is original wording that follows the patterns in `../references/`.

| Template | Copy to | Purpose |
|---|---|---|
| `commands/triage-issue.md` | `.claude/commands/triage-issue.md` | CI issue triage, labels only |
| `commands/dedupe.md` | `.claude/commands/dedupe.md` | CI duplicate detection |
| `scripts/gh-readonly.sh` | `scripts/gh-readonly.sh` | A read-only `gh` allowlist wrapper |
| `scripts/edit-issue-labels.sh` | `scripts/edit-issue-labels.sh` | Label writes bound to the event's issue |
| `scripts/comment-on-duplicates.sh` | `scripts/comment-on-duplicates.sh` | A fixed-template duplicate comment, at most 3 |
| `workflows/claude-issue-triage.yml` | `.github/workflows/` | The triage and dedupe jobs with every hardening layer |
| `scripts/check_workflow_hardening.py` | `scripts/` | Enforcement check: fails CI when a Claude job breaks the rules |
| `workflows/workflow-hardening.yml` | `.github/workflows/` | Runs the check; make it a required status check |
| `workflows/egress-firewall.yaml` | `.github/egress-firewall.yaml` | The network allowlist |
| `CLAUDE-md-snippet.md` | append to `CLAUDE.md` | The rules the enforcement check backs |

The workflow skills (`feature`, `review-diff`, `ship-pr`, `reply-review`, `customize`, `setup-repo`) live in the plugin's `skills/` folder, and the review agents live in `agents/`.

Install everything into a repo with the bundled installer:

    bash <plugin>/scripts/init-repo.sh --all /path/to/repo      # or: /ship-workflow:setup-repo --all
