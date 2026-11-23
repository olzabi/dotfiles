---
name: hc
description: "Run, watch and coordinate programs and sub-agents in persistent herdr-core terminals with `hc` (run, read, send, wait, keys, exec --on). Use when orchestrating parallel agents, starting long-running commands (servers, builds, tests) the user should be able to watch, or reading/messaging another terminal. Not for changing the Herdr window (that is herdr-app)."
---

# hc: herdr-core

Read the current manual first, it matches the installed version:

```sh
hc --skill
```

House rules for this machine:
- A repo's own pipeline wins: if its AGENTS.md/CLAUDE.md defines how workers start (plan loop, `plan:start`, `claude --bg`), use that; hc is then only for watching (`hc ls`, `hc read`) and long-running commands.
- Otherwise, one worker per git worktree: `hc run --name <task> --cwd <worktree> -- claude "<task>"`, then `hc wait <name>`.
- Workers you start report back when they exit (`<hc>… exited</hc>`). Pass `--no-notify` for helpers whose exit you don't care about.
- Never `hc send` into the user's own terminal, or an agent you didn't start, unless asked.
- Review handoff: the user leaves notes in hunk; read them with the hunk-review skill (`hunk session comment list --repo .`).
