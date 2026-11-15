import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { CacheStep, Ctx, Harness, Row, Usage } from '../types'
import { cell, tokens } from './format'
import { growth, skillRows } from './harness'
import { togglePane } from './pane'
import { SESSION } from './state'
import { ago, hitOf, limitLabel, meter, orderLimits, spark, until, usd } from './usage'

// Shared values, declared here as the loader reads each file's own (the same plugin and key in every file).
const ctx = atom({ plugin: 'footer', key: 'ctx' } as const, null as Ctx | null)
const usage = atom({ plugin: 'footer', key: 'usage' } as const, null as Usage | null)
const cacheLog = atom({ plugin: 'footer', key: 'cacheLog' } as const, [] as CacheStep[])
const tick = atom({ plugin: 'footer', key: 'tick' } as const, 0)
const skills = atom({ plugin: 'footer', key: 'skills' } as const, {} as Record<string, number>)
const compactions = atom({ plugin: 'footer', key: 'compactions' } as const, 0)
const harness = atom({ plugin: 'footer', key: 'harness' } as const, null as Harness | null)
const base = atom({ plugin: 'footer', key: 'base' } as const, {} as Record<string, number>)
const sessionTab = atom({ plugin: 'footer', key: 'sessionTab' } as const, 1)
const ctxOpen = atom({ plugin: 'footer', key: 'ctxOpen' } as const, null as string | null)
const pluginOpen = atom({ plugin: 'footer', key: 'pluginOpen' } as const, {} as Record<string, boolean>)
const pluginSel = atom({ plugin: 'footer', key: 'pluginSel' } as const, 0)
const compactArmed = atom({ plugin: 'footer', key: 'compactArmed' } as const, false)

// The session pane: three tabs on keys 1-3 (Context, Plugins, Cache), `c` twice to compact, `x` or esc to close.
// Long lists fold to one line each and open on a key, one at a time; an open list is drawn whole and the pane's body
// scrolls over it (wheel, or the scroll keys while the pane holds them). Each tab is the detail behind one footer figure.
type On = Parameters<Register>[0]
type Ui = ReturnType<EngineInterface['ui']['resolve']>

const TABS = ['Context', 'Plugins', 'Cache'] as const
const TICK_MS = 5000
const ARM_MS = 4000
const LABEL = 10
const SECTIONS = [
  { id: 'memory', key: 'm', title: 'Memory files' },
  { id: 'mcp', key: 'v', title: 'MCP servers' },
  { id: 'skills', key: 's', title: 'Skills' },
  { id: 'agents', key: 'a', title: 'Agents' },
] as const

// Runs only while the pane is open, so its "N ago" figures age on screen; stopped by stopSessionTick at ui.close.
let ticker: { cancel: () => void } | undefined

export async function toggleSession($: EngineInterface) {
  const isOpen = await togglePane($, SESSION, 'Session')
  if (isOpen && !ticker) ticker = $.clock.every(TICK_MS, () => update($, tick, n => n + 1))
}

export function stopSessionTick() {
  ticker?.cancel()
  ticker = undefined
}

// Called at session.start: a reload inside the arming window leaves it armed with no timer to lapse it.
export async function disarmCompact($: EngineInterface) {
  await update($, compactArmed, () => false)
}

// The first `c` arms, the second (within a few seconds) compacts; a compaction summarizes the transcript, so not on one key.
async function compactNow($: EngineInterface) {
  if (!(await read($, compactArmed))) {
    await update($, compactArmed, () => true)
    $.clock.after(ARM_MS, () => update($, compactArmed, () => false))
    return
  }
  await update($, compactArmed, () => false)
  const r = await $.session.compact().catch((err: unknown) => ({ error: String(err) }))
  $.ui.toast('error' in r ? `Compaction failed: ${r.error}` : 'Compacted.')
}

async function toggleSection($: EngineInterface, id: string) {
  await update($, ctxOpen, open => (open === id ? null : id))
}

// Moves the pick and scrolls the pane just enough to keep that row in view.
async function movePlugin($: EngineInterface, dir: -1 | 1) {
  const plugins = (await read($, harness))?.plugins ?? []
  let to = 0
  await update($, pluginSel, at => (to = Math.max(0, Math.min(plugins.length - 1, at + dir))))
  const name = plugins[to]?.name
  if (name) await $.ui.scroll({ in: SESSION, to: { key: `plugin-row-${name}` }, block: 'nearest' })
}

