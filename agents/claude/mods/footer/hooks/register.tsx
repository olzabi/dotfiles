import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, ThemeKey } from 'claude-code'

import type { Ctx, Harness, Row, Step } from '../types'
import { baseOf, growth, skillRows, snapshot } from './harness'

const prompts = atom({ plugin: 'footer', key: 'prompts' } as const, [] as string[])
const cursor = atom({ plugin: 'footer', key: 'cursor' } as const, null as number | null)
const step = atom({ plugin: 'footer', key: 'step' } as const, null as Step | null)
const ctx = atom({ plugin: 'footer', key: 'ctx' } as const, null as Ctx | null)
const branch = atom({ plugin: 'footer', key: 'branch' } as const, null as string | null)
const skills = atom({ plugin: 'footer', key: 'skills' } as const, {} as Record<string, number>)
const compactions = atom({ plugin: 'footer', key: 'compactions' } as const, 0)
const harness = atom({ plugin: 'footer', key: 'harness' } as const, null as Harness | null)
const base = atom({ plugin: 'footer', key: 'base' } as const, {} as Record<string, number>)
const PANE = 'harness'
const DETAIL_ROWS = 6
const turn = atom({ plugin: 'footer', key: 'turn' } as const, null as { ms: number; at: number } | null)

// shortcut: no API exposes the vim or permission mode, so both are read from the hint line's text
// (`-- INSERT -- ⏵⏵ auto mode on (shift+tab to cycle) · ← 1 agent`); upgrade if the engine adds one.
const VIM = /--\s*(INSERT|NORMAL|VISUAL(?: LINE| BLOCK)?|REPLACE)\s*--/
const PERM = /[⏵⏸»]*\s*(auto mode|auto-accept edits|accept edits|plan mode|bypass permissions)\s+on\b(?:\s*\([^)]*\))?/i
const PERM_LABEL: Record<string, { label: string; color: ThemeKey }> = {
  'auto mode': { label: 'AUTO', color: 'permission' },
  'auto-accept edits': { label: 'EDITS', color: 'autoAccept' },
  'accept edits': { label: 'EDITS', color: 'autoAccept' },
  'plan mode': { label: 'PLAN', color: 'planMode' },
  'bypass permissions': { label: 'BYPASS', color: 'error' },
}
const VIM_COLOR: Record<string, ThemeKey> = { INSERT: 'success', NORMAL: 'suggestion', REPLACE: 'error' }
const LIVE = new Set(['pending', 'running', 'waiting'])
const AGENT_PILL = /^\d+\s+(?:\w+\s+)?agents?$/i
const MAX_AGENTS = 3

// Leading arrows, triangles and bullets the engine puts before a pill.
const MARKS = /^[\s←→↑↓⏵⏸»•·✻⚠]+/

export type Hint = { vim?: string; perm?: { label: string; color: ThemeKey }; rest: string[] }

// The hint line taken apart: the two modes as badges, the rest as plain parts without their marks.
export function parseHint(hint: string): Hint {
  let text = hint
  const out: Hint = { rest: [] }
  const v = VIM.exec(text)
  if (v?.[1]) {
    out.vim = v[1]
    text = text.replace(v[0], ' ')
  }
  const p = PERM.exec(text)
  const known = p?.[1] ? PERM_LABEL[p[1].toLowerCase()] : undefined
  if (p && known) {
    out.perm = known
    text = text.replace(p[0], ' ')
  }
  out.rest = text
    .split(/\s+·\s+|\s{2,}/)
    .map(s => s.replace(MARKS, '').trim())
    .filter(Boolean)
  return out
}

// `6s`, `2m 6s`, `1h 4m`, as the engine's turn line writes a duration.
export function duration(ms: number): string {
  const s = Math.round(ms / 1000)
  if (s < 60) return `${s}s`
  if (s < 3600) return `${Math.floor(s / 60)}m ${s % 60}s`
  return `${Math.floor(s / 3600)}h ${Math.floor((s % 3600) / 60)}m`
}

const fit = (s: string, n: number) => (s.length > n ? `${s.slice(0, n - 1)}…` : s)

