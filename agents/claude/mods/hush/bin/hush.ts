#!/usr/bin/env node
// hush CLI: the harness-neutral side of hush. Reads Claude Code / pi / OMP transcripts and the
// hush ledger (core/ledger.ts); all logic lives in core/ (pure), this file only does IO.
//
//   hush replay <session|file> [--agents] [--previews N] [--text] [--no-color]
//   hush stats [<session> | --recent N] [--project DIR]     habits, failures per tool, savings estimate
//   hush analyze [--recent N] [--project DIR]                habits + project hot spots + suggestions
//   hush trace [--session ID] [--failed] [--file X] [--label X] [--agent main|ID] [--last N]
//   hush tree <session> [--full]                             span tree from the ledger
//   hush board [--hours H] [--rows]                          active sessions (herdr: --rows)
//   hush digest [--days N] [--project DIR]                   weekly raw note into the wiki
//   hush wiki init                                           scaffold $HUSH_WIKI (default ~/wiki)
//   hush mcp                                                 stdio MCP server: trace, tree, board, analyze
//   hush brief [--project DIR] [--days N]                    calls that keep failing in a project (the mod feeds it to agents)
//   hush lessons [--project DIR] [--days N] [--accept 1,3]   recurring failures as rules; --accept adds them to DIR/CLAUDE.md
//   hush effect [--project DIR] [--days N]                   sessions with a feature held out vs all on: tokens, failures, handoffs
//   hush context [--recent N] [--project DIR]                first-call context, and which plugins/MCP servers/skills get used
//   hush corrections [--recent N] [--project DIR]            your prompts that corrected the agent (material for rules/memories)
//   hush refusals [--project DIR] [--days N]                 policy/classifier refusals by reason, to decide each kind once
//   hush log '<json>'                                        append one call to the ledger (pi/OMP hooks call this)
//   hush gc [--cache-days N] [--ledger-days N]               drop trimmed outputs (14d) and ledgers (90d); digest runs it
import { appendFileSync, closeSync, existsSync, mkdirSync, openSync, readdirSync, readFileSync, readSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { basename, dirname, join, resolve as absolute } from 'node:path';

import { hash, queryTrace } from '../core/agent.ts';
import { describe, label } from '../core/format.ts';
import { LEDGER_VERSION, ledgerRoot, loopFile, parseLedger } from '../core/ledger.ts';
import type { LedgerEntry, LedgerMeta } from '../core/ledger.ts';
import { parseTranscript, PI_TOOLS } from '../core/readers.ts';
import type { Item, Transcript } from '../core/readers.ts';
import { boardRow, brief, contextAudit, corrections, digestNote, effectText, refusals, habits, habitsText, lessons, project, savings, sessionFacts, suggestions, tree } from '../core/report.ts';

const HOME = homedir();
const CLAUDE = join(process.env.CLAUDE_CONFIG_DIR || join(HOME, '.claude'), 'projects');
const SESSION_DIRS = (
  process.env.HUSH_SESSION_DIRS ?? `${CLAUDE}:${HOME}/.pi/agent/sessions:${HOME}/.omp/agent/sessions`
)
  .split(':')
  .filter(existsSync);
const LEDGER = ledgerRoot(HOME, process.env.XDG_STATE_HOME);
const WIKI = process.env.HUSH_WIKI || join(HOME, 'wiki');

const [cmd = '', ...rest] = process.argv.slice(2);
const flag = (f: string) => rest.includes(f);
const opt = (f: string) => (rest.includes(f) ? rest[rest.indexOf(f) + 1] : undefined);
const VALUED = new Set([
  '--previews',
  '--recent',
  '--project',
  '--session',
  '--file',
  '--label',
  '--last',
  '--hours',
  '--days',
  '--agent',
  '--cache-days',
  '--ledger-days',
  '--accept',
]);
const positional = rest.filter((a, i) => !a.startsWith('--') && !VALUED.has(rest[i - 1] ?? ''));

const isColor = !flag('--no-color') && process.stdout.isTTY;
const width = process.stdout.columns || 120;
const paint = (code: string, s: string) => (isColor ? `\x1b[${code}m${s}\x1b[0m` : s);
const dim = (s: string) => paint('2', s);
const fit = (s: string, cells: number) => (s.length > cells ? `${s.slice(0, Math.max(0, cells - 1))}…` : s);
const flat = (s: string) => s.replace(/\s+/g, ' ').trim();

// ── Transcripts ─────────────────────────────────────────────────────────────
// Files can vanish between a listing and a stat (gc, a rename, a dead link): treat them as gone, never crash.
const mtimeOf = (p: string) => {
  try {
    return statSync(p).mtimeMs;
  } catch {
    return 0;
  }
};
const isDir = (p: string) => {
  try {
    return statSync(p).isDirectory();
  } catch {
    return false;
  }
};
const listed = (dir: string) => {
  try {
    return readdirSync(dir);
  } catch {
    return [];
  }
};

type Found = { file: string; mtime: number };
function transcripts(): Found[] {
  const out: Found[] = [];
  for (const root of SESSION_DIRS) {
    for (const p of listed(root)) {
      const dir = join(root, p);
      if (!isDir(dir)) continue;
      for (const f of listed(dir)) {
        const mtime = f.endsWith('.jsonl') ? mtimeOf(join(dir, f)) : 0;
        if (mtime) out.push({ file: join(dir, f), mtime });
      }
    }
  }
  return out.sort((a, b) => b.mtime - a.mtime);
}

// A transcript's directory from its head alone, so `--project` picks files before any is read whole.
function cwdOf(file: string): string {
  try {
    const fd = openSync(file, 'r');
    const buf = Buffer.alloc(65536);
    const n = readSync(fd, buf, 0, buf.length, 0);
    closeSync(fd);
    const m = /"cwd":("(?:[^"\\]|\\.)*")/.exec(buf.toString('utf8', 0, n));
    return m ? (JSON.parse(m[1] as string) as string) : '';
  } catch {
    return '';
  }
}
// `--project` as an absolute directory; a path is in it when it is that directory or under it.
const projectDir = () => (opt('--project') ? absolute(opt('--project') as string) : undefined);
const isIn = (cwd: string, dir: string) => cwd === dir || cwd.startsWith(`${dir}/`);

