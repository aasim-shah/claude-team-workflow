#!/usr/bin/env bash
# Test suite: wrapper scripts (with a fake gh), the enforcement check, the repo installer,
# the user installer, and manifest/skill sanity. Run from anywhere: bash tests/run.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN="$ROOT/plugins/ship-workflow"
SKILL="$PLUGIN/skills/shipping-like-claude-code-team"
T="$SKILL/templates"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0 fail=0
ok()   { echo "  ok   $1"; pass=$((pass + 1)); }
bad()  { echo "  FAIL $1"; [[ -n "${2:-}" ]] && echo "$2" | sed 's/^/       /'; fail=$((fail + 1)); }
expect_ok()   { local name="$1"; shift; local out; if out=$("$@" 2>&1); then ok "$name"; else bad "$name" "$out"; fi; }
expect_fail() { local name="$1"; shift; local out; if out=$("$@" 2>&1); then bad "$name (should fail)" "$out"; else ok "$name"; fi; }
expect_out()  { local name="$1" want="$2"; shift 2; local out; out=$("$@" 2>&1); if grep -qF -- "$want" <<<"$out"; then ok "$name"; else bad "$name (want: $want)" "$out"; fi; }

# --- fake gh -------------------------------------------------------------------------------
mkdir -p "$WORK/bin"
cat > "$WORK/bin/gh" <<'EOF'
#!/bin/sh
echo "GH $*"
case "$1 $2" in
  "label list") printf 'bug\nquestion\nneeds-info\n' ;;
  "issue view") [ "$3" = "404" ] && exit 1 ;;
esac
exit 0
EOF
chmod +x "$WORK/bin/gh"
echo '{"issue":{"number":42}}' > "$WORK/event.json"
export PATH="$WORK/bin:$PATH" GH_REPO="acme/widgets" GITHUB_EVENT_PATH="$WORK/event.json"

echo "gh-readonly.sh"
G="$T/scripts/gh-readonly.sh"
expect_out  "issue view passes"            "GH issue view 12"            bash "$G" issue view 12
expect_out  "--comments allowed"           "GH issue view 12 --comments" bash "$G" issue view 12 --comments
expect_out  "search scoped to repo"        "--repo acme/widgets"         bash "$G" search issues "crash" --limit 3
expect_ok   "label list"                                                bash "$G" label list
expect_fail "issue edit refused"                                        bash "$G" issue edit 12
expect_fail "issue comment refused"                                     bash "$G" issue comment 12
expect_fail "--json flag refused"                                       bash "$G" issue view 12 --json body
expect_fail "non-numeric id refused"                                    bash "$G" issue view abc
expect_fail "repo: qualifier refused"                                   bash "$G" search issues "x repo:evil/r"
expect_fail "ORG: qualifier refused"                                    bash "$G" search issues "x ORG:evil"
expect_fail "missing GH_REPO refused"                                   env -u GH_REPO -u GITHUB_REPOSITORY bash "$G" label list

echo "edit-issue-labels.sh"
E="$T/scripts/edit-issue-labels.sh"
expect_out  "targets event issue"          "GH issue edit 42 --add-label bug --remove-label question" bash "$E" --add-label bug --add-label invented --remove-label question
expect_out  "unknown labels dropped"       "nothing changed"            bash "$E" --add-label invented
expect_fail "issue number arg refused"                                  bash "$E" --issue 7 --add-label bug
expect_fail "no args refused"                                           bash "$E"
echo '{}' > "$WORK/empty.json"
expect_fail "no issue in payload refused"                               env GITHUB_EVENT_PATH="$WORK/empty.json" bash "$E" --add-label bug

