import { expect, test } from 'claude-code/testing'

const ROW = {
  plugin: 'hush',
  component: 'ToolUse',
  requestId: 't1',
  surface: 'terminal',
  props: { tool_use_id: 't1', tool: 'Bash', input: { command: 'cd x && git log -1', description: 'Show last commit' }, isRunning: false, isErrored: false, isInterrupted: false },
} as const

test('a JSON MCP result reaches the model as TOON', async ($, on) => {
  const json = JSON.stringify({ items: [{ id: 1, name: 'one' }, { id: 2, name: 'two' }] }, null, 2)
  on('tool.call', () => ({ result: [{ type: 'text', text: json }], text: json }))

  const r = await $.tool.call({ tool: 'mcp__srv__list' } as never)

  expect((r as { result: unknown }).result).toEqual([{ type: 'text', text: 'items[2]{id,name}:\n  1,one\n  2,two' }])
})

test('a press on a row label unfolds its output in place; ▾ marks it', async ($, on) => {
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
  const output = { stdout: 'c0ddb1f fix\n', stderr: '' }
  const ui = await $.ui.mount({ ...ROW, props: { ...ROW.props, output } } as never)

  expect((await ui.find({ type: 'Text', text: /GIT/ }))?.text).toBe('GIT  ')
  expect((await ui.find({ type: 'Text', text: /Show last commit/ }))?.text).toBe(' Show last commit')
  expect(await ui.find({ type: 'Text', text: /▾/ })).toBeFalsy()
  await ui.press({ key: 'row-t1' })
  expect((await ui.find({ type: 'Text', text: /▾/ }))?.text).toBe('▾ ')
  await ui.unmount()

  const result = await $.ui.mount({
    plugin: 'hush', component: 'ToolResult', requestId: 't1', surface: 'terminal',
    props: { tool_use_id: 't1', tool: 'Bash', isErrored: false, output },
  } as never)
  expect((await result.find({ type: 'Text', text: /c0ddb1f/ }))?.text).toBe('  c0ddb1f fix')
  await result.unmount()
})

const SAID = `Checking the build. ${'x'.repeat(100)}`

test('text of a step that ended in tool calls folds to its first 80 characters', async ($, on) => {
  on('turn.step', async function* () {
    yield { kind: 'text', index: 0, text: SAID }
    return { turnId: 't', index: 0, answer: SAID, toolUses: [{ id: 'x', name: 'Bash', input: {} }], stopReason: 'tool_use', usage: null }
  } as never)
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
  const step = $.turn.step({ turnId: 't', index: 0, model: 'm', messageCount: 1 } as never)
  for await (const _ of step) void _
  await step.result

  const ui = await $.ui.mount({
    plugin: 'hush', component: 'AssistantMessage', requestId: 'a1', surface: 'terminal',
    props: { text: SAID, isFirstOfReply: true },
  } as never)
  expect((await ui.find({ type: 'Text', text: /Checking/ }))?.text).toBe(`Checking the build. ${'x'.repeat(59)}…`)
  expect(await ui.find({ type: 'Text', text: /engine/ })).toBeFalsy()
  await ui.unmount()
})

const READ = (content: string) =>
  ({
    plugin: 'hush', component: 'ToolResult', requestId: 'r1', surface: 'terminal',
    props: { tool_use_id: 'r1', tool: 'Read', isErrored: false, output: { type: 'text', file: { filePath: '/a/shop.ts', content, numLines: 5, startLine: 1, totalLines: 5 } } },
  }) as never

test('a result folds to its row by default', async $ => {
  const ui = await $.ui.mount(READ('export class Shop {}'))

  expect(await ui.find({ type: 'Text' })).toBeFalsy()
  await ui.unmount()
})

test('with previews on, a Read shows its declaration outline', async ($, on) => {
  on('store.set', () => ({ value: undefined }) as never)
  const pane = await $.ui.mount({
    plugin: 'hush', component: 'Pane', requestId: 'hush', surface: 'terminal',
    props: { title: 'Hush', isFocused: false, bodyColumns: 80, placement: 'dock', scroll: { offset: 0, bodyRows: 30 }, view: {} },
  } as never)
  await pane.press({ key: 'toggle-previews' })
  await pane.unmount()

  const ui = await $.ui.mount(READ('export class Shop {\n  total() {\n    return 1\n  }\n}'))

  expect((await ui.find({ type: 'Text', text: /class Shop/ }))?.text).toBe('   1 export class Shop')
  await ui.unmount()
})