function resolve(t: string): string {
  if (existsSync(t)) return t;
  const hit = transcripts().find((f) => basename(f.file).includes(t));
  if (hit) return hit.file;
  throw new Error(`hush: no transcript matching "${t}" under ${SESSION_DIRS.join(', ')}`);
}

// Claude subagent transcripts of a session, by the Agent call (tool_use_id) that started each.
function subagentsOf(file: string): Map<string, string> {
  const dir = join(dirname(file), basename(file, '.jsonl'), 'subagents');
  const found = new Map<string, string>();
  if (!existsSync(dir)) return found;
  for (const f of readdirSync(dir).filter((f) => f.endsWith('.meta.json'))) {
    try {
      const meta = JSON.parse(readFileSync(join(dir, f), 'utf8')) as { toolUseId?: string };
      if (meta.toolUseId) found.set(meta.toolUseId, join(dir, f.replace(/\.meta\.json$/, '.jsonl')));
    } catch {
      // a meta file mid-write
    }
  }
  return found;
}

const load = (file: string): Transcript => parseTranscript(readFileSync(file, 'utf8'));
// A session with its subagents, each read as its own transcript; a file gone since the listing is no transcript.
const withSubagents = (file: string): Transcript[] => {
  try {
    return [load(file), ...[...subagentsOf(file).values()].filter(existsSync).map(load)];
  } catch {
    return [];
  }
};

function pick(): Transcript[] {
  const recent = Number(opt('--recent')) || 0;
  const dir = projectDir();
  // The project's newest N, not the project's share of everyone's newest N.
  const files = positional[0]
    ? [resolve(positional[0])]
    : transcripts()
        .filter((f) => !dir || isIn(cwdOf(f.file), dir))
        .slice(0, recent || 20)
        .map((f) => f.file);
  return files.flatMap(withSubagents);
}

// ── replay ──────────────────────────────────────────────────────────────────
type Row = Item | { kind: 'calls'; first: Extract<Item, { kind: 'call' }>; n: number };
const COLORS: Record<string, string> = { Read: '36', Edit: '36', Write: '36', Grep: '33', Agent: '34', Skill: '35' };
function colorOf(c: Extract<Item, { kind: 'call' }>) {
  if (c.isErrored) return '31';
  if (c.tool.startsWith('mcp__')) return '35';
  if (c.tool === 'Bash') return /^(GIT|GREP|RG)$/.test(c.label) ? '33' : '0';
  return COLORS[c.tool] ?? '0';
}