echo "comment-on-duplicates.sh"
C="$T/scripts/comment-on-duplicates.sh"
expect_out  "posts on event issue"         "GH issue comment 42"        bash "$C" --potential-duplicates 7 9
expect_out  "fixed template"               "unless someone objects"     bash "$C" --potential-duplicates 7
expect_fail "more than 3 refused"                                       bash "$C" --potential-duplicates 1 2 3 4
expect_fail "self-reference refused"                                    bash "$C" --potential-duplicates 42
expect_fail "missing issue refused"                                     bash "$C" --potential-duplicates 404
expect_fail "non-numeric refused"                                       bash "$C" --potential-duplicates 7x
expect_fail "wrong flag refused"                                        bash "$C" 7 9

echo "check_workflow_hardening.py"
CHK="$T/scripts/check_workflow_hardening.py"
if python3 -c 'import yaml' 2>/dev/null; then
  mkdir -p "$WORK/good/.github/workflows" "$WORK/bad/.github/workflows"
  cp "$T/workflows/claude-issue-triage.yml" "$T/workflows/workflow-hardening.yml" "$WORK/good/.github/workflows/"
  cp "$T/workflows/egress-firewall.yaml" "$WORK/good/.github/"
  expect_ok "templates pass" python3 -I "$CHK" "$WORK/good"
  sed -e 's/ubuntu-24.04-firewall/ubuntu-latest/' "$T/workflows/claude-issue-triage.yml" > "$WORK/bad/.github/workflows/a.yml"
  cp "$T/workflows/egress-firewall.yaml" "$WORK/bad/.github/"
  expect_out "wrong runner caught" "runs-on must be ubuntu-24.04-firewall" python3 -I "$CHK" "$WORK/bad"
  sed -e 's/--permission-mode auto//' "$T/workflows/claude-issue-triage.yml" > "$WORK/bad/.github/workflows/a.yml"
  expect_out "missing auto mode caught" "lacks --permission-mode auto" python3 -I "$CHK" "$WORK/bad"
  sed -e 's/claude-sonnet-5-5/claude-sonnet-4-5/' "$T/workflows/claude-issue-triage.yml" > "$WORK/bad/.github/workflows/a.yml"
  expect_out "old model caught" "too old for auto mode" python3 -I "$CHK" "$WORK/bad"
  sed -e 's/WebSearch,Write,Edit,MultiEdit/WebSearch,Write,MultiEdit/' "$T/workflows/claude-issue-triage.yml" > "$WORK/bad/.github/workflows/a.yml"
  expect_out "Edit not denied caught" "does not disallow ['Edit']" python3 -I "$CHK" "$WORK/bad"
  sed -e 's/anthropic_federation_rule_id:.*/anthropic_api_key: ${{ secrets.KEY }}/' "$T/workflows/claude-issue-triage.yml" > "$WORK/bad/.github/workflows/a.yml"
  expect_out "static key caught" "static API key" python3 -I "$CHK" "$WORK/bad"
  cp "$T/workflows/claude-issue-triage.yml" "$WORK/bad/.github/workflows/a.yml"
  printf 'mode: audit\nallow:\n  - "*.github.com"\n' > "$WORK/bad/.github/egress-firewall.yaml"
  expect_out "audit mode caught" "mode must be enforce" python3 -I "$CHK" "$WORK/bad"
  expect_out "wildcard host caught" "wildcard host" python3 -I "$CHK" "$WORK/bad"
  rm "$WORK/bad/.github/egress-firewall.yaml"
  expect_out "missing allowlist caught" "is missing" python3 -I "$CHK" "$WORK/bad"
else
  bad "pyyaml not installed (pip install pyyaml)"
fi

echo "init-repo.sh"
I="$PLUGIN/scripts/init-repo.sh"
mkdir -p "$WORK/repo" && git -C "$WORK/repo" init -q
expect_out  "dry run changes nothing"      "Dry run"                    bash "$I" --all --dry-run "$WORK/repo"
[[ -z "$(find "$WORK/repo" -mindepth 1 -maxdepth 1 ! -name .git)" ]] && ok "dry run left repo empty" || bad "dry run wrote files"
expect_ok   "default installs commands"                                  bash "$I" "$WORK/repo"
[[ -f "$WORK/repo/.claude/commands/feature.md" && ! -e "$WORK/repo/scripts" ]] && ok "commands only by default" || bad "default install layout"
expect_ok   "--ci installs CI"                                           bash "$I" --ci "$WORK/repo"
for f in .claude/commands/triage-issue.md scripts/gh-readonly.sh .github/workflows/claude-issue-triage.yml .github/egress-firewall.yaml CLAUDE.md; do
  [[ -e "$WORK/repo/$f" ]] && ok "wrote $f" || bad "missing $f"