async function togglePlugin($: EngineInterface, name?: string) {
  const target = name ?? (await read($, harness))?.plugins?.[await read($, pluginSel)]?.name
  if (target) await update($, pluginOpen, open => ({ ...open, [target]: !open[target] }))
}

// What a plugin's items come to by kind: `skills 32k (314)   agents 8.2k (71)   chrome-devtools 0.8k`.
export function kindSummary(items: readonly Row[]): string {
  const part = (note: string, label: string) => {
    const rows = items.filter(i => i.note === note)
    return rows.length ? `${label} ${tokens(rows.reduce((a, r) => a + r.tokens, 0))} (${rows.length})` : ''
  }
  const mcp = items.filter(i => i.note === 'MCP').map(r => `${r.name} ${tokens(r.tokens)}`)
  return [part('skill', 'skills'), part('agent', 'agents'), ...mcp].filter(Boolean).join('   ')
}

export function registerSession(on: On) {
  on('ui.render', { component: 'Pane', requestId: SESSION }, async ($, e) => {
    const [stored, armed] = await Promise.all([read($, sessionTab), read($, compactArmed)])
    const tab = stored >= 1 && stored <= TABS.length ? stored : 1
    const ui = $.ui.resolve(e)
    const { Box, Button, Text } = ui
    const width = e.props.bodyColumns
    const body = tab === 2 ? await pluginsTab($, ui, width) : tab === 3 ? await cacheTab($, ui) : await contextTab($, ui, width)
    return (
      <Box flexDirection="column">
        <Box>
          <Box flexGrow={1}>
            {TABS.map((name, i) => (
              <Box key={`tab-${name}`}>
                <Button key={`tab-${i + 1}`} plain hotkey={`${i + 1}`} label={name} dimColor={tab !== i + 1} onPress={() => update($, sessionTab, () => i + 1)} />
                <Text>{'   '}</Text>
              </Box>
            ))}
          </Box>
          <Button key="compact" plain hotkey="c" label={armed ? 'press c again to compact' : 'compact'} onPress={() => compactNow($)} />
          <Text>{'   '}</Text>
          <Button key="close" plain hotkey="x" label="close" role="dismiss" onPress={() => toggleSession($)} />
        </Box>
        <Text color="inactive">{'─'.repeat(Math.max(10, width))}</Text>
        {e.props.isFocused ? <Text>{' '}</Text> : <Text color="warning">Click inside the pane (or ctrl+x tab) to use its keys.</Text>}
        {body}
      </Box>
    )
  })
}

