import { atom, read, update } from 'claude-code'
import type { EngineInterface, Events, Register } from 'claude-code'

import { cleanOutput, compactFacts, conflictNote, hash, isBounded, isReadLike, loopNote, queryTrace, recapOf, repeatNote, reportsNote, routeRead, runawayNote, tidyOutput, TRIM, TRIM_READ, trimOutput, turnStats } from '../core/agent.ts'
import type { CallEntry, EditClaim } from '../core/agent.ts'
import { describe, label, str } from '../core/format.ts'
import { capByLoop, LEDGER_VERSION, ledgerRoot, loopFile } from '../core/ledger.ts'
import type { LedgerEntry } from '../core/ledger.ts'
import { isOn, TOGGLES_INITIAL } from './toggles'
import type { Toggle, Toggles } from '../types'

type On = Parameters<Register>[0]
type ToolCallHook = Events['tool.call']

const toggles = atom({ plugin: 'hush', key: 'toggles' } as const, TOGGLES_INITIAL)
const trace = atom({ plugin: 'hush', key: 'trace' } as const, [])
const saved = atom({ plugin: 'hush', key: 'saved' } as const, {})
const pendingRecap = atom({ plugin: 'hush', key: 'pendingRecap' } as const, false)
const turnFrom = atom({ plugin: 'hush', key: 'turnFrom' } as const, 0)
const lastTurn = atom({ plugin: 'hush', key: 'lastTurn' } as const, null)

export const TRACE_TOOL = 'mcp__hush__trace'
const DESCRIBE_NOTE = 'hush: give Bash calls a short `description`; the user sees it as the tool row instead of the raw command.'

// Envelope and prose keys a call's identity leaves out: the same command with a new description is the same call.
const EDIT_TOOLS = new Set(['Edit', 'Write', 'NotebookEdit', 'MultiEdit'])
const SIG_SKIP = new Set(['tool', 'tool_use_id', 'agentId', 'requestMeta', 'consent', 'description'])

// Reads already in the model's context: path+range → content fingerprint and when.
// Plain memory: a reload, a compaction or /clear forgets it, so a dedupe never points at text the model lost.
const reads = new Map<string, { hash: string; at: number }>()
// When each loop ('' main) last compacted: searches before it are no longer in context.
const compacted = atom({ plugin: 'hush', key: 'compactedAt' } as const, {})
// Loops already asked once for Bash descriptions ('' is the main loop).
const nudged = new Set<string>()
// Subagent loops that compacted: their next call carries their own recap.
const pendingSub = new Set<string>()
// What the ledger says keeps failing in this project (`hush brief`), read once at session start;
// the main loop gets it in its prompt, each subagent with its first call.
let briefText: string | null = null
const briefed = new Set<string>()
export const briefSection = () => (heldOut === 'brief' ? null : briefText)

// To measure hush (`hush effect`), one session in five runs with one of these off, named in meta.json.
const HOLDOUT: Toggle[] = ['trim', 'guards', 'route', 'brief']
let heldOut: Toggle | null = null
const pickHoldout = (t: Toggles): Toggle | null =>
  isOn(t, 'holdout') && Math.random() < 0.2 ? (HOLDOUT[Math.floor(Math.random() * HOLDOUT.length)] ?? null) : null
// A toggle as this session runs it: on, and not the one held out.
const live = (t: Toggles, k: Toggle) => k !== heldOut && isOn(t, k)

// A reload or resume keeps the session's holdout; a new session draws one. A meta.json from before
// holdouts existed means none was drawn.
async function settleHoldout($: EngineInterface) {
  heldOut = null
  // No ledger, nothing would record the holdout: run everything.
  const dir = await ledgerDirOf($)
  if (!dir) return
  const old = await $.fs.read(`${dir}/meta.json`).then(t => JSON.parse(String(t)) as { heldOut?: Toggle | null }, () => null)
  heldOut = old ? (old.heldOut ?? null) : pickHoldout(await read($, toggles))
}