test('@@ completes offered agent types', async ($, on) => {
  on('agent.offer', () => ({ isOffered: true }))
  on('prompt.autocomplete', () => ({ suggestions: [] }))
  await $.agent.offer({ agent: 'Explore', description: 'Read-only search', source: 'built-in' } as never)

  // shortcut: prompt.autocomplete is not on the typed test noun yet; drop the cast once it is.
  const complete = ($.prompt as unknown as { autocomplete: (e: unknown) => Promise<{ suggestions: unknown[] }> }).autocomplete
  const r = await complete({ text: 'ask @@ex', cursor: 8, token: '@@ex', start: 4 })

  expect(r.suggestions).toEqual([{ text: '@@Explore ', label: '@@Explore', description: 'Read-only search' }])
})

test('the spinner line draws nothing by default', async $ => {
  const ui = await $.ui.mount({
    plugin: 'hush', component: 'Spinner', requestId: 's', surface: 'terminal',
    props: { word: 'Sauteing', message: null, suffix: '…', mode: 'thinking' },
  } as never)

  expect(await ui.find({ type: 'Text' })).toBeFalsy()
  await ui.unmount()
})

test('a reply draws padded with no bullet', async ($, on) => {
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
  const ui = await $.ui.mount({
    plugin: 'hush', component: 'AssistantMessage', requestId: 'a2', surface: 'terminal',
    props: { text: 'All done.', isFirstOfReply: true },
  } as never)

  expect(await ui.find({ type: 'Text', text: /●|engine/ })).toBeFalsy()
  await ui.unmount()
})

test('a run with a failed call lists every call, the failure red with its reason', async $ => {
  const calls = [
    { tool_use_id: 'c1', tool: 'Bash', input: { command: 'ls' }, isRunning: false, isErrored: false, isInterrupted: false, output: { stdout: 'a', stderr: '' } },
    { tool_use_id: 'c2', tool: 'Bash', input: { command: 'rm -rf x' }, isRunning: false, isErrored: true, isInterrupted: false, output: 'Permission to use Bash with command rm -rf x has been denied.' },
  ]
  const ui = await $.ui.mount({
    plugin: 'hush', component: 'ToolGroup', requestId: 'g1', surface: 'terminal',
    props: { calls, isActive: false, isExpanded: false, isCallsOnly: false },
  } as never)

  expect((await ui.find({ type: 'Text', text: /ls/ }))?.text).toBe(' ls')
  expect((await ui.find({ type: 'Text', text: /denied/ }))?.text).toBe('  │ Permission to use Bash with command rm -rf x has been denied.')
  expect(await ui.find({ type: 'Text', text: /calls$/ })).toBeFalsy()
  await ui.unmount()
})

test('a typed prompt draws as a USER call row on one line under a rule; a press unfolds it', async $ => {
  const ui = await $.ui.mount({
    plugin: 'hush', component: 'UserMessage', requestId: 'u1', surface: 'terminal',
    props: { text: 'fix the scroll\nand the label', origin: { kind: 'composer' } },
  } as never)
  expect((await ui.find({ type: 'Text', text: /USER/ }))?.props.color).toBe('ide')
  expect(await ui.find({ type: 'Text', text: /^─+$/ })).toBeTruthy()
  expect((await ui.find({ type: 'Text', text: /scroll/ }))?.text).toBe(' fix the scroll and the label')
  await ui.press({ key: 'row-user-u1' })
  expect((await ui.find({ type: 'Text', text: /\n/ }))?.text).toBe('fix the scroll\nand the label')
  await ui.unmount()
})

test('a failed call shows in the band; a press unfolds it; prompt and thought only while working', async ($, on) => {
  on('tool.call', () => ({ result: {}, isError: true, text: 'no' }) as never)
  await $.tool.call({ tool: 'Bash', tool_use_id: 'f1', command: 'rm -rf x' } as never)
  await $.prompt.submit({ text: 'do it', origin: { kind: 'composer' } } as never).catch(() => undefined)

  const ui = await $.ui.mount({
    plugin: 'hush', component: 'AbovePrompt', requestId: 'band', surface: 'terminal',
    props: { hasSurvey: false, isWorking: false, view: {}, bodyColumns: 80 },
  } as never)
  expect((await ui.find({ type: 'Text', text: /failed/ }))?.text).toBe('✗ 1 failed ')
  expect(await ui.find({ type: 'Text', text: /do it/ })).toBeFalsy()
  await ui.press({ key: 'fail-f1' })
  await ui.unmount()

  const row = await $.ui.mount({
    plugin: 'hush', component: 'ToolResult', requestId: 'f1', surface: 'terminal',
    props: { tool_use_id: 'f1', tool: 'Bash', isErrored: true, output: 'Permission denied.\nmore' },
  } as never)
  expect((await row.find({ type: 'Text', text: /more/ }))?.text).toBe('  more')
  await row.unmount()
})

