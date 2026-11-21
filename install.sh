#!/usr/bin/env bash
# Install ship-workflow without the plugin system.
#
#   ./install.sh               the core skill (shipping-like-claude-code-team)
#   ./install.sh --skills      also the workflow skills as /ship-feature, /ship-review-diff,
#                              /ship-write-pr, /ship-ship-pr, /ship-reply-review, /ship-customize, /ship-setup-repo,
#                              and the review agents       (--commands is an alias)
#   ./install.sh --uninstall   remove everything this script installed
#
# Remote one-liner:
#   curl -fsSL https://raw.githubusercontent.com/aasim-shah/claude-team-workflow/main/install.sh | bash -s -- --skills
#
# Prefer the plugin when you can:  /plugin marketplace add aasim-shah/claude-team-workflow
set -euo pipefail

REPO_URL="https://github.com/aasim-shah/claude-team-workflow.git"
CORE="shipping-like-claude-code-team"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
HOME_DIR="$CLAUDE_HOME/ship-workflow"          # full plugin copy (templates, installer)
MANIFEST="$HOME_DIR/.installed"
WORKFLOW_SKILLS="feature review-diff write-pr ship-pr reply-review customize setup-repo harden-ci-agent"

with_skills=false uninstall=false
for arg in "$@"; do
  case "$arg" in
    --skills|--commands) with_skills=true ;;
    --uninstall) uninstall=true ;;
    -h|--help) sed -n '2,13p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg (see --help)" >&2; exit 2 ;;
  esac
done

if $uninstall; then
  if [[ -f "$MANIFEST" ]]; then
    while IFS= read -r path; do
      [[ -n "$path" && "$path" == "$CLAUDE_HOME"/* ]] && rm -rf "$path" && echo "  removed ${path#"$CLAUDE_HOME"/}"
    done < "$MANIFEST"
  fi
  rm -rf "${HOME_DIR:?}"
  echo "Uninstalled ship-workflow from $CLAUDE_HOME."
  exit 0
fi

# Find the source: this checkout, or a fresh shallow clone.
src=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  [[ -d "$here/plugins/ship-workflow" ]] && src="$here"
fi
if [[ -z "$src" ]]; then
  command -v git >/dev/null || { echo "Error: git is required" >&2; exit 1; }
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  git clone --quiet --depth 1 "$REPO_URL" "$tmp/repo"
  src="$tmp/repo"
fi
plugin="$src/plugins/ship-workflow"

# Keep the manifest across reinstalls so uninstall still finds earlier files.
old_manifest=""
[[ -f "$MANIFEST" ]] && old_manifest="$(cat "$MANIFEST")"
rm -rf "${HOME_DIR:?}"
mkdir -p "$HOME_DIR" "$CLAUDE_HOME/skills"
cp -R "$plugin/." "$HOME_DIR/"
chmod +x "$HOME_DIR/scripts/"*.sh "$HOME_DIR/skills/$CORE/templates/scripts/"*
printf '%s\n' "$old_manifest" | sed '/^$/d' > "$MANIFEST"
record() { grep -qxF "$1" "$MANIFEST" || echo "$1" >> "$MANIFEST"; }

rm -rf "${CLAUDE_HOME:?}/skills/$CORE"
cp -R "$plugin/skills/$CORE" "$CLAUDE_HOME/skills/$CORE"
record "$CLAUDE_HOME/skills/$CORE"
echo "Installed skill: $CORE"

if $with_skills; then
  for s in $WORKFLOW_SKILLS; do
    dest="$CLAUDE_HOME/skills/ship-$s"
    if [[ -e "$dest" ]] && ! grep -qxF "$dest" "$MANIFEST"; then
      echo "  skip /ship-$s (exists and is not ours)"; continue
    fi
    rm -rf "$dest"; mkdir -p "$dest"
    # Prefix the name so it cannot collide with other skills; point links at the installed copy.
    sed -e "s/^name: $s\$/name: ship-$s/" \
        -e "s#(../../CONNECTORS.md)#($HOME_DIR/CONNECTORS.md)#" \
        -e "s#\${CLAUDE_PLUGIN_ROOT}#$HOME_DIR#g" \
        "$plugin/skills/$s/SKILL.md" > "$dest/SKILL.md"
    record "$dest"; echo "  added /ship-$s"
  done
  mkdir -p "$CLAUDE_HOME/agents"
  for a in "$plugin"/agents/*.md; do
    dest="$CLAUDE_HOME/agents/$(basename "$a")"
    if [[ -e "$dest" ]] && ! grep -qxF "$dest" "$MANIFEST"; then
      echo "  skip agent $(basename "$a" .md) (exists and is not ours)"; continue
    fi
    cp "$a" "$dest"; record "$dest"; echo "  added agent $(basename "$a" .md)"
  done
fi

cat <<EOF

Next:
  • Start Claude Code in a repo. The core skill loads when you build features, open PRs or review.
  • Put the skills and CI into a repo for your whole team:
      bash "$HOME_DIR/scripts/init-repo.sh" --all /path/to/repo
EOF
