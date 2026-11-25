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

The skill uses [gh-tail](https://github.com/KimNorgaard/gh-tail) for GitHub: PR and issue comments,
reviews, approvals, merges, releases, deployments, and CI checks as they finish, including external
CI such as Crow CI that reports to GitHub. It also says how to write a watch for any other tool.

It needs a gh-tail release newer than 0.3.0 on each machine, for the `check` kind:

```sh
gh extension install KimNorgaard/gh-tail
```

## License

MIT
