import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, ThemeKey } from 'claude-code'

import type { Backgrounds, Mode, Target, Toggle, Toggles } from '../types'
import { capRows, compactDiff, groupMatches, jsonToToon, mcpPreview, mentions, outline, toToon, touched } from '../core/format.ts'
import { args, base, describe, label, str } from '../core/format.ts'
import type { Call } from '../core/format.ts'
import type { DiffRow } from '../core/format.ts'
import { kb, turnLine } from '../core/agent.ts'
import { isOn, TOGGLES_INITIAL } from './toggles'
import { briefSection, recapContext, registerAgent, startAgent, traceCall } from './agent-register'

const MODES: Mode[] = ['cards', 'lines', 'group']
const PREVIEW_LINES = 5
const MIN_LABEL = 5
const PANE = 'hush'
const THOUGHT_ROWS = 3
const OUTLINE_LINES = 8

const mode = atom({ plugin: 'hush', key: 'mode' } as const, 'lines', {
  shape: 'mode-1',
})
const toggles = atom({ plugin: 'hush', key: 'toggles' } as const, TOGGLES_INITIAL)
const trace = atom({ plugin: 'hush', key: 'trace' } as const, [])
const saved = atom({ plugin: 'hush', key: 'saved' } as const, {})
const lastTurn = atom({ plugin: 'hush', key: 'lastTurn' } as const, null)
const lastPrompt = atom({ plugin: 'hush', key: 'lastPrompt' } as const, null)
const thought = atom({ plugin: 'hush', key: 'thought' } as const, null)
const expanded = atom({ plugin: 'hush', key: 'expanded' } as const, [])
const narration = atom({ plugin: 'hush', key: 'narration' } as const, [])
const finals = atom({ plugin: 'hush', key: 'finals' } as const, [])
// Kept short: a tall unfolded block repaints whole under a moving pointer.
const OPEN_LINES = 60
// From this many rows an unfolded block gets a second fold control at its end.
const TAIL_CONTROL_AT = 12
const KEEP_NARRATION = 200
// Read by the model: in-between text stays a status line; what matters lands in the reply.
// Read by the model: Bash rows show the description; without one they fall back to the command.
const DESCRIBE_RULE = 'Give every Bash call a short `description` in plain words: the user sees it as the tool row instead of the command.'
const NARRATION_RULE = [
  'Text you write between tool calls is shown to the user folded to one line.',
  'Keep it to one short status sentence, or nothing.',
  'Put every finding, decision, result and open question in your final message after the last tool call,',
  'and cite the places it comes from as path:line so the user can open them.',
].join(' ')
const backgrounds = atom({ plugin: 'hush', key: 'backgrounds' } as const, {})
const DIFF_LINES = 12


// Dark tints; any `#rrggbb` is taken as it is.
// shortcut: no light-theme variants; upgrade when a light theme is in use.
const PRESETS: Record<string, string> = {
  slate: '#1e2430', blue: '#14213d', green: '#13261b', amber: '#2b2210', purple: '#241a33', rose: '#2e1820',
}
const PRESET_NAMES = ['off', ...Object.keys(PRESETS)]
const TARGETS: { key: Target; hotkey: string; title: string }[] = [
  { key: 'assistant', hotkey: 'a', title: 'Replies' },
  { key: 'tool', hotkey: 'o', title: 'Tool rows' },
]
const HEX = /^#[0-9a-f]{6}$/i
const bgOf = (b: Backgrounds, k: Target) => {
  const v = b[k]
  return v && HEX.test(v) ? v : v && Object.hasOwn(PRESETS, v) ? PRESETS[v] : undefined
}

const TOGGLES: { key: Toggle; hotkey: string; title: string; hint: string }[] = [
  { key: 'prompt', hotkey: 'p', title: 'Last prompt', hint: '❯ your latest prompt above the editor' },
  { key: 'thinking', hotkey: 't', title: 'Thinking', hint: 'first … last sentence of the latest thought' },
  { key: 'spinner', hotkey: 's', title: 'Spinner', hint: 'the animated working/thinking line above the prompt' },
  { key: 'narration', hotkey: 'n', title: 'Fold narration', hint: 'text between tool calls as one line; findings asked for in the reply' },
  { key: 'tight', hotkey: 'g', title: 'Tight rows', hint: 'experimental: pull tool rows and folded lines over the blank line above' },
  { key: 'previews', hotkey: 'v', title: 'Previews', hint: 'results under rows; off folds each call to its row' },
  { key: 'outlines', hotkey: 'd', title: 'Outlines', hint: 'declarations of reads and writes; what an edit touched' },
  { key: 'toon', hotkey: 'j', title: 'TOON', hint: 'JSON MCP results reach the model as TOON' },
  { key: 'mentions', hotkey: 'm', title: '@@agents', hint: '@@ suggests subagent types; a mention asks to delegate' },
  { key: 'trim', hotkey: 'r', title: 'Trim output', hint: 'long Bash output reaches the model as head + tail (whole on disk); unchanged re-reads as a pointer' },
  { key: 'trace', hotkey: 'l', title: 'Call ledger', hint: 'every call logged for mcp__hush__trace; a recap after compaction' },
  { key: 'guards', hotkey: 'u', title: 'Loop guard', hint: 'the same call failing the same way 3 times gets a note to change approach' },
  { key: 'route', hotkey: 'w', title: 'Route reads', hint: 'a whole-file Read of a big code file is pointed at an outline first; repeating it passes' },
  { key: 'brief', hotkey: 'b', title: 'Project brief', hint: 'calls that keep failing in this project (from past sessions) told to the model and its subagents' },
  { key: 'holdout', hotkey: 'h', title: 'Measure', hint: 'one session in five runs with trim, guards, route or brief off, so `hush effect` can compare' },
  { key: 'summary', hotkey: 'y', title: 'Turn summary', hint: 'calls, failures, files edited and characters saved of the last turn, above the prompt' },
]

