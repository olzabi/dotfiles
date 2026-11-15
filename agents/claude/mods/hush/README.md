# hush

Compact transcript rows for Claude Code, plus a harness-neutral layer for agent history: a call ledger, token trimming, analysis and digests. Roadmap and measurements: `PLAN.md`.

## In Claude Code (the mod)

`/hush` opens the panel; every feature is a toggle there. On by default:

| Toggle (key) | What it changes for the model |
| --- | --- |
| Trim output (`r`) | Bash stdout past 160 lines / 20k chars → head + tail; the whole is saved first to `~/.cache/hush/<session>/<call>.txt`. Unchanged re-read of a range → one pointer. |
| Call ledger (`l`) | Every call to `~/.local/state/hush/<session>/`; `mcp__hush__trace`; a recap after compaction, for the main loop and for each subagent that compacts. |
| Loop guard (`u`) | Third identical failure in a row, or third identical Grep/Glob with no edit between → a note. |
| Route reads (`w`) | Whole-file Read of a code/data file ≥60 kB is refused once with the outline-first way; repeating it passes. |
| Project brief (`b`) | Calls that failed the same way 3+ times in this project in the last 7 days (`hush brief`), in the main loop's prompt and with each subagent's first call. |
| Turn summary (`y`) | `∑ last turn: …` above the prompt (UI only). |

`/hush stats` shows calls logged and characters kept from the model.

## Everywhere else (`hush` CLI, `~/Dotfiles/bin/hush`)

```
hush replay <session> --agents        a transcript (Claude, pi, OMP) as compact rows
hush stats --recent 20                habits, failures per tool, savings estimate
hush analyze --project ~/Projects/x   + hot files, failing commands, suggestions
hush tree <session> [--full]          span tree from the ledger
hush board --hours 6                  sessions active across projects/worktrees
hush digest --days 7                  weekly note into ~/wiki/raw/hush
hush mcp                              stdio MCP server: trace, tree, board, analyze
hush brief --project ~/Projects/x     calls that keep failing there (what the mod tells agents)
hush gc                               drop trimmed outputs >14d, ledgers >90d (digest runs it)
```

In Claude Code the same commands run as `/hush wiki init`, `/hush board`, `/hush digest`, …

## Other harnesses

pi and OMP write the same ledger through `hush log`: `agents/pi/agent/extensions/hush-ledger.ts` and
`agents/omp/agent/hooks/pre/hush-ledger.ts`. So `trace`, `tree`, `board` and `brief` cover them live.

## Weekly digest timer (not enabled)

```
ln -s ~/Dotfiles/config/hush/hush-digest.{service,timer} ~/.config/systemd/user/
systemctl --user daemon-reload && systemctl --user enable --now hush-digest.timer
```
