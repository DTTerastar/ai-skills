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

It needs the CLI on each machine. Until upstream releases
[KimNorgaard/gh-tail#4](https://github.com/KimNorgaard/gh-tail/pull/4) (deployments) and
[#5](https://github.com/KimNorgaard/gh-tail/pull/5) (comments and reviews), install the preview
build from this repo's [`gh-tail-preview` release](https://github.com/DTTerastar/ai-skills/releases/tag/gh-tail-preview):

```sh
os=$(uname -s | tr A-Z a-z); arch=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
mkdir -p ~/.local/bin
gh release download gh-tail-preview -R DTTerastar/ai-skills -p "gh-tail-$os-$arch" -O ~/.local/bin/gh-tail --clobber
chmod +x ~/.local/bin/gh-tail
```

The skill does this on its own when `gh-tail` is missing or too old. Once upstream ships, use
`gh extension install KimNorgaard/gh-tail` instead.

## License

MIT
