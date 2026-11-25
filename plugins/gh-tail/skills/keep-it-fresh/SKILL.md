---
name: keep-it-fresh
description: Keep your picture of the user's work fresh by running commands under the Monitor tool, so you never tell them a PR, issue or build is still waiting on them after it was merged, closed, answered or finished. Use when the user says "keep it fresh", when you have opened PRs or issues in this session and will report on them again, or when the user wants to hear about comments, reviews, merges, CI results or deployments as they happen. Has commands for GitHub (gh-tail), PR checks and Crow CI, and says how to write one for anything else.
---

# Keep it fresh

What you know about a PR, issue or build is only true as of when you last looked. The user merges, closes and comments without telling you. Keep a command running under the Monitor tool for each thing you have told the user is waiting on them, so that what you say matches reality. When a line arrives, update your picture before you next mention that item.

A command suits Monitor when it prints **one line per change** and nothing else:

- At startup it prints at most the last few things that happened, then only what changes. Those few lines are useful: they bring you up to date and cover anything missed since an earlier watch ended. The aim is not a perfect record; it is not telling the user to do something they already did.
- Every stage of a pipe flushes per line (`jq --unbuffered`, `grep --line-buffered`, `sed -u`).
- Errors reach stdout (`2>&1`), so a broken watch is not a silent one.
- It exits when the thing it watches is finished, or runs until you stop it with TaskStop.

## GitHub: PRs, issues, reviews, merges, releases, deployments

One watch per repository. `-n 5` shows the last five events at startup, which may be ones you have already seen.

```sh
gh tail -R owner/repo --kinds 'pr:*,issue:*' -n 5 2>&1 </dev/null
```

In a busy repository, keep only your own numbers:

```sh
gh tail -R owner/repo --kinds 'pr:*,issue:*' -n 5 --json 2> >(sed -u 's/^/ERROR /') </dev/null \
  | jq --unbuffered -r 'select(.number | IN(4, 7)) | "\(.action) @\(.actor // "-") \(.text) \(.url // "")"'
```

`gh tail --help` lists the other kinds and `--filter`. If it is missing, run `gh extension install KimNorgaard/gh-tail`. Comment text is cut at 200 characters, so read the whole comment before acting on it. Events arrive up to a minute late.

## PR checks

One line per finished check, then it exits. Start it again after each push.

```sh
prev=; while :; do s=$(gh pr checks 4 -R owner/repo --json name,bucket)
  cur=$(jq -r '.[] | select(.bucket != "pending" and .bucket != "skipping") | "check \(.bucket) \(.name)"' <<<"$s" | sort)
  comm -13 <(echo "$prev") <(echo "$cur"); prev=$cur
  jq -e 'length > 0 and all(.bucket != "pending")' <<<"$s" >/dev/null && break; sleep 30; done
```

## Crow CI pipelines

One line each time a pipeline finishes or is blocked waiting for approval. PR pipelines also show up as PR checks; this covers pushes and deployments too.

```sh
f='.[] | select(.status | test("^(success|failure|killed|error|declined|blocked)$")) | "crow \(.status) #\(.number) \(.event) \(.ref) \(.message | split("\n")[0])"'
prev=$(crow pipeline ls owner/repo -o json | jq -r "$f" | sort)
while sleep 30; do cur=$(crow pipeline ls owner/repo -o json | jq -r "$f" | sort); [ -n "$cur" ] || continue
  comm -13 <(echo "$prev") <(echo "$cur"); prev=$cur; done
```

## Anything else

The last two are the same pattern, and it works for any tool that can list state: print the state as sorted lines, compare with the previous poll using `comm -13`, and print only the new lines. Tools that already stream (`tail -F`, `journalctl -f`, `kubectl get -w`, `mosquitto_sub`) need only a filter.