// Where the window stands and what the account allows, then the categories, then the four detail lists folded.
async function contextTab($: EngineInterface, { Box, Button, Text }: Ui, width: number) {
  const [table, b, loaded, cx, us, compacted, open] = await Promise.all([
    read($, harness), read($, base), read($, skills), read($, ctx), read($, usage), read($, compactions), read($, ctxOpen), read($, tick),
  ])
  if (!table) return <Text color="subtle">Waiting for the first context reading.</Text>
  const now = Date.now()
  const name = Math.max(12, width - 26)
  const cap = cx ? (cx.compactAt ?? cx.window) : 0
  const fill = cx?.tokens !== undefined && cap ? cx.tokens / cap : undefined
  const limits = orderLimits(us?.limits ?? [])
  const budget = [
    ...limits.map(l => {
      const r = until(l.resetsAt, now)
      return `${limitLabel(l.kind)} ${Math.round(l.percentUsed)}%${r ? ` resets in ${r}` : ''}`
    }),
    us?.usd !== undefined ? `${usd(us.usd)} this session` : '',
  ].filter(Boolean)
  const line = (r: Row, delta?: number, isHeader?: boolean) => (
    <Box key={`${r.name}-${r.note ?? ''}`}>
      <Text color={isHeader ? 'text' : r.kind === 'free' || r.kind === 'deferred' ? 'inactive' : 'subtle'} bold={isHeader}>
        {cell(r.note ? `${r.name}  ${r.note}` : r.name, name)}
      </Text>
      <Text color={isHeader ? 'text' : 'claude'}>{tokens(r.tokens).padStart(8)}</Text>
      <Text color="subtle">{`${table.max ? Math.round((r.tokens / table.max) * 100) : 0}%`.padStart(6)}</Text>
      <Text color={delta && delta > 0 ? 'warning' : 'success'}>{(delta ? `${delta > 0 ? '+' : '-'}${tokens(Math.abs(delta))}` : '').padStart(10)}</Text>
    </Box>
  )
  const lists: Record<string, Row[]> = { memory: table.memory, mcp: table.mcp, skills: skillRows(table.skills, loaded), agents: table.agents }
  return (
    <Box flexDirection="column">
      {fill !== undefined && cx ? (
        <Box>
          <Text bold color="text">{cell('Used', LABEL)}</Text>
          <Text color="text">{`${tokens(cx.tokens ?? 0)} of ${tokens(cap)}  ${meter(fill)} ${Math.round(fill * 100)}%`}</Text>
          <Text color="subtle" wrap="truncate-end">{`${cx.compactAt ? '   of where compaction runs' : '   of the window'}${compacted ? `   compacted ${compacted}×` : ''}`}</Text>
        </Box>
      ) : null}
      {budget.length ? (
        <Box>
          <Text bold color="text">{cell('Budget', LABEL)}</Text>
          <Text color="subtle" wrap="truncate-end">{budget.join('    ')}</Text>
        </Box>
      ) : null}
      <Text>{' '}</Text>
      <Box>
        <Text bold color="text">{cell('Category', name)}</Text>
        <Text bold color="text">{'Tokens'.padStart(8)}</Text>
        <Text bold color="text">{'Share'.padStart(6)}</Text>
        <Text bold color="text">{'This turn'.padStart(10)}</Text>
      </Box>
      {table.rows.map(r => line(r, growth(r, b)))}
      {line({ name: 'Total', tokens: table.total }, undefined, true)}
      <Text>{' '}</Text>
      {SECTIONS.map(s => {
        const list = lists[s.id] ?? []
        const sum = list.reduce((a, r) => a + r.tokens, 0)
        const isOpen = open === s.id
        return (
          <Box key={`section-${s.id}`} flexDirection="column">
            <Box>
              <Button key={`section-${s.id}`} plain hotkey={s.key} label={`${isOpen ? '▾' : '▸'} ${s.title} (${list.length})`} onPress={() => toggleSection($, s.id)} />
              <Text color="claude">{`   ${tokens(sum)}`}</Text>
            </Box>
            {isOpen ? list.map(r => line({ ...r, name: `  ${r.name}` })) : null}
          </Box>
        )
      })}
    </Box>
  )
}

// One row per plugin, largest first; j/k pick (the pane scrolls to keep the pick in view), e or a click opens a row.
async function pluginsTab($: EngineInterface, { Box, Button, Text }: Ui, width: number) {
  const [table, open, sel] = await Promise.all([read($, harness), read($, pluginOpen), read($, pluginSel)])
  const plugins = table?.plugins ?? []
  if (!table || !plugins.length) return <Text color="subtle">No plugin puts anything in the context yet.</Text>
  const name = Math.max(12, Math.min(28, width - 50))
  const items = (plugin: string) => table.pluginItems?.[plugin] ?? []
  const shown = plugins.map((p, i) => ({ p, i }))
  return (
    <Box flexDirection="column">
      <Box>
        <Text bold color="text">{`  ${cell(`Plugin (${plugins.length})`, name)}`}</Text>
        <Text bold color="text">{'Tokens'.padStart(8)}</Text>
        <Text bold color="text">{'   Brings'}</Text>
      </Box>
      {shown.map(({ p, i }) => (
        <Box key={`plugin-${p.name}`} flexDirection="column">
          <Box>
            <Button key={`plugin-row-${p.name}`} plain onPress={() => update($, pluginSel, () => i).then(() => togglePlugin($, p.name))}>
              <Text color={i === sel ? 'suggestion' : 'text'}>{`${open[p.name] ? '▾' : '▸'} ${cell(p.name, name)}`}</Text>
            </Button>
            <Text color="claude">{tokens(p.tokens).padStart(8)}</Text>
            <Text color="subtle" wrap="truncate-end">{`   ${p.note ?? ''}`}</Text>
          </Box>
          {open[p.name] ? <Text color="subtle" wrap="truncate-end">{`    ${kindSummary(items(p.name))}`}</Text> : null}
          {open[p.name]
            ? items(p.name).map(item => (
                <Box key={`item-${p.name}-${item.note}-${item.name}`}>
                  <Text color="inactive">{`    ${cell(item.name, name - 2)}`}</Text>
                  <Text color="subtle">{tokens(item.tokens).padStart(8)}</Text>
                  <Text color="inactive">{`   ${item.note}`}</Text>
                </Box>
              ))
            : null}
        </Box>
      ))}
      <Box>
        <Button key="plugin-up" plain hotkey="k" label="up" onPress={() => movePlugin($, -1)} />
        <Text>{'   '}</Text>
        <Button key="plugin-down" plain hotkey="j" label="down" onPress={() => movePlugin($, 1)} />
        <Text>{'   '}</Text>
        <Button key="plugin-open" plain hotkey="e" label="open / fold" onPress={() => togglePlugin($)} />
        <Text color="inactive">{`   ${sel + 1}/${plugins.length}`}</Text>
      </Box>
    </Box>
  )
}

