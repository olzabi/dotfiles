## Tooling: mise

This project uses [mise](https://mise.jdx.dev) to manage tool versions, environment variables, and tasks.

- Tool versions and tasks are defined in `mise.toml` (the source of truth). Read it before assuming which versions or commands are available.
- Run `mise install` to install the tools the project needs.
- Add or change a tool with `mise use <tool>@<version>` (e.g. `mise use node@22`) instead of editing versions by hand or using other version managers.
- Do not use nvm, pyenv, asdf, rbenv, sdkman, or similar tools, and don't install project tools globally with brew/apt/npm -g.
- Never run `mise use -g`; keep tool changes in the project's `mise.toml`.
- Run project tasks with `mise run <task>` (see `mise tasks` for the list). Prefer these over ad-hoc commands when a task exists.
- If a tool isn't found on PATH, run it via `mise exec -- <command>` or check that `mise install` has been run.
- Environment variables for the project belong in the `[env]` section of `mise.toml` (secrets go in `.env` or `mise.local.toml`, never committed).
- Commit `mise.toml` (and `mise.lock` if used) whenever tool versions change.
