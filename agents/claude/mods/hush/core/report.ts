// Reports over transcripts and ledgers, pure: habits, project hot spots, savings estimate,
// suggestions, span trees and the weekly digest note. Text in, text or numbers out.
import { DENIED, isBounded, isDenial, isReadLike, openFailures, TRIM, TRIM_READ, trimOutput } from './agent.ts';
import type { LedgerEntry, LedgerMeta } from './ledger.ts';
import type { CallItem, Transcript } from './readers.ts';
import { callsOf } from './readers.ts';

const pct = (a: number, b: number) => (b ? `${Math.round((a / b) * 100)}%` : '-');
const median = (xs: number[]) => {
  const s = [...xs].sort((a, b) => a - b);
  return s.length ? (s[Math.floor(s.length / 2)] as number) : 0;
};
const top = <T>(m: Map<T, number>, n: number) => [...m].sort((a, b) => b[1] - a[1]).slice(0, n);
const bump = <T>(m: Map<T, number>, k: T, by = 1) => m.set(k, (m.get(k) ?? 0) + by);
const EDITS = new Set(['Edit', 'Write', 'NotebookEdit', 'MultiEdit']);
const CORRECTION = /^\s*(no\b|nope|stop\b|don'?t\b|wrong|not that|actually\b|undo\b|revert\b|wait\b|that'?s not)/i;

export type Habits = {
  sessions: number;
  prompts: number;
  medianPromptChars: number;
  corrections: number;
  interruptions: number;
  denials: number;
  bash: number;
  described: number;
  medianToFirstEditS: number | null;
  calls: number;
  failed: number;
  perTool: [string, { calls: number; failed: number }][];
};

export function habits(ts: readonly Transcript[]): Habits {
  let prompts = 0;
  let corrections = 0;
  let interruptions = 0;
  let denials = 0;
  let bash = 0;
  let described = 0;
  const lengths: number[] = [];
  const toEdit: number[] = [];
  const tools = new Map<string, { calls: number; failed: number }>();
  for (const t of ts) {
    let promptAt: number | undefined;
    for (const i of t.items) {
      if (i.kind === 'user') {
        prompts++;
        lengths.push(i.text.length);
        if (CORRECTION.test(i.text)) corrections++;
        promptAt = i.at;
      }
      if (i.kind === 'interrupt') interruptions++;
      if (i.kind !== 'call') continue;
      const s = tools.get(i.tool) ?? { calls: 0, failed: 0 };
      s.calls++;
      if (i.isErrored) s.failed++;
      tools.set(i.tool, s);
      if (i.isErrored && DENIED.test(i.result)) denials++;
      if (i.tool === 'Bash') {
        bash++;
        if (i.input.description) described++;
      }
      if (EDITS.has(i.tool) && promptAt && i.at) {
        toEdit.push((i.at - promptAt) / 1000);
        promptAt = undefined;
      }
    }
  }
  const all = [...tools.values()];
  return {
    sessions: ts.length,
    prompts,
    medianPromptChars: median(lengths),
    corrections,
    interruptions,
    denials,
    bash,
    described,
    medianToFirstEditS: toEdit.length ? Math.round(median(toEdit)) : null,
    calls: all.reduce((a, s) => a + s.calls, 0),
    failed: all.reduce((a, s) => a + s.failed, 0),
    perTool: [...tools].sort((a, b) => b[1].calls - a[1].calls),
  };
}

export type Project = {
  edited: [string, number][];
  read: [string, number][];
  docs: [string, number][];
  failing: [string, number][];
  skills: [string, number][];
  agents: [string, number][];
};

// Reports leave the machine's transcripts for notes: secrets in commands never travel with them.
export const redact = (s: string) =>
  s
    .replace(/\b(\w*(?:token|secret|passw(?:or)?d|api[_-]?key|auth)\w*)=\S+/gi, '$1=…')
    .replace(/\b(bearer|basic)\s+\S+/gi, '$1 …')
    .replace(/(--?(?:token|password|secret|api-?key)[= ]+)\S+/gi, '$1…')
    .replace(/(\w+:\/\/)[^\s/@:]+:[^\s/@]+@/g, '$1…@')
    .replace(/[A-Za-z0-9+_-]{32,}={0,2}/g, '…')

