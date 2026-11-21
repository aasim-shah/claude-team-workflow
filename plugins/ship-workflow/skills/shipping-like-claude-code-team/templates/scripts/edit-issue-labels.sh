#!/usr/bin/env bash
# Add or remove labels on the issue that triggered the workflow. The issue number comes from the
# event payload, never from arguments, so an injected prompt cannot target another issue.
# Labels that do not exist in the repo are dropped.
set -euo pipefail

ISSUE=$(jq -r '.issue.number // .inputs.issue_number // empty' "${GITHUB_EVENT_PATH:?GITHUB_EVENT_PATH not set}")
[[ "$ISSUE" =~ ^[0-9]+$ ]] || { echo "Error: no issue number in event payload" >&2; exit 1; }

add=(); remove=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --add-label)    add+=("${2:?}");    shift 2 ;;
    --remove-label) remove+=("${2:?}"); shift 2 ;;
    *) echo "Error: only --add-label and --remove-label are accepted" >&2; exit 1 ;;
  esac
done
[[ ${#add[@]} -gt 0 || ${#remove[@]} -gt 0 ]] || { echo "Error: nothing to do" >&2; exit 1; }

valid=$(gh label list --limit 500 --json name --jq '.[].name')
args=(issue edit "$ISSUE")
for l in ${add[@]+"${add[@]}"};       do grep -qxF -- "$l" <<<"$valid" && args+=(--add-label "$l"); done
for l in ${remove[@]+"${remove[@]}"}; do grep -qxF -- "$l" <<<"$valid" && args+=(--remove-label "$l"); done

[[ ${#args[@]} -gt 3 ]] || { echo "No valid labels given; nothing changed"; exit 0; }
gh "${args[@]}"
