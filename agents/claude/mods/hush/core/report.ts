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
export const CORRECTION = /^\s*(no\b|nope|stop\b|don'?t\b|wrong|not that|actually\b|undo\b|revert\b|wait\b|that'?s not)/i;

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
  lessons?: readonly Lesson[];
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
    '## Proposed rules (`hush lessons --project DIR --accept N` adds one to that CLAUDE.md)',
    '',
    ...(o.lessons?.length ? o.lessons.map((l, i) => `${i + 1}. ${l.rule} (×${l.n} in ${l.sessions} sessions)`) : ['- none this period']),
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
// `known`: text already holding accepted lessons (the project's CLAUDE.md); a failure it names is not repeated.
const USER_NO = /doesn't want to proceed|was rejected|user denied/i;
// Paths differ from worktree to worktree; the failure is the same one.
const normErr = (s: string) => s.replace(/\/[\w./-]+/g, '/…');
type FailGroup = { n: number; label: string; err: string; sessions: Set<string>; members: LedgerEntry[] };
function failGroups(all: readonly LedgerEntry[], known = ''): FailGroup[] {
  const seen = normErr(known);
  const groups = new Map<string, FailGroup>();
  for (const e of all) {
    if (e.ok || !e.err || USER_NO.test(e.err)) continue;
    const err = redact(e.err).replace(/\s+/g, ' ').slice(0, 160);
    const label = isDenial(e) ? 'REFUSED' : e.label;
    const short = normErr(err).slice(0, 60);
    if (seen && seen.includes(short)) continue;
    const k = `${label}|${short}`;
    const g = groups.get(k) ?? { n: 0, label, err, sessions: new Set<string>(), members: [] };
    g.n++;
    g.members.push(e);
    g.sessions.add(e.session);
    groups.set(k, g);
  }
  return [...groups.values()].sort((a, b) => b.n - a.n);
}

export function brief(all: readonly LedgerEntry[], min = 3, n = 5, known = ''): string | null {
  const rows = failGroups(all, known).filter((g) => g.n >= min).slice(0, n);
  if (!rows.length) return null;
  return [
    'hush: calls that failed repeatedly in this project lately (from the call ledger). Check before repeating one as it was:',
    ...rows.map((g) => `- ${g.label} ×${g.n}: ${g.err}`),
  ].join('\n');
}

// A failure that recurs across sessions, as a rule for a human to accept into CLAUDE.md: what failed, how,
// and the call of the same tool that next succeeded in that loop (the likely fix; the human judges).
export type Lesson = { label: string; err: string; n: number; sessions: number; failed: string; fix: string | null; rule: string };
export function lessons(all: readonly LedgerEntry[], minSessions = 2, min = 3, known = ''): Lesson[] {
  const loops = new Map<string, LedgerEntry[]>();
  for (const e of all) {
    const k = `${e.session}|${e.agentId ?? ''}`;
    const es = loops.get(k);
    if (es) es.push(e);
    else loops.set(k, [e]);
  }
  const next = new Map<LedgerEntry, LedgerEntry>();
  for (const es of loops.values()) {
    es.sort((a, b) => a.at - b.at);
    es.forEach((e, i) => {
      if (e.ok) return;
      // A call on another file is no fix for one on this file.
      const fix = es.slice(i + 1, i + 6).find((x) => x.ok && x.tool === e.tool && x.label === e.label && (!e.files[0] || x.files[0] === e.files[0]));
      if (fix) next.set(e, fix);
    });
  }
  return failGroups(all, known)
    .filter((g) => g.n >= min && g.sessions.size >= minSessions)
    .map((g) => {
      const fixes = new Map<string, number>();
      for (const e of g.members) {
        const f = next.get(e);
        if (f) bump(fixes, redact(f.what).slice(0, 120));
      }
      // A refusal is a boundary, not a puzzle: no workaround is proposed. A fix seen once may be chance.
      const [best, seen = 0] = top(fixes, 1)[0] ?? [];
      const fix = g.label !== 'REFUSED' && seen >= 2 ? (best ?? null) : null;
      const failed = redact(g.members[0]?.what ?? '').slice(0, 120);
      const how =
        g.label === 'REFUSED' ? 'it is refused here: ask the user instead of retrying or working around it'
        : fix ? `what worked next: \`${fix}\`` : 'find the cause before retrying it';
      return { label: g.label, err: g.err, n: g.n, sessions: g.sessions.size, failed, fix, rule: `\`${failed}\` (${g.label}) fails with "${g.err}"; ${how}.` };
    });
}

