---
name: keep-it-fresh
description: Keep your picture of GitHub fresh while you work, so you never tell the user a PR or issue is still waiting on them after they merged, closed or answered it. Use when the user says "keep it fresh", when you have opened PRs or issues in this session and will report on them again, or when the user wants to be told about comments, reviews, merges, releases or deployments as they happen. Watches live repository activity as one-line events, using the gh-tail CLI and the Monitor tool. Not for CI check results; use `gh pr checks --watch` for those.
---

# Keep it fresh

What you know about a PR or issue is only true as of when you last looked. The user merges, closes and comments without telling you, and a status you repeat from memory may be hours out of date. Keeping it fresh means watching the repositories you have open work in, so each change reaches you as it happens and what you tell the user matches GitHub.

**What to watch:** every PR and issue you opened in this session or have told the user is waiting on them, plus anything they ask you to follow. Run one watch per repository, because gh-tail follows one repository at a time. When work starts in another repository, start a watch there too.

**When an event arrives:** update your picture before you next mention that item. A merged or closed PR is no longer something the user needs to do.

The tool is [gh-tail](https://github.com/KimNorgaard/gh-tail), a gh extension run as `gh tail`. It polls a repository and prints one line per event. Run it under the **Monitor** tool so that each line arrives as a notification while you keep working. It uses `gh`'s auth and ETag caching, so an idle repo costs nothing against the rate limit.

## Setup (once per machine)

```sh
gh tail --version   # want 0.3.0 or later
```

If it's missing, run `gh extension install KimNorgaard/gh-tail`. If it's older than 0.3.0 (no comment, review or deployment events), run `gh extension upgrade tail`. A standalone `gh-tail` left in `~/.local/bin` by the old `0.2.1-dt.*` preview builds is stale: delete it, so nothing runs it by mistake.

## Start a watch

Always pipe it (Monitor does). With no TTY, the spinner and status line are off and the output is plain rows. Always pass `-n 0`, so a restart doesn't replay old events as if they were new. Use `</dev/null` and `2>&1`, so errors show up as `gh-tail: …` lines instead of being lost.

```
Monitor(
  description: "gh-tail on owner/repo",
  timeout_ms: 1800000,
  command: "gh tail -R owner/repo --kinds 'pr:*,issue:*' -n 0 2>&1 </dev/null",
)
```

**Watch only your PRs or issues:** use JSON and filter on the numbers. It is the only reliable match, because comment text can mention other numbers.

```sh
gh tail -R owner/repo --kinds 'pr:*' -n 0 --json 2> >(sed -u 's/^/ERROR /') </dev/null \
  | jq --unbuffered -r 'select(.number | IN(4, 7)) | "\(.action) @\(.actor // "-") \(.text) \(.url // "")"'
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

## While it runs

- If `gh-tail: …` error lines repeat, such as auth, 404 or rate limit, tell the user instead of restarting in a loop.
- Stop a watch with TaskStop when nothing you are tracking in that repository is still open, or when the user says so.
- Act on events the user would care about: a review requesting changes, a question to them, a merge. Push a notification for those. Don't narrate routine ones.

## Limits

- Polls every 60s at most (or GitHub's `X-Poll-Interval`), so events arrive up to a minute or so late. Reopened, labeled and assigned events come from the Events API and can lag from minutes to hours.
- Dismissed and pending reviews aren't reported. Edits to existing comments aren't reported.
- A busy repo can drop events beyond the latest 100 comments or updated issues between two polls.
- No CI or check-run events.
- No resume: events that happen while no watch is running are not replayed by a later one started with `-n 0`.
