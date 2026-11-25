---
name: keep-it-fresh
description: Keep your picture of GitHub fresh, so you never tell the user a PR or issue is still waiting on them after they merged, closed or answered it. Use when the user says "keep it fresh", when you have opened PRs or issues in this session and will report on them again, or when the user wants to hear about comments, reviews, merges, releases or deployments as they happen. Also reports CI checks as they finish. Uses the gh-tail CLI and a checks script under the Monitor tool.
---

# Keep it fresh

What you know about a PR or issue is only true as of when you last looked. The user merges, closes and comments without telling you. Watch every repository where you opened a PR or issue this session, or told the user something is waiting on them, so that what you say matches GitHub.

Run one watch per repository under the Monitor tool:

```
Monitor(description: "gh-tail on owner/repo", timeout_ms: 1800000,
  command: "gh tail -R owner/repo --kinds 'pr:*,issue:*' -n 0 2>&1 </dev/null")
```

In a busy repository, keep only your own numbers:

```sh
gh tail -R owner/repo --kinds 'pr:*,issue:*' -n 0 --json 2> >(sed -u 's/^/ERROR /') </dev/null \
  | jq --unbuffered -r 'select(.number | IN(4, 7)) | "\(.action) @\(.actor // "-") \(.text) \(.url // "")"'
```

gh-tail has no CI events. After each push to a PR, watch its checks with the script in this skill's directory. It prints one line per finished check, then a summary, and exits:

```
Monitor(description: "checks on owner/repo#4", timeout_ms: 1800000,
  command: "<this skill's directory>/scripts/watch-checks.sh owner/repo 4")
```

- `-n 0` stops a new watch from replaying old events as new. Without `jq --unbuffered`, nothing arrives.
- `gh tail --help` lists the other kinds (release, tag, branch, deployment) and `--filter`, such as `-actor:*[bot]`.
- If `gh tail` is missing, run `gh extension install KimNorgaard/gh-tail`. It needs 0.3.0 or later.

When an event arrives, update your picture before you next mention that item: a merged or closed PR is no longer something the user needs to do. Comment text is cut at 200 characters, so read the whole comment (`gh pr view N --comments`) before acting on it. Tell the user about events they would act on and don't narrate the rest. If `gh-tail: …` errors repeat, tell the user. Stop a watch with TaskStop when nothing you track in that repository is still open.

Limits: events arrive up to a minute late, and events that happen while no watch is running are not replayed.