// $.state lives for the session; $.store carries the choices to the next one.
type Saved = { mode?: unknown; toggles?: Record<string, unknown>; backgrounds?: Record<string, unknown> }
const save = async ($: EngineInterface) =>
  $.store.set('settings', {
    mode: await read($, mode),
    toggles: await read($, toggles),
    backgrounds: await read($, backgrounds),
  })

async function load($: EngineInterface) {
  const saved = ((await $.store.get('settings')) ?? {}) as Saved
  const m = saved.mode as Mode
  if (MODES.includes(m)) await update($, mode, () => m)
  const t = saved.toggles ?? {}
  await update($, toggles, now => {
    const next = { ...now }
    for (const { key } of TOGGLES) if (typeof t[key] === 'boolean') next[key] = t[key] as boolean
    return next
  })
  const b = saved.backgrounds ?? {}
  await update($, backgrounds, () => {
    const next: Backgrounds = {}
    for (const { key } of TARGETS) {
      const v = b[key]
      if (typeof v === 'string' && (HEX.test(v) || Object.hasOwn(PRESETS, v))) next[key] = v
    }
    return next
  })
}

// An edit's compact diff; a new file is all additions, so its outline is drawn instead.
function diffOf(tool: string, output: unknown): DiffRow[] | undefined {
  const o = (output ?? {}) as Record<string, unknown>
  if ((tool !== 'Edit' && tool !== 'Write') || o.type === 'create' || !Array.isArray(o.structuredPatch)) return undefined
  return compactDiff(base(str(o.filePath) ?? ''), o.structuredPatch as never)
}

const DIFF_BG: Partial<Record<DiffRow['kind'], ThemeKey>> = { add: 'diffAdded', del: 'diffRemoved' }

// A press unfolds a call (or a folded text) where it stands and scrolls its header to the
// top of the window, so the block reads down from the control that folds it again; a fold
// (from the header or the block's end) scrolls the header back into view.
// The scroll is allowed because it answers the press.
async function toggleOpen($: EngineInterface, id: string, at: string) {
  let isOpen = false
  await update($, expanded, ids => {
    isOpen = !ids.includes(id)
    return isOpen ? [...ids, id].slice(-200) : ids.filter(x => x !== id)
  })
  await reveal($, at, isOpen ? 'start' : 'nearest')
}

// Scrolls a transcript row (by the requestId its render saw; a { key } reaches only the
// mod's own panes and band) into view. Twice: before the redraw a row near the bottom has
// nothing below it to scroll over, and the unfolded block then grows under a window pinned
// to the end; after it, the row can go up.
async function reveal($: EngineInterface, at: string, block: 'start' | 'center' | 'nearest') {
  const go = async () => (await $.ui.scroll({ to: { requestId: at }, block })).deny
  await go().catch(() => undefined)
  // shortcut: a fixed wait for the redraw (ten a second at most); no "drawn" event to await.
  await $.clock.sleep(150).catch(() => undefined)
  const deny = await go().catch(err => String(err))
  if (deny) $.ui.toast(`hush: could not scroll (${deny})`)
}

type Row = { text: string; kind?: DiffRow['kind'] | 'in' | 'err' }
// What an unfolded call shows: rows, or a block the engine draws better (highlighted code, markdown).
type Body = { rows: Row[] } | { code: { source: string; path?: string; startLine?: number } } | { md: string }
const cap = (rows: Row[]): Row[] =>
  rows.length > OPEN_LINES ? [...rows.slice(0, OPEN_LINES), { text: `[... ${rows.length - OPEN_LINES} more rows]`, kind: 'gap' }] : rows
const capText = (s: string) => {
  const l = s.split('\n')
  return l.length > OPEN_LINES ? `${l.slice(0, OPEN_LINES).join('\n')}\n[... ${l.length - OPEN_LINES} more lines]` : s
}
const toRows = (text: string, kind?: Row['kind']): Row[] =>
  text.split('\n').map(clean).filter((l, n, all) => l.trim() || n < all.length - 1).map(t => ({ text: t, ...(kind ? { kind } : {}) }))
// Prose results read as markdown: a subagent's report, a fetched page.
const MD_TOOLS = new Set(['Agent', 'Task', 'WebFetch', 'WebSearch'])
// Input keys an unfolded call leaves out: the envelope, the row's own description, what the diff shows.
const SKIP_INPUT = new Set(['tool', 'tool_use_id', 'agentId', 'requestMeta', 'description', 'old_string', 'new_string', 'content', 'prompt'])

// The call as asked, whole (the row cuts it): the command, the agent's task, the pattern and path.
function inputRows(c: Call): Row[] {
  const i = (c.input ?? {}) as Record<string, unknown>
  const s = (k: string) => str(i[k]) ?? ''
  const lines =
    c.tool === 'Bash' ? s('command').split('\n').map((l, n) => `${n ? '  ' : '$ '}${l}`)
    : c.tool === 'Agent' || c.tool === 'Task' ? [`${s('subagent_type') || 'agent'}${s('model') ? ` (${s('model')})` : ''}: ${s('description')}`, ...s('prompt').split('\n').slice(0, 8)]
    : Object.entries(i).filter(([k, v]) => !SKIP_INPUT.has(k) && ['string', 'number', 'boolean'].includes(typeof v)).map(([k, v]) => `${k}: ${String(v).replace(/\s+/g, ' ').slice(0, 300)}`)
  return lines.filter(l => l.trim()).map(text => ({ text: clean(text), kind: 'in' as const }))
}