const rel = (p: string, cwd: string) => (cwd && p.startsWith(`${cwd}/`) ? p.slice(cwd.length + 1) : p);

export function project(ts: readonly Transcript[], n = 10): Project {
  const edited = new Map<string, number>();
  const read = new Map<string, number>();
  const docs = new Map<string, number>();
  const failing = new Map<string, number>();
  const skills = new Map<string, number>();
  const agents = new Map<string, number>();
  for (const t of ts) {
    for (const c of callsOf(t)) {
      const f = typeof c.input.file_path === 'string' ? rel(c.input.file_path, t.cwd) : undefined;
      if (f && EDITS.has(c.tool)) bump(edited, f);
      if (f && c.tool === 'Read') bump(/\.(md|mdx)$/i.test(f) ? docs : read, f);
      if (c.isErrored && !DENIED.test(c.result)) bump(failing, `${c.label} ${redact(c.what).slice(0, 70)}`);
      if (c.tool === 'Skill' && typeof c.input.skill === 'string') bump(skills, c.input.skill);
      if (c.tool === 'Agent') bump(agents, String(c.input.subagent_type ?? 'general-purpose'));
    }
  }
  return {
    edited: top(edited, n),
    read: top(read, n),
    docs: top(docs, n),
    failing: top(failing, n),
    skills: top(skills, n),
    agents: top(agents, n),
  };
}

// What hush's trim and re-read rules would have kept out of context, and how many cache-read
// tokens that is over the model calls that followed (chars / 4 ≈ tokens).
export function savings(ts: readonly Transcript[]) {
  let results = 0;
  let trim = 0;
  let reread = 0;
  let carried = 0;
  for (const t of ts) {
    const reads = new Map<string, string>();
    for (const c of callsOf(t)) {
      if (c.isErrored) continue;
      results += c.result.length;
      let cut = 0;
      const command = String(c.input.command ?? '');
      if (c.tool === 'Bash' && !isBounded(command)) {
        // The mod's own rule, so the estimate and the live trim never drift apart.
        const out = trimOutput(c.result, '', isReadLike(command) ? TRIM_READ : TRIM);
        cut = out === null ? 0 : Math.max(0, c.result.length - out.length);
        trim += cut;
      }
      if (c.tool === 'Read' && c.result.length > 400) {
        const k = `${c.input.file_path}|${c.input.offset ?? ''}|${c.input.limit ?? ''}`;
        if (reads.get(k) === c.result) {
          cut = c.result.length - 120;
          reread += cut;
          reads.delete(k);
        } else reads.set(k, c.result);
      }
      carried += cut * Math.max(0, t.modelCalls - c.modelCall);
    }
  }
  const tok = (c: number) => Math.round(c / 4);
  return {
    resultTokens: tok(results),
    trimTokens: tok(trim),
    rereadTokens: tok(reread),
    cacheReadTokensAvoided: tok(carried),
  };
}

