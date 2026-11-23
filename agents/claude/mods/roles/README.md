# roles

Picks each subagent's model by its type, like OMP's `modelRoles`. The table is `roles.json` beside this file:

```json
{ "Explore": "haiku", "general-purpose": "sonnet", "Plan": "opus", "*": "sonnet" }
```

- Keys are subagent types as the Agent tool names them (`Explore`, `plugin-dev:plugin-validator`); `*` is the fallback; keys starting with `_` are notes.
- An Agent call that names a `model` keeps it. Forks, resumed runs, workflow agents and teammates are left alone.
- Unlisted types fall through to the agent's own `model:` and then `CLAUDE_CODE_SUBAGENT_MODEL`.
- The file is read on every spawn, so edits apply at once. A missing or broken file changes nothing.

The main session's model stays `/model` (the orchestrator).
