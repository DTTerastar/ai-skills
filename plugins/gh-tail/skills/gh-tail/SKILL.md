---
name: gh-tail
description: Watch live GitHub repository activity (PR and issue comments, reviews, approvals, merges, opened and closed PRs and issues, releases, tags, branches, deployments) as a stream of one-line events, using the gh-tail CLI and the Monitor tool. Use when the user wants to be told when someone comments on, reviews or merges a PR, wants to keep an eye on a repo, or asks Claude to watch, follow or stay up to date on GitHub activity. Not for CI check results; use `gh pr checks --watch` for those.
---

# Watching GitHub with gh-tail

`gh-tail` (in `~/.local/bin`, on PATH) polls a repository and prints one line per event. Run it under the **Monitor** tool so that each line arrives as a notification while you keep working. It uses `gh`'s auth and ETag caching, so an idle repo costs nothing against the rate limit.

## Setup (once per machine)

Until KimNorgaard/gh-tail#4 (deployments) and #5 (comments and reviews) are released upstream, use the preview build in this repo's `gh-tail-preview` release. Check it first:

```sh
gh-tail --version   # want 0.2.1-dt.2+pr4.pr5.* or later (older dt builds repeat deployment statuses: reinstall)
```

If it's missing or older, install the preview into `~/.local/bin`, which is on PATH for login shells and Paseo:

```sh
os=$(uname -s | tr A-Z a-z); arch=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
mkdir -p ~/.local/bin
gh release download gh-tail-preview -R DTTerastar/ai-skills -p "gh-tail-$os-$arch" -O ~/.local/bin/gh-tail --clobber
chmod +x ~/.local/bin/gh-tail
```

Builds exist for linux and darwin, amd64 and arm64. If `gh release download` reports that the release is gone, upstream has shipped both PRs: use `gh extension install KimNorgaard/gh-tail` and run it as `gh tail` (same flags). If `--kinds pr:commented` fails with `unknown action`, the installed build is too old. Reinstall as above instead of polling by hand.

## Start a watch

Always pipe it (Monitor does). With no TTY, the spinner and status line are off and the output is plain rows. Always pass `-n 0`, so a restart doesn't replay old events as if they were new. Use `</dev/null` and `2>&1`, so errors show up as `gh-tail: …` lines instead of being lost.

```
Monitor(
  description: "gh-tail on owner/repo",
  timeout_ms: 1800000,
  command: "gh-tail -R owner/repo --kinds 'pr:*,issue:*' -n 0 2>&1 </dev/null",
)
```

**Watch one PR or issue:** use JSON and filter on the number. It is the only reliable match, because comment text can mention other numbers.

```sh
gh-tail -R owner/repo --kinds 'pr:*' -n 0 --json 2> >(sed -u 's/^/ERROR /') </dev/null \
  | jq --unbuffered -r 'select(.number == 4) | "\(.action) @\(.actor // "-") \(.text) \(.url // "")"'
```

`jq --unbuffered` is required, or lines sit in the buffer and never arrive.

## Kinds

`--kinds` decides which APIs are polled, so select only what's needed. `kind` gets its default actions, `kind:action` one action, `kind:*` all of them.

| Want | `--kinds` |
|------|-----------|
| Everything on PRs and issues | `'pr:*,issue:*'` |
| PR discussion only | `pr:commented,pr:approved,pr:changes_requested,pr:reviewed` |
| Lifecycle only (default) | `pr,issue` (opened, closed, merged) |
| Releases and tags | `release,tag` |
| Deployments / failures | `deployment` / `deployment:failure` |

`commented` covers conversation comments and inline code comments. An inline comment's text starts with `#N path:line:`. `reviewed` is a review submitted as a comment, neither approval nor change request.

`--filter` hides events after they are fetched: `-actor:*[bot]` drops bots, `-actor:@me` drops the user's own actions (including ones Claude took on their account), `label:bug`, `actor:kim`. Comment events have no `author`, so don't filter them with `author:`.

## Reading events

Plain row: `TIME  KIND  ACTION  ACTOR  TEXT`, for example

```
2026-11-24 17:10:31  pr  approved   babakks  #15100 Revoke CLI OAuth tokens on logout: Looks good to me now.
2026-11-24 17:04:07  pr  commented  Copilot  #15149 docs/SKILL.md:49: Requirement: classify …
```

Comment and review bodies are cut at 200 characters. When a comment needs action, read it in full: `gh pr view N -R owner/repo --comments`, `gh api repos/owner/repo/pulls/N/comments` for inline comments, or the event's URL with `--json`.

## Keeping it running

- A Monitor lasts at most 30 minutes. When the expiry notice arrives, start the same command again (still with `-n 0`). Keep doing this as long as the user wants the watch.
- If `gh-tail: …` error lines repeat, such as auth, 404 or rate limit, tell the user instead of restarting in a loop.
- Stop with TaskStop when the PR is merged or closed, or when the user says so.
- Act on events the user would care about: a review requesting changes, a question to them, a merge. Push a notification for those. Don't narrate routine ones.

## Limits

- Polls every 60s at most (or GitHub's `X-Poll-Interval`), so events arrive up to a minute or so late. Reopened, labeled and assigned events come from the Events API and can lag from minutes to hours.
- Dismissed and pending reviews aren't reported. Edits to existing comments aren't reported.
- A busy repo can drop events beyond the latest 100 comments or updated issues between two polls.
- No CI or check-run events.
