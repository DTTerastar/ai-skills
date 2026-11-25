# ai-skills

Public Claude Code skills, packaged as a plugin marketplace.

```
/plugin marketplace add DTTerastar/ai-skills
/plugin install gh-tail@dtterastar-skills
```

## gh-tail

The plugin has one skill, `keep-it-fresh`. Tell the agent "keep it fresh" and it keeps commands
running under Claude Code's Monitor tool for the things it has told you are waiting on you, so it
stops saying a PR needs you after you merged or closed it. Each change arrives as one line.

The skill has ready commands for three sources, and says how to write one for anything else:

- GitHub activity through [gh-tail](https://github.com/KimNorgaard/gh-tail): PR and issue
  comments, reviews, approvals, merges, releases, tags, branches and deployments.
- A PR's CI checks as they finish.
- Crow CI pipelines as they finish.

It needs gh-tail 0.3.0 or later on each machine:

```sh
gh extension install KimNorgaard/gh-tail
```

## License

MIT