// A call's whole output: an edit's diff, a read as highlighted code, prose as markdown,
// Bash as stdout then stderr (red), anything else as text (JSON as TOON).
function bodyOf(c: Call & { output?: unknown }): Body {
  const o = (c.output ?? {}) as Record<string, unknown>
  if ((c.tool === 'Edit' || c.tool === 'Write') && o.type !== 'create' && Array.isArray(o.structuredPatch)) {
    return { rows: cap(compactDiff(base(str(o.filePath) ?? ''), o.structuredPatch as never, true)) }
  }
  if (c.isErrored) {
    const text = typeof c.output === 'string' ? c.output : fullText(c.tool, c.output)
    return { rows: cap(toRows(text, 'err')) }
  }
  const f = (o.file ?? {}) as Record<string, unknown>
  if (c.tool === 'Read' && o.type === 'text' && typeof f.content === 'string' && f.content) {
    return { code: { source: capText(f.content), ...(str(f.filePath) ? { path: str(f.filePath) } : {}), startLine: Number(f.startLine) || 1 } }
  }
  if (c.tool === 'Bash' && typeof c.output === 'object') {
    const rows = [...toRows(str(o.stdout) ?? ''), ...toRows(str(o.stderr) ?? '', 'err')].filter(r => r.text.trim() || r.kind !== 'err')
    return { rows: rows.length ? cap(rows) : [{ text: '(no output)', kind: 'gap' }] }
  }
  const text = fullText(c.tool, c.output)
  if (MD_TOOLS.has(c.tool) && text.trim()) return { md: capText(text) }
  const rows = toRows(text)
  return { rows: rows.length ? cap(rows) : [{ text: '(no output yet)', kind: 'gap' }] }
}

type Elements = ReturnType<EngineInterface['ui']['resolve']>
type Els = Pick<Elements, 'Box' | 'Button' | 'Code' | 'Markdown' | 'Text'>

// One row of an unfolded block: a dim gutter, the text wrapped beside it in its own colour.
function gutterRow(el: Pick<Elements, 'Box' | 'Text'>, r: Row, key: string, indent: string) {
  const { Box, Text } = el
  const bg = r.kind === 'add' || r.kind === 'del' ? DIFF_BG[r.kind] : undefined
  return (
    <Box key={key}>
      <Text dimColor>{`${indent}│ `}</Text>
      <Text wrap="wrap" color={r.kind === 'err' ? 'error' : undefined} dimColor={r.kind === 'gap' || r.kind === 'ctx'} bold={r.kind === 'head'} backgroundColor={bg}>
        {r.text || ' '}
      </Text>
    </Box>
  )
}
// An unfolded block opens on a line of its own, apart from the row it unfolds.
const gapLine = (el: Pick<Elements, 'Text'>, id: string) => <el.Text key={`gap-${id}`}> </el.Text>
// The input above the output, parted by a short rule.
function inputBlock(el: Pick<Elements, 'Box' | 'Text'>, id: string, rows: Row[], indent: string) {
  const { Text } = el
  return [gapLine(el, id), ...rows.map((r, n) => gutterRow(el, r, `in-${id}-${n}`, indent)), ...(rows.length ? [<Text key={`sep-${id}`} dimColor>{`${indent}├${'─'.repeat(24)}`}</Text>] : [])]
}

// An unfolded call: its input (when the caller has it), then its output; a long block ends
// in a second fold control, so it can be folded from where it ends.
// `input` null: the row above drew the input (and the opening gap) itself.
function unfolded($: EngineInterface, el: Els, id: string, at: string, body: Body, indent: string, input: Row[] | null = []) {
  const { Box, Button, Code, Markdown, Text } = el
  const out =
    'rows' in body ? body.rows.map((r, n) => gutterRow(el, r, `out-${id}-${n}`, indent))
    : [<Box key={`out-${id}`} paddingLeft={indent.length + 2}>{'code' in body ? <Code {...body.code} /> : <Markdown text={body.md} />}</Box>]
  const tall = 'rows' in body ? body.rows.length : ('code' in body ? body.code.source : body.md).split('\n').length
  return [
    ...(input ? inputBlock(el, id, input, indent) : []),
    ...out,
    tall >= TAIL_CONTROL_AT ? (
      <Button key={`tail-${id}`} plain dimColor onPress={() => toggleOpen($, id, at)}>
        <Text>{`${indent}▴ fold`}</Text>
      </Button>
    ) : null,
  ]
}

// A folded text shows this many characters; the rest waits for a click.
const FOLD_CHARS = 80

// The first line a failed call says, `Permission to use Bash … denied.` and the like.
const reasonOf = (output: unknown) =>
  flat((typeof output === 'string' ? output : textOf(output) || JSON.stringify(output ?? '')).split('\n').find(l => l.trim()) ?? 'failed')

// Exact match; containment only for longer text (a step's answer can join several text
// blocks), so a short final reply like "Done." never folds as an earlier step's part.
const isNarration = (said: readonly string[], text: string) => {
  const t = flat(text)
  return !!t && said.some(a => a === t || (t.length >= 40 && a.includes(t)))
}

const flat = (s: string) => s.replace(/\s+/g, ' ').trim()

// First and last sentence of a thought, `...` between when middle ones are left out.
export function excerpt(text: string): string {
  const s = flat(text).match(/[^.!?]+(?:[.!?]+|$)/g)?.map(x => x.trim()).filter(Boolean) ?? []
  return s.length <= 2 ? s.join(' ') : `${s[0]} ... ${s[s.length - 1]}`
}

const fit = (s: string, cells: number) => (s.length > cells ? `${s.slice(0, Math.max(0, cells - 3))}...` : s)


// Theme keys only: a theme fills every one (a built-in theme too); any other name resolves
// only where a custom theme sets it, and draws as plain text elsewhere.
const COLORS: Record<string, ThemeKey> = {
  Read: 'suggestion', Edit: 'suggestion', NotebookEdit: 'suggestion',
  Write: 'text', Glob: 'text',
  Grep: 'warning', WebFetch: 'merged', WebSearch: 'merged',
  Agent: 'permission', Task: 'permission', Skill: 'ide',
}
// Shared with Skill rows; the theme keys hold no closer "you" colour.
const USER_COLOR: ThemeKey = 'ide'
const BASH_COLORS: Record<string, ThemeKey> = { GIT: 'warning', RG: 'warning', GREP: 'warning' }

