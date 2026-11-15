// The call ledger on disk, schema v1: one JSONL file per loop of a session, written by any
// harness adapter and read by the CLI, the MCP server and other surfaces (herdr, digests).
//   $XDG_STATE_HOME/hush/<session>/meta.json      { v, session, harness, cwd, startedAt }
//   $XDG_STATE_HOME/hush/<session>/main.jsonl     the main loop's calls
//   $XDG_STATE_HOME/hush/<session>/<agentId>.jsonl one subagent's calls
import type { CallEntry } from '../types'

export const LEDGER_VERSION = 1

export type LedgerEntry = CallEntry & {
  v: number
  session: string
  turn?: string
  // An Agent call: the id of the subagent it started, whose file is <spawned>.jsonl.
  spawned?: string
}

export type LedgerMeta = { v: number; session: string; harness: string; cwd: string; startedAt: number }

export const ledgerRoot = (home: string, xdgState?: string) => `${xdgState || `${home}/.local/state`}/hush`
export const loopFile = (agentId?: string) => `${agentId ? agentId.replace(/[^\w.-]/g, '_') : 'main'}.jsonl`

export function parseLedger(text: string): LedgerEntry[] {
  const out: LedgerEntry[] = []
  for (const line of text.split('\n')) {
    if (!line.trim()) continue
    try {
      const e = JSON.parse(line) as LedgerEntry
      // Other writers may leave fields out: readers rely on these.
      if (e && typeof e.id === 'string' && typeof e.tool === 'string') out.push({ ...e, label: e.label ?? e.tool, what: e.what ?? '', files: Array.isArray(e.files) ? e.files : [], ms: e.ms ?? 0, at: e.at ?? 0, ok: e.ok !== false })
    } catch {
      // a line cut by a crash mid-write: the rest still reads
    }
  }
  return out
}

// The state copy for the UI: the main loop's last `main`, each subagent's last `each`,
// so a swarm of workers never evicts the main loop's history.
export function capByLoop<T extends { agentId?: string }>(all: readonly T[], main = 300, each = 40, agents = 20): T[] {
  const seen = new Map<string, number>()
  const keep: boolean[] = new Array(all.length).fill(false)
  for (let i = all.length - 1; i >= 0; i--) {
    const k = all[i]?.agentId ?? ''
    // Only the most recent `agents` subagents stay: a swarm's older workers live on in the files.
    if (k && !seen.has(k) && seen.size - (seen.has('') ? 1 : 0) >= agents) continue
    const n = (seen.get(k) ?? 0) + 1
    seen.set(k, n)
    keep[i] = n <= (k ? each : main)
  }
  return all.filter((_, i) => keep[i])
}