test('a short final reply inside earlier narration is not folded', async ($, on) => {
  const said = 'Done. Now running the tests.'
  on('turn.step', async function* () {
    yield { kind: 'text', index: 0, text: said }
    return { turnId: 't', index: 0, answer: said, toolUses: [{ id: 'x', name: 'Bash', input: {} }], stopReason: 'tool_use', usage: null }
  } as never)
  const step = $.turn.step({ turnId: 't', index: 0, model: 'm', messageCount: 1 } as never)
  for await (const _ of step) void _
  await step.result

  const ui = await $.ui.mount({
    plugin: 'hush', component: 'AssistantMessage', requestId: 'a9', surface: 'terminal',
    props: { text: 'Done.', isFirstOfReply: false },
  } as never)
  expect(await ui.find({ type: 'Button' })).toBeFalsy()
  await ui.unmount()
})

test('an engine summary draws as a dim line with no bullet; `command cat` is labelled CAT', async ($, on) => {
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>● engine</Text>
  })
  const ui = await $.ui.mount({
    plugin: 'hush', component: 'AssistantMessage', requestId: 's1', surface: 'terminal',
    props: { text: 'Rewrote the theme.', isFirstOfReply: false, isSummary: true },
  } as never)
  expect(await ui.find({ type: 'Text', text: /●/ })).toBeFalsy()
  expect((await ui.find({ type: 'Text', text: /Rewrote/ }))?.props.dimColor).toBe(true)
  await ui.unmount()

  const row = await $.ui.mount({
    plugin: 'hush', component: 'ToolUse', requestId: 'c9', surface: 'terminal',
    props: { tool_use_id: 'c9', tool: 'Bash', input: { command: 'command cat a.md' }, isRunning: false, isErrored: false },
  } as never)
  expect(await row.find({ type: 'Text', text: /^CAT/ })).toBeTruthy()
  await row.unmount()
})

test('a subagent row is labelled by its type', async $ => {
  const row = await $.ui.mount({
    plugin: 'hush', component: 'ToolUse', requestId: 'g1', surface: 'terminal',
    props: { tool_use_id: 'g1', tool: 'Agent', input: { subagent_type: 'plugin-dev:agent-creator', description: 'make it' }, isRunning: false, isErrored: false },
  } as never)
  expect(await row.find({ type: 'Text', text: /^AGENT-CREATOR/ })).toBeTruthy()
  await row.unmount()

  const first = await $.ui.mount({
    plugin: 'hush', component: 'AssistantMessage', requestId: 'z2', surface: 'terminal',
    props: { text: 'Hi.', isFirstOfReply: true },
  } as never)
  expect(await first.find({ type: 'Text', text: /^─+$/ })).toBeFalsy()
  await first.unmount()
})

test('the turn line draws nothing in the transcript', async $ => {
  const ui = await $.ui.mount({
    plugin: 'hush', component: 'TurnDuration', requestId: 't1', surface: 'terminal',
    props: { word: 'Brewed', durationMs: 6000 },
  } as never)
  expect(await ui.find({ type: 'Text' })).toBeFalsy()
  await ui.unmount()
})

test('the answer after a turn\'s tool calls gets a rule; a first answer does not', async ($, on) => {
  on('turn.step', async function* (_: unknown, e: { index: number }) {
    const answer = e.index === 0 ? '' : 'All set.'
    return { turnId: 't', index: e.index, answer, toolUses: e.index === 0 ? [{ id: 'x', name: 'Bash', input: {} }] : [], stopReason: 'end_turn', usage: null }
  } as never)
  for (const index of [0, 1]) {
    const step = $.turn.step({ turnId: 't', index, model: 'm', messageCount: 1 } as never)
    for await (const _ of step) void _
    await step.result
  }
  const last = await $.ui.mount({
    plugin: 'hush', component: 'AssistantMessage', requestId: 'z1', surface: 'terminal',
    props: { text: 'All set.', isFirstOfReply: true },
  } as never)
  expect(await last.find({ type: 'Text', text: /^─+$/ })).toBeTruthy()
  expect(await last.find({ type: 'Text', text: /p\.text/ })).toBeFalsy()
  await last.unmount()
})
