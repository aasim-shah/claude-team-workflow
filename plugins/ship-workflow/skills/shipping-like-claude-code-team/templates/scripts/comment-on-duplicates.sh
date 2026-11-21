#!/usr/bin/env bash
# Post a fixed-template "possible duplicates" comment on the triggering issue.
# 1–3 numeric issue numbers, each must exist. A separate deterministic job closes the issue
# later only if nobody objects (comment or thumbs-down) within the grace period.
set -euo pipefail

REPO="${GH_REPO:-${GITHUB_REPOSITORY:?}}"
GRACE_DAYS="${DUPLICATE_GRACE_DAYS:-3}"
BASE=$(jq -r '.issue.number // .inputs.issue_number // empty' "${GITHUB_EVENT_PATH:?GITHUB_EVENT_PATH not set}")
[[ "$BASE" =~ ^[0-9]+$ ]] || { echo "Error: no issue number in event payload" >&2; exit 1; }

[[ "${1:-}" == "--potential-duplicates" ]] || { echo "Error: usage: --potential-duplicates N [N] [N]" >&2; exit 1; }
shift
dups=("$@")
[[ ${#dups[@]} -ge 1 && ${#dups[@]} -le 3 ]] || { echo "Error: give 1 to 3 issues" >&2; exit 1; }
for d in "${dups[@]}"; do
  [[ "$d" =~ ^[0-9]+$ && "$d" != "$BASE" ]] || { echo "Error: bad issue number: $d" >&2; exit 1; }
  gh issue view "$d" --repo "$REPO" >/dev/null 2>&1 || { echo "Error: #$d does not exist" >&2; exit 1; }
done

body="Found ${#dups[@]} possible duplicate issue(s):"$'\n\n'
i=1; for d in "${dups[@]}"; do body+="$i. https://github.com/$REPO/issues/$d"$'\n'; i=$((i+1)); done
body+=$'\n'"This issue will be closed as a duplicate in $GRACE_DAYS days unless someone objects."$'\n'
body+="- If it is a duplicate, close it and 👍 the original instead."$'\n'
body+="- To keep it open, comment or 👎 this comment."$'\n'

gh issue comment "$BASE" --repo "$REPO" --body "$body"
