#!/usr/bin/env bash
# Print one line per CI check on a PR as it finishes (skipped checks are left out),
# then a summary line, and exit when none are pending.
# Usage: watch-checks.sh OWNER/REPO PR_NUMBER
# Each stdout line is one event, so it suits the Monitor tool. Re-run after a new push.
set -u
repo=${1:?usage: watch-checks.sh OWNER/REPO PR_NUMBER}
pr=${2:?usage: watch-checks.sh OWNER/REPO PR_NUMBER}
interval=${CHECKS_INTERVAL:-30}
seen=""
empty=0
while true; do
  # gh exits non-zero while checks are pending or failed, but still prints the JSON.
  json=$(gh pr checks "$pr" -R "$repo" --json name,bucket,link 2>/dev/null)
  if ! jq -e 'type == "array" and length > 0' <<<"$json" >/dev/null 2>&1; then
    # Checks can take a moment to register after a push; give up after 4 empty polls.
    empty=$((empty + 1))
    if [ "$empty" -ge 4 ]; then
      echo "checks #$pr: none reported"
      exit 0
    fi
    sleep "$interval"
    continue
  fi
  empty=0
  done_now=$(jq -r '.[] | select(.bucket != "pending" and .bucket != "skipping") | "\(.bucket)\t\(.name)\t\(if .bucket == "pass" then "" else .link // "" end)"' <<<"$json" | sort -u)
  while IFS= read -r line; do
    [ -n "$line" ] && printf 'check #%s  %s\n' "$pr" "${line//$'\t'/  }"
  done < <(comm -13 <(printf '%s\n' "$seen") <(printf '%s\n' "$done_now"))
  seen=$done_now
  if jq -e 'all(.[]; .bucket != "pending")' <<<"$json" >/dev/null; then
    jq -r '[.[] | .bucket] | group_by(.) | map("\(length) \(.[0])") | join(", ")' <<<"$json" \
      | sed "s/^/checks #$pr done: /"
    exit 0
  fi
  sleep "$interval"
done
