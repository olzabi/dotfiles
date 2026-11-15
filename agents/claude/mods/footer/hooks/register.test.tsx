import { expect, test } from 'claude-code/testing'

import { baseOf, growth, pluginRows, skillRows, snapshot } from './harness'
import { ctxColor, duration, estimate, shortModel, tokens } from './format'
import { parseHint } from './register'
import { kindSummary } from './session'
import { faultsOf, gist, nextFault, promptText, target } from './trace'
import { busiest, drift, ownerOf, parseAheadBehind, parseWorktrees } from './worktrees'
import { ago, cacheStep, countDirty, hitOf, limitLabel, meter, orderLimits, parseRevParse, spark, until, usd } from './usage'

test('the live hint splits into vim and permission badges and plain parts without marks', () => {
  expect(parseHint('-- INSERT -- ⏵⏵ auto mode on (shift+tab to cycle) · ← 1 agent')).toEqual({
    vim: 'INSERT',
    perm: { label: 'AUTO', color: 'permission' },
    rest: ['1 agent'],
  })
  expect(parseHint('-- NORMAL -- ⏸ plan mode on (shift+tab to cycle)')).toEqual({
    vim: 'NORMAL',
    perm: { label: 'PLAN', color: 'planMode' },
    rest: [],
  })
  expect(parseHint('? for shortcuts')).toEqual({ rest: ['? for shortcuts'] })
  expect(parseHint('esc to interrupt · ctrl+t to hide todos').rest).toEqual(['esc to interrupt', 'ctrl+t to hide todos'])
})

test('model ids shorten; others pass as given', () => {
  expect(shortModel('claude-opus-5-5')).toBe('opus 5.5')
  expect(shortModel('claude-haiku-5-5-20261001')).toBe('haiku 5.5')
  expect(shortModel('gpt-x')).toBe('gpt-x')
})

test('context colors by how close it is to its cap', () => {
  expect(ctxColor(50_000, 160_000)).toBe('subtle')
  expect(ctxColor(120_000, 160_000)).toBe('warning')
  expect(ctxColor(150_000, 160_000)).toBe('error')
})

test('token counts read short', () => {
  expect([tokens(950), tokens(2_140), tokens(12_400), tokens(104_300), tokens(1_200_000)]).toEqual(['950', '2.1k', '12k', '104k', '1.2M'])
  expect(estimate('a'.repeat(4001))).toBe(1001)
})

test('jumps go back from the bottom and stop at both ends', () => {
  expect(target(null, 3, -1)).toBe(2)
  expect(target(null, 3, 1)).toBeNull()
  expect(target(0, 3, -1)).toBe(0)
  expect(target(2, 3, 1)).toBe(2)
  expect(target(null, 0, -1)).toBeNull()
})

const HINT = { plugin: 'footer', component: 'PromptHint', requestId: 'hint' } as const

test('the footer draws the badges, the plain hint and the model', async ($, on) => {
  on('session.model', () => ({ value: 'claude-opus-5-5' }))
  on('agent.list', () => ({
    value: [
      { id: 'a1', description: 'research the API', type: 'Explore', status: 'running' },
      { id: 'a2', description: 'finished one', type: 'Explore', status: 'completed' },
    ],
  }))

  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({
      ...HINT,
      surface,
      props: { isDraft: false, isWorking: true, hint: '-- INSERT -- ⏵⏵ auto mode on (shift+tab to cycle) · ← 1 agent' },
    })
    expect((await ui.find({ type: 'Text', text: /INSERT/ }))?.text).toBe(' INSERT ')
    expect((await ui.find({ type: 'Text', text: /AUTO/ }))?.text).toBe(' AUTO ')
    // The agents pill becomes a button per live agent; its text is gone.
    expect((await ui.find({ type: 'Text', text: /research/ }))?.text).toBe('  research the API')
    expect(await ui.find({ type: 'Text', text: /1 agent|finished/ })).toBeFalsy()
    expect(await ui.find({ type: 'Text', text: /opus 5\.5/ })).toBeTruthy()
    expect(await ui.find({ type: 'Text', text: /shift\+tab|⏵/ })).toBeFalsy()
    await ui.unmount()
  }
})

test('durations read as the engine writes them', () => {
  expect([duration(6000), duration(126000), duration(3840000)]).toEqual(['6s', '2m 6s', '1h 4m'])
})

