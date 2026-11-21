#!/usr/bin/env bash
# Copy ship-workflow files into a repository, so everyone who clones it gets them.
#
#   init-repo.sh [--skills] [--ci] [--all] [--force] [--dry-run] [TARGET_DIR]
#
#   --skills    workflow skills into .claude/skills/ (feature, review-diff, write-pr, ship-pr,
#               reply-review, customize) and review agents into .claude/agents/   (--commands is an alias)
#   --ci        hardened issue triage + dedupe for GitHub Actions, wrapper scripts, the enforcement
#               check, the egress allowlist, and the CLAUDE.md rules
#   --all       both (default when neither is given: --skills)
#   --force     overwrite files that already exist (default: skip them)
#   --dry-run   print what would happen, change nothing
#   TARGET_DIR  repository root (default: current directory)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES="$PLUGIN_DIR/skills/shipping-like-claude-code-team/templates"
SKILLS="feature review-diff write-pr ship-pr reply-review customize harden-ci-agent"
MARKER="## Workflows that call Claude"

want_skills=false want_ci=false force=false dry=false target="."
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skills|--commands) want_skills=true ;;
    --ci) want_ci=true ;;
    --all) want_skills=true; want_ci=true ;;
    --force) force=true ;;
    --dry-run) dry=true ;;
    -h|--help) sed -n '2,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "Unknown option: $1 (see --help)" >&2; exit 2 ;;
    *) target="$1" ;;
  esac
  shift
done
$want_skills || $want_ci || want_skills=true

[[ -d "$target" ]] || { echo "Error: $target is not a directory" >&2; exit 1; }
target="$(cd "$target" && pwd)"
[[ -d "$TEMPLATES" && -d "$PLUGIN_DIR/agents" ]] || { echo "Error: plugin files not found under $PLUGIN_DIR" >&2; exit 1; }
git -C "$target" rev-parse --is-inside-work-tree >/dev/null 2>&1 || echo "Note: $target is not a git repository."

copied=0 skipped=0
put() { # put SRC DEST_RELATIVE [mode]
  local src="$1" dest="$target/$2" mode="${3:-644}"
  if [[ -e "$dest" && "$force" != true ]]; then
    echo "  skip    $2 (exists; --force to overwrite)"; skipped=$((skipped + 1)); return
  fi
  echo "  write   $2"
  if [[ "$dry" != true ]]; then
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    chmod "$mode" "$dest"
  fi
  copied=$((copied + 1))
}

echo "Target: $target"
if $want_skills; then
  echo "Workflow skills and agents:"
  for s in $SKILLS; do
    put "$PLUGIN_DIR/skills/$s/SKILL.md" ".claude/skills/$s/SKILL.md"
  done
  put "$PLUGIN_DIR/CONNECTORS.md" ".claude/CONNECTORS.md"
  for a in "$PLUGIN_DIR"/agents/*.md; do
    put "$a" ".claude/agents/$(basename "$a")"
  done
fi

if $want_ci; then
  echo "CI automation:"
  put "$TEMPLATES/commands/triage-issue.md" ".claude/commands/triage-issue.md"
  put "$TEMPLATES/commands/dedupe.md" ".claude/commands/dedupe.md"
  for s in gh-readonly.sh edit-issue-labels.sh comment-on-duplicates.sh check_workflow_hardening.py; do
    put "$TEMPLATES/scripts/$s" "scripts/$s" 755
  done
  put "$TEMPLATES/workflows/claude-issue-triage.yml" ".github/workflows/claude-issue-triage.yml"
  put "$TEMPLATES/workflows/workflow-hardening.yml" ".github/workflows/workflow-hardening.yml"
  put "$TEMPLATES/workflows/egress-firewall.yaml" ".github/egress-firewall.yaml"

  if [[ -f "$target/CLAUDE.md" ]] && grep -qF "$MARKER" "$target/CLAUDE.md"; then
    echo "  skip    CLAUDE.md (rules already present)"; skipped=$((skipped + 1))
  else
    echo "  append  CLAUDE.md (workflow and PR rules)"
    if [[ "$dry" != true ]]; then
      [[ -s "$target/CLAUDE.md" ]] && printf '\n' >> "$target/CLAUDE.md"
      cat "$TEMPLATES/CLAUDE-md-snippet.md" >> "$target/CLAUDE.md"
    fi
    copied=$((copied + 1))
  fi
fi

echo
$dry && echo "Dry run: nothing changed."
echo "Done: $copied written, $skipped skipped."
if $want_skills; then
  echo
  echo "Next: run /customize in Claude Code to record this repo's test commands and conventions."
fi
if $want_ci; then
  cat <<'EOF'

Next steps for CI:
  1. Set repo variables ANTHROPIC_FEDERATION_RULE_ID, ANTHROPIC_ORGANIZATION_ID,
     ANTHROPIC_SERVICE_ACCOUNT_ID, ANTHROPIC_WORKSPACE_ID (workload identity federation).
  2. Create the labels your triage uses (bug, enhancement, question, invalid, duplicate,
     needs-repro, needs-info, stale, autoclose). Unknown labels are dropped.
  3. If your org has no ubuntu-24.04-firewall runner, change runs-on and the
     FIREWALL_RUNNER constant in scripts/check_workflow_hardening.py together.
  4. Run: python3 scripts/check_workflow_hardening.py .   (needs pyyaml)
  5. After merge: make "Security check for workflows that call Claude" a required check,
     then open a test issue and confirm labels and no blocked hosts.
EOF
fi
