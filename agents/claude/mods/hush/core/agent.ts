// Agent-facing logic, pure: output trimming, the call ledger, its queries and recaps.
// No engine imports, so `bin/` and tests use it as it is.

import type { CallEntry, TurnStats } from '../types'
import { stripLead } from './format.ts'
export type { CallEntry, TurnStats }

const ANSI = /\x1b\[[0-9;?]*[ -/]*[@-~]|\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)|\x1b[@-_]/g;
const base = (p: string) => p.split('/').pop() ?? p;

// The identity of a call for guards and open failures: loop + tool + its exact input
// (`sig`, a hash of the arguments), so two Edits of different index.ts files never merge.
export const callKey = (e: Pick<CallEntry, 'agentId' | 'tool' | 'label' | 'what' | 'sig'>) =>
  `${e.agentId ?? ''}|${e.tool}|${e.sig ?? `${e.label}|${e.what}`}`;

// The model asked for this much on purpose: trimming it would undo the ask.
// A limiter as a command word (start, or after | ; & ( ), or grep's own -m N; not a word inside quotes.
const BOUNDED = /(?:^|[|;&(]\s*)(?:(?:head|tail|wc|less|more)\b|sed\s+-n|awk\s+[^|]*\bNR\b)|\bgrep\b[^|]*\s-m\s*\d+/;
// Reading a file or a diff on purpose: cut only far later (TRIM_READ), the model asked for that text.
const READ_LIKE = /(?:^|[|;&(]\s*)(?:cat|bat|less|git\s+(?:show|diff)|diff)\b/;
export const isReadLike = (command: string) => READ_LIKE.test(command);
// One pipeline only: in `a; b | head` the limiter bounds b, not a (quoted text hides its separators).
// A command taken for unbounded is only trimmed with its whole saved, so the doubt goes that way.
export const isBounded = (command: string) => {
  const c = stripLead(command);
  return !/&&|\|\||;|\n/.test(c.replace(/'[^']*'|"[^"]*"/g, 'Q')) && BOUNDED.test(c);
};

// Lossless-ish tidy: colour codes and `\r` redraws dropped, a run of 4+ identical lines
// kept once with a count.
// Colour codes and `\r` redraws dropped: what a terminal would have shown. Safe on any output.
// Colour codes only: `\r` can be a record separator, so redraws collapse only in tidyOutput (whole saved).
export function cleanOutput(text: string): string {
  return text.replace(ANSI, '');
}

// Lossy tidy, only for output whose whole is saved: a run of 4+ identical lines kept once with a count.
export function tidyOutput(text: string): string {
  const lines = cleanOutput(text).split('\n').map(l => l.split('\r').filter(Boolean).pop() ?? '');
  const out: string[] = [];
  for (let i = 0; i < lines.length; ) {
    let j = i + 1;
    while (j < lines.length && lines[j] === lines[i]) j++;
    const run = j - i;
    if (run >= 4) out.push(lines[i] as string, `[hush: line above repeated ${run - 1} more times]`);
    else out.push(...lines.slice(i, j));
    i = j;
  }
  return out.join('\n');
}

export const TRIM = { lines: 160, chars: 20000, keep: 50 };

// Head and tail of a long output with a marker naming what was cut and where the whole is;
// null when it is short enough to pass whole.
export const TRIM_READ = { lines: 600, chars: 60000 };

export function trimOutput(text: string, savedAt: string, limit: { lines: number; chars: number } = TRIM): string | null {
  const lines = text.split('\n');
  if (lines.length <= limit.lines && text.length <= limit.chars) return null;
  // Very long lines (minified, base64) count by characters: keep the ends of the text.
  const kept = [...lines.slice(0, TRIM.keep), ...lines.slice(-TRIM.keep)].reduce((a, l) => a + l.length + 1, 0);
  if (lines.length <= TRIM.keep * 2 || kept > TRIM.chars) {
    const half = Math.floor(TRIM.chars / 4);
    return `${text.slice(0, half)}\n[hush: ${text.length - half * 2} characters cut; whole output: ${savedAt}]\n${text.slice(-half)}`;
  }
  const cut = lines.length - TRIM.keep * 2;
  return [
    ...lines.slice(0, TRIM.keep),
    `[hush: ${cut} lines cut; whole output: ${savedAt}]`,
    ...lines.slice(-TRIM.keep),
  ].join('\n');
}

// A cheap content fingerprint for "unchanged since the last read".
export function hash(text: string): string {
  let h = 5381;
  for (let i = 0; i < text.length; i++) h = ((h << 5) + h + text.charCodeAt(i)) | 0;
  return `${text.length}:${(h >>> 0).toString(36)}`;
}

const ago = (now: number, at: number) => {
  const s = Math.max(0, Math.round((now - at) / 1000));
  return s < 60 ? `${s}s` : s < 3600 ? `${Math.round(s / 60)}m` : `${Math.round(s / 3600)}h`;
};

const kb = (n: number) => (n < 1024 ? `${n}B` : `${(n / 1024).toFixed(1)}kB`);

export type TraceQuery = { failed?: boolean; file?: string; tool?: string; agent?: string; last?: number };

// The ledger as rows the model reads: a summary line, then one row per matching call.
export function queryTrace(all: readonly CallEntry[], q: TraceQuery, now: number): string {
  const tool = q.tool?.toUpperCase();
  const hits = all.filter(
    (e) =>
      (!q.failed || !e.ok) &&
      (!q.file || e.files.some((f) => f.includes(q.file as string)) || e.what.includes(q.file)) &&
      (!tool || e.label === tool || e.tool.toUpperCase() === tool) &&
      (!q.agent || (q.agent === 'main' ? !e.agentId : e.agentId === q.agent)),
  );
  const shown = hits.slice(-(q.last && q.last > 0 ? q.last : 40));
  const failed = hits.filter((e) => !e.ok).length;
  const head = `${hits.length} of ${all.length} calls match; ${failed} failed; showing the last ${shown.length}.`;
  const rows = shown.map((e) => {
    const who = e.agentId ? ` [${e.agentId.slice(0, 8)}]` : '';
    const tail = e.ok ? '' : `\n    ✗ ${e.err ?? 'failed'}`;
    return `${ago(now, e.at).padStart(4)} ${e.ok ? '✓' : '✗'} ${e.label} ${e.what} (${e.ms}ms, ${kb(e.bytes)})${who}${tail}`;
  });
  return [head, ...rows].join('\n');
}

const EDITS = new Set(['Edit', 'Write', 'NotebookEdit', 'MultiEdit']);

// A refusal (permission, policy, the user's no): nothing to retry, so never an open failure.
export const DENIED = /doesn't want to proceed|was rejected|Permission to use .* (was )?denied|user denied|isolated in the worktree|^(?:<tool_use_error>)?Blocked:/i;
export const isDenial = (e: Pick<CallEntry, 'denied' | 'err'>) => !!e.denied || DENIED.test(e.err ?? '');

// Calls that failed and were not followed by a success of the same row (loop, tool, label, file):
// still open. Looser than callKey: the retry that works rarely has the failed call's exact arguments.
export function openFailures(all: readonly CallEntry[]): CallEntry[] {
  const open = new Map<string, CallEntry>();
  for (const e of all) {
    const k = `${e.agentId ?? ''}|${e.tool}|${e.label}|${e.files[0] ?? ''}`;
    if (e.ok) open.delete(k);
    else if (!isDenial(e)) open.set(k, e);
  }
  return [...open.values()];
}

// What survives a compaction: files edited and read, failures still open, counts.
// `agentId` names a subagent's loop; without it, the main loop's.
export function recapOf(all: readonly CallEntry[], agentId?: string): string | null {
  const main = all.filter((e) => (agentId ? e.agentId === agentId : !e.agentId));
  if (!main.length) return null;
  const edited = [...new Set(main.filter((e) => EDITS.has(e.tool)).flatMap((e) => e.files))];
  const read = [...new Set(main.filter((e) => e.tool === 'Read').flatMap((e) => e.files))].filter(
    (f) => !edited.includes(f),
  );
  const fails = openFailures(main).slice(-5);
  const parts = [
    `hush recap after compaction: ${main.length} calls so far${agentId ? '' : ` (${all.length - main.length} in subagents)`}.`,
  ];
  if (edited.length) parts.push(`Edited: ${edited.slice(-15).join(', ')}.`);
  if (read.length) parts.push(`Read: ${read.slice(-15).join(', ')}.`);
  if (fails.length)
    parts.push(
      `Still failing: ${fails.map((f) => `${f.label} ${f.what.slice(0, 60)} (${f.err?.slice(0, 80) ?? 'failed'})`).join('; ')}.`,
    );
  parts.push('Call mcp__hush__trace for the full call history instead of re-running commands.');
  return parts.join(' ');
}

// The same call failing the same way, `times` times in a row of its loop: a note asking
// for another approach; null otherwise.
export function loopNote(all: readonly CallEntry[], e: CallEntry, times = 3): string | null {
  if (e.ok) return null;
  const mine = all.filter((x) => callKey(x) === callKey(e));
  const tail = mine.slice(-times);
  if (tail.length < times || !tail.every((x) => !x.ok && x.err === e.err)) return null;
  return `hush: \`${e.label} ${e.what.slice(0, 80)}\` has failed ${times} times in a row with the same error (${(e.err ?? '').slice(0, 120)}). Retrying will not help: read the error, change the approach, or ask the user.`;
}

export function turnStats(entries: readonly CallEntry[], saved: number): TurnStats {
  return {
    calls: entries.length,
    failed: entries.filter((e) => !e.ok).length,
    edited: [...new Set(entries.filter((e) => EDITS.has(e.tool)).flatMap((e) => e.files.map(base)))],
    agents: new Set(entries.map((e) => e.agentId).filter(Boolean)).size,
    saved,
  };
}

export function turnLine(s: TurnStats): string {
  const parts = [`${s.calls} calls`];
  if (s.failed) parts.push(`${s.failed} failed`);
  if (s.edited.length)
    parts.push(`edited ${s.edited.length} (${s.edited.slice(0, 4).join(', ')}${s.edited.length > 4 ? ', …' : ''})`);
  if (s.agents) parts.push(`${s.agents} subagent${s.agents > 1 ? 's' : ''}`);
  if (s.saved) parts.push(`saved ${kb(s.saved)}`);
  return parts.join(' · ');
}

export { kb };

// ── Routing before the model ────────────────────────────────────────────────
// A whole-file Read of a big code or data file: point at an outline and a range first.
const ROUTED = /\.(ts|tsx|js|jsx|mjs|cjs|py|go|rs|java|kt|cs|rb|php|swift|c|cc|cpp|h|hpp|sql|json|ya?ml|xml|html|css|scss|bsl|toml)$/i
export const BIG_READ = 60_000

export function routeRead(path: string, size: number, hasRange: boolean): string | null {
  if (hasRange || size < BIG_READ || !ROUTED.test(path)) return null
  return `hush: ${path.split('/').pop()} is ${Math.round(size / 1024)} kB (~${Math.round(size / 4 / 1000)}k tokens). Read an outline first (mcp__codebase-memory__get_file_outline, or Grep for the symbol), then Read with offset/limit. Repeat this exact Read to get the whole file anyway.`
}

// The same search run again in one loop: its earlier result is still in context.
export function repeatNote(all: readonly CallEntry[], e: CallEntry, since = 0): string | null {
  if (e.tool !== 'Grep' && e.tool !== 'Glob') return null
  // Only calls since the loop's last compaction (older results are gone from context) and its last
  // edit (a search after an edit is a check, not a repeat).
  let from = since
  for (const x of all) if (x.ok && EDITS.has(x.tool) && (x.agentId ?? '') === (e.agentId ?? '') && x.at > from) from = x.at
  const same = all.filter(x => x.at >= from && callKey(x) === callKey(e))
  if (same.length < 3) return null
  return `hush: this exact ${e.tool} ran ${same.length} times in this loop; its earlier result is still in your context (mcp__hush__trace lists them).`
}