export function suggestions(h: Habits, p: Project): string[] {
  const out: string[] = [];
  if (h.bash >= 20 && h.described / h.bash < 0.8)
    out.push(
      `Only ${pct(h.described, h.bash)} of Bash calls carry a description: check which harness or model drops it (hush's DESCRIBE_RULE covers Claude's main loop).`,
    );
  if (h.prompts >= 10 && h.corrections / h.prompts > 0.15)
    out.push(
      `${pct(h.corrections, h.prompts)} of prompts correct the agent: the corrected topics are candidates for AGENTS.md rules or memory.`,
    );
  if (h.interruptions >= 3)
    out.push(
      `${h.interruptions} interruptions: look at what ran before each (often long polls or wrong-direction edits).`,
    );
  if (h.denials >= 3)
    out.push(`${h.denials} denied tool calls: an allow rule or a narrower instruction would save the round trips.`);
  for (const [row, n] of p.failing.slice(0, 3))
    if (n >= 3) out.push(`\`${row}\` failed ${n} times: a flaky or misremembered command; document the right one.`);
  for (const [doc, n] of p.docs.slice(0, 2))
    if (n >= 5)
      out.push(`\`${doc}\` was read ${n} times: keep it short, or split what agents need into a smaller entry point.`);
  for (const [file, n] of p.read.slice(0, 2))
    if (n >= 8)
      out.push(
        `\`${file}\` was read ${n} times: an outline (codebase-memory get_file_outline) or a codemap entry would be cheaper.`,
      );
  return out;
}

const list = (rows: [string, number][]) =>
  rows.length ? rows.map(([k, n]) => `- \`${k}\` ×${n}`).join('\n') : '- none';

export function habitsText(h: Habits): string {
  return [
    `${h.sessions} transcripts, ${h.prompts} prompts (median ${h.medianPromptChars} chars), ${h.calls} calls, ${pct(h.failed, h.calls)} failed`,
    `corrections ${h.corrections} · interruptions ${h.interruptions} · denials ${h.denials} · Bash with description ${pct(h.described, h.bash)} (${h.described}/${h.bash})`,
    `median time from prompt to first edit: ${h.medianToFirstEditS === null ? '-' : `${h.medianToFirstEditS}s`}`,
    ...h.perTool
      .slice(0, 12)
      .map(
        ([name, s]) =>
          `  ${name.padEnd(40)} ${String(s.calls).padStart(6)}  ${pct(s.failed, s.calls).padStart(4)} failed`,
      ),
  ].join('\n');
}

// The weekly note: a raw source for the wiki (llm-wiki "raw" layer), facts only; the
// wiki's own pages are written from it by an ingest pass.
export function digestNote(o: {
  title: string;
  date: string;
  scope: string;
  h: Habits;
  p: Project;
  s: ReturnType<typeof savings>;
  ideas: string[];
}): string {
  return [
    '---',
    `title: ${JSON.stringify(o.title)}`,
    `date: ${o.date}`,
    'type: raw/hush-digest',
    `scope: ${JSON.stringify(o.scope)}`,
    `sessions: ${o.h.sessions}`,
    '---',
    '',
    `# ${o.title}`,
    '',
    '## Habits',
    '',
    '```',
    habitsText(o.h),
    '```',
    '',
    '## Context and tokens',
    '',
    `- tool results ~${o.s.resultTokens} tokens; hush trim would cut ~${o.s.trimTokens}, re-read pointers ~${o.s.rereadTokens}; ~${o.s.cacheReadTokensAvoided} cache-read tokens avoided over later calls`,
    '',
    '## Project hot spots',
    '',
    '### Edited',
    list(o.p.edited),
    '### Read (code)',
    list(o.p.read),
    '### Read (docs)',
    list(o.p.docs),
    '### Failing',
    list(o.p.failing),
    '### Skills',
    list(o.p.skills),
    '### Subagents',
    list(o.p.agents),
    '',
    '## Suggestions (for a human to accept)',
    '',
    ...(o.ideas.length ? o.ideas.map((i) => `- [ ] ${i}`) : ['- none this period']),
    '',
  ].join('\n');
}

