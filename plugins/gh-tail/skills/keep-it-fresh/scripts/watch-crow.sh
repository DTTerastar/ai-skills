#!/usr/bin/env bash
# Print one line each time a Crow CI pipeline in a repository finishes or needs approval.
# Usage: watch-crow.sh OWNER/REPO
# Runs until stopped. Pipelines that had already finished at startup are not reported.
# Needs the crow CLI with a server configured (crow server add, or CROW_SERVER and CROW_TOKEN).
set -u
repo=${1:?usage: watch-crow.sh OWNER/REPO}
interval=${CROW_INTERVAL:-30}
# Statuses worth a line: every finished state, plus blocked (waiting for someone to approve).
report='success|failure|killed|error|declined|blocked'
server=${CROW_SERVER:-}
repo_id=$(crow repo show "$repo" -o json 2>/dev/null | jq -r '(if type == "array" then .[0] else . end) | .id // empty' 2>/dev/null)
seen=""
first=1
last_err=""
while true; do
  if json=$(crow pipeline ls "$repo" --limit 50 -o json 2>&1) && jq -e 'type == "array"' <<<"$json" >/dev/null 2>&1; then
    last_err=""
    now=$(jq -r --arg report "$report" '.[] | select(.status | test("^(" + $report + ")$")) | "\(.number) \(.status)"' <<<"$json" | sort)
    if [ "$first" -eq 0 ]; then
      while read -r number status; do
        [ -n "$number" ] || continue
        jq -r --argjson n "$number" --arg repo "$repo" --arg url "${server:+${server%/}/repos/$repo_id/pipeline/$number}" '
          .[] | select(.number == $n)
          | ((.ref // "" | capture("refs/pull/(?<pr>[0-9]+)/") | "PR #\(.pr)") // .branch) as $where
          | ([.title, .message] | map(select(. != null and . != "")) | (.[0] // "") | split("\n")[0] // "" | .[0:80]) as $what
          | "crow  \(.status)  \($repo) pipeline #\(.number)  \(.event)  \($where)  \($what)  \($url)"' <<<"$json"
      done < <(comm -13 <(printf '%s\n' "$seen") <(printf '%s\n' "$now"))
    fi
    seen=$now
    first=0
  else
    # Report an error once, not on every poll.
    err=$(head -n 1 <<<"$json" | cut -c1-200)
    [ "$err" != "$last_err" ] && echo "crow: $err"
    last_err=$err
  fi
  sleep "$interval"
done