// Calls per loop since its run began ('' main: since the turn began), and whether it was warned.
const runs = new Map<string, { n: number; first: number; warned: boolean }>()

// The last editor of each file, across sessions: ~/.local/state/hush-editing/<hash>.json.
// `hush gc` drops records older than the trimmed-output keep (14 days).
async function claimEdit($: EngineInterface, path: string, owner: string): Promise<string | null> {
  const dir = await ledgerDirOf($)
  if (!dir) return null
  const f = `${dir.slice(0, dir.lastIndexOf('/'))}-editing/${hash(path).replace(/[^\w-]/g, '_')}.json`
  const prev = await $.fs.read(f).then(t => JSON.parse(String(t)) as EditClaim, () => null)
  const now = Date.now()
  await $.fs.write(f, JSON.stringify({ owner, at: now, path } satisfies EditClaim)).catch(() => undefined)
  return conflictNote(prev, owner, now)
}

// Subagent reports this process saw, by agent id: the task (from its Agent call) and the whole report on disk.
const reports = new Map<string, { what?: string; path: string }>()

async function loadBrief($: EngineInterface) {
  briefText = null
  const cwd = await $.session.cwd().catch(() => '')
  if (!cwd) return
  const r = await $.process.run(['node', `${$.plugin.root}/bin/hush.ts`, 'brief', '--project', cwd], { timeoutMs: 4000 })
  if (r.exitCode === 0 && r.stdout.trim()) briefText = r.stdout.trim().slice(0, 1200)
}
// The main turn now running (turn.start's id), stamped on each ledger line.
const turnState = atom({ plugin: 'hush', key: 'turnState' } as const, { id: null, savedAtStart: 0 })
// Ledger dirs whose meta.json this process has written (after /clear a new session id needs its own).
const metaDirs = new Set<string>()
// Ledger files this process writes, by `dir|loop`: opened once (the highest part read back, so a
// reload continues it), then every write for that key is chained so parallel calls never race.
// shortcut: a write rewrites the part ($.fs has no append); parts roll at PART_BYTES, under $.fs's 4 MiB.
type LedgerFile = { lines: string[]; size: number; part: number; isBroken: boolean }
const ledgerFiles = new Map<string, Promise<LedgerFile>>()
const ledgerChains = new Map<string, Promise<void>>()
// UTF-8 bytes, as $.fs counts its 4 MiB limit (a String's length counts UTF-16 units).
const PART_BYTES = 3_000_000
function utf8Bytes(s: string): number {
  let n = 0
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i)
    n += c < 0x80 ? 1 : c < 0x800 ? 2 : c >= 0xd800 && c < 0xdc00 ? (i++, 4) : 3
  }
  return n
}
const partPath = (dir: string, loop: string, part: number) => `${dir}/${loop}${part > 1 ? `.${part}` : ''}.jsonl`

async function openLedger($: EngineInterface, dir: string, loop: string): Promise<LedgerFile> {
  let part = 1
  while (await $.fs.exists(partPath(dir, loop, part + 1)).catch(() => false)) part++
  const path = partPath(dir, loop, part)
  if (!(await $.fs.exists(path).catch(() => false))) return { lines: [], size: 0, part, isBroken: false }
  try {
    const text = await $.fs.read(path)
    const t = typeof text === 'string' ? text : ''
    return { lines: t.split('\n').filter(l => l.trim()), size: utf8Bytes(t), part, isBroken: false }
  } catch {
    // An existing part that will not read (too big, damaged): left as it is; writing goes on in the next part.
    const next = part + 1
    return (await $.fs.exists(partPath(dir, loop, next)).catch(() => true))
      ? { lines: [], size: 0, part, isBroken: true }
      : { lines: [], size: 0, part: next, isBroken: false }
  }
}

