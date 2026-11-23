# hush roadmap

One pure core, adapters around it:

- `core/` (no engine, no Node imports): `format.ts` rows, `agent.ts` trim/guards/routing/recap, `ledger.ts` schema v1, `readers.ts` Claude + pi/OMP transcripts, `report.ts` habits/project/savings/tree/digest.
- Claude adapter: `hooks/` (the mod: UI, ledger writer, `mcp__hush__trace`).
- Everyone else: `bin/hush.ts` (`~/Dotfiles/bin/hush`) CLI and `hush mcp` stdio server, registered for OMP (`agents/omp/agent/mcp.json`) and pi (`agents/pi/agent/mcp-adapter.json`).
- Data, not engine state: `~/.local/state/hush/<session>/{meta.json,main.jsonl,<agentId>.jsonl}`; any surface reads the files.

## Done 2026-11-10

- P0 ledger on disk per loop (append via rewrite, read once after a reload), Agent calls carry `spawned` → subagent file; `$.state` copy capped per loop (main 300, each subagent 40).
- P1 core extracted; readers for Claude, pi and OMP; CLI `replay | stats | analyze | trace | tree | board | digest | wiki init | mcp`; MCP tools `trace`, `tree`, `board`, `analyze`.
- P2 herdr `side/60-hush` (board rows, click = tree, o = replay); digests go to the local wiki `~/wiki/raw/hush/<week>.md` (+ `log.md`), schema in `~/wiki/AGENTS.md` (llm-wiki layout). Weekly timer units in `editor/hush/` (not enabled: see README).
- P3 habits (prompts, corrections, interruptions, denials, description coverage, time to first edit) and project (edited, read, docs, failing, skills, subagents) with suggestions; report rows redact secrets.
- P4 routing: a whole-file Read of a big code/data file (≥60 kB) is refused once with the outline-first way (Route reads, `w`); the third identical Grep/Glob in a loop gets a note.
- P5 span tree (`hush tree`, subagents folded under their Agent call, `--full` expands), cross-session board (`hush board`).

- Follow-up: the failures band left hush (footer shows failures); `/hush <cli command>` runs the CLI; `hush gc` retention.
- Review round 1 (all 10 + small points fixed): loop guard reads the real error line and keys on the call's exact arguments (`sig`); short outputs never lose repeated lines; subagent turns no longer restamp the main loop; reads/searches reset on every compaction per loop; ledger counts UTF-8 bytes, skips an unreadable part, drops a refused line; TOON skips >2^53 integers; disjoint shell-word regex (no ReDoS); `/hush trace|tree` scoped to this session; MCP ignores junk lines; gc by newest file; notes verified to reach the model live.

- Review round 2 (all 10 fixed): /clear resets reads, routing, nudges, ledger handles and state (session.end) and writes meta lazily; subagent tasks and compaction summaries no longer count as prompts; nested subagents nest in `tree` and `replay`; TOON skips long decimals; `\r` kept unless the whole is saved; MCP rows fall back to their first argument; turn/compaction state in `$.state` (survives reloads), at most 20 subagents in the state copy; bounded-command words need a boundary, `cat`/`git diff|show` trim only past 600 lines; herdr passes ids as arguments; CLI stats survive vanished files; ledger lines get defaults.

- Review round 3 (2026-11-12): trim cuts long lines by characters past 100 lines too; a limiter bounds its own pipeline only (`jq`, `cut` are none); open failures close on a later success of the same row and never hold refusals; a search after an edit is not a repeat; `--project` picks files before the newest-N cut and matches whole directories; the CLI survives vanished transcripts; gc leaves unreadable folders; the savings estimate runs the mod's own trim; meta is written with the first call only.
- Seamless (2026-11-12): `hush brief` (recurring failures of a project) reaches the main loop's prompt and each subagent's first call; subagents get their own recap after a compaction; pi and OMP write the ledger live (`hush log`); the digest unit carries a PATH with node.

- Measure and learn (2026-11-16): a per-session holdout (`h`, 1 in 5) and per-session tokens in `meta.json`, compared by `hush effect`; `hush lessons` turns failures recurring across sessions into rules (a refusal gets "ask the user", a fix only when seen twice on the same file), `--accept` appends them to the project's CLAUDE.md and the brief stops repeating them; the digest lists them; subagent reports kept on disk and pointed at in the main recap; auto-mode classifier denials count as refusals.

- Context and coordination (2026-11-16): `hush context` (first-call context: median 33k tokens over 71 sessions; telegram, hookify, plugin-dev, frontend-design and the headroom, memory, sequential-thinking servers showed 0 uses in the last 30), `hush corrections`, `hush refusals`; compaction instructions carry the ledger's facts; runaway note; cross-session edit-clash note.

- Readable unfold (2026-11-16): an unfolded call shows its input whole (the command, the agent's task, other inputs as key: value) above its output, behind a dim `│` gutter, wrapped and in normal colour; Bash stderr red, a Read as highlighted `Code`, Agent and web results as `Markdown`, other JSON as TOON.

## Measured 2026-11-10

- 120 transcripts: trim would cut 8.3% of tool-result text; ~1.5% of cache-read tokens over later calls. Average context per call ~171k tokens: fewer calls and a smaller base context matter more. Re-run: `hush stats --recent N`.

## Next

- Read `hush effect` once ~10 sessions per holdout exist (about 50 sessions with Measure on); drop or retune what shows no gain.

- footer: its Trace pane reads the ledger instead of its own `trail` (footer is being changed in another session; not touched here).
- pi/OMP ledger writers were tested against a fake host only: check one real session of each with `hush board`.
- Enable the weekly timer (README); nothing runs the digest until then.
- Export the ledger to codebase-memory `ingest_traces`.
- Small-model summary of big cut outputs (`model.classify` / Haiku) — skipped: latency on every big output for ~1% tokens.
- Tune `TRIM`, `BIG_READ` and the bounded-command list from `hush stats` over the next weeks.