done
[[ -x "$WORK/repo/scripts/edit-issue-labels.sh" ]] && ok "scripts executable" || bad "scripts not executable"
expect_out  "second run skips existing"    "skip"                       bash "$I" --all "$WORK/repo"
[[ "$(grep -c 'Workflows that call Claude' "$WORK/repo/CLAUDE.md")" == 1 ]] && ok "CLAUDE.md appended once" || bad "CLAUDE.md appended twice"
if python3 -c 'import yaml' 2>/dev/null; then
  expect_ok "installed repo passes check" python3 -I "$WORK/repo/scripts/check_workflow_hardening.py" "$WORK/repo"
fi
expect_fail "bad option refused"                                         bash "$I" --nope "$WORK/repo"

echo "install.sh"
H="$WORK/home"
expect_ok   "installs skill"                                             env CLAUDE_CONFIG_DIR="$H" bash "$ROOT/install.sh" --commands
[[ -f "$H/skills/shipping-like-claude-code-team/SKILL.md" ]] && ok "skill in place" || bad "skill missing"
[[ -f "$H/commands/review-diff.md" ]] && ok "commands in place" || bad "commands missing"
expect_out  "bundled init-repo works"      "Done:"                      bash "$H/skills/shipping-like-claude-code-team/bin/init-repo.sh" --dry-run --all "$WORK/repo"
expect_ok   "uninstall"                                                  env CLAUDE_CONFIG_DIR="$H" bash "$ROOT/install.sh" --uninstall
[[ ! -e "$H/skills/shipping-like-claude-code-team" && ! -e "$H/commands/review-diff.md" ]] && ok "uninstall removed files" || bad "uninstall left files"

echo "manifests and skill"
for j in "$ROOT/.claude-plugin/marketplace.json" "$PLUGIN/.claude-plugin/plugin.json"; do
  expect_ok "valid JSON: ${j#$ROOT/}" jq -e . "$j"
done
v1=$(jq -r .version "$PLUGIN/.claude-plugin/plugin.json"); v2=$(jq -r '.plugins[0].version' "$ROOT/.claude-plugin/marketplace.json")
[[ "$v1" == "$v2" ]] && ok "versions match ($v1)" || bad "plugin $v1 != marketplace $v2"
head -1 "$SKILL/SKILL.md" | grep -q '^---$' && grep -q '^name: shipping-like-claude-code-team$' "$SKILL/SKILL.md" && grep -q '^description: Use when' "$SKILL/SKILL.md" && ok "skill frontmatter" || bad "skill frontmatter"
desc_len=$(sed -n 's/^description: //p' "$SKILL/SKILL.md" | wc -c | tr -d ' ')
[[ "$desc_len" -le 1024 ]] && ok "description ≤ 1024 chars ($desc_len)" || bad "description too long ($desc_len)"
missing=""
for ref in $(grep -oE '`(references|templates)/[^`]+`' "$SKILL/SKILL.md" | tr -d '`' | sed 's/ .*//' | sort -u); do
  [[ -e "$SKILL/$ref" ]] || missing="$missing $ref"
done
[[ -z "$missing" ]] && ok "SKILL.md links resolve" || bad "broken links:$missing"
for c in "$PLUGIN"/commands/*.md "$T"/commands/*.md; do
  head -1 "$c" | grep -q '^---$' && grep -q '^description:' "$c" || bad "frontmatter: ${c#$ROOT/}"
done
ok "command frontmatter"

echo
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