// `claude-opus-5-5` → `opus 5.5`; anything else as given.
export function shortModel(id: string): string {
  const m = /^claude-([a-z]+)-(\d+)-(\d+)/.exec(id)
  return m ? `${m[1]} ${m[2]}.${m[3]}` : id
}

// `950`, `12.4k`, `104k`, `1.2M`.
export function tokens(n: number): string {
  if (n < 1000) return `${n}`
  if (n < 10_000) return `${(n / 1000).toFixed(1)}k`
  if (n < 1_000_000) return `${Math.round(n / 1000)}k`
  return `${(n / 1_000_000).toFixed(1)}M`
}

// shortcut: a skill body's tokens are estimated at 4 characters each; count them exactly if the engine reports it.
export const estimate = (text: string) => Math.ceil(text.length / 4)

// Coloured by how much is left before compaction runs (or before the window ends, with it off).
export function ctxColor(used: number, cap: number): ThemeKey {
  const share = cap > 0 ? used / cap : 0
  return share >= 0.9 ? 'error' : share >= 0.7 ? 'warning' : 'subtle'
}

// Where a jump lands: from the bottom (null) back to the last prompt, never past either end.
export function target(at: number | null, count: number, dir: -1 | 1): number | null {
  if (!count) return null
  if (at === null) return dir === -1 ? count - 1 : null
  return Math.max(0, Math.min(count - 1, at + dir))
}

async function jump($: EngineInterface, dir: -1 | 1) {
  const ids = await read($, prompts)
  let to: number | null = null
  await update($, cursor, at => (to = target(at, ids.length, dir)))
  const id = to === null ? undefined : ids[to]
  if (!id) return
  // Allowed: it answers the person's press. A row hush folds still scrolls by its message id.
  const r = await $.ui.scroll({ to: { requestId: id }, block: 'start' })
  if (r.deny) $.ui.toast(`Could not jump to that prompt (${r.deny})`)
}

// What each loaded skill costs, the listing first.
export function skillReport(list: number | undefined, loaded: Record<string, number>): string {
  const rows = Object.entries(loaded).sort((a, b) => b[1] - a[1]).map(([name, n]) => `${name} ${tokens(n)}`)
  return [`listing ${tokens(list ?? 0)}`, ...rows].join('  ')
}

async function showSkills($: EngineInterface) {
  const [cx, loaded] = await Promise.all([read($, ctx), read($, skills)])
  $.ui.toast(skillReport(cx?.skillList, loaded))
}

async function openHarness($: EngineInterface) {
  const r = await $.ui.open({ id: PANE, title: 'Harness' })
  if (!r.isPlaced) $.ui.toast(`The harness table waits for room (${r.reason})`)
}

async function openAgent($: EngineInterface, agentId: string) {
  const r = await $.ui.view({ agentId })
  if (r.deny) $.ui.toast(`Could not open that agent (${r.deny})`)
}