// The last request split by where its prompt came from, the run of recent hits, then every logged request, newest first.
async function cacheTab($: EngineInterface, { Box, Text }: Ui) {
  const [log] = await Promise.all([read($, cacheLog), read($, tick)])
  const lastStep = log.at(-1)
  if (!lastStep) return <Text color="subtle">No request has finished yet.</Text>
  const now = Date.now()
  const hits = log.map(hitOf)
  const avg = Math.round(hits.reduce((a, h) => a + h, 0) / hits.length)
  const lastWrite = [...log].reverse().find(s => s.written > 0)
  const all = lastStep.read + lastStep.written + lastStep.fresh
  const share = (n: number) => `${Math.round((n / all) * 100)}%`.padStart(5)
  const part = (label: string, n: number, what: string) => (
    <Box key={label}>
      <Text color="text">{cell(`  ${label}`, LABEL)}</Text>
      <Text color="claude">{tokens(n).padStart(8)}</Text>
      <Text color="subtle">{`${share(n)}   ${what}`}</Text>
    </Box>
  )
  return (
    <Box flexDirection="column">
      <Box>
        <Text bold color="text">{cell('Last', LABEL)}</Text>
        <Text color={hitOf(lastStep) < 50 ? 'warning' : 'text'}>{`${hitOf(lastStep)}% from cache`}</Text>
        <Text color="subtle">{`   ${ago(lastStep.at, now)} ago   ${tokens(all)} prompt tokens`}</Text>
      </Box>
      {part('read', lastStep.read, 'served from the cache')}
      {part('written', lastStep.written, 'added to the cache for the next request')}
      {part('new', lastStep.fresh, 'sent uncached')}
      <Text>{' '}</Text>
      <Box>
        <Text bold color="text">{cell('History', LABEL)}</Text>
        <Text color="text">{`${spark(hits)}  avg ${avg}%`}</Text>
        <Text color="subtle">{`   ${hits.length} request${hits.length === 1 ? '' : 's'}${lastWrite ? `   last written ${ago(lastWrite.at, now)} ago` : ''}`}</Text>
      </Box>
      <Text>{' '}</Text>
      {(
        <Box>
          <Text bold color="text">{cell('  when', LABEL)}</Text>
          <Text bold color="text">{`${'hit'.padStart(5)}${'read'.padStart(9)}${'written'.padStart(9)}${'new'.padStart(9)}`}</Text>
        </Box>
      )}
      {[...log].reverse().map((s, i) => (
        <Box key={`req-${s.at}-${i}`}>
          <Text color="subtle">{cell(`  ${ago(s.at, now)}`, LABEL)}</Text>
          <Text color={hitOf(s) < 50 ? 'warning' : 'subtle'}>{`${hitOf(s)}%`.padStart(5)}</Text>
          <Text color="subtle">{`${tokens(s.read).padStart(9)}${tokens(s.written).padStart(9)}${tokens(s.fresh).padStart(9)}`}</Text>
        </Box>
      ))}
    </Box>
  )
}