async function writeLedgerLine($: EngineInterface, file: Promise<LedgerFile>, dir: string, loop: string, entry: LedgerEntry) {
  const f = await file
  if (f.isBroken) return
  const line = JSON.stringify(entry)
  const bytes = utf8Bytes(line) + 1
  if (f.size + bytes > PART_BYTES && f.lines.length) {
    f.part++
    f.lines = []
    f.size = 0
  }
  f.lines.push(line)
  f.size += bytes
  try {
    await $.fs.write(partPath(dir, loop, f.part), `${f.lines.join('\n')}\n`)
  } catch {
    // A refused write leaves the file as it was; the line goes, so the next write is not refused for it too.
    f.lines.pop()
    f.size -= bytes
  }
}

async function ledgerDirOf($: EngineInterface): Promise<string | null> {
  const home = await homeOf($)
  if (!home) return null
  let state: string | undefined
  try {
    state = await $.env.get('XDG_STATE_HOME')
  } catch {
    state = undefined
  }
  return `${ledgerRoot(home, state)}/${await sessionIdOf($)}`
}

async function appendLedger($: EngineInterface, entry: LedgerEntry) {
  const dir = await ledgerDirOf($)
  if (!dir) return
  const loop = loopFile(entry.agentId).replace(/\.jsonl$/, '')
  if (!metaDirs.has(dir)) {
    metaDirs.add(dir)
    await writeMeta($).catch(() => undefined)
  }
  const key = `${dir}|${loop}`
  let file = ledgerFiles.get(key)
  if (!file) {
    file = openLedger($, dir, loop)
    ledgerFiles.set(key, file)
  }
  const f = file
  const done = (ledgerChains.get(key) ?? Promise.resolve()).then(() => writeLedgerLine($, f, dir, loop, entry)).catch(() => undefined)
  ledgerChains.set(key, done)
  await done
}

async function writeMeta($: EngineInterface) {
  const dir = await ledgerDirOf($)
  if (!dir) return
  const cwd = await $.session.cwd().catch(() => '')
  const meta = { v: LEDGER_VERSION, session: await sessionIdOf($), harness: 'claude', cwd, startedAt: Date.now(), heldOut }
  const old = await $.fs.read(`${dir}/meta.json`).then(t => (typeof t === 'string' ? t : ''), () => '')
  if (!old) await $.fs.write(`${dir}/meta.json`, `${JSON.stringify(meta)}\n`).catch(() => undefined)
}

// Each turn's tokens added to meta.json, chained so turns ending together never lose one.
let usageChain: Promise<void> = Promise.resolve()
type TokenCounts = { input_tokens: number; output_tokens: number; cache_read_input_tokens: number; cache_creation_input_tokens: number }
async function addUsage($: EngineInterface, u: TokenCounts) {
  const dir = await ledgerDirOf($)
  if (!dir) return
  usageChain = usageChain.then(async () => {
    metaDirs.add(dir)
    await writeMeta($)
    const m = JSON.parse(String(await $.fs.read(`${dir}/meta.json`))) as { usage?: { input: number; output: number; cacheRead: number; cacheWrite: number } }
    const o = m.usage ?? { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 }
    m.usage = { input: o.input + (u.input_tokens || 0), output: o.output + (u.output_tokens || 0), cacheRead: o.cacheRead + (u.cache_read_input_tokens || 0), cacheWrite: o.cacheWrite + (u.cache_creation_input_tokens || 0) }
    await $.fs.write(`${dir}/meta.json`, `${JSON.stringify(m)}\n`)
  }).catch(() => undefined)
  await usageChain
}

// A turn's end: its tokens into meta.json and, for a subagent, its report kept whole on disk.
async function recordTurn($: EngineInterface, e: { agentId?: string; answer?: string; usage?: TokenCounts }) {
  if (!isOn(await read($, toggles), 'trace')) return
  if (e.usage) await addUsage($, e.usage)
  if (!e.agentId || !e.answer?.trim()) return
  const home = await homeOf($)
  if (!home) return
  const path = `${home}/.cache/hush/${await sessionIdOf($)}/agent-${e.agentId.replace(/[^\w.-]/g, '_')}.md`
  if (await $.fs.write(path, e.answer).then(() => true, () => false)) reports.set(e.agentId, { ...reports.get(e.agentId), path })
}

