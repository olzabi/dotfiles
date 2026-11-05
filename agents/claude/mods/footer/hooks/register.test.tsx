import { expect, test } from 'claude-code/testing'

import { baseOf, growth, skillRows, snapshot } from './harness'
import { ctxColor, duration, estimate, parseHint, shortModel, skillReport, target, tokens } from './register'

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

test('the skills report lists the listing, then loaded skills by size', () => {
  expect(skillReport(2100, { small: 900, big: 5000 })).toBe('listing 2.1k  big 5.0k  small 900')
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

test('the harness pane draws the categories and sections', async ($, on) => {
  const seeded = { rows: [{ name: 'Messages', tokens: 40000, kind: 'used' }], mcp: [{ name: 'memory', tokens: 500, note: '1/2 tools' }], memory: [], agents: [], skills: [], total: 40000, max: 200000 }
  // What a measurement stored earlier; every other value reads as never stored.
  on('state.get', (_, e) => ({ value: { value: e.key === 'harness' ? seeded : undefined, version: 1 } }) as never)
  const ui = await $.ui.mount({
    plugin: 'footer', component: 'Pane', requestId: 'harness', surface: 'terminal',
    props: { title: 'Harness', isFocused: false, bodyColumns: 60, placement: 'dock', scroll: { offset: 0, bodyRows: 30 }, view: {} },
  } as never)
  expect(await ui.find({ type: 'Text', text: /^Messages/ })).toBeTruthy()
  expect(await ui.find({ type: 'Text', text: /MCP servers/ })).toBeTruthy()
  expect((await ui.find({ type: 'Text', text: /^ +20%$/ }))?.text).toBe('   20%')
  await ui.unmount()
})