test('the harness snapshot groups MCP tools by server and sorts each section by size', () => {
  const b = {
    categories: [
      { name: 'System prompt', tokens: 3000, kind: 'used' },
      { name: 'Messages', tokens: 40000, kind: 'used' },
      { name: 'Free space', tokens: 100000, kind: 'free' },
    ],
    mcpTools: [
      { name: 'a', serverName: 'memory', tokens: 500, isLoaded: true },
      { name: 'b', serverName: 'memory', tokens: 300, isLoaded: false },
      { name: 'c', serverName: 'headroom', tokens: 900, isLoaded: true },
    ],
    memoryFiles: [{ path: '/home/me/.claude/CLAUDE.md', type: 'User', tokens: 700 }],
    agents: [{ agentType: 'Explore', source: 'built-in', tokens: 200 }],
    skills: { totalSkills: 2, includedSkills: 2, tokens: 150, skillFrontmatter: [{ name: 'pdf', source: 'plugin', tokens: 50 }, { name: 'xlsx', source: 'plugin', tokens: 100 }] },
    totalTokens: 43000,
    rawMaxTokens: 200000,
  } as never
  const h = snapshot(b)
  expect(h.mcp).toEqual([
    { name: 'headroom', tokens: 900, note: '1/1 tools' },
    { name: 'memory', tokens: 500, note: '1/2 tools' },
  ])
  expect(h.memory[0]).toEqual({ name: '.claude/CLAUDE.md', tokens: 700, note: 'User' })
  expect(h.skills.map(s => s.name)).toEqual(['xlsx', 'pdf'])
  expect(skillRows(h.skills, { ponytail: 2000 })[0]).toEqual({ name: 'ponytail', tokens: 2000, note: 'loaded' })
  const was = baseOf(h)
  expect(growth({ name: 'Messages', tokens: 45000 }, was)).toBe(5000)
  expect(growth({ name: 'System prompt', tokens: 3000 }, was)).toBeUndefined()
})


test('usage windows read short, in order, with resets only while ahead', () => {
  expect([limitLabel('five_hour'), limitLabel('seven_day'), limitLabel('spend_limit'), limitLabel('x')]).toEqual(['5h', '7d', 'spend', 'x'])
  expect(orderLimits([{ kind: 'seven_day', percentUsed: 1 }, { kind: 'five_hour', percentUsed: 2 }]).map(l => l.kind)).toEqual(['five_hour', 'seven_day'])
  const now = Date.parse('2026-11-10T12:00:00Z')
  expect(until('2026-11-10T12:35:00Z', now)).toBe('35m')
  expect(until('2026-11-10T13:42:00Z', now)).toBe('1h42m')
  expect(until('2026-11-12T12:00:00Z', now)).toBe('2d')
  expect(until('2026-11-10T11:00:00Z', now)).toBeUndefined()
  expect(until(undefined, now)).toBeUndefined()
  expect([usd(3.421), usd(0.07), usd(12.6)]).toEqual(['$3.42', '$0.07', '$13'])
})

test('git output reads into branch, worktree and uncommitted lines', () => {
  const main = '/p/erp\n/p/erp/.git\n/p/erp/.git\n'
  const linked = '/p/erp/.claude/worktrees/fix-x\n/p/erp/.git/worktrees/fix-x\n/p/erp/.git\n'
  expect(parseRevParse(main, 'dev\n')).toEqual({ branch: 'dev', worktree: undefined })
  expect(parseRevParse(linked, 'fix/tab\n')).toEqual({ branch: 'fix/tab', worktree: 'fix-x' })
  expect(parseRevParse('/p/w\n/p/.git/worktrees/w\n/p/.git\n', 'w')).toEqual({ branch: 'w', worktree: undefined })
  expect(parseRevParse(main, '')).toEqual({ branch: null, worktree: undefined })
  expect(parseRevParse('', 'dev')).toBeNull()
  expect(countDirty(' M a.ts\n?? b.ts\n')).toBe(2)
})

test('meters fill by share', () => {
  expect([meter(0), meter(0.63), meter(1.4)]).toEqual(['▱▱▱▱▱▱▱▱', '▰▰▰▰▰▱▱▱', '▰▰▰▰▰▰▰▰'])
})

const seed = (on: (event: 'state.get', hook: never) => void, values: Record<string, unknown>) =>
  on('state.get', ((_: unknown, e: { key: string }) => ({ value: { value: values[e.key], version: 1 } })) as never)