function replay(file: string, pad: string, subs: Map<string, string>) {
  const t = load(file);
  const cells = width - pad.length;
  const calls = t.items.filter((i) => i.kind === 'call') as Extract<Item, { kind: 'call' }>[];
  const w = Math.min(10, Math.max(5, ...calls.map((c) => c.label.length)));
  const previews = Number(opt('--previews')) || 0;
  const rows: Row[] = [];
  for (const i of t.items) {
    const prev = rows[rows.length - 1];
    if (
      i.kind === 'call' &&
      prev?.kind === 'calls' &&
      !i.isErrored &&
      !prev.first.isErrored &&
      prev.first.label === i.label &&
      prev.first.what === i.what
    ) {
      rows[rows.length - 1] = { kind: 'calls', first: i, n: prev.n + 1 };
    } else rows.push(i.kind === 'call' ? { kind: 'calls', first: i, n: 1 } : i);
  }
  for (const r of rows) {
    if (r.kind === 'user') {
      console.log(dim(pad + '─'.repeat(Math.max(0, cells))));
      console.log(`${pad}${paint('35', 'USER'.padEnd(w))} ${fit(flat(r.text), cells - w - 1)}`);
    } else if (r.kind === 'bg') console.log(`${pad}${paint('34', 'BG'.padEnd(w))} ${dim(fit(r.text, cells - w - 1))}`);
    else if (r.kind === 'interrupt')
      console.log(`${pad}${paint('31', 'STOP'.padEnd(w))} ${dim('interrupted by the user')}`);
    else if (r.kind === 'text') {
      if (flag('--text'))
        console.log(
          r.text
            .split('\n')
            .map((l) => `${pad}  ${l}`)
            .join('\n'),
        );
      else console.log(`${pad}  ${dim(fit(flat(r.text), cells - 2))}`);
    } else if (r.kind === 'calls') {
      const c = r.first;
      const times = r.n > 1 ? dim(` ×${r.n}`) : '';
      console.log(
        `${pad}${paint(colorOf(c), c.label.padEnd(w))} ${fit(c.what, cells - w - 1 - (r.n > 1 ? 4 : 0))}${times}`,
      );
      const out = c.result
        .replace(/\x1b\[[0-9;?]*[ -/]*[@-~]/g, '')
        .split('\n')
        .filter((l) => l.trim());
      if (c.isErrored) console.log(pad + paint('31', fit(`  │ ${out[0] ?? 'failed'}`, cells)));
      else for (const l of out.slice(0, previews)) console.log(pad + dim(fit(`  │ ${l}`, cells)));
      const sub = subs.get(c.id);
      // Nested subagents sit in the same flat folder: the same map finds them.
      if (sub && existsSync(sub)) replay(sub, `${pad}    `, subs);
    }
  }
}

// ── Ledger ──────────────────────────────────────────────────────────────────
const newestIn = (dir: string) => {
  try {
    return Math.max(mtimeOf(dir), ...readdirSync(dir).map((f) => mtimeOf(join(dir, f))));
  } catch {
    return 0;
  }
};

function ledgerSessions(): { dir: string; mtime: number }[] {
  if (!existsSync(LEDGER)) return [];
  return readdirSync(LEDGER)
    .map((s) => join(LEDGER, s))
    .filter((d) => isDir(d))
    .map((dir) => ({ dir, mtime: newestIn(dir) }))
    .sort((a, b) => b.mtime - a.mtime);
}

function readLedger(dir: string): { meta: LedgerMeta | null; loops: Map<string, LedgerEntry[]> } {
  let meta: LedgerMeta | null = null;
  try {
    meta = JSON.parse(readFileSync(join(dir, 'meta.json'), 'utf8'));
  } catch {
    meta = null;
  }
  const loops = new Map<string, LedgerEntry[]>();
  for (const f of readdirSync(dir).filter((f) => f.endsWith('.jsonl')))
    {
    const key = basename(f, '.jsonl').replace(/\.\d+$/, '');
    loops.set(key, [...(loops.get(key) ?? []), ...parseLedger(readFileSync(join(dir, f), 'utf8'))]);
  }
  // Rolled parts (main.2.jsonl) list before main.jsonl: time puts them back in order.
  for (const es of loops.values()) es.sort((a, b) => a.at - b.at);
  return { meta: meta ?? { v: 1, session: basename(dir), harness: '?', cwd: '', startedAt: 0 }, loops };
}

function ledgerDir(id?: string): string {
  const all = ledgerSessions();
  const hit = id ? all.find((s) => basename(s.dir).startsWith(id)) : all[0];
  if (!hit) {
    throw new Error(`hush: no ledger${id ? ` for "${id}"` : ''} under ${LEDGER}`);
  }
  return hit.dir;
}

function traceText(q: Record<string, unknown>): string {
  const { loops } = readLedger(ledgerDir(typeof q.session === 'string' ? q.session : undefined));
  const all = [...loops.values()].flat().sort((a, b) => a.at - b.at);
  return queryTrace(
    all,
    {
      failed: q.failed === true,
      ...(typeof q.file === 'string' ? { file: q.file } : {}),
      ...(typeof q.label === 'string' ? { tool: q.label } : {}),
      ...(typeof q.agent === 'string' ? { agent: q.agent } : {}),
      ...(typeof q.last === 'number' ? { last: q.last } : {}),
    },
    Date.now(),
  );
}

// Ledgers of the sessions touched in the last `days` that ran in `dir` (every project when null).
function ledgersSince(dir: string | null | undefined, days: number): { meta: LedgerMeta; loops: Map<string, LedgerEntry[]> }[] {
  const since = Date.now() - days * 86_400_000;
  const out: { meta: LedgerMeta; loops: Map<string, LedgerEntry[]> }[] = [];
  for (const { dir: d, mtime } of ledgerSessions()) {
    if (mtime < since) break;
    const { meta, loops } = readLedger(d);
    if (meta && (!dir || isIn(meta.cwd, dir))) out.push({ meta, loops });
  }
  return out;
}
const entriesOf = (ls: { loops: Map<string, LedgerEntry[]> }[], days: number) => {
  const since = Date.now() - days * 86_400_000;
  return ls.flatMap((l) => [...l.loops.values()].flat().filter((e) => e.at >= since));
};
const claudeMd = (dir: string) => join(dir, 'CLAUDE.md');
const knownOf = (dir: string) => (existsSync(claudeMd(dir)) ? readFileSync(claudeMd(dir), 'utf8') : '');

// Recurring failures of the sessions that ran in a project (the current directory by default),
// less those its CLAUDE.md already holds as accepted lessons.
function briefText(): string {
  const dir = projectDir() ?? process.cwd();
  const days = Number(opt('--days')) || 7;
  return brief(entriesOf(ledgersSince(dir, days), days), 3, 5, knownOf(dir)) ?? '';
}

// Failures that recur across sessions, numbered; `--accept 1,3` appends those rules to the project's CLAUDE.md
// (which also drops them from the brief), so the fix is told once rather than warned about every session.
const LESSONS_HEAD = '## Lessons from hush';
function lessonsText(): string {
  const dir = projectDir() ?? process.cwd();
  const days = Number(opt('--days')) || 30;
  const known = knownOf(dir);
  const ls = lessons(entriesOf(ledgersSince(dir, days), days), 2, 3, known);
  const accept = (opt('--accept') ?? '').split(',').map(Number).filter((n) => n >= 1 && n <= ls.length);
  if (accept.length) {
    const lines = accept.map((n) => `- ${ls[n - 1]?.rule}`);
    const head = known.includes(LESSONS_HEAD) ? '' : `${known && !known.endsWith('\n') ? '\n' : ''}\n${LESSONS_HEAD}\n\n`;
    appendFileSync(claudeMd(dir), `${head}${lines.join('\n')}\n`);
    return `added ${lines.length} to ${claudeMd(dir)}:\n${lines.join('\n')}`;
  }
  if (!ls.length) return `no failure recurred in 2+ sessions in ${dir} over ${days} days`;
  return [
    `failures recurring in ${dir} over ${days} days (accept with: hush lessons --project ${dir} --accept N[,N])`,
    ...ls.map((l, i) => `${i + 1}. ${l.rule} (×${l.n} in ${l.sessions} sessions)`),
  ].join('\n');
}

const CONFIG = process.env.CLAUDE_CONFIG_DIR || join(HOME, '.claude');
const jsonAt = (f: string): Record<string, unknown> => {
  try {
    return JSON.parse(readFileSync(f, 'utf8'));
  } catch {
    return {};
  }
};
function contextReport(): string {
  const settings = jsonAt(join(CONFIG, 'settings.json'));
  const plugins = Object.entries((settings.enabledPlugins ?? {}) as Record<string, boolean>).filter(([, on]) => on).map(([k]) => k.split('@')[0] ?? k);
  const servers = Object.keys((jsonAt(join(CONFIG, '.claude.json')).mcpServers ?? {}) as Record<string, unknown>);
  const skillsDir = join(CONFIG, 'skills');
  const skills = existsSync(skillsDir) ? readdirSync(skillsDir).filter((d) => existsSync(join(skillsDir, d, 'SKILL.md'))) : [];
  return contextAudit(pick(), { plugins, servers, skills });
}

function effectReport(): string {
  return effectText(ledgersSince(projectDir(), Number(opt('--days')) || 30).map((l) => sessionFacts(l.meta, l.loops)));
}

// One call from a harness with no ledger writer of its own (pi, OMP): the hook hands over what it saw,
// the row is built here so every harness's lines read alike.
function logCall(json: string) {
  const c = JSON.parse(json) as {
    session?: string; harness?: string; cwd?: string; id?: string; tool?: string; agentId?: string;
    input?: Record<string, unknown>; ok?: boolean; err?: string; ms?: number; at?: number; bytes?: number;
  };
  if (!c.session || !c.tool) throw new Error('hush log: session and tool are required');
  const args = c.input ?? {};
  const input = { ...args, file_path: args.file_path ?? args.path };
  const tool = PI_TOOLS[c.tool] ?? c.tool;
  const call = { tool, input, isRunning: false, isErrored: c.ok === false };
  const at = c.at ?? Date.now();
  const file = typeof input.file_path === 'string' && tool !== 'Grep' && tool !== 'Glob' ? [input.file_path] : [];
  const entry: LedgerEntry = {
    v: LEDGER_VERSION,
    session: c.session,
    id: c.id ?? `x${at}`,
    ...(c.agentId ? { agentId: c.agentId } : {}),
    tool,
    label: label(call),
    what: describe(call, c.cwd ?? '').slice(0, 200),
    at,
    ms: c.ms ?? 0,
    ok: c.ok !== false,
    bytes: c.bytes ?? 0,
    files: file,
    sig: hash(JSON.stringify(Object.entries(args))),
    ...(c.ok === false ? { err: (c.err ?? 'failed').slice(0, 200) } : {}),
  };
  const dir = join(LEDGER, c.session.replace(/[^\w.-]/g, '_'));
  mkdirSync(dir, { recursive: true, mode: 0o700 });
  if (!existsSync(join(dir, 'meta.json')))
    writeFileSync(join(dir, 'meta.json'), `${JSON.stringify({ v: LEDGER_VERSION, session: c.session, harness: c.harness ?? '?', cwd: c.cwd ?? '', startedAt: at })}\n`);
  appendFileSync(join(dir, loopFile(c.agentId)), `${JSON.stringify(entry)}\n`);
}

const ago = (ms: number) => {
  const s = Math.max(0, Math.round((Date.now() - ms) / 1000));
  return s < 60 ? `${s}s` : s < 3600 ? `${Math.round(s / 60)}m` : `${Math.round(s / 3600)}h`;
};

function boardLines(hours: number, rows: boolean): string[] {
  const out: string[] = [];
  for (const { dir, mtime } of ledgerSessions()) {
    if (mtime < Date.now() - hours * 3_600_000) break;
    const { meta, loops } = readLedger(dir);
    if (!meta) continue;
    const b = boardRow(meta, loops, Date.now());
    if (!b.calls) continue;
    const place = b.cwd.replace(HOME, '~');
    const fails = b.open.length ? ` · ${b.open.length} open ✗ ${b.open.at(-1)?.label ?? ''}` : '';
    const line = `${b.session.slice(0, 8)} ${place} · ${ago(b.last)} ago · ${b.hour} calls/h · ${b.agents} subagents${fails}`;
    out.push(rows ? `session\t${b.session}\t  ${b.open.length ? '✗' : '○'} ${line}` : line);
  }
  return out;
}

function analyzeText(): string {
  const ts = pick();
  const h = habits(ts);
  const p = project(ts);
  const s = savings(ts);
  const ideas = suggestions(h, p);
  const sec = (title: string, rows: [string, number][]) =>
    [`${title}:`, ...rows.map(([k, n]) => `  ${String(n).padStart(4)}  ${k}`)].join('\n');
  return [
    habitsText(h),
    `savings estimate: trim ~${s.trimTokens} tokens, re-read ~${s.rereadTokens}, ~${s.cacheReadTokensAvoided} cache-read tokens over later calls (of ~${s.resultTokens} in tool results)`,
    sec('edited most', p.edited),
    sec('code read most', p.read),
    sec('docs read most', p.docs),
    sec('failing most', p.failing),
    sec('skills', p.skills),
    sec('subagents', p.agents),
    'suggestions:',
    ...(ideas.length ? ideas.map((i) => `  - ${i}`) : ['  - none']),
  ].join('\n');
}

// ── Wiki (llm-wiki layout: raw/ sources, wiki/ pages the LLM owns, AGENTS.md schema) ──
const WIKI_SCHEMA = `# Personal wiki: schema

Maintained by an LLM agent; read in Obsidian (\`ob ~/wiki\`). Layout after
https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f

- \`raw/\` sources, never edited by the agent. \`raw/hush/\` holds weekly digests written by \`hush digest\`
  (habits, project hot spots, savings, suggestions); add clipped articles under \`raw/web/\`, notes under \`raw/notes/\`.
- \`wiki/\` pages the agent owns: \`wiki/projects/<name>.md\`, \`wiki/habits.md\`, \`wiki/tools/<tool>.md\`,
  \`wiki/concepts/<idea>.md\`. Every page links its sources (\`[[raw/hush/2026-W46]]\`) and related pages.
- \`index.md\` catalogs every wiki page with a one-line summary, by category; read it first.
- \`log.md\` is append-only: \`## [YYYY-MM-DD] ingest|query|lint|digest | title\`.

## Operations

- ingest <raw file>: summarize into the pages it touches (create missing ones), update index.md, append to log.md.
  A hush digest updates wiki/habits.md (trends, not copies), wiki/projects/<cwd name>.md (hot files, failing
  commands, decisions to propose) and wiki/tools/* (what hush, headroom, ponytail saved or cost).
- query <question>: answer from index.md and the pages, citing them; file a good answer back as a page.
- lint: contradictions, stale claims, orphan pages, suggestions in digests never acted on.

## Rules

- Personal and local: never copy secrets, tokens or customer data from transcripts; paths and counts only.
- Suggestions are proposals: a change to a repo's AGENTS.md or memory is made in that repo, by the user.
`;

function wikiInit() {
  for (const d of ['raw/hush', 'raw/web', 'raw/notes', 'wiki/projects', 'wiki/tools', 'wiki/concepts'])
    mkdirSync(join(WIKI, d), { recursive: true });
  if (!existsSync(join(WIKI, 'AGENTS.md'))) writeFileSync(join(WIKI, 'AGENTS.md'), WIKI_SCHEMA);
  if (!existsSync(join(WIKI, 'CLAUDE.md'))) writeFileSync(join(WIKI, 'CLAUDE.md'), '@AGENTS.md\n');
  if (!existsSync(join(WIKI, 'index.md')))
    writeFileSync(join(WIKI, 'index.md'), '# Index\n\n## Projects\n\n## Habits\n\n## Tools\n\n## Concepts\n');
  if (!existsSync(join(WIKI, 'log.md'))) writeFileSync(join(WIKI, 'log.md'), '# Log\n\n');
  console.log(`wiki at ${WIKI}`);
}

function isoWeek(d: Date): string {
  const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
  const day = t.getUTCDay() || 7;
  t.setUTCDate(t.getUTCDate() + 4 - day);
  const y = t.getUTCFullYear();
  const w = Math.ceil(((t.getTime() - Date.UTC(y, 0, 1)) / 86_400_000 + 1) / 7);
  return `${y}-W${String(w).padStart(2, '0')}`;
}

function digest() {
  wikiInit();
  const days = Number(opt('--days')) || 7;
  const since = Date.now() - days * 86_400_000;
  const dir = projectDir();
  const ts = transcripts()
    .filter((f) => f.mtime >= since && (!dir || isIn(cwdOf(f.file), dir)))
    .flatMap((f) => withSubagents(f.file));
  const h = habits(ts);
  const p = project(ts);
  const now = new Date();
  const week = isoWeek(now);
  const title = `hush digest ${week}${dir ? ` ${basename(dir)}` : ''}`;
  const name = `${week}${dir ? `-${basename(dir)}` : ''}.md`;
  const note = digestNote({
    title,
    date: now.toISOString().slice(0, 10),
    scope: dir ?? 'all',
    h,
    p,
    s: savings(ts),
    ideas: suggestions(h, p),
    lessons: lessons(entriesOf(ledgersSince(dir, days), days), 2, 3, dir ? knownOf(dir) : ''),
  });
  // A second run in a week rewrites the note; the log names it once.
  const isNew = !existsSync(join(WIKI, 'raw/hush', name));
  writeFileSync(join(WIKI, 'raw/hush', name), note);
  if (isNew) appendFileSync(join(WIKI, 'log.md'), `## [${now.toISOString().slice(0, 10)}] digest | ${title}\n\n`);
  console.log(join(WIKI, 'raw/hush', name));
}

// ── Retention ───────────────────────────────────────────────────────────────
// Session folders untouched for longer than their keep: trimmed outputs (the model only needs
// them while the session runs) and ledgers (digests keep what matters past that).
function gc() {
  const cacheDays = Number(opt('--cache-days')) || 14;
  const ledgerDays = Number(opt('--ledger-days')) || 90;
  let n = 0;
  for (const [root, days] of [[join(HOME, '.cache/hush'), cacheDays], [LEDGER, ledgerDays]] as const) {
    if (!existsSync(root)) continue;
    for (const d of readdirSync(root)) {
      const dir = join(root, d);
      // A folder's mtime does not move when a file in it is rewritten: the newest file decides.
      const newest = isDir(dir) ? newestIn(dir) : Infinity;
      // 0 is a folder that would not read: left alone, never taken for old.
      if (newest > 0 && newest < Date.now() - days * 86_400_000) {
        rmSync(dir, { recursive: true, force: true });
        n++;
      }
    }
  }
  // Who-edited-what records (the mod's edit-clash note): only the last weeks matter.
  const editing = `${LEDGER}-editing`;
  if (existsSync(editing))
    for (const f of readdirSync(editing)) if (mtimeOf(join(editing, f)) < Date.now() - cacheDays * 86_400_000) rmSync(join(editing, f), { force: true });
  console.log(`hush gc: ${n} old session folder${n === 1 ? '' : 's'} removed`);
}

// ── MCP (stdio, JSON-RPC 2.0, newline-delimited) ────────────────────────────
const MCP_TOOLS = [
  {
    name: 'trace',
    description:
      'Tool-call history of a coding-agent session from the hush ledger (latest session by default): what ran, failed, which files.',
    inputSchema: {
      type: 'object',
      properties: {
        session: { type: 'string' },
        failed: { type: 'boolean' },
        file: { type: 'string' },
        label: { type: 'string' },
        agent: { type: 'string' },
        last: { type: 'number' },
      },
    },
  },
  {
    name: 'tree',
    description: 'Span tree of a session: turns, calls, subagents folded to one summary row each.',
    inputSchema: { type: 'object', properties: { session: { type: 'string' }, full: { type: 'boolean' } } },
  },
  {
    name: 'board',
    description: 'Agent sessions active in the last hours across projects and worktrees, with open failures.',
    inputSchema: { type: 'object', properties: { hours: { type: 'number' } } },
  },
  {
    name: 'analyze',
    description:
      'Habits, project hot spots, savings estimate and suggestions over recent transcripts (Claude Code, pi, OMP).',
    inputSchema: { type: 'object', properties: { recent: { type: 'number' }, project: { type: 'string' } } },
  },
];

function mcpCall(name: string, a: Record<string, unknown>): string {
  if (name === 'trace') return traceText(a);
  if (name === 'tree') {
    const { meta, loops } = readLedger(ledgerDir(typeof a.session === 'string' ? a.session : undefined));
    return tree(meta, loops, a.full === true).join('\n');
  }
  if (name === 'board')
    return boardLines(typeof a.hours === 'number' ? a.hours : 6, false).join('\n') || 'no active sessions';
  if (name === 'analyze') {
    rest.length = 0;
    if (typeof a.recent === 'number') rest.push('--recent', String(a.recent));
    if (typeof a.project === 'string') rest.push('--project', a.project);
    positional.length = 0;
    return analyzeText();
  }
  throw new Error(`unknown tool ${name}`);
}

function mcp() {
  let buf = '';
  const send = (m: unknown) => process.stdout.write(`${JSON.stringify(m)}\n`);
  process.stdin.setEncoding('utf8');
  process.stdin.on('data', (chunk) => {
    buf += chunk;
    for (let i = buf.indexOf('\n'); i >= 0; i = buf.indexOf('\n')) {
      const line = buf.slice(0, i).trim();
      buf = buf.slice(i + 1);
      if (!line) continue;
      let msg: { id?: number | string; method?: string; params?: Record<string, unknown> };
      try {
        msg = JSON.parse(line);
      } catch {
        continue;
      }
      if (!msg || typeof msg !== 'object' || msg.id === undefined) continue; // notifications and junk
      const reply = (result: unknown) => send({ jsonrpc: '2.0', id: msg.id, result });
      if (msg.method === 'initialize')
        reply({
          protocolVersion: msg.params?.protocolVersion ?? '2025-06-18',
          capabilities: { tools: {} },
          serverInfo: { name: 'hush', version: '0.8.0' },
        });
      else if (msg.method === 'tools/list') reply({ tools: MCP_TOOLS });
      else if (msg.method === 'tools/call') {
        const p = msg.params as { name?: string; arguments?: Record<string, unknown> };
        try {
          reply({ content: [{ type: 'text', text: mcpCall(String(p.name), p.arguments ?? {}) }] });
        } catch (err) {
          reply({ content: [{ type: 'text', text: String(err) }], isError: true });
        }
      } else if (msg.method === 'ping') reply({});
      else send({ jsonrpc: '2.0', id: msg.id, error: { code: -32601, message: `no method ${msg.method}` } });
    }
  });
}

// process.exit would cut a pipe mid-write (`hush tree x | head`): a closed stdout just ends.
process.stdout.on('error', () => process.exit(0));

try {
switch (cmd) {
  case 'replay': {
    if (!positional[0]) {
      console.error('usage: hush replay <session|file> [--agents] [--previews N] [--text] [--no-color]');
      process.exit(2);
    }
    const file = resolve(positional[0]);
    replay(file, '', flag('--agents') ? subagentsOf(file) : new Map());
    break;
  }
  case 'stats': {
    const ts = pick();
    const s = savings(ts);
    console.log(habitsText(habits(ts)));
    console.log(
      `savings estimate: trim ~${s.trimTokens} tokens, re-read ~${s.rereadTokens}, ~${s.cacheReadTokensAvoided} cache-read tokens over later calls`,
    );
    break;
  }
  case 'analyze':
    console.log(analyzeText());
    break;
  case 'trace':
    console.log(
      traceText({
        session: opt('--session'),
        failed: flag('--failed'),
        file: opt('--file'),
        label: opt('--label'),
        agent: opt('--agent'),
        last: Number(opt('--last')) || undefined,
      }),
    );
    break;
  case 'tree': {
    const { meta, loops } = readLedger(ledgerDir(positional[0]));
    console.log(tree(meta, loops, flag('--full')).join('\n'));
    break;
  }
  case 'board':
    console.log(boardLines(Number(opt('--hours')) || 6, flag('--rows')).join('\n'));
    break;
  case 'digest':
    digest();
    gc();
    break;
  case 'gc':
    gc();
    break;
  case 'brief': {
    const text = briefText();
    if (text) console.log(text);
    break;
  }
  case 'lessons':
    console.log(lessonsText());
    break;
  case 'effect':
    console.log(effectReport());
    break;
  case 'context':
    console.log(contextReport());
    break;
  case 'corrections':
    console.log(corrections(pick()).join('\n') || 'no corrections in these sessions');
    break;
  case 'refusals': {
    const days = Number(opt('--days')) || 30;
    const rows = refusals(entriesOf(ledgersSince(projectDir(), days), days));
    console.log(rows.length ? [...rows, '', 'Read-only commands you keep approving by hand: run /fewer-permission-prompts in Claude Code.'].join('\n') : 'no refusals');
    break;
  }
  case 'log':
    logCall(rest[0] ?? '');
    break;
  case 'wiki':
    if (positional[0] === 'init') wikiInit();
    else console.error('usage: hush wiki init');
    break;
  case 'mcp':
    mcp();
    break;
  default:
    console.log(
      readFileSync(new URL(import.meta.url), 'utf8')
        .split('\n')
        .slice(1)
        .filter((l, i, all) => all.slice(0, i + 1).every((x) => x.startsWith('//')))
        .map((l) => l.replace(/^\/\/ ?/, ''))
        .join('\n'),
    );
}
} catch (err) {
  console.error(err instanceof Error ? err.message : String(err));
  process.exit(1);
}
