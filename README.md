# ai-skills

Public Claude Code skills, packaged as a plugin marketplace.

```
/plugin marketplace add DTTerastar/ai-skills
/plugin install gh-tail@dtterastar-skills
```

## gh-tail

Watches a GitHub repository's live activity, one notification per event: PR and issue comments,
reviews, approvals, merges, releases, tags, branches and deployments. It runs
[gh-tail](https://github.com/KimNorgaard/gh-tail) under Claude Code's Monitor tool and re-arms it
when it expires. It also covers which `--kinds` to pick, filtering to one PR, and when to tell you
about an event.

It needs the CLI on each machine:

```sh
gh extension install KimNorgaard/gh-tail
```

Comment, review and deployment events need a gh-tail release that includes
[KimNorgaard/gh-tail#4](https://github.com/KimNorgaard/gh-tail/pull/4) and
[#5](https://github.com/KimNorgaard/gh-tail/pull/5).

## License

MIT