async function readBranch($: EngineInterface) {
  const r = await $.process.run(['git', 'branch', '--show-current'], { timeoutMs: 2000 }).catch(() => null)
  const name = r && r.exitCode === 0 ? r.stdout.trim() || null : null
  await update($, branch, () => name)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const r = await next(e)
    $.ui.status(undefined) // drops the line the first version pinned
    await $.command.register({ name: 'harness', description: 'Live table of what fills the context: tools, MCP, memory, skills, messages' })
    await readBranch($)
    return r
  })

  on('command.run', { command: 'harness' }, async $ => {
    await openHarness($)
    return { text: 'Harness table opened.' }
  })

  // The table's growth column counts from here.
  on('turn.start', async ($, e, next) => {
    if (!e.agentId) {
      const snap = await read($, harness)
      if (snap) await update($, base, () => baseOf(snap))
    }
    return next(e)
  })

  // A turn may have switched branches through Bash.
  on('turn.complete', async ($, e, next) => {
    const r = await next(e)
    if (!e.agentId) {
      await update($, turn, () => ({ ms: e.durationMs, at: Date.now() }))
      await readBranch($)
    }
    return r
  })

  on('session.append', async ($, e, next) => {
    const r = await next(e)
    if (!e.agentId && e.door === 'prompt' && e.origin.kind === 'composer' && !e.message.isMeta) {
      await update($, prompts, ids => [...ids, e.uuid].slice(-500))
      await update($, cursor, () => null)
    }
    return r
  }).catch(($, e, next) => next(e))

  on('turn.step', async function* ($, e, next) {
    if (!e.agentId) await update($, step, () => ({ model: e.model, effort: e.effort }))
    return yield* next(e)
  })

  on('session.measure', async ($, e, next) => {
    // The summary breakdown is a local estimate: no request is sent for it.
    const b = (await $.session.usage({ breakdown: 'summary' }).catch(() => null))?.context.breakdown
    await update($, ctx, () => ({
      percent: e.context.percent,
      tokens: e.context.tokens,
      window: e.context.window,
      compactAt: b?.isAutoCompactEnabled ? b.autoCompactThreshold : undefined,
      skillList: b?.skills?.tokens,
    }))
    if (b) await update($, harness, () => snapshot(b))
    return next(e)
  })

  on('skill.prompt', async ($, e, next) => {
    const r = await next(e)
    await update($, skills, all => ({ ...all, [e.skill]: (all[e.skill] ?? 0) + estimate(r.text) }))
    return r
  }).catch(($, e, next) => next(e))

  // A compaction summarizes the loaded skill bodies away, so their count starts over.
  on('session.compact', async ($, e, next) => {
    const r = await next(e)
    if (e.trigger !== 'precompute' && r.messages) {
      await update($, compactions, n => n + 1)
      await update($, skills, () => ({}))
    }
    return r
  }).catch(($, e, next) => next(e))

  // The hint line, drawn whole:  INSERT  AUTO  1 agent ……… prev 3/7 next  main  opus 5.5  medium  52%
  // The engine's agents pill (`← 1 agent`) becomes one button per live agent, opening its transcript as the tasks list does.
