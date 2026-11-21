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
expect_ok   "default installs skills"                                    bash "$I" "$WORK/repo"
[[ -f "$WORK/repo/.claude/skills/feature/SKILL.md" && -f "$WORK/repo/.claude/agents/finding-validator.md" && -f "$WORK/repo/.claude/CONNECTORS.md" && ! -e "$WORK/repo/scripts" ]] && ok "skills + agents only by default" || bad "default install layout"
expect_ok   "--commands alias still works"                               bash "$I" --commands --dry-run "$WORK/repo"
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
mkdir -p "$H/agents" && echo "mine" > "$H/agents/bug-hunter.md"
expect_ok   "installs"                                                   env CLAUDE_CONFIG_DIR="$H" bash "$ROOT/install.sh" --skills
[[ -f "$H/skills/shipping-like-claude-code-team/SKILL.md" ]] && ok "core skill in place" || bad "core skill missing"
grep -q '^name: ship-feature$' "$H/skills/ship-feature/SKILL.md" 2>/dev/null && ok "workflow skill prefixed (ship-feature)" || bad "ship-feature missing or not renamed"
grep -q "$H/ship-workflow/scripts/init-repo.sh" "$H/skills/ship-setup-repo/SKILL.md" && ok "setup-repo points at installed copy" || bad "setup-repo path not rewritten"
[[ -f "$H/agents/finding-validator.md" ]] && ok "agents in place" || bad "agents missing"
[[ "$(cat "$H/agents/bug-hunter.md")" == "mine" ]] && ok "user's own agent not overwritten" || bad "overwrote user's agent"
expect_out  "installed init-repo works"    "Done:"                      bash "$H/ship-workflow/scripts/init-repo.sh" --dry-run --all "$WORK/repo"
expect_ok   "reinstall is idempotent"                                    env CLAUDE_CONFIG_DIR="$H" bash "$ROOT/install.sh" --skills
expect_ok   "uninstall"                                                  env CLAUDE_CONFIG_DIR="$H" bash "$ROOT/install.sh" --uninstall
[[ ! -e "$H/skills/shipping-like-claude-code-team" && ! -e "$H/skills/ship-feature" && ! -e "$H/agents/finding-validator.md" && ! -e "$H/ship-workflow" ]] && ok "uninstall removed our files" || bad "uninstall left files"
[[ -f "$H/agents/bug-hunter.md" ]] && ok "uninstall kept user's agent" || bad "uninstall removed user's agent"

echo "manifests, skills, agents, evals"
for j in "$ROOT/.claude-plugin/marketplace.json" "$PLUGIN/.claude-plugin/plugin.json"; do
  expect_ok "valid JSON: ${j#"$ROOT"/}" jq -e . "$j"
done
v1=$(jq -r .version "$PLUGIN/.claude-plugin/plugin.json"); v2=$(jq -r '.plugins[0].version' "$ROOT/.claude-plugin/marketplace.json"); v3=$(jq -r '.metadata.version' "$ROOT/.claude-plugin/marketplace.json")
[[ "$v1" == "$v2" && "$v1" == "$v3" ]] && ok "versions match ($v1)" || bad "versions differ: plugin $v1, entry $v2, metadata $v3"
grep -q "^## $v1\$" "$ROOT/CHANGELOG.md" && ok "CHANGELOG has $v1" || bad "CHANGELOG lacks ## $v1"
if python3 -c 'import yaml' 2>/dev/null; then
  expect_ok "skill + agent frontmatter" python3 -I - "$PLUGIN" <<'PY'
import pathlib, sys, yaml
root = pathlib.Path(sys.argv[1]); errs = []
def fm(p):
    t = p.read_text(encoding="utf-8")
    assert t.startswith("---\n"), f"{p}: no frontmatter"
    return yaml.safe_load(t.split("\n---\n", 1)[0][4:])
for p in sorted(root.glob("skills/*/SKILL.md")):
    d = fm(p)
    if d.get("name") != p.parent.name: errs.append(f"{p}: name != dir")
    if not d.get("description") or len(d["description"]) > 1024: errs.append(f"{p}: description missing or > 1024")
for p in sorted(root.glob("agents/*.md")):
    d = fm(p)
    if d.get("name") != p.stem: errs.append(f"{p}: name != file")
    if "<example>" not in str(d.get("description", "")): errs.append(f"{p}: no <example> in description")
    if d.get("model") not in {"inherit", "sonnet", "opus", "haiku"}: errs.append(f"{p}: bad model")
    if not d.get("tools"): errs.append(f"{p}: no tools allowlist")
for p in sorted(root.glob("skills/shipping-like-claude-code-team/templates/commands/*.md")):
    if not fm(p).get("description"): errs.append(f"{p}: no description")
if errs: sys.exit("\n".join(errs))
PY
fi
for e in "$PLUGIN"/evals/*/; do
  [[ "$(basename "$e")" == results ]] && continue   # local `claude plugin eval` output, gitignored
  [[ -f "$e/prompt.md" ]] && compgen -G "$e/graders/*.md" >/dev/null && ok "eval $(basename "$e")" || bad "eval $(basename "$e") incomplete"
done
missing=""
for ref in $(grep -ohE '`(references|templates)/[^`]+`' "$SKILL/SKILL.md" | tr -d '`' | sed 's/ .*//' | sort -u); do
  [[ -e "$SKILL/$ref" ]] || missing="$missing $ref"
done
for s in "$PLUGIN"/skills/*/SKILL.md; do
  grep -q 'CONNECTORS.md' "$s" && [[ ! -f "$PLUGIN/CONNECTORS.md" ]] && missing="$missing CONNECTORS.md"
done
[[ -z "$missing" ]] && ok "links resolve" || bad "broken links:$missing"
for s in "$PLUGIN"/skills/*/SKILL.md "$PLUGIN"/agents/*.md; do
  grep -ohE '`(code-explorer|code-architect|bug-hunter|rule-checker|finding-validator|silent-failure-hunter)`' "$s"
done | tr -d '`' | sort -u | while read -r a; do [[ -f "$PLUGIN/agents/$a.md" ]] || echo "missing agent $a"; done > "$WORK/agentrefs"
[[ ! -s "$WORK/agentrefs" ]] && ok "agent references resolve" || bad "$(cat "$WORK/agentrefs")"

echo "safety (what the plugin ships)"
[[ ! -e "$PLUGIN/hooks" && ! -e "$PLUGIN/.claude-plugin/hooks.json" ]] && ok "no hooks" || bad "plugin registers hooks: update README safety section"
[[ ! -e "$PLUGIN/.mcp.json" ]] && ok "no MCP servers" || bad "plugin ships MCP servers: update README safety section"
net=$(grep -rnE '\b(curl|wget|nc|Invoke-WebRequest|urllib|requests\.|fetch\()' "$PLUGIN" --include='*.sh' --include='*.py' --include='*.ts' --include='*.js' || true)
[[ -z "$net" ]] && ok "shipped scripts make no direct network calls (gh only)" || bad "network call in shipped code" "$net"
secrets=$(grep -rnE '(ANTHROPIC_API_KEY|ANTHROPIC_AUTH_TOKEN|security find-|\.aws/credentials|id_rsa)' "$PLUGIN" --include='*.sh' --include='*.py' || true)
[[ -z "$secrets" ]] && ok "shipped scripts read no credentials" || bad "credential access in shipped code" "$secrets"

echo
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