test('the line stays quiet: branch, model and a context meter with the cache share', async ($, on) => {
  seed(on as never, {
    ctx: { tokens: 100_000, window: 1_000_000, compactAt: 160_000 },
    repo: { branch: 'dev', dirty: 3 },
    turn: { ms: 126_000, at: 0 },
    usage: { limits: [{ kind: 'five_hour', percentUsed: 37, resetsAt: '2099-01-01T00:00:00Z' }, { kind: 'seven_day', percentUsed: 12 }], usd: 3.42 },
    cacheLog: [{ read: 92, written: 0, fresh: 8, at: 0 }],
  })
  on('session.model', () => ({ value: 'claude-opus-5-5' }))
  on('agent.list', () => ({ value: [] }))
  const ui = await $.ui.mount({ ...HINT, surface: 'terminal', props: { isDraft: false, isWorking: false, hint: '? for shortcuts' } })
  for (const text of [/^dev$/, /●3/, /opus 5\.5/, /^ · 2m 6s$/, /^context ▰▰▰▰▰▱▱▱ 100k\/160k$/, /^92% cached$/]) {
    expect(await ui.find({ type: 'Text', text })).toBeTruthy()
  }
  // The rest waits in the session pane: no cost beside a window, no reset under 70%, no lines changed.
  expect(await ui.find({ type: 'Text', text: /\$3|resets|5h|7d|\+212/ })).toBeFalsy()
  await ui.unmount()
})

test('a low cache share shows in the warning colour and usage stays out of the footer', async ($, on) => {
  const later = new Date(Date.now() + 102 * 60_000).toISOString()
  seed(on as never, { usage: { limits: [{ kind: 'five_hour', percentUsed: 82, resetsAt: later }] }, cacheLog: [{ read: 12, written: 80, fresh: 8, at: 0 }], ctx: { tokens: 150_000, window: 1_000_000, compactAt: 160_000 } })
  on('session.model', () => ({ value: 'claude-opus-5-5' }))
  on('agent.list', () => ({ value: [] }))
  const ui = await $.ui.mount({ ...HINT, surface: 'terminal', props: { isDraft: false, isWorking: false, hint: '' } })
  expect(await ui.find({ type: 'Text', text: /5h|82%/ })).toBeFalsy()
  expect(await ui.find({ type: 'Text', text: /^12% cached$/ })).toBeTruthy()
  await ui.unmount()
})


test('the cache log reads request by request', () => {
  const step = cacheStep({ input_tokens: 2, output_tokens: 9, cache_read_input_tokens: 90, cache_creation_input_tokens: 8 }, 5)
  expect(step).toEqual({ read: 90, written: 8, fresh: 2, at: 5 })
  expect(hitOf(step!)).toBe(90)
  expect(cacheStep({ input_tokens: 0, output_tokens: 1, cache_read_input_tokens: 0, cache_creation_input_tokens: 0 }, 5)).toBeUndefined()
  expect(spark([0, 50, 99, 100])).toBe('▁▅██')
  expect([ago(0, 14_000), ago(0, 180_000), ago(0, 3_900_000)]).toEqual(['14s', '3m', '1h5m'])
})

test('plugins add up their skills, agents and MCP tools', () => {
  const rows = pluginRows({
    skills: { skillFrontmatter: [{ name: 'a', source: 'plugin', pluginName: 'ecc', tokens: 40 }, { name: 'b', source: 'plugin', pluginName: 'ecc', tokens: 60 }, { name: 'c', source: 'userSettings', tokens: 999 }] },
    agents: [{ agentType: 'ecc:architect', source: 'plugin', tokens: 30 }, { agentType: 'Explore', source: 'built-in', tokens: 999 }],
    mcpTools: [{ name: 'x', serverName: 'plugin:ecc:chrome-devtools', tokens: 20, isLoaded: true }, { name: 'y', serverName: 'plugin:ponytail:p', tokens: 5, isLoaded: true }, { name: 'z', serverName: 'memory', tokens: 999, isLoaded: true }],
  } as never)
  expect(rows).toEqual([
    { name: 'ecc', tokens: 150, note: '2 skills · 1 agent · 1 MCP' },
    { name: 'ponytail', tokens: 5, note: '1 MCP' },
  ])
})