// shortcut: other pills are drawn from the hint's text and lose their click; give each its own button when one matters.
  on('ui.render', { component: 'PromptHint' }, async ($, e) => {
    const hint = parseHint(e.props.hint)
    const [ids, at, st, cx, br, last, loaded, compacted] = await Promise.all([
      read($, prompts), read($, cursor), read($, step), read($, ctx), read($, branch), read($, turn), read($, skills), read($, compactions),
    ])
    const skillTokens = (cx?.skillList ?? 0) + Object.values(loaded).reduce((a, b) => a + b, 0)
    // The hint redraws when its agent count changes, so the list read here stays current.
    const agents = (await $.agent.list().catch(() => [])).filter(a => !a.parentId && LIVE.has(a.status))
    const rest = agents.length ? hint.rest.filter(part => !AGENT_PILL.test(part)) : hint.rest
    const model = st?.model ?? (await $.session.model())
    const { Box, Button, Text } = $.ui.resolve(e)
    return (
      <Box>
        <Box flexGrow={1}>
          {hint.vim ? (
            <Text bold color="inverseText" backgroundColor={VIM_COLOR[hint.vim] ?? 'planMode'}>{` ${hint.vim} `}</Text>
          ) : null}
          {hint.vim && hint.perm ? <Text>{' '}</Text> : null}
          {hint.perm ? (
            <Text bold color="inverseText" backgroundColor={hint.perm.color}>{` ${hint.perm.label} `}</Text>
          ) : null}
          {agents.slice(0, MAX_AGENTS).map(a => (
            <Button key={`agent-${a.id}`} plain onPress={() => openAgent($, a.id)}>
              <Text color="suggestion">{`  ${fit(a.name ?? a.description, 24)}`}</Text>
            </Button>
          ))}
          {agents.length > MAX_AGENTS ? <Text color="subtle">{`  +${agents.length - MAX_AGENTS}`}</Text> : null}
          {rest.length ? (
            <Text color="subtle" wrap="truncate-end">{`${hint.vim || hint.perm || agents.length ? '  ' : ''}${rest.join('  ')}`}</Text>
          ) : null}
        </Box>
        {ids.length ? (
          <Box>
            <Button key="prev" plain onPress={() => jump($, -1)}>
              <Text color="suggestion">prev</Text>
            </Button>
            <Text color="subtle">{` ${at === null ? '-' : at + 1}/${ids.length} `}</Text>
            <Button key="next" plain onPress={() => jump($, 1)}>
              <Text color="suggestion">next</Text>
            </Button>
            <Text>{'  '}</Text>
          </Box>
        ) : null}
        {last && !e.props.isWorking ? (
          <Text color="subtle">{`${duration(last.ms)} ${new Date(last.at).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })}  `}</Text>
        ) : null}
        {br ? <Text color="remember">{`${br}  `}</Text> : null}
        <Text color="claude">{shortModel(model)}</Text>
        {st?.effort !== undefined ? <Text color="subtle">{`  ${st.effort}`}</Text> : null}
        {cx?.tokens !== undefined ? (
          <Button key="harness" plain onPress={() => openHarness($)}>
            <Text color={ctxColor(cx.tokens, cx.compactAt ?? cx.window)}>{`  ${tokens(cx.tokens)}/${tokens(cx.window)}`}</Text>
          </Button>
        ) : null}
        {cx?.tokens !== undefined && cx.compactAt ? (
          <Text color="subtle">{`  compact in ${tokens(Math.max(0, cx.compactAt - cx.tokens))}`}</Text>
        ) : null}
        {compacted ? <Text color="subtle">{` (${compacted}x)`}</Text> : null}
        {skillTokens ? (
          <Button key="skills" plain onPress={() => showSkills($)}>
            <Text color="remember">{`  skills ${tokens(skillTokens)}`}</Text>
          </Button>
        ) : null}
      </Box>
    )
  })

  // The harness table: each /context category with its tokens, share of the window and growth this turn,
  // then what MCP servers, memory files, agents and skills each cost.
  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const [table, b, loaded] = await Promise.all([read($, harness), read($, base), read($, skills)])
    const { Box, Text } = $.ui.resolve(e)
    if (!table) return <Text color="subtle">Waiting for the first context reading.</Text>
    const name = Math.max(12, e.props.bodyColumns - 26)
    const line = (r: Row, delta?: number, isHeader?: boolean) => (
      <Box key={`${r.name}-${r.note ?? ''}`}>
        <Text color={isHeader ? 'text' : r.kind === 'free' || r.kind === 'deferred' ? 'inactive' : 'subtle'} bold={isHeader}>
          {fit(r.note ? `${r.name}  ${r.note}` : r.name, name).padEnd(name)}
        </Text>
        <Text color={isHeader ? 'text' : 'claude'}>{tokens(r.tokens).padStart(8)}</Text>
        <Text color="subtle">{`${table.max ? Math.round((r.tokens / table.max) * 100) : 0}%`.padStart(6)}</Text>
        <Text color={delta && delta > 0 ? 'warning' : 'success'}>{(delta ? `${delta > 0 ? '+' : '-'}${tokens(Math.abs(delta))}` : '').padStart(10)}</Text>
      </Box>
    )
    const section = (title: string, rows: Row[]) =>
      rows.length ? (
        <Box key={title} flexDirection="column" marginTop={1}>
          <Text bold color="text">{title}</Text>
          {rows.slice(0, DETAIL_ROWS).map(r => line(r))}
          {rows.length > DETAIL_ROWS ? <Text color="inactive">{`${rows.length - DETAIL_ROWS} more`}</Text> : null}
        </Box>
      ) : null
    return (
      <Box flexDirection="column">
        <Box>
          <Text bold color="text">{'Category'.padEnd(name)}</Text>
          <Text bold color="text">{'Tokens'.padStart(8)}</Text>
          <Text bold color="text">{'Share'.padStart(6)}</Text>
          <Text bold color="text">{'This turn'.padStart(10)}</Text>
        </Box>
        {table.rows.map(r => line(r, growth(r, b)))}
        {line({ name: 'Total', tokens: table.total }, undefined, true)}
        {section('MCP servers', table.mcp)}
        {section('Memory files', table.memory)}
        {section('Skills', skillRows(table.skills, loaded))}
        {section('Agents', table.agents)}
      </Box>
    )
  })
}
