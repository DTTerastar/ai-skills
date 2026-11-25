# ai-skills

Public Claude Code skills, packaged as a plugin marketplace.

```
/plugin marketplace add DTTerastar/ai-skills
/plugin install gh-tail@dtterastar-skills
```

## gh-tail

The plugin has one skill, `keep-it-fresh`. Tell the agent "keep it fresh" and it watches the
repositories it has open PRs and issues in, so it stops telling you something is waiting on you
after you merged or closed it. Each event arrives as one notification: PR and issue comments,
reviews, approvals, merges, releases, tags, branches and deployments. It runs
[gh-tail](https://github.com/KimNorgaard/gh-tail) under Claude Code's Monitor tool, one watch per
repository. A small script reports a PR's CI checks as they finish. It also covers which `--kinds` to pick, filtering to your own PRs, and when to tell you
about an event.

It needs gh-tail 0.3.0 or later on each machine:

```sh
gh extension install KimNorgaard/gh-tail
```

## License

MIT