// What one session's ledger says about how hush served it, for comparing sessions with a feature held out.
export type SessionFacts = {
  session: string;
  heldOut: string | null | undefined;
  calls: number;
  failed: number;
  // Failures of a call that already failed the same way in the same loop.
  repeated: number;
  // Cost-weighted tokens: cache reads cost about a tenth of a fresh input token. null: no usage recorded.
  tokens: number | null;
  // Reads by subagents of files the main loop had already read that session: context the handoff did not pass on.
  handoffRereads: number;
  subagents: number;
};
export function sessionFacts(meta: LedgerMeta, loops: Map<string, LedgerEntry[]>): SessionFacts {
  const all = [...loops.values()].flat();
  const failedBefore = new Set<string>();
  let repeated = 0;
  for (const e of [...all].sort((a, b) => a.at - b.at)) {
    if (e.ok) continue;
    const k = `${e.agentId ?? ''}|${e.label}|${e.sig ?? e.what}|${e.err ?? ''}`;
    if (failedBefore.has(k)) repeated++;
    failedBefore.add(k);
  }
  const mainReads = new Map<string, number>();
  for (const e of loops.get('main') ?? []) if (e.tool === 'Read' && e.ok) for (const f of e.files) if (!mainReads.has(f)) mainReads.set(f, e.at);
  let handoffRereads = 0;
  for (const [k, es] of loops) {
    if (k === 'main') continue;
    for (const e of es) if (e.tool === 'Read' && e.files.some((f) => (mainReads.get(f) ?? Infinity) < e.at)) handoffRereads++;
  }
  const u = meta.usage;
  return {
    session: meta.session,
    heldOut: meta.heldOut,
    calls: all.length,
    failed: all.filter((e) => !e.ok).length,
    repeated,
    tokens: u ? u.input + u.cacheWrite + u.output + Math.round(u.cacheRead / 10) : null,
    handoffRereads,
    subagents: loops.size - (loops.has('main') ? 1 : 0),
  };
}

// Sessions grouped by the feature held out, medians per session; tasks differ, so few sessions are noise.
export function effectText(rows: readonly SessionFacts[]): string {
  // Sessions of a few calls (a headless check, a quick question) say nothing about the features.
  const known = rows.filter((r) => r.heldOut !== undefined && r.calls >= 5);
  const out = [`${rows.length} sessions, ${known.length} with a recorded holdout (older ones carry none)`];
  if (!known.length) return out.join('\n');
  const groups = new Map<string, SessionFacts[]>();
  for (const r of known) groups.set(r.heldOut ?? 'none', [...(groups.get(r.heldOut ?? 'none') ?? []), r]);
  const per = (a: number, b: number) => (b ? a / b : 0);
  out.push('', 'held out     sessions  tokens/call  fail%  repeat-fail%  handoff re-reads/subagent');
  for (const [k, rs] of [...groups].sort((a, b) => (a[0] === 'none' ? -1 : b[0] === 'none' ? 1 : a[0].localeCompare(b[0])))) {
    const withTokens = rs.filter((r) => r.tokens !== null);
    const tpc = withTokens.length ? String(Math.round(median(withTokens.map((r) => per(r.tokens ?? 0, r.calls))))) : '-';
    const fail = median(rs.map((r) => per(r.failed, r.calls) * 100)).toFixed(1);
    const rep = median(rs.map((r) => per(r.repeated, r.failed) * 100)).toFixed(1);
    const hand = median(rs.filter((r) => r.subagents).map((r) => per(r.handoffRereads, r.subagents))).toFixed(1);
    out.push(`${(k === 'none' ? 'none (all on)' : k).padEnd(13)}${String(rs.length).padStart(8)}${tpc.padStart(13)}${fail.padStart(7)}${rep.padStart(14)}${hand.padStart(27)}${rs.length < 10 ? '  (under 10 sessions: noise)' : ''}`);
  }
  return out.join('\n');
}

