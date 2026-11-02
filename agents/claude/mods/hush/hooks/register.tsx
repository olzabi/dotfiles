import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, ThemeKey } from 'claude-code'

import type { Backgrounds, Mode, Target, Toggle, Toggles } from '../types'
import { capRows, compactDiff, groupMatches, jsonToToon, mcpPreview, mentions, outline, touched } from './format'
import type { DiffRow } from './format'

const MODES: Mode[] = ['cards', 'lines', 'group']
const PREVIEW_LINES = 5
const MIN_LABEL = 5
const PANE = 'hush'
const THOUGHT_ROWS = 3
const OUTLINE_LINES = 8

const mode = atom({ plugin: 'hush', key: 'mode' } as const, 'lines', {
  shape: 'mode-1',
})
const toggles = atom({ plugin: 'hush', key: 'toggles' } as const, { prompt: true, thinking: true })
const lastPrompt = atom({ plugin: 'hush', key: 'lastPrompt' } as const, null)
const thought = atom({ plugin: 'hush', key: 'thought' } as const, null)
const failures = atom({ plugin: 'hush', key: 'failures' } as const, [])
const expanded = atom({ plugin: 'hush', key: 'expanded' } as const, [])
const narration = atom({ plugin: 'hush', key: 'narration' } as const, [])
const finals = atom({ plugin: 'hush', key: 'finals' } as const, [])
// Kept short: a tall unfolded block repaints whole under a moving pointer.
const OPEN_LINES = 60
// From this many rows an unfolded block gets a second fold control at its end.
const TAIL_CONTROL_AT = 12
const KEEP_NARRATION = 200
// Read by the model: in-between text stays a status line; what matters lands in the reply.
const NARRATION_RULE = [
  'Text you write between tool calls is shown to the user folded to one line.',
  'Keep it to one short status sentence, or nothing.',
  'Put every finding, decision, result and open question in your final message after the last tool call,',
  'and cite the places it comes from as path:line so the user can open them.',
].join(' ')
const backgrounds = atom({ plugin: 'hush', key: 'backgrounds' } as const, {})
const DIFF_LINES = 12

// Previews start off (a call folds to its row), and the spinner line is hidden. Every other tweak starts on.
const DEFAULT_OFF: Toggle[] = ['previews', 'spinner', 'tight']
const isOn = (t: Toggles, k: Toggle) => t[k] ?? !DEFAULT_OFF.includes(k)

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
  return v && HEX.test(v) ? v : v ? PRESETS[v] : undefined
}