test('the trace reads prompts and failures and steps through failures newest first', () => {
  expect(gist('\n  tsc: not found\nmore')).toBe('tsc: not found')
  expect(gist('x'.repeat(100), 10)).toBe(`${'x'.repeat(9)}…`)
  expect(promptText([{ type: 'text', text: 'fix the\n  footer' }, { type: 'image' }, { type: 'text', text: 'now' }] as never)).toBe('fix the footer now')
  const t = [
    { id: 'p1', text: 'a', at: 0, tools: 2, faults: [{ id: 't1', tool: 'Bash', summary: 'x', at: 0 }] },
    { id: 'p2', text: 'b', at: 0, tools: 1, faults: [] },
    { id: 'p3', text: 'c', at: 0, tools: 3, faults: [{ id: 't2', tool: 'Edit', summary: 'y', at: 0 }] },
  ]
  expect(faultsOf(t).map(f => [f.id, f.prompt])).toEqual([['t1', 0], ['t2', 2]])
  expect([nextFault(null, 2), nextFault(1, 2), nextFault(0, 2), nextFault(null, 0)]).toEqual([1, 0, 1, null])
})

const TRAIL = [
  { id: 'p1', text: 'run the checks', at: Date.parse('2026-11-10T14:02:00'), tools: 4, faults: [{ id: 'tu1', tool: 'Bash', summary: 'zsh: command not found: tsc', at: 0 }] },
  { id: 'p2', text: 'redesign the footer', at: Date.parse('2026-11-10T14:30:00'), tools: 1, faults: [] },
]

test('the footer navigator sits before the agents: prompt position, then failures', async ($, on) => {
  seed(on as never, { trail: TRAIL })
  on('session.model', () => ({ value: 'claude-opus-5-5' }))
  on('agent.list', () => ({ value: [{ id: 'a1', description: 'research the API', type: 'Explore', status: 'running' }] }))
  const ui = await $.ui.mount({ ...HINT, surface: 'terminal', props: { isDraft: false, isWorking: true, hint: '-- INSERT -- · ← 1 agent' } })
  expect((await ui.find({ type: 'Text', text: /^prompt/ }))?.text).toBe('prompt 2/2')
  expect((await ui.find({ type: 'Text', text: /failed/ }))?.text).toBe('✗ 1 failed')
  expect(await ui.find({ type: 'Text', text: /research the API/ })).toBeTruthy()
  await ui.unmount()
})

test('the trace pane lists prompts newest first with their failures under them', async ($, on) => {
  seed(on as never, { trail: TRAIL })
  const ui = await $.ui.mount({
    plugin: 'footer', component: 'Pane', requestId: 'trace', surface: 'terminal',
    props: { title: 'Trace', isFocused: false, bodyColumns: 80, placement: 'dock', scroll: { offset: 0, bodyRows: 30 }, view: {} },
  } as never)
  const rows = await ui.findAll({ type: 'Text', text: /^#\d/ })
  expect(rows.map(r => r.text.trim())).toEqual(['#2', '#1'])
  expect((await ui.find({ type: 'Text', text: /4 tools/ }))?.text).toBe('  2:02 PM  4 tools')
  expect((await ui.find({ type: 'Text', text: /^✗/ }))?.text).toBe('✗ Bash')
  expect((await ui.find({ type: 'Text', text: /command not found/ }))?.text).toBe('  zsh: command not found: tsc')
  await ui.unmount()
})

const SESSION_PANE = {
  plugin: 'footer', component: 'Pane', requestId: 'harness', surface: 'terminal',
  props: { title: 'Session', isFocused: true, bodyColumns: 90, placement: 'dock', scroll: { offset: 0, bodyRows: 40 }, view: {} },
} as never


test('the Plugins tab lists plugins and opens one to what it brings', async ($, on) => {
  const harness = {
    rows: [], mcp: [], memory: [], agents: [], skills: [], total: 0, max: 1,
    plugins: [{ name: 'ecc', tokens: 41_000, note: '314 skills · 71 agents · 1 MCP' }, { name: 'ponytail', tokens: 2100, note: '3 skills' }],
    pluginItems: { ecc: [{ name: 'architect', tokens: 900, note: 'agent' }, { name: 'tdd', tokens: 500, note: 'skill' }, { name: 'chrome-devtools', tokens: 800, note: 'MCP' }] },
  }
  seed(on as never, { sessionTab: 2, harness, pluginOpen: { ecc: true } })
  const ui = await $.ui.mount(SESSION_PANE)
  expect(await ui.find({ type: 'Text', text: /^▾ ecc/ })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: /^▸ ponytail/ })).toBeTruthy()
  expect((await ui.find({ type: 'Text', text: /skills 500/ }))?.text).toBe('    skills 500 (1)   agents 900 (1)   chrome-devtools 800')
  await ui.unmount()
})

