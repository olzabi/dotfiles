## VCS: jj

This repo uses [jj](https://jj-vcs.github.io) (colocated with git). Use jj for local version control, not git.

- Read-only git (`git log`, `git diff`, `git blame`) is fine. Never run git commands that change state: commit, checkout, switch, rebase, stash, reset, branch.
- A detached git HEAD is normal here. Don't "fix" it.
- Always pass `-m` (`jj describe -m`, `jj commit -m`). Avoid interactive commands (`jj split`, `jj squash -i`, `jj resolve`) because they hang without a TTY.
- Push: `jj bookmark set <name> -r @-`, then `jj git push -b <name>`.
- PRs: `gh pr create --head <name>`. `gh` can't infer the branch from a detached HEAD.
