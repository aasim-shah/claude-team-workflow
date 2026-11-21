#!/usr/bin/env bash
# Read-only gh wrapper for agents. Allows: issue view, issue list, search issues, label list.
# Every call is scoped to GH_REPO (or GITHUB_REPOSITORY). Search queries may not widen scope.
set -euo pipefail

REPO="${GH_REPO:-${GITHUB_REPOSITORY:-}}"
[[ "$REPO" =~ ^[^/]+/[^/]+$ ]] || { echo "Error: set GH_REPO=owner/repo" >&2; exit 1; }
export GH_REPO="$REPO" GH_HOST=github.com

cmd="${1:-} ${2:-}"
case "$cmd" in
  "issue view"|"issue list"|"search issues"|"label list") shift 2 ;;
  *) echo "Error: allowed: issue view | issue list | search issues | label list" >&2; exit 1 ;;
esac

allowed_flag() { case "$1" in --comments|--state|--limit|--label) return 0 ;; *) return 1 ;; esac; }
takes_value()  { case "$1" in --state|--limit|--label) return 0 ;; *) return 1 ;; esac; }

pos=(); flags=(); expect_value=false
for arg in "$@"; do
  if $expect_value; then flags+=("$arg"); expect_value=false; continue; fi
  if [[ "$arg" == -* ]]; then
    name="${arg%%=*}"
    allowed_flag "$name" || { echo "Error: flag $name not allowed" >&2; exit 1; }
    flags+=("$arg")
    [[ "$arg" != *=* ]] && takes_value "$name" && expect_value=true
  else
    pos+=("$arg")
  fi
done

case "$cmd" in
  "search issues")
    q="${pos[0]:-}"
    shopt -s nocasematch
    [[ "$q" =~ (repo:|org:|user:) ]] && { echo "Error: query may not contain repo:/org:/user:" >&2; exit 1; }
    gh search issues "$q" --repo "$REPO" ${flags[@]+"${flags[@]}"} ;;
  "issue view")
    [[ ${#pos[@]} -eq 1 && "${pos[0]}" =~ ^[0-9]+$ ]] || { echo "Error: issue view needs one numeric id" >&2; exit 1; }
    gh issue view "${pos[0]}" ${flags[@]+"${flags[@]}"} ;;
  *)
    [[ ${#pos[@]} -eq 0 ]] || { echo "Error: no positional args allowed" >&2; exit 1; }
    gh ${cmd} ${flags[@]+"${flags[@]}"} ;;
esac