test('the Cache tab splits the last request and lists recent ones', async ($, on) => {
  seed(on as never, { sessionTab: 3, cacheLog: [{ read: 92_000, written: 6_000, fresh: 2_000, at: Date.now() - 14_000 }] })
  const ui = await $.ui.mount(SESSION_PANE)
  expect((await ui.find({ type: 'Text', text: /from cache$/ }))?.text).toBe('92% from cache')
  expect(await ui.find({ type: 'Text', text: /added to the cache/ })).toBeTruthy()
  await ui.unmount()
})

test('kind summaries add up a plugin by kind', () => {
  expect(kindSummary([{ name: 'a', tokens: 1000, note: 'skill' }, { name: 'b', tokens: 2000, note: 'skill' }, { name: 'srv', tokens: 300, note: 'MCP' }])).toBe('skills 3.0k (2)   srv 300')
})

test('worktree output reads into paths, branches, drift and owners', () => {
  const porcelain = 'worktree /r\nHEAD a\nbranch refs/heads/dev\n\nworktree /r/.claude/worktrees/x\nHEAD b\ndetached\n'
  expect(parseWorktrees(porcelain)).toEqual([{ path: '/r', branch: 'dev' }, { path: '/r/.claude/worktrees/x', branch: null }])
  expect(parseAheadBehind('2\t5\n')).toEqual({ behind: 2, ahead: 5 })
  expect(parseAheadBehind('')).toBeUndefined()
  expect(ownerOf('/r/.claude/worktrees/x/src', ['/r', '/r/.claude/worktrees/x'])).toBe('/r/.claude/worktrees/x')
  expect(ownerOf('/r/apps', ['/r', '/r/.claude/worktrees/x'])).toBe('/r')
  expect(ownerOf('/elsewhere', ['/r'])).toBeUndefined()
  expect(busiest(['idle', 'working', 'odd'])).toBe('working')
  const t = { path: '/r', branch: 'dev', isCurrent: true }
  expect([drift(t), drift({ ...t, ahead: 0, behind: 0 }), drift({ ...t, ahead: 2, behind: 1 })]).toEqual(['no upstream', 'even', '↑2 ↓1'])
})

test('the worktrees pane draws one row per worktree with the current one marked', async ($, on) => {
  seed(on as never, {
    trees: [
      { path: '/r', branch: 'dev', isCurrent: true, dirty: 3, ahead: 0, behind: 2 },
      { path: '/r/w', branch: 'feat/catalog-engine', isCurrent: false, dirty: 0, agent: 'working' },
    ],
    treesAt: Date.now() - 12_000,
  })
  const ui = await $.ui.mount({ ...(SESSION_PANE as object), requestId: 'worktrees', props: { title: 'Worktrees', isFocused: true, bodyColumns: 100, placement: 'dock', scroll: { offset: 0, bodyRows: 40 }, view: {} } } as never)
  expect((await ui.find({ type: 'Text', text: /^Worktrees/ }))?.text).toBe('Worktrees (2)')
  expect(await ui.find({ type: 'Text', text: /^●dev/ })).toBeTruthy()
  expect((await ui.find({ type: 'Text', text: /^↓2/ }))?.text?.trim()).toBe('↓2')
  expect((await ui.find({ type: 'Text', text: /^agent/ }))?.text).toBe('agent working')
  expect((await ui.find({ type: 'Text', text: /^here$/ }))).toBeTruthy()
  await ui.unmount()
})

test('the Context tab puts the budget above the categories and folds the lists', async ($, on) => {
  seed(on as never, {
    sessionTab: 1,
    ctx: { tokens: 104_000, window: 1_000_000, compactAt: 164_000 },
    usage: { limits: [{ kind: 'seven_day', percentUsed: 48 }, { kind: 'five_hour', percentUsed: 37 }], usd: 3.42 },
    harness: { rows: [{ name: 'Messages', tokens: 40000, kind: 'used' }], mcp: [{ name: 'memory', tokens: 500, note: '1/2 tools' }], memory: [], agents: [], skills: [], total: 40000, max: 200000 },
    ctxOpen: 'mcp',
  })
  const ui = await $.ui.mount(SESSION_PANE)
  expect((await ui.find({ type: 'Text', text: /^5h/ }))?.text).toBe('5h 37%    7d 48%    $3.42 this session')
  expect((await ui.find({ type: 'Text', text: /^104k of 164k/ }))).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: /^ {2}memory/ })).toBeTruthy()
  await ui.unmount()
})