// A call's state ahead of its label: ✓ done, ✗ failed, ■ cut, · running; ▾ while unfolded.
type Mark = { isRunning: boolean; isErrored: boolean; isInterrupted?: boolean }
function markOf(el: Pick<Elements, 'Text'>, c: Mark, isOpen: boolean, pad = '') {
  const [m, color]: [string, ThemeKey | undefined] = isOpen ? ['▾', undefined] : c.isRunning ? ['·', undefined] : c.isErrored ? ['✗', 'error'] : c.isInterrupted ? ['■', undefined] : ['✓', 'success']
  return <el.Text key="m" color={color} dimColor={!color}>{`${pad}${m} `}</el.Text>
}
// The call's start time from the ledger, right-aligned on its row (none with the ledger off).
const clockOf = (at?: number) => (at ? ` ${new Date(at).toTimeString().slice(0, 8)}` : '')
const startsOf = async ($: EngineInterface) => new Map((await read($, trace)).map(x => [x.id, x.at]))

function colorOf(c: Call): ThemeKey {
  if (c.isErrored) return 'error'
  if (c.tool === 'Bash') return BASH_COLORS[label(c)] ?? 'text'
  if (c.tool.startsWith('mcp__')) return 'remember'
  return COLORS[c.tool] ?? 'text'
}


const textOf = (output: unknown): string => {
  if (typeof output === 'string') return output
  const o = (output ?? {}) as Record<string, unknown>
  return [str(o.stdout), str(o.stderr)].filter(Boolean).join('\n')
}

// A call's whole output as text, for unfolding it in place.
function fullText(tool: string, output: unknown): string {
  if (output === undefined) return ''
  if (typeof output === 'string') return output
  const o = output as Record<string, unknown>
  if (tool === 'Bash') return textOf(output)
  if (tool === 'Read') return str((o.file as Record<string, unknown> | undefined)?.content) ?? ''
  if (tool.startsWith('mcp__')) return (mcpPreview(output, Infinity) ?? []).join('\n')
  const files = Array.isArray(o.filenames) ? (o.filenames as unknown[]).join('\n') : undefined
  // A subagent's or a tool's content blocks: their text, not the JSON around it.
  const blocks = Array.isArray(o.content) ? (o.content as unknown[]).map(b => str((b as Record<string, unknown> | null)?.text) ?? '').filter(Boolean).join('\n\n') : undefined
  return str(o.content) ?? (blocks || undefined) ?? files ?? (str(o.result) || toToon(output))
}

// Rows a result preview draws in place of the engine's; null leaves the engine's.
function previewRows(tool: string, output: unknown, outlines: boolean): string[] | null {
  const o = (output ?? {}) as Record<string, unknown>
  if (tool === 'Bash' && !o.backgroundTaskId) {
    const lines = textOf(output).split('\n').map(clean).filter(l => l.trim())
    return capRows(groupMatches(lines.join('\n')) ?? lines, PREVIEW_LINES)
  }
  if (tool.startsWith('mcp__')) return mcpPreview(output, PREVIEW_LINES)?.map(clean) ?? null
  if (!outlines) return HIDDEN_RESULTS.has(tool) ? [] : null
  if (tool === 'Read') {
    const f = (o.file ?? {}) as Record<string, unknown>
    if (o.type !== 'text' || typeof f.content !== 'string') return []
    return capRows(outline(f.content, str(f.filePath), Number(f.startLine) || 1), OUTLINE_LINES)
  }
  if (tool === 'Write' && o.type === 'create' && typeof o.content === 'string') {
    return capRows(outline(o.content, str(o.filePath)), OUTLINE_LINES)
  }
  if ((tool === 'Edit' || tool === 'Write') && Array.isArray(o.structuredPatch)) {
    const names = touched(o.originalFile as string | null, o.structuredPatch as never, str(o.filePath))
    // Nothing named: the engine's diff says more than an empty row.
    return names.length ? capRows(names.map(n => `touched ${n}`), OUTLINE_LINES) : null
  }
  return HIDDEN_RESULTS.has(tool) ? [] : null
}

// Raw escapes and \r redraws in a Text are counted as cells by the layout and smear rows over each other.
const ANSI = /\x1b\[[0-9;?]*[ -/]*[@-~]|\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)|\x1b[@-_]/g
const clean = (line: string) =>
  (line.split('\r').pop() ?? '').replace(ANSI, '').replace(/\t/g, '  ').replace(/[\x00-\x1f\x7f]/g, '')

// Reads and searches are named by their row; their content stays behind ctrl+o.
const HIDDEN_RESULTS = new Set(['Read', 'Glob', 'Grep', 'LS'])

// On a reload session.start runs before the screen is bound, and register throws
// ("no session is bound in this process"); a throwing hook is skipped whole. So the
// command is tried at start, retried on a timer, and again on each prompt.
let isRegistered = false
async function ensureCommand($: EngineInterface, left = 20): Promise<void> {
  if (isRegistered) return
  try {
    await $.command.register({
      name: 'hush',
      description: 'Open the hush panel; or: cards | lines | group | cycle | collapse | stats | bg | wiki | digest | board | tree | trace | analyze | replay | gc',
    })
    isRegistered = true
  } catch {
    if (left > 0) $.clock.after(1000, () => void ensureCommand($, left - 1))
  }
}

// Subagent types the model is offered, as `agent.offer` lists them; filled by the first model call.
const agents = new Map<string, string>()
const agentNamed = (name: string) => [...agents.keys()].find(a => a.toLowerCase() === name.toLowerCase())

// `/hush <cmd>` run by the CLI; the rest are the mod's own.
const CLI = new Set(['wiki', 'digest', 'board', 'tree', 'trace', 'analyze', 'replay', 'gc'])
const CLI_REPLY = 8000
const CLI_HELP = [...CLI].join(' | ')

const savedLine = (s: Record<string, number>) =>
  Object.entries(s).filter(([, n]) => n > 0).map(([k, n]) => `${k} ${kb(n)}`).join(' · ') || 'nothing yet'