// Characters saved when the main turn started, so a turn reports its own.
const total = (s: Record<string, number>) => Object.values(s).reduce((a, b) => a + b, 0)

// The line that says what went wrong: past a bare `Exit code N`, which every failing command shares.
function errLine(r: { text?: string; result?: unknown; deny?: string }): string | undefined {
  const text = r.deny ?? r.text ?? (typeof r.result === 'string' ? r.result : JSON.stringify(r.result ?? ''))
  // Tags and rules (a front matter's `---`) say nothing about what went wrong.
  const lines = text.split('\n').map(l => l.replace(/<\/?tool_use_error>/g, '').trim()).filter(l => l && !/^[-=*_#~`]+$/.test(l))
  const said = lines.find(l => !/^Exit code \d+$/.test(l)) ?? lines[0]
  return said?.slice(0, 200)
}

function filesOf(e: Record<string, unknown>): string[] {
  const f = str(e.file_path) ?? str(e.notebook_path) ?? (e.tool === 'Grep' || e.tool === 'Glob' ? undefined : str(e.path))
  return f ? [f] : []
}

async function addSaved($: EngineInterface, rule: string, n: number) {
  if (n > 0) await update($, saved, s => ({ ...s, [rule]: (s[rule] ?? 0) + n })).catch(() => undefined)
}

// Where trimmed output goes whole: ~/.cache/hush/<session>/<call>.txt (outside the repo).
// `hush gc` (run by each digest) drops session folders older than 14 days.
async function homeOf($: EngineInterface): Promise<string | undefined> {
  try {
    return await $.env.get('HOME')
  } catch {
    return undefined // a host without env access (tests): the session's directory instead
  }
}

async function sessionIdOf($: EngineInterface): Promise<string> {
  try {
    return await $.session.id()
  } catch {
    return 'session'
  }
}

let isTraceRegistered = false
async function ensureTraceTool($: EngineInterface, left = 20): Promise<void> {
  if (isTraceRegistered) return
  try {
    await $.tool.register({
      name: 'trace',
      description:
        "Your own tool-call history in this session (main loop and subagents): what ran, how long, what failed and with which error, which files were read or edited. Use it after a compaction or before re-running a command or re-reading a file, instead of repeating the call.",
      inputSchema: {
        type: 'object',
        properties: {
          failed: { type: 'boolean', description: 'only failed calls' },
          file: { type: 'string', description: 'calls touching a path containing this text' },
          label: { type: 'string', description: 'tool or row label, e.g. Read, Edit, GIT, PNPM' },
          agent: { type: 'string', description: '"main" or a subagent id' },
          last: { type: 'number', description: 'how many rows (default 40)' },
        },
      },
    })
    isTraceRegistered = true
  } catch {
    if (left > 0) $.clock.after(1000, () => void ensureTraceTool($, left - 1))
  }
}


// Called from the mod's own session.start (one unmatched hook per event).
export async function startAgent($: EngineInterface) {
  reads.clear()
  nudged.clear()
  ledgerFiles.clear()
  ledgerChains.clear()
  routedReads.clear()
  pendingSub.clear()
  briefed.clear()
  reports.clear()
  runs.clear()
  await settleHoldout($).catch(() => undefined)
  await ensureTraceTool($)
  // The brief is a convenience: no ledger, no node, a slow disk all leave the session without one.
  await loadBrief($).catch(() => undefined)
}

// The recap a prompt carries after a compaction, once; null otherwise.
export async function recapContext($: EngineInterface): Promise<string | null> {
  if (!(await read($, pendingRecap))) return null
  await update($, pendingRecap, () => false)
  return [recapOf(await read($, trace)), reportsNote([...reports.values()])].filter(Boolean).join('\n\n') || null
}

// Whole-file reads of big files already pointed at an outline once (loop|path): the repeat passes.
const routedReads = new Set<string>()

// A call worth redirecting before it runs: a refusal naming the cheaper way, once per target.
async function routeFirst($: EngineInterface, e: Parameters<ToolCallHook>[1]): Promise<string | null> {
  if (e.tool !== 'Read' || !live(await read($, toggles), 'route')) return null
  const i = e as unknown as Record<string, unknown>
  const path = str(i.file_path)
  if (!path) return null
  const key = `${e.agentId ?? ''}|${path}`
  if (routedReads.has(key)) return null
  const st = await $.fs.stat(path).catch(() => null)
  const msg = st?.kind === 'file' ? routeRead(path, st.size, i.offset !== undefined || i.limit !== undefined || i.pages !== undefined) : null
  if (msg) routedReads.add(key)
  return msg
}

// Runs the call (`next`) and returns its result as the model should read it: logged in the
// ledger, with notes (description, loop guard, recap), long Bash output trimmed and
// unchanged re-reads pointed at. Called from the mod's own tool.call hook.
export async function traceCall($: EngineInterface, e: Parameters<ToolCallHook>[1], next: Parameters<ToolCallHook>[2]) {
  if ((e.tool as string) === TRACE_TOOL) return next(e)
  const routed = await routeFirst($, e).catch(() => null)
  if (routed) return { deny: routed }
  const t0 = Date.now()
  const r = await next(e)
  // The tool has run: whatever fails from here hands back its own result, never a second run.
  try {
    return await afterCall($, e, r, t0)
  } catch {
    return r
  }
}

type CallResult = Awaited<ReturnType<Parameters<ToolCallHook>[2]>>

// A result with notes added: `ref` dropped, since core takes a result carrying it verbatim
// and would send the model the original without the notes.
function withNotes(r: CallResult, context: readonly string[] | undefined): CallResult {
  // An errored result's `result` is the error text: without `ref` core validates it against the tool's output schema
  // and the model gets "does not match its output shape" in place of the command's output. Keep it whole.
  if (r.isError) return { ...r, context } as CallResult
  const { ref: _ref, ...rest } = r as CallResult & { ref?: number }
  void _ref
  return { ...rest, context } as CallResult
}

async function afterCall($: EngineInterface, e: Parameters<ToolCallHook>[1], r: CallResult, t0: number): Promise<CallResult> {
    const t = await read($, toggles)
    const input = e as unknown as Record<string, unknown>
    const call = { tool: e.tool, input, isRunning: false, isErrored: !!(r.deny !== undefined || r.isError) }
    const root = await $.session.cwd().catch(() => '')
    const entry: CallEntry = {
      id: e.tool_use_id ?? `x${t0}`,
      ...(e.agentId ? { agentId: e.agentId } : {}),
      tool: e.tool,
      label: label(call),
      // Capped so mcp__hush__trace stays small; the row truncates to the screen anyway.
      what: describe(call, root).slice(0, 200),
      at: t0,
      ms: Date.now() - t0,
      ok: !call.isErrored,
      bytes: (r.text ?? '').length,
      files: filesOf(input),
      sig: hash(JSON.stringify(Object.entries(input).filter(([k]) => !SIG_SKIP.has(k)))),
      ...(call.isErrored ? { err: errLine(r) ?? 'failed' } : {}),
      ...(r.deny !== undefined ? { denied: true } : {}),
    }
    let all: CallEntry[] = []
    if (isOn(t, 'trace')) {
      await update($, trace, now => (all = capByLoop([...now, entry]))).catch(() => undefined)
      const spawned = e.tool === 'Agent' ? str((r.result as Record<string, unknown> | undefined)?.agentId) : undefined
      if (spawned) reports.set(spawned, { path: '', ...reports.get(spawned), what: entry.what })
      const turn = e.agentId ? undefined : ((await read($, turnState)).id ?? undefined)
      const line: LedgerEntry = { v: LEDGER_VERSION, session: await sessionIdOf($), ...(turn ? { turn } : {}), ...entry, ...(spawned ? { spawned } : {}) }
      await appendLedger($, line).catch(() => undefined)
    }
    if (r.deny !== undefined) return r

    const notes: string[] = []
    const loop = e.agentId ?? ''
    if (e.tool === 'Bash' && !str(input.description) && !nudged.has(loop)) {
      nudged.add(loop)
      notes.push(DESCRIBE_NOTE)
    }
    if (live(t, 'guards') && all.length) {
      const note = loopNote(all, entry) ?? repeatNote(all, entry, (await read($, compacted))[loop] ?? 0)
      if (note) notes.push(note)
    }
    if (live(t, 'guards')) {
      const c = runs.get(loop) ?? { n: 0, first: t0, warned: false }
      c.n++
      runs.set(loop, c)
      const note = c.warned ? null : runawayNote(c.n, Date.now() - c.first, !!e.agentId)
      if (note) {
        c.warned = true
        notes.push(note)
      }
      const file = entry.ok && EDIT_TOOLS.has(e.tool) ? entry.files[0] : undefined
      const clash = file ? await claimEdit($, file, `${await sessionIdOf($)}|${loop}`).catch(() => null) : null
      if (clash) notes.push(clash)
    }
    if (!e.agentId && (await read($, pendingRecap))) {
      await update($, pendingRecap, () => false)
      const recap = recapOf(all.length ? all : await read($, trace))
      if (recap) notes.push(recap)
      const kept = reportsNote([...reports.values()])
      if (kept) notes.push(kept)
    }
    if (e.agentId && pendingSub.delete(e.agentId)) {
      const recap = recapOf(all.length ? all : await read($, trace), e.agentId)
      if (recap) notes.push(recap)
    }
    if (e.agentId && briefText && !briefed.has(e.agentId) && live(t, 'brief')) {
      briefed.add(e.agentId)
      notes.push(briefText)
    }
    const context = notes.length ? [...(r.context ?? []), ...notes] : r.context
    if (r.isError || !live(t, 'trim')) return notes.length ? withNotes(r, context) : r

    // A Bash result too long for its use: tidied, then head and tail with the whole on disk.
    if (e.tool === 'Bash') {
      const o = r.result as Record<string, unknown>
      const command = str(input.command) ?? ''
      if (o && typeof o.stdout === 'string' && !o.backgroundTaskId && !o.persistedOutputPath && !o.rawOutputPath && !o.isImage) {
        const bounded = isBounded(command)
        // Colour codes and redraws go always; anything lossier only when the whole is saved.
        let out = cleanOutput(o.stdout)
        if (!bounded) {
          const sid = await sessionIdOf($)
          const home = (await homeOf($)) ?? root
          const path = `${home}/.cache/hush/${sid}/${entry.id}.txt`
          const cut = trimOutput(tidyOutput(o.stdout), path, isReadLike(command) ? TRIM_READ : TRIM)
          // The whole output is cut only once it is safe on disk.
          if (cut && (await $.fs.write(path, o.stdout).then(() => true, () => false))) out = cut
        }
        if (out.length < o.stdout.length) {
          void addSaved($, 'trim', o.stdout.length - out.length)
          return { result: { ...o, stdout: out } as never, ...(context ? { context } : {}) }
        }
      }
    }

    // A read of a range already in context with the same content: a pointer, not the text again.
    if (e.tool === 'Read') {
      const o = r.result as { type?: string; file?: { content?: string } }
      const content = o?.type === 'text' ? o.file?.content : undefined
      if (typeof content === 'string' && content.length > 400) {
        const key = `${loop}|${str(input.file_path)}|${input.offset ?? ''}|${input.limit ?? ''}|${input.pages ?? ''}`
        const h = hash(content)
        const seen = reads.get(key)
        // One pointer per range: a read again after it means the model needs the text back.
        if (seen?.hash === h) reads.delete(key)
        else reads.set(key, { hash: h, at: t0 })
        if (seen?.hash === h) {
          const mins = Math.max(1, Math.round((t0 - seen.at) / 60000))
          const text = `[hush: unchanged since your read of this range ${mins}m ago; that text is still in your context above.]`
          void addSaved($, 'read', content.length - text.length)
          return { result: { ...o, file: { ...o.file, content: text } } as never, ...(context ? { context } : {}) }
        }
      }
    }
    return notes.length ? withNotes(r, context) : r
}

// Ledger, trimming, read dedupe, loop guard, compaction recap and per-turn stats.
export function registerAgent(on: On) {

  on('tool.call', { tool: /^mcp__hush__trace$/ }, async ($, e) => {
    const q = e as unknown as Record<string, unknown>
    const text = queryTrace(await read($, trace), {
      failed: q.failed === true,
      file: str(q.file),
      // `tool` is the envelope's own field (this tool's name), so the filter is `label`.
      tool: str(q.label),
      agent: str(q.agent),
      last: typeof q.last === 'number' ? q.last : undefined,
    }, Date.now())
    return { result: [{ type: 'text', text }] as never }
  })

  // /clear goes on under a new session id with no session.start: everything this process knew
  // about the old context is wrong for the new one.
  on('session.end', async ($, e, next) => {
    if (e.reason === 'clear') {
      reads.clear()
      routedReads.clear()
      nudged.clear()
      pendingSub.clear()
      briefed.clear()
      reports.clear()
      runs.clear()
      heldOut = pickHoldout(await read($, toggles).catch(() => TOGGLES_INITIAL))
      ledgerFiles.clear()
      ledgerChains.clear()
      metaDirs.clear()
      await update($, compacted, () => ({})).catch(() => undefined)
      await update($, turnState, () => ({ id: null, savedAtStart: 0 })).catch(() => undefined)
      await update($, trace, () => []).catch(() => undefined)
      await update($, pendingRecap, () => false).catch(() => undefined)
    }
    return next(e)
  })

  // A compaction drops the reads the model saw and the history it kept in mind.
  on('session.compact', async ($, e, next) => {
    // The summary is told what the ledger knows, so less depends on the recap afterwards.
    const facts = isOn(await read($, toggles), 'trace') ? compactFacts(await read($, trace), e.agentId, [...reports.values()]) : null
    const r = await next(facts ? { ...e, instructions: [e.instructions, facts].filter(Boolean).join('\n\n') } : e)
    // `precompute` prepares a summary ahead of time; nothing is dropped until a real one.
    if (e.trigger === 'precompute' || !r.messages) return r
    const loop = e.agentId ?? ''
    // The loop's reads and searches are gone from its context, whatever the toggles.
    for (const k of [...reads.keys()]) if (k.startsWith(`${loop}|`)) reads.delete(k)
    await update($, compacted, c => ({ ...c, [loop]: Date.now() })).catch(() => undefined)
    if (!isOn(await read($, toggles), 'trace')) return r
    if (e.agentId) pendingSub.add(e.agentId)
    else await update($, pendingRecap, () => true).catch(() => undefined)
    return r
  })

  // Main-loop turns only: a subagent's turn would restamp the main loop's ledger lines and stats.
  on('turn.start', async ($, e, next) => {
    if ((e as { agentId?: string }).agentId) return next(e)
    runs.delete('')
    await update($, turnFrom, () => Date.now()).catch(() => undefined)
    const savedAtStart = total(await read($, saved))
    await update($, turnState, () => ({ id: e.turnId, savedAtStart })).catch(() => undefined)
    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    await recordTurn($, e).catch(() => undefined)
    if ((e as { agentId?: string }).agentId) return next(e)
    const from = await read($, turnFrom)
    const mine = (await read($, trace)).filter(x => x.at >= from)
    if (mine.length) {
      const s = total(await read($, saved)) - (await read($, turnState)).savedAtStart
      await update($, lastTurn, () => turnStats(mine, s)).catch(() => undefined)
    }
    return next(e)
  })
}
