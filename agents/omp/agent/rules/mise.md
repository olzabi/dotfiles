# Tooling: mise

- This machine uses mise for all language runtimes and dev tools.
- Before running project commands, check `mise.toml` and `mise tasks`.
- Prefer `mise run <task>` (test, lint, build) over raw commands.
- For a one-off command that needs a specific tool version, use `mise x -- <cmd>`.
- If a tool is missing, add it to the project with `mise use <tool>@<version>`
  (updates the project's mise.toml). Never run `mise use -g`, and do not
  install tools with brew, apt, `npm -g`, or `pip install` outside a mise-managed env.
- After editing mise.toml, run `mise install`.