export const register: Register = on => {
  registerAgent(on)
  on('session.start', async ($, e, next) => {
    await ensureCommand($)
    await startAgent($).catch(() => undefined)
    // Saved choices are a convenience: a failed load keeps the defaults and never costs the command.
    await load($).catch(err => $.ui.log(`hush: settings not restored (${String(err).slice(0, 80)})`, { to: 'debug' }))
    return next(e)
  })

  on('command.run', { command: 'hush' }, async ($, e) => {
    const [arg = '', ...rest] = e.args.trim().split(/\s+/)
    if (!arg) {
      await $.ui.open({ id: PANE, title: 'Hush' })
      return { text: 'Hush panel opened.' }
    }
    // The harness-neutral CLI (bin/hush.ts) answers its own commands; its output is the reply.
    if (CLI.has(arg)) {
      // trace and tree default to this session, not the last ledger any session touched.
      const sid = await $.session.id().catch(() => '')
      const hasTarget = rest.some(x => !x.startsWith('--'))
      const args = arg === 'trace' && sid && !rest.includes('--session') ? [...rest, '--session', sid] : arg === 'tree' && sid && !hasTarget ? [sid, ...rest] : rest
      const r = await $.process.run(['node', `${$.plugin.root}/bin/hush.ts`, arg, ...args, '--no-color'], { timeoutMs: 120_000 })
      const all = r.stdout.trim() || r.stderr.trim()
      // Long output keeps its head (the summary) and its tail (the newest rows).
      const out = all.length > CLI_REPLY ? `${all.slice(0, 2000)}\n[… ${all.length - CLI_REPLY} characters …]\n${all.slice(-(CLI_REPLY - 2000))}` : all
      return { text: out || `hush ${arg}: exit ${r.exitCode}` }
    }
    if (arg === 'stats') {
      const all = await read($, trace)
      return { text: `Calls logged: ${all.length} (${all.filter(x => !x.ok).length} failed). Kept from the model: ${savedLine(await read($, saved))}.` }
    }
    if (arg === 'collapse') {
      await update($, expanded, () => [])
      return { text: 'Every unfolded row is folded again.' }
    }
    if (arg === 'bg') {
      const [target, value = 'off'] = rest as [Target | undefined, string?]
      if (!target || !TARGETS.some(t => t.key === target) || !(value === 'off' || HEX.test(value) || Object.hasOwn(PRESETS, value))) {
        return { text: `Usage: /hush bg assistant|tool ${PRESET_NAMES.join('|')}|#rrggbb` }
      }
      await update($, backgrounds, b => ({ ...b, [target]: value === 'off' ? undefined : value }))
      await save($)
      return { text: `${target} background: ${value}` }
    }
    const now = await read($, mode)
    const want = arg as Mode
    if (!MODES.includes(want) && arg !== 'cycle') {
      return { text: `Unknown option "${arg}": cards | lines | group | cycle | collapse | stats | bg | ${CLI_HELP}` }
    }
    const next = MODES.includes(want) ? want : MODES[(MODES.indexOf(now) + 1) % MODES.length]
    await update($, mode, () => next)
    await save($)
    return { text: `Tool rows: ${MODES.map(m => (m === next ? `[${m}]` : m)).join(' · ')}` }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Button, Text } = $.ui.resolve(e)
    const m = await read($, mode)
    const t = await read($, toggles)
    const b = await read($, backgrounds)
    return (
      <Box flexDirection="column">
        <Text bold>Tool rows</Text>
        <Box>
          {MODES.map((x, i) => (
            <Button
              key={`mode-${x}`}
              label={x}
              hotkey={`${i + 1}`}
              variant={x === m ? 'primary' : 'secondary'}
              onPress={async () => {
                await update($, mode, () => x)
                await save($)
              }}
            />
          ))}
        </Box>
        <Text dimColor>Fullscreen: click a row's label or a folded line to unfold it in place; again folds it.</Text>
        <Text> </Text>
        <Text bold>Tweaks</Text>
        {TOGGLES.map(d => (
          <Box key={`row-${d.key}`}>
            <Button
              key={`toggle-${d.key}`}
              label={`${isOn(t, d.key) ? 'on ' : 'off'} ${d.title}`}
              hotkey={d.hotkey}
              variant={isOn(t, d.key) ? 'primary' : 'secondary'}
              onPress={async () => {
                await update($, toggles, now => ({ ...now, [d.key]: !isOn(now, d.key) }))
                await save($)
              }}
            />
            <Text dimColor>{`  ${d.hint}`}</Text>
          </Box>
        ))}
        <Text> </Text>
        <Text bold>Colors</Text>
        {TARGETS.map(d => {
          const v = b[d.key] ?? 'off'
          const bg = bgOf(b, d.key)
          return (
            <Box key={`bg-${d.key}`}>
              <Button
                key={`bg-btn-${d.key}`}
                label={`${d.title}: ${v}`}
                hotkey={d.hotkey}
                variant={bg ? 'primary' : 'secondary'}
                onPress={async () => {
                  // A press cycles the presets; a hex set by command steps on to the first.
                  const i = PRESET_NAMES.indexOf(v)
                  const n = PRESET_NAMES[(i + 1) % PRESET_NAMES.length] as string
                  await update($, backgrounds, now => ({ ...now, [d.key]: n === 'off' ? undefined : n }))
                  await save($)
                }}
              />
              {bg ? <Text backgroundColor={bg}>{'  sample  '}</Text> : null}
            </Box>
          )
        })}
        <Text dimColor>Any color: /hush bg assistant|tool #rrggbb</Text>
        <Text> </Text>
        <Text bold>Kept from the model</Text>
        <Text dimColor>{savedLine(await read($, saved))}</Text>
      </Box>
    )
  })

  on('prompt.submit', async ($, e, next) => {
    void ensureCommand($, 0)
    const recap = e.command || e.isMeta ? null : await recapContext($).catch(() => null)
    if (recap) e = { ...e, context: [...(e.context ?? []), recap] }
    if (e.command || e.isMeta || e.origin.kind !== 'composer' || !e.text.trim()) return next(e)
    await update($, lastPrompt, () => flat(e.text))
    if (!isOn(await read($, toggles), 'mentions')) return next(e)
    const named = mentions(e.text).map(agentNamed).filter((a): a is string => !!a)
    if (!named.length) return next(e)
    const note =
      `The user mentioned ${named.map(a => `@@${a}`).join(', ')}. Delegate the matching part of this ` +
      `request with the Agent tool: ${named.map(a => `subagent_type "${a}"`).join(', ')}.`
    $.ui.toast(`→ ${named.join(', ')}`)
    return next({ ...e, context: [...(e.context ?? []), note] })
  }).catch(($, e, next) => next(e))

  on('agent.offer', async ($, e, next) => {
    const r = await next(e)
    if (r.isOffered) agents.set(e.agent, e.description)
    else agents.delete(e.agent)
    return r
  })

  on('prompt.autocomplete', { token: /^@@/ }, async ($, e, next) => {
    const r = await next(e)
    if (!isOn(await read($, toggles), 'mentions')) return r
    const q = e.token.slice(2).toLowerCase()
    const mine = [...agents]
      .filter(([a]) => a.toLowerCase().includes(q))
      .sort(([a], [b]) => Number(!a.toLowerCase().startsWith(q)) - Number(!b.toLowerCase().startsWith(q)))
      .slice(0, 12)
      .map(([a, d]) => ({ text: `@@${a} `, label: `@@${a}`, description: flat(d).slice(0, 120) }))
    return { suggestions: [...r.suggestions, ...mine] }
  })

  // No .catch: a hook that fails after `next` keeps that result, never a second run of the tool.
  // The model reads a JSON MCP result as TOON; text that is not JSON, errors and
  // structured (schema) results pass as they are.
  on('tool.call', async ($, e, next) => {
    const r = await traceCall($, e, next)
    if (!e.tool.startsWith('mcp__') || r.deny !== undefined || r.isError || typeof r.text !== 'string') return r
    if (!isOn(await read($, toggles), 'toon')) return r
    const toon = jsonToToon(r.text)
    if (!toon) return r
    await update($, saved, s => ({ ...s, toon: (s.toon ?? 0) + (r.text as string).length - toon.length })).catch(() => undefined)
    const out = r.result as unknown
    if (typeof out === 'string') return { result: toon as never, context: r.context }
    const blocks = Array.isArray(out) ? (out as { type?: string }[]) : null
    if (blocks?.length && blocks.every(b => b?.type === 'text')) {
      return { result: [{ type: 'text', text: toon }] as never, context: r.context }
    }
    return r
  })

  // Thinking streams through each model request of the main loop; the band keeps the last
  // thought until new thinking arrives. A step that ends in tool calls is narration: its
  // text is remembered so its transcript block draws folded. Chunks pass untouched, and a
  // failed write never cuts the stream (a generator that throws mid-stream stops there).
  on('turn.step', async function* ($, e, next) {
    if (e.agentId) return yield* next(e)
    const t = await read($, toggles)
    const isThinking = isOn(t, 'thinking')
    const stream = next(e)
    let text = ''
    let drawnAt = 0
    const show = () => update($, thought, () => excerpt(text)).catch(() => undefined)
    for await (const c of stream) {
      if (isThinking && c.kind === 'thinking' && c.text) {
        text += c.text
        // shortcut: 4 redraws/s while thinking streams; raise if the band lags.
        if (Date.now() - drawnAt > 250) {
          drawnAt = Date.now()
          void show()
        }
      }
      yield c
    }
    if (text) void show()
    const result = await stream.result
    const said = flat(result.answer ?? '')
    if (said && result.toolUses.length) {
      await update($, narration, n => [...n, said].slice(-KEEP_NARRATION)).catch(() => undefined)
    }
    // The answer after a turn's tool calls: a later step that calls nothing.
    if (said && !result.toolUses.length && e.index > 0) {
      await update($, finals, f => [...f, said].slice(-KEEP_NARRATION)).catch(() => undefined)
    }
    return result
  })

  on('prompt.compose', async ($, e, next) => {
    const r = await next(e)
    const sections = [...r.sections, { id: 'hush:describe', text: DESCRIBE_RULE, scope: 'session' as const }]
    const t = await read($, toggles)
    if (isOn(t, 'narration')) sections.push({ id: 'hush:narration', text: NARRATION_RULE, scope: 'session' as const })
    const brief = isOn(t, 'brief') ? briefSection() : null
    if (brief) sections.push({ id: 'hush:brief', text: brief, scope: 'session' as const })
    return { sections }
  }).catch(($, e, next) => next(e))

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const p = e.props
    if (p.hasSurvey || p.view.agentId) return next(e)
    const t = await read($, toggles)
    // Prompt and thought only while a turn runs: once it ends they repeat the transcript.
    const prompt = isOn(t, 'prompt') && p.isWorking ? await read($, lastPrompt) : null
    const th = isOn(t, 'thinking') && p.isWorking ? await read($, thought) : null
    const turn = isOn(t, 'summary') && !p.isWorking ? await read($, lastTurn) : null
    if (!prompt && !th && !turn) return next(e)
    const { Box, Button, Text } = $.ui.resolve(e)
    const w = Math.max(20, p.bodyColumns)
    return (
      <Box flexDirection="column">
        {prompt ? (
          <Text wrap="truncate-end">
            <Text color="suggestion">{'❯ '}</Text>
            <Text dimColor>{fit(prompt, w - 2)}</Text>
          </Text>
        ) : null}
        {turn ? <Text dimColor wrap="truncate-end">{`∑ last turn: ${turnLine(turn)}`}</Text> : null}
        {th ? <Text dimColor>{'∴ thinking'}</Text> : null}
        {th ? <Text dimColor italic>{fit(th, w * THOUGHT_ROWS)}</Text> : null}
      </Box>
    )
  })

  // A typed prompt as a call row under a rule: `  USER  first line…`, the label in USER_COLOR; a click on the label unfolds the whole prompt under it, as a call's output.
  on('ui.render', { component: 'UserMessage' }, async ($, e, next) => {
    const p = e.props
    if (p.origin.kind === 'task-notification' && p.task && !p.isExpanded) {
      const { Box, Text } = $.ui.resolve(e)
      const call = p.task.toolUseId ? (await read($, trace)).find(x => x.id === p.task?.toolUseId) : undefined
      const status = p.task.status ?? 'done'
      const mark = status === 'completed' ? '✓' : status === 'failed' ? '✗' : '■'
      const secs = p.task.durationMs ? ` · ${Math.round(p.task.durationMs / 1000)}s` : ''
      const what = call ? `${call.label} ${call.what}` : flat(p.text)
      return (
        <Box>
          <Text color={status === 'failed' ? 'error' : USER_COLOR}>{`  ${'BG'.padEnd(MIN_LABEL)} ${mark} `}</Text>
          <Text dimColor wrap="truncate-end">{`${what}${secs}`}</Text>
        </Box>
      )
    }
    if (p.origin.kind !== 'composer') return next(e)
    const { Box, Button, Text } = $.ui.resolve(e)
    const id = `user-${e.requestId}`
    const isOpen = (await read($, expanded)).includes(id)
    return (
      <Box flexDirection="column">
        {/* A rule parts the new prompt from the transcript above. */}
        <Text dimColor wrap="truncate-end">{'─'.repeat(400)}</Text>
        <Box>
          <Text dimColor>{isOpen ? '▾ ' : '  '}</Text>
          <Button key={`row-${id}`} plain onPress={() => toggleOpen($, id, e.requestId)}>
            <Text color={USER_COLOR}>{'USER'.padEnd(MIN_LABEL)}</Text>
          </Button>
          <Text wrap="truncate-end">{` ${flat(p.text)}`}</Text>
        </Box>
        {isOpen ? (
          <Box paddingLeft={2}>
            <Text>{p.text}</Text>
          </Box>
        ) : null}
      </Box>
    )
  })

  // Replies draw padded, with no ● (the engine's row draws one, so the mod draws its own).
  // Text of a step that went on to call tools folds to its first 80 characters; a click
  // unfolds it in place.
  on('ui.render', { component: 'AssistantMessage' }, async ($, e, next) => {
    const p = e.props
    const t = await read($, toggles)
    const { Box, Button, Markdown, Text } = $.ui.resolve(e)
    // The engine's own one-line summary of in-between text: drawn as a folded line, no ●.
    if (p.isSummary) {
      return (
        <Box paddingLeft={2} marginTop={isOn(t, 'tight') ? -1 : 0}>
          <Text dimColor italic wrap="truncate-end">{flat(p.text)}</Text>
        </Box>
      )
    }
    const bg = bgOf(await read($, backgrounds), 'assistant')
    if (isOn(t, 'narration') && isNarration(await read($, narration), p.text)) {
      const id = `say-${e.requestId}`
      const isOpen = (await read($, expanded)).includes(id)
      const all = flat(p.text)
      const line = all.length > FOLD_CHARS ? `${all.slice(0, FOLD_CHARS - 1).trimEnd()}…` : all
      return (
        <Box flexDirection="column" marginTop={isOn(t, 'tight') ? -1 : 0}>
          <Box>
            <Text dimColor>{isOpen ? '▾ ' : '  '}</Text>
            <Button key={`row-${id}`} plain dimColor onPress={() => toggleOpen($, id, e.requestId)}>
              <Text italic wrap="truncate-end">{line}</Text>
            </Button>
          </Box>
          {isOpen ? (
            <Box paddingLeft={2} backgroundColor={bg}>
              <Markdown text={p.text} />
            </Box>
          ) : null}
        </Box>
      )
    }
    // The answer after a turn's tool calls: a rule parts it from the calls above.
    const rule = isNarration(await read($, finals), p.text) ? <Text dimColor wrap="truncate-end">{'─'.repeat(400)}</Text> : null
    return (
      <Box flexDirection="column" width="100%">
        {rule}
        <Box paddingLeft={2} backgroundColor={bg} width="100%">
          <Markdown text={p.text} />
        </Box>
      </Box>
    )
  })

  // The `✻ Brewed for 6s` transcript row draws nothing (ctrl+o keeps it; a row that waits on
  // background agents keeps its text): the footer mod shows the last turn's time under the prompt.
  on('ui.render', { component: 'TurnDuration' }, async ($, e, next) => {
    if (e.props.isExpanded || e.props.waitingFor) return next(e)
    const { Box } = $.ui.resolve(e)
    return <Box />
  })

  // The spinner line (`Sauteing… (12s · thinking)`) is drawn as nothing unless switched on.
  on('ui.render', { component: 'Spinner' }, async ($, e, next) => {
    if (isOn(await read($, toggles), 'spinner')) return next(e)
    const { Box } = $.ui.resolve(e)
    return <Box />
  })

  // One call outside a burst: `  LABEL  what`, the label unfolding the call in place
  // (▾ while unfolded; its ToolResult draws the output). ctrl+o keeps the engine's card.
  on('ui.render', { component: 'ToolUse' }, async ($, e, next) => {
    const p = e.props
    if (p.isExpanded || (await read($, mode)) === 'cards') return next(e)
    const { Box, Button, Text } = $.ui.resolve(e)
    const isOpen = (await read($, expanded)).includes(p.tool_use_id)
    const bg = p.isErrored ? undefined : bgOf(await read($, backgrounds), 'tool')
    const root = await $.session.cwd().catch(() => '')
    const at = (await startsOf($)).get(p.tool_use_id)
    const row = (
      <Box backgroundColor={bg} marginTop={isOn(await read($, toggles), 'tight') ? -1 : 0}>
        {markOf({ Text }, p, isOpen)}
        {/* Only the label takes the pointer: a hover inverts what it covers. */}
        <Button key={`row-${p.tool_use_id}`} plain onPress={() => toggleOpen($, p.tool_use_id, p.tool_use_id)}>
          <Text color={colorOf(p)}>{label(p).padEnd(MIN_LABEL)}</Text>
        </Button>
        <Box flexGrow={1}>
          <Text dimColor={p.isRunning} italic={p.isRunning} wrap="truncate-end">{` ${describe(p, root)}`}</Text>
        </Box>
        <Text dimColor>{clockOf(at)}</Text>
      </Box>
    )
    // Unfolded, the call's input sits under its row; its ToolResult draws the output below.
    const input = isOpen ? inputBlock({ Box, Text }, p.tool_use_id, inputRows(p), '  ') : []
    return isOpen ? <Box flexDirection="column">{row}{input}</Box> : row
  })

  // Folded by default: the row alone, errors kept. With previews on: an edit's compact diff,
  // Bash and MCP previews, outlines of reads and writes; else the tool's own renderer.
  on('ui.render', { component: 'ToolResult' }, async ($, e, next) => {
    const p = e.props
    if (p.isExpanded || (await read($, mode)) === 'cards') return next(e)
    const t = await read($, toggles)
    const { Box, Button, Code, Markdown, Text } = $.ui.resolve(e)
    if (p.isErrored && !(await read($, expanded)).includes(p.tool_use_id)) {
      return <Text color="error" wrap="truncate-end">{`  │ ${reasonOf(p.output)}`}</Text>
    }
    if ((await read($, expanded)).includes(p.tool_use_id)) {
      return <Box flexDirection="column">{unfolded($, { Box, Button, Code, Markdown, Text }, p.tool_use_id, p.tool_use_id, bodyOf({ tool: p.tool, input: {}, isRunning: false, isErrored: p.isErrored, output: p.output }), '  ', null)}</Box>
    }
    const diff = isOn(t, 'previews') ? diffOf(p.tool, p.output) : undefined
    if (diff?.length) {
      const shown = capRows(diff.map(r => r.text), DIFF_LINES)
      return (
        <Box flexDirection="column">
          {shown.map((text, n) => {
            const kind = diff[n]?.kind ?? 'gap'
            return (
              <Text key={`${n}`} wrap="truncate-end" backgroundColor={DIFF_BG[kind]} bold={kind === 'head'} dimColor={kind === 'gap'}>
                {text}
              </Text>
            )
          })}
        </Box>
      )
    }
    const rows = isOn(t, 'previews') ? previewRows(p.tool, p.output, isOn(t, 'outlines')) : []
    if (!rows) return next(e)
    return (
      <Box flexDirection="column">
        {rows.map((r, n) => (
          <Text key={`${n}`} dimColor wrap="truncate-end">
            {r}
          </Text>
        ))}
      </Box>
    )
  })

  // lines (or a burst still running): every call, labels aligned.
  // group: ✓/✗ N calls · K failed, then one bullet per distinct label in first-use order.
  // A clicked row unfolds its whole output in place, in either.
  on('ui.render', { component: 'ToolGroup' }, async ($, e, next) => {
    const p = e.props
    const m = await read($, mode)
    // A run with a failed or cut call is drawn too (the engine's own folds it to a count),
    // every call on its row, the failure red with its reason under it.
    const isTroubled = p.calls.some(c => c.isErrored || c.isInterrupted)
    if (m === 'cards' || p.isExpanded || (!p.isCallsOnly && !isTroubled)) return next(e)
    const { Box, Button, Code, Markdown, Text } = $.ui.resolve(e)
    const open = new Set(await read($, expanded))
    const bg = bgOf(await read($, backgrounds), 'tool')

    const isSummary = m === 'group' && !p.isActive && !isTroubled
    const failed = p.calls.filter(c => c.isErrored).length
    const root = await $.session.cwd().catch(() => '')
    const starts = await startsOf($)
    type GroupCall = (typeof p.calls)[number]
    // Repeats in a row (a poll run twice) draw once as `×N`, on the latest call.
    const runs: { c: GroupCall; n: number }[] = []
    for (const c of p.calls) {
      const prev = runs[runs.length - 1]
      const same = prev && !prev.c.isErrored && !c.isErrored && label(prev.c) === label(c) && describe(prev.c, root) === describe(c, root)
      if (same) runs[runs.length - 1] = { c, n: prev.n + 1 }
      else runs.push({ c, n: 1 })
    }
    let rows = runs
    if (isSummary) {
      const last = new Map<string, { c: GroupCall; n: number }>()
      for (const c of p.calls) last.set(label(c), { c, n: 1 })
      rows = [...last.values()]
    }
    const width = Math.max(MIN_LABEL, ...rows.map(r => label(r.c).length))
    const pad = isSummary ? '  ' : ''

    return (
      <Box flexDirection="column" backgroundColor={bg} marginTop={isOn(await read($, toggles), 'tight') ? -1 : 0}>
        {isSummary ? (
          <Text>
            <Text color={failed ? 'error' : 'success'}>{failed ? '✗ ' : '✓ '}</Text>
            <Text dimColor>{`${p.calls.length} calls`}</Text>
            {failed ? <Text color="error">{` · ${failed} failed`}</Text> : null}
          </Text>
        ) : null}
        {rows.map(({ c, n: times }, n) => {
          const id = c.tool_use_id
          const isOpen = !!id && open.has(id)
          const head = [
            markOf({ Text }, c, isOpen, pad),
            <Text key="l" color={colorOf(c)}>{label(c).padEnd(width)}</Text>,
          ]
          const what = [
            <Box key="w" flexGrow={1}>
              <Text dimColor={c.isRunning} italic={c.isRunning} wrap="truncate-end">
                {` ${describe(c, root)}`}
                {times > 1 ? <Text dimColor>{` ×${times}`}</Text> : null}
              </Text>
            </Box>,
            <Text key="t" dimColor>{clockOf(id ? starts.get(id) : undefined)}</Text>,
          ]
          return (
            <Box key={`call-${id ?? n}`} flexDirection="column">
              <Box>
                {id ? (
                  <Button key={`row-${id}`} plain onPress={() => toggleOpen($, id, e.requestId)}>
                    {head}
                  </Button>
                ) : (
                  <Text>{head}</Text>
                )}
                {what}
              </Box>
              {isOpen && id ? unfolded($, { Box, Button, Code, Markdown, Text }, id, e.requestId, bodyOf(c), `${pad}  `, inputRows(c)) : null}
              {!isOpen && c.isErrored ? (
                <Text color="error" wrap="truncate-end">{`${pad}  │ ${reasonOf(c.output)}`}</Text>
              ) : null}
              {!isOpen && c.isInterrupted && !c.isErrored ? <Text dimColor>{`${pad}  │ Interrupted`}</Text> : null}
            </Box>
          )
        })}
      </Box>
    )
  })
}
