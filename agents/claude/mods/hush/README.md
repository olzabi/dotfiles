# hush

Compact transcript rows for Claude Code, plus a harness-neutral layer for agent history: a call ledger, token trimming, analysis and digests. Roadmap and measurements: `PLAN.md`.

## In Claude Code (the mod)

`/hush` opens the panel; every feature is a toggle there. On by default:

| Toggle (key) | What it changes for the model |
| --- | --- |
| Trim output (`r`) | Bash stdout past 160 lines / 20k chars → head + tail; the whole is saved first to `~/.cache/hush/<session>/<call>.txt`. Unchanged re-read of a range → one pointer. |
| Call ledger (`l`) | Every call to `~/.local/state/hush/<session>/`, each turn's tokens to its `meta.json`; `mcp__hush__trace`; a recap after compaction, for the main loop and for each subagent that compacts. Each subagent's report is kept whole in `~/.cache/hush/<session>/agent-<id>.md`, and the main loop's recap lists them so it reads one instead of running the agent again. A compaction's summarizer is told the edited files, open failures and kept reports. |
| Loop guard (`u`) | Third identical failure in a row, or third identical Grep/Glob with no edit between → a note. A subagent past 120 calls or 30 min, or a turn past 250 calls → one note to stop and report. An edit to a file another session (or a parallel subagent) edited in the last 15 min → a note to re-read it first (`~/.local/state/hush-editing/`). |
| Route reads (`w`) | Whole-file Read of a code/data file ≥60 kB is refused once with the outline-first way; repeating it passes. |
| Project brief (`b`) | Calls that failed the same way 3+ times in this project in the last 7 days (`hush brief`), in the main loop's prompt and with each subagent's first call. |
| Measure (`h`) | One session in five runs with one of trim, guards, route or brief off, named in `meta.json` as `heldOut`, so `hush effect` has sessions to compare. Off: every session runs everything. |
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
hush lessons --project ~/Projects/x   failures recurring across sessions, as rules; --accept 1,3 adds them to its CLAUDE.md
hush effect [--project DIR]           sessions by feature held out: tokens/call, fail %, repeat-fail %, subagent re-reads
hush context --recent 30              first-call context; enabled plugins, MCP servers, skills by use (0 = cut candidate)
hush corrections --recent 100         your prompts that corrected the agent
hush refusals [--project DIR]         policy/classifier refusals by reason
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