// What every session pays before its task: the first call's context, and which enabled plugins,
// MCP servers and local skills these sessions actually used. Hooks and LSPs leave no calls to count.
export function contextAudit(ts: readonly Transcript[], o: { plugins: string[]; servers: string[]; skills: string[] }): string {
  const base = ts.map((t) => t.firstContext).filter((n): n is number => typeof n === 'number' && n > 0);
  const uses = new Map<string, number>();
  for (const t of ts)
    for (const c of callsOf(t)) {
      const skill = c.tool === 'Skill' && typeof c.input.skill === 'string' ? c.input.skill : '';
      const agent = c.tool === 'Agent' && typeof c.input.subagent_type === 'string' ? c.input.subagent_type : '';
      // A plugin's server shows as mcp__plugin_<p>_<server>__ or, on some versions, as plain mcp__<server>__.
      const server = /^mcp__(?!plugin_)([^_].*?)__/.exec(c.tool)?.[1];
      const mine = (p: string) => c.tool.startsWith(`mcp__plugin_${p}_`) || skill.startsWith(`${p}:`) || agent.startsWith(`${p}:`) || (!!server && (p.startsWith(server) || server.startsWith(p)));
      const owner = o.plugins.find(mine);
      if (owner) bump(uses, `plugin:${owner}`);
      if (server && !owner) bump(uses, `server:${server}`);
      if (skill && !skill.includes(':')) bump(uses, `skill:${skill}`);
    }
  const row = (kind: string, names: string[]) =>
    names.length
      ? [`${kind} (uses in these sessions; 0 = loaded every call, never used):`, ...names.map((n) => [n, uses.get(`${kind.slice(0, -1)}:${n}`) ?? 0] as const).sort((a, b) => a[1] - b[1]).map(([n, k]) => `  ${String(k).padStart(5)}  ${n}`)]
      : [];
  return [
    `${ts.length} sessions; first-call context ${base.length ? `median ${Math.round(median(base) / 1000)}k tokens (min ${Math.round(Math.min(...base) / 1000)}k, max ${Math.round(Math.max(...base) / 1000)}k)` : 'unknown'}`,
    '',
    ...row('plugins', o.plugins),
    ...row('servers', [...new Set([...o.servers, ...[...uses.keys()].filter((k) => k.startsWith('server:')).map((k) => k.slice(7))])]),
    ...row('skills', o.skills),
    '',
    'Plugins with hooks or LSPs only show 0 here although they work; judge those by what they do.',
  ].join('\n');
}

// The user's prompts that correct the agent, newest last: material for a feedback memory or a rule.
export function corrections(ts: readonly Transcript[], n = 30): string[] {
  const out: { at: number; text: string }[] = [];
  for (const t of ts)
    for (const i of t.items) if (i.kind === 'user' && CORRECTION.test(i.text)) out.push({ at: i.at ?? 0, text: redact(i.text).replace(/\s+/g, ' ').slice(0, 200) });
  return out.sort((a, b) => a.at - b.at).slice(-n).map((c) => `${c.at ? new Date(c.at).toISOString().slice(0, 10) : '?'}  ${c.text}`);
}

// Refusals by the policy or classifier, grouped by reason, so each kind is decided once (allow it,
// or change how agents go about it). The user's own "no" is left out.
export function refusals(all: readonly LedgerEntry[]): string[] {
  const groups = new Map<string, { n: number; examples: string[] }>();
  for (const e of all) {
    if (e.ok || !isDenial(e) || USER_NO.test(e.err ?? '')) continue;
    const err = e.err ?? '';
    const k = /Reason: \[([^\]]+)\]/.exec(err)?.[1] ?? (/isolated in the worktree/.test(err) ? 'worktree isolation: the command reaches outside the worktree' : normErr(redact(err)).slice(0, 70));
    const g = groups.get(k) ?? { n: 0, examples: [] };
    g.n++;
    if (g.examples.length < 2 && !g.examples.includes(e.what)) g.examples.push(redact(e.what).slice(0, 80));
    groups.set(k, g);
  }
  return [...groups].sort((a, b) => b[1].n - a[1].n).map(([k, g]) => `${String(g.n).padStart(5)}  ${k}  e.g. ${g.examples.join(' | ')}`);
}

export type { CallItem };