const TOGGLES: { key: Toggle; hotkey: string; title: string; hint: string }[] = [
  { key: 'prompt', hotkey: 'p', title: 'Last prompt', hint: '❯ your latest prompt above the editor' },
  { key: 'thinking', hotkey: 't', title: 'Thinking', hint: 'first … last sentence of the latest thought' },
  { key: 'errors', hotkey: 'e', title: 'Failures', hint: 'failed calls above the prompt; a click jumps to one, unfolded' },
  { key: 'spinner', hotkey: 's', title: 'Spinner', hint: 'the animated working/thinking line above the prompt' },
  { key: 'narration', hotkey: 'n', title: 'Fold narration', hint: 'text between tool calls as one line; findings asked for in the reply' },
  { key: 'tight', hotkey: 'g', title: 'Tight rows', hint: 'experimental: pull tool rows and folded lines over the blank line above' },
  { key: 'previews', hotkey: 'v', title: 'Previews', hint: 'results under rows; off folds each call to its row' },
  { key: 'outlines', hotkey: 'd', title: 'Outlines', hint: 'declarations of reads and writes; what an edit touched' },
  { key: 'toon', hotkey: 'j', title: 'TOON', hint: 'JSON MCP results reach the model as TOON' },
  { key: 'mentions', hotkey: 'm', title: '@@agents', hint: '@@ suggests subagent types; a mention asks to delegate' },
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
      if (typeof v === 'string' && (HEX.test(v) || v in PRESETS)) next[key] = v
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

// The transcript row that holds a call: its group's, once a group drew it, else its own.
// Plain memory, not state: a render hook may not write state, and a reload redraws it.
const rowOf = new Map<string, string>()

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

// A failure from the band: unfolded where it stands, centred so the rows before it show.
async function jumpTo($: EngineInterface, id: string) {
  await update($, expanded, ids => (ids.includes(id) ? ids : [...ids, id].slice(-200)))
  await reveal($, rowOf.get(id) ?? id, 'center')
}

type Row = { text: string; kind?: DiffRow['kind'] }
const cap = (rows: Row[]): Row[] =>
  rows.length > OPEN_LINES ? [...rows.slice(0, OPEN_LINES), { text: `[... ${rows.length - OPEN_LINES} more rows]`, kind: 'gap' }] : rows

// A call's whole output as rows: an edit's diff with context, else its text.
function rowsOf(c: Call & { output?: unknown }): Row[] {
  const o = (c.output ?? {}) as Record<string, unknown>
  if ((c.tool === 'Edit' || c.tool === 'Write') && o.type !== 'create' && Array.isArray(o.structuredPatch)) {
    return cap(compactDiff(base(str(o.filePath) ?? ''), o.structuredPatch as never, true))
  }
  const text = c.isErrored && typeof c.output === 'string' ? c.output : fullText(c.tool, c.output)
  const rows = text.split('\n').map(clean).filter((l, n, all) => l.trim() || n < all.length - 1)
  return rows.length ? cap(rows.map(t => ({ text: t }))) : [{ text: '(no output yet)', kind: 'gap' }]
}

type Elements = ReturnType<EngineInterface['ui']['resolve']>

// An unfolded call's rows, one line each, diff rows on the theme's diff backgrounds; a
// long block ends in a second fold control, so it can be folded from where it ends.
function unfolded($: EngineInterface, el: Pick<Elements, 'Button' | 'Text'>, id: string, at: string, rows: Row[], indent: string) {
  const { Button, Text } = el
  return [
    ...rows.map((r, n) => (
      <Text key={`out-${id}-${n}`} wrap="truncate-end" dimColor={!r.kind || r.kind === 'gap' || r.kind === 'ctx'}
        backgroundColor={r.kind ? DIFF_BG[r.kind] : undefined} bold={r.kind === 'head'}>
        {`${indent}${r.text}`}
      </Text>
    )),
    rows.length >= TAIL_CONTROL_AT ? (
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

// `6s`, `2m 6s`, `1h 4m`, as the engine's turn line writes a duration.
export function duration(ms: number): string {
  const s = Math.round(ms / 1000)
  if (s < 60) return `${s}s`
  if (s < 3600) return `${Math.floor(s / 60)}m ${s % 60}s`
  return `${Math.floor(s / 3600)}h ${Math.floor((s % 3600) / 60)}m`
}

const fit = (s: string, cells: number) => (s.length > cells ? `${s.slice(0, Math.max(0, cells - 3))}...` : s)

type Call = { tool: string; input: unknown; isRunning: boolean; isErrored: boolean }

const str = (v: unknown) => (typeof v === 'string' ? v : undefined)
const base = (p: string) => p.split('/').pop() ?? p
const args = (c: Call) => (c.input ?? {}) as Record<string, unknown>
const CD = /^\s*cd\s+[^&;]+(&&|;)\s*/

// Bash rows are named for the program they run, past `cd dir &&`, env assignments and wrappers.
const WRAPPERS = new Set(['sudo', 'env', 'command', 'exec', 'nohup', 'time'])
function program(command: string): string {
  const words = command.replace(CD, '').trim().split(/\s+/)
  const w = words.find(x => !/^\w+=/.test(x) && !WRAPPERS.has(x)) || 'bash'
  return base(w)
}

function label(c: Call): string {
  const i = args(c)
  if (c.tool === 'Bash') return program(str(i.command) ?? '').toUpperCase()
  if (c.tool === 'Skill') return `/${str(i.skill) ?? 'skill'}`
  if (c.tool.startsWith('mcp__')) return c.tool.split('__').slice(1).join(':').toUpperCase()
  // A subagent is named for its type, past a plugin prefix (`plugin-dev:agent-creator`).
  if (c.tool === 'Agent' || c.tool === 'Task') return (str(i.subagent_type)?.split(':').pop() || 'agent').toUpperCase()
  return c.tool.toUpperCase()
}

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

function colorOf(c: Call): ThemeKey {
  if (c.isErrored) return 'error'
  if (c.tool === 'Bash') return BASH_COLORS[label(c)] ?? 'text'
  if (c.tool.startsWith('mcp__')) return 'remember'
  return COLORS[c.tool] ?? 'text'
}

// shortcut: per-tool field guesses, no local-model intent line; upgrade by reading `description` from more tools.
function describe(c: Call): string {
  const i = args(c)
  const file = str(i.file_path) ?? str(i.notebook_path) ?? str(i.path)
  const what =
    str(i.description) ??
    (c.tool === 'Bash' ? str(i.command)?.replace(CD, '') : undefined) ??
    str(i.pattern) ?? str(i.query) ?? str(i.url) ?? str(i.prompt) ?? str(i.args)
  return [what?.split('\n')[0]?.slice(0, 80), file && base(file)].filter(Boolean).join('  ')
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
  return str(o.content) ?? files ?? JSON.stringify(output, null, 2)
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
      description: 'Open the hush panel; or: cards | lines | group | cycle | collapse | bg',
    })
    isRegistered = true
  } catch {
    if (left > 0) $.clock.after(1000, () => void ensureCommand($, left - 1))
  }
}

// Subagent types the model is offered, as `agent.offer` lists them; filled by the first model call.
const agents = new Map<string, string>()
const agentNamed = (name: string) => [...agents.keys()].find(a => a.toLowerCase() === name.toLowerCase())

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await ensureCommand($)
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
    if (arg === 'collapse') {
      await update($, expanded, () => [])
      return { text: 'Every unfolded row is folded again.' }
    }
    if (arg === 'bg') {
      const [target, value = 'off'] = rest as [Target | undefined, string?]
      if (!target || !TARGETS.some(t => t.key === target) || !(value === 'off' || HEX.test(value) || value in PRESETS)) {
        return { text: `Usage: /hush bg assistant|tool ${PRESET_NAMES.join('|')}|#rrggbb` }
      }
      await update($, backgrounds, b => ({ ...b, [target]: value === 'off' ? undefined : value }))
      await save($)
      return { text: `${target} background: ${value}` }
    }
    const now = await read($, mode)
    const want = arg as Mode
    if (!MODES.includes(want) && arg !== 'cycle') {
      return { text: `Unknown option "${arg}": cards | lines | group | cycle | collapse | bg` }
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
      </Box>
    )
  })

  on('prompt.submit', async ($, e, next) => {
    void ensureCommand($, 0)
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

  // The model reads a JSON MCP result as TOON; text that is not JSON, errors and
  // structured (schema) results pass as they are.
  on('tool.call', async ($, e, next) => {
    const r = await next(e)
    // Failures of the main loop, for the band; a subagent's rows are not in this transcript.
    if ((r.deny !== undefined || r.isError) && !e.agentId) {
      const c = { tool: e.tool, input: e, isRunning: false, isErrored: true }
      const f = { id: e.tool_use_id, label: label(c), what: describe(c) }
      await update($, failures, all => [...all, f].slice(-20)).catch(() => undefined)
    }
    if (!e.tool.startsWith('mcp__') || r.deny !== undefined || r.isError || typeof r.text !== 'string') return r
    if (!isOn(await read($, toggles), 'toon')) return r
    const toon = jsonToToon(r.text)
    if (!toon) return r
    const out = r.result as unknown
    if (typeof out === 'string') return { result: toon as never, context: r.context }
    const blocks = Array.isArray(out) ? (out as { type?: string }[]) : null
    if (blocks?.length && blocks.every(b => b?.type === 'text')) {
      return { result: [{ type: 'text', text: toon }] as never, context: r.context }
    }
    return r
  }).catch(($, e, next) => next(e))

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
    if (!isOn(await read($, toggles), 'narration')) return r
    return { sections: [...r.sections, { id: 'hush:narration', text: NARRATION_RULE, scope: 'session' as const }] }
  }).catch(($, e, next) => next(e))

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const p = e.props
    if (p.hasSurvey || p.view.agentId) return next(e)
    const t = await read($, toggles)
    // Prompt and thought only while a turn runs: once it ends they repeat the transcript.
    const prompt = isOn(t, 'prompt') && p.isWorking ? await read($, lastPrompt) : null
    const th = isOn(t, 'thinking') && p.isWorking ? await read($, thought) : null
    const fails = isOn(t, 'errors') ? await read($, failures) : []
    if (!prompt && !th && !fails.length) return next(e)
    const { Box, Button, Text } = $.ui.resolve(e)
    const w = Math.max(20, p.bodyColumns)
    return (
      <Box flexDirection="column">
        {fails.length ? (
          <Box>
            <Text color="error">{`✗ ${fails.length} failed `}</Text>
            {fails.slice(-3).map(f => (
              <Button key={`fail-${f.id}`} plain onPress={() => jumpTo($, f.id)}>
                <Text color="error">{` ${f.label} `}</Text>
                <Text dimColor>{`${f.what.slice(0, 24)} `}</Text>
              </Button>
            ))}
            <Button key="fail-clear" plain dimColor onPress={() => update($, failures, () => [])}>
              <Text>{' clear'}</Text>
            </Button>
          </Box>
        ) : null}
        {prompt ? (
          <Text wrap="truncate-end">
            <Text color="suggestion">{'❯ '}</Text>
            <Text dimColor>{fit(prompt, w - 2)}</Text>
          </Text>
        ) : null}
        {th ? <Text dimColor>{'∴ thinking'}</Text> : null}
        {th ? <Text dimColor italic>{fit(th, w * THOUGHT_ROWS)}</Text> : null}
      </Box>
    )
  })

  // A typed prompt as a call row: `  USER  first line…`, the label in USER_COLOR; a click on the label unfolds the whole prompt under it, as a call's output.
  on('ui.render', { component: 'UserMessage' }, async ($, e, next) => {
    const p = e.props
    if (p.origin.kind !== 'composer') return next(e)
    const { Box, Button, Text } = $.ui.resolve(e)
    const id = `user-${e.requestId}`
    const isOpen = (await read($, expanded)).includes(id)
    return (
      <Box flexDirection="column">
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

  // The `✻ Brewed for 6s · done 5:49 AM` row moves to the status line under the prompt: the
  // main loop's turn is timed here, and the transcript row draws nothing (ctrl+o keeps it;
  // a row that waits on background agents keeps its text).
  let turnStartedAt = 0
  on('turn.start', async ($, e, next) => {
    if (!e.agentId) turnStartedAt = Date.now()
    return next(e)
  })
  on('turn.complete', async ($, e, next) => {
    const r = await next(e)
    if (!e.agentId && turnStartedAt) {
      const done = new Date().toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })
      $.ui.status(`✻ ${duration(Date.now() - turnStartedAt)} · done ${done}`)
      turnStartedAt = 0
    }
    return r
  })
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
    return (
      <Box backgroundColor={bg} marginTop={isOn(await read($, toggles), 'tight') ? -1 : 0}>
        <Text dimColor>{isOpen ? '▾ ' : '  '}</Text>
        {/* Only the label takes the pointer: a hover inverts what it covers. */}
        <Button key={`row-${p.tool_use_id}`} plain onPress={() => toggleOpen($, p.tool_use_id, p.tool_use_id)}>
          <Text color={colorOf(p)}>{label(p).padEnd(MIN_LABEL)}</Text>
        </Button>
        <Text dimColor={p.isRunning} italic={p.isRunning}>{` ${describe(p)}`}</Text>
      </Box>
    )
  })

  // Folded by default: the row alone, errors kept. With previews on: an edit's compact diff,
  // Bash and MCP previews, outlines of reads and writes; else the tool's own renderer.
  on('ui.render', { component: 'ToolResult' }, async ($, e, next) => {
    const p = e.props
    if (p.isExpanded || (await read($, mode)) === 'cards') return next(e)
    const t = await read($, toggles)
    const { Box, Button, Text } = $.ui.resolve(e)
    if (p.isErrored && !(await read($, expanded)).includes(p.tool_use_id)) {
      return <Text color="error" wrap="truncate-end">{`  │ ${reasonOf(p.output)}`}</Text>
    }
    if ((await read($, expanded)).includes(p.tool_use_id)) {
      return <Box flexDirection="column">{unfolded($, { Button, Text }, p.tool_use_id, p.tool_use_id, rowsOf({ tool: p.tool, input: {}, isRunning: false, isErrored: false, output: p.output }), '  ')}</Box>
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
    const { Box, Button, Text } = $.ui.resolve(e)
    for (const c of p.calls) if (c.tool_use_id) rowOf.set(c.tool_use_id, e.requestId)
    const open = new Set(await read($, expanded))
    const bg = bgOf(await read($, backgrounds), 'tool')

    const isSummary = m === 'group' && !p.isActive && !isTroubled
    const failed = p.calls.filter(c => c.isErrored).length
    let rows: (typeof p.calls)[number][] = [...p.calls]
    if (isSummary) {
      const last = new Map<string, (typeof p.calls)[number]>()
      for (const c of p.calls) last.set(label(c), c)
      rows = [...last.values()]
    }
    const width = Math.max(MIN_LABEL, ...rows.map(c => label(c).length))
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
        {rows.map((c, n) => {
          const id = c.tool_use_id
          const isOpen = !!id && open.has(id)
          const head = [
            <Text key="b" dimColor>{`${pad}${isOpen ? '▾ ' : '  '}`}</Text>,
            <Text key="l" color={colorOf(c)}>{label(c).padEnd(width)}</Text>,
          ]
          const what = <Text dimColor={c.isRunning} italic={c.isRunning}>{` ${describe(c)}`}</Text>
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
              {isOpen && id ? unfolded($, { Button, Text }, id, e.requestId, rowsOf(c), `${pad}  `) : null}
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
