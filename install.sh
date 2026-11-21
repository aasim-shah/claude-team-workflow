#!/usr/bin/env bash
# Install ship-workflow without the plugin system.
#
#   ./install.sh                 install the skill into ~/.claude/skills
#   ./install.sh --commands      also install the dev commands into ~/.claude/commands
#                                (/feature, /review-diff, /ship-pr, /reply-review, /setup-repo)
#   ./install.sh --uninstall     remove what this script installed
#
# Remote one-liner:
#   curl -fsSL https://raw.githubusercontent.com/aasim-shah/claude-team-workflow/main/install.sh | bash -s -- --commands
#
# Prefer the plugin when you can:  /plugin marketplace add aasim-shah/claude-team-workflow
set -euo pipefail

REPO_URL="https://github.com/aasim-shah/claude-team-workflow.git"
SKILL="shipping-like-claude-code-team"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
COMMAND_NAMES="feature review-diff ship-pr reply-review setup-repo"

with_commands=false uninstall=false
for arg in "$@"; do
  case "$arg" in
    --commands) with_commands=true ;;
    --uninstall) uninstall=true ;;
    -h|--help) sed -n '2,12p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg (see --help)" >&2; exit 2 ;;
  esac
done

if $uninstall; then
  list="$CLAUDE_HOME/skills/$SKILL/.installed-commands"
  if [[ -f "$list" ]]; then
    while IFS= read -r c; do
      [[ -n "$c" ]] && rm -f "$CLAUDE_HOME/commands/$c.md" && echo "  removed /$c"
    done < "$list"
  fi
  rm -rf "${CLAUDE_HOME:?}/skills/$SKILL"
  echo "Removed $SKILL from $CLAUDE_HOME."
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

mkdir -p "$CLAUDE_HOME/skills"
rm -rf "${CLAUDE_HOME:?}/skills/$SKILL"
cp -R "$plugin/skills/$SKILL" "$CLAUDE_HOME/skills/$SKILL"
# Make the bundled installer reachable from the skill folder too.
mkdir -p "$CLAUDE_HOME/skills/$SKILL/bin"
cp "$plugin/scripts/init-repo.sh" "$CLAUDE_HOME/skills/$SKILL/bin/init-repo.sh"
cp -R "$plugin/commands" "$CLAUDE_HOME/skills/$SKILL/commands"
chmod +x "$CLAUDE_HOME/skills/$SKILL/bin/init-repo.sh" "$CLAUDE_HOME/skills/$SKILL/templates/scripts/"*
echo "Installed skill: $CLAUDE_HOME/skills/$SKILL"

if $with_commands; then
  mkdir -p "$CLAUDE_HOME/commands"
  for c in $COMMAND_NAMES; do
    if [[ -e "$CLAUDE_HOME/commands/$c.md" ]]; then
      echo "  skip $c.md (exists)"
    else
      cp "$plugin/commands/$c.md" "$CLAUDE_HOME/commands/$c.md"
      echo "$c" >> "$CLAUDE_HOME/skills/$SKILL/.installed-commands"
      echo "  added /$c"
    fi
  done
fi

cat <<EOF

Next:
  • Start Claude Code in a repo. The skill loads when you build features, open PRs or review.
  • Add commands/CI to a repo:  bash "$CLAUDE_HOME/skills/$SKILL/bin/init-repo.sh" --all /path/to/repo
EOF