// A session's ledger as a span tree: turns, main-loop calls, and each subagent folded into one
// summary row under the call that started it (`full` lists its calls too).
export function tree(meta: LedgerMeta | null, loops: Map<string, LedgerEntry[]>, full = false): string[] {
  const main = loops.get('main') ?? [];
  const out: string[] = [meta ? `session ${meta.session.slice(0, 8)} · ${meta.harness} · ${meta.cwd}` : 'session'];
  const row = (e: LedgerEntry, pad: string) =>
    `${pad}${e.ok ? '✓' : '✗'} ${e.label} ${e.what.slice(0, 90)} (${e.ms}ms)${e.ok ? '' : ` — ${e.err ?? 'failed'}`}`;
  const summary = (es: LedgerEntry[]) => {
    const files = new Set(es.flatMap((e) => e.files)).size;
    const ms = es.reduce((a, e) => a + e.ms, 0);
    return `${es.length} calls · ${es.filter((e) => !e.ok).length} failed · ${files} files · ${Math.round(ms / 1000)}s`;
  };
  const placed = new Set<string>();
  // A loop's calls under `pad`; each Agent call's subagent folded under it, recursively (nested agents).
  const walk = (es: LedgerEntry[], pad: string, depth: number) => {
    for (const e of es) {
      if (full || depth === 0) out.push(row(e, pad));
      const sub = e.spawned && !placed.has(e.spawned) ? loops.get(e.spawned) : undefined;
      if (!sub || !e.spawned) continue;
      placed.add(e.spawned);
      out.push(`${pad}  └ ${e.spawned.slice(0, 10)}: ${summary(sub)}`);
      if (depth < 8) walk(sub, `${pad}      `, depth + 1);
    }
  };
  let turn: string | undefined = '\0';
  for (const e of main) {
    if (e.turn !== turn) {
      turn = e.turn;
      out.push(`turn ${e.turn?.slice(0, 8) ?? '?'}`);
    }
    walk([e], '  ', 0);
  }
  // Loops no Agent call in the ledger started (spawned before the ledger recorded it): roots of their own,
  // with whatever they started nested under them.
  const referenced = new Set([...loops.values()].flat().map((e) => e.spawned).filter(Boolean));
  for (const [k, es] of loops) {
    if (k === 'main' || placed.has(k) || referenced.has(k)) continue;
    placed.add(k);
    out.push(`agent ${k.slice(0, 10)} (no parent call in the ledger): ${summary(es)}`);
    walk(es, '    ', 1);
  }
  return out;
}

// One line per session for the board: recency, place, last-hour activity, open failures.
export function boardRow(meta: LedgerMeta, loops: Map<string, LedgerEntry[]>, now: number) {
  const all = [...loops.values()].flat();
  const last = Math.max(meta.startedAt, ...all.map((e) => e.at));
  const hour = all.filter((e) => e.at > now - 3_600_000);
  return {
    session: meta.session,
    cwd: meta.cwd,
    last,
    calls: all.length,
    hour: hour.length,
    agents: loops.size - (loops.has('main') ? 1 : 0),
    open: openFailures(all),
  };
}

// What the ledger teaches the next session in a project: calls that failed the same way `min` times
// or more, most frequent first; null when nothing recurs. The user's own refusals are choices, not lessons.
const USER_NO = /doesn't want to proceed|was rejected|user denied/i;
export function brief(all: readonly LedgerEntry[], min = 3, n = 5): string | null {
  const groups = new Map<string, { n: number; label: string; err: string }>();
  for (const e of all) {
    if (e.ok || !e.err || USER_NO.test(e.err)) continue;
    const err = redact(e.err).replace(/\s+/g, ' ').slice(0, 160);
    const label = isDenial(e) ? 'REFUSED' : e.label;
    // Paths differ from worktree to worktree; the failure is the same one.
    const k = `${label}|${err.replace(/\/[\w./-]+/g, '/…').slice(0, 60)}`;
    const g = groups.get(k) ?? { n: 0, label, err };
    g.n++;
    groups.set(k, g);
  }
  const rows = [...groups.values()].filter((g) => g.n >= min).sort((a, b) => b.n - a.n).slice(0, n);
  if (!rows.length) return null;
  return [
    'hush: calls that failed repeatedly in this project lately (from the call ledger). Check before repeating one as it was:',
    ...rows.map((g) => `- ${g.label} ×${g.n}: ${g.err}`),
  ].join('\n');
}

export type { CallItem };
