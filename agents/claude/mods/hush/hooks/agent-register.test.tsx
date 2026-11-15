import { expect, test } from 'claude-code/testing'

const long = Array.from({ length: 400 }, (_, i) => `row ${i}`).join('\n')

test('long Bash output reaches the model as head + tail; the whole is written to disk', async ($, on) => {
  const files = new Map<string, string>()
  on('tool.call', () => ({ result: { stdout: long, stderr: '', interrupted: false } as never, text: long }))
  on('fs.write', ($, e) => (files.set(e.path, e.text), { value: undefined }) as never)

  const r = await $.tool.call({ tool: 'Bash', command: 'pnpm build', description: 'Build' } as never)
  const out = (r.result as { stdout: string }).stdout

  expect(out).toContain('300 lines cut; whole output:')
  const path = /whole output: (\S+)\]/.exec(out)?.[1] ?? ''
  expect(files.get(path)).toBe(long)
})

test('without a place to save the whole, nothing is cut', async ($, on) => {
  on('tool.call', () => ({ result: { stdout: long, stderr: '', interrupted: false } as never, text: long }))

  const r = await $.tool.call({ tool: 'Bash', command: 'pnpm build', description: 'Build' } as never)

  expect((r.result as { stdout: string }).stdout).toBe(long)
})

test('output bounded by the command passes whole', async ($, on) => {
  on('tool.call', () => ({ result: { stdout: long, stderr: '', interrupted: false } as never, text: long }))

  const r = await $.tool.call({ tool: 'Bash', command: 'sed -n 1,400p big.txt', description: 'Show file' } as never)

  expect((r.result as { stdout: string }).stdout).toBe(long)
})

test('a re-read of the same unchanged range is a pointer', async ($, on) => {
  const content = 'x'.repeat(1000)
  on('tool.call', () => ({ result: { type: 'text', file: { filePath: '/r/a.ts', content, numLines: 1, startLine: 1, totalLines: 1 } } as never }))

  const first = await $.tool.call({ tool: 'Read', file_path: '/r/a.ts' } as never)
  const second = await $.tool.call({ tool: 'Read', file_path: '/r/a.ts' } as never)

  expect((first.result as { file: { content: string } }).file.content).toBe(content)
  expect((second.result as { file: { content: string } }).file.content).toContain('unchanged since your read')
  const third = await $.tool.call({ tool: 'Read', file_path: '/r/a.ts' } as never)
  expect((third.result as { file: { content: string } }).file.content).toBe(content)
})

test('a Bash call without a description gets one note per loop', async ($, on) => {
  on('tool.call', () => ({ result: { stdout: 'ok', stderr: '', interrupted: false } as never, text: 'ok' }))

  const a = await $.tool.call({ tool: 'Bash', command: 'ls' } as never)
  const b = await $.tool.call({ tool: 'Bash', command: 'ls' } as never)

  expect(a.context?.join(' ')).toContain('give Bash calls a short `description`')
  expect(b.context ?? []).toEqual([])
})

test('the trace tool lists calls and the third same failure gets a guard note', async ($, on) => {
  on('tool.call', () => ({ isError: true, result: 'Exit code 1', text: 'Exit code 1' }) as never)

  let last
  for (let i = 0; i < 3; i++) last = await $.tool.call({ tool: 'Bash', command: 'pnpm test', description: 'Run tests' } as never)
  const t = await $.tool.call({ tool: 'mcp__hush__trace', failed: true } as never)

  expect(last?.context?.join(' ')).toContain('failed 3 times in a row')
  expect(JSON.stringify(t.result)).toContain('3 of 3 calls match; 3 failed')
})

test('a background-task notice draws as one BG row', async ($) => {
  const ui = await $.ui.mount({
    plugin: 'hush', component: 'UserMessage', requestId: 'n1', surface: 'terminal',
    props: { text: 'Background command "pnpm build" completed', origin: { kind: 'task-notification' }, isExpanded: false, task: { status: 'completed', durationMs: 5000 } },
  } as never)

  expect((await ui.find({ type: 'Text', text: /BG/ }))?.text).toBe('  BG    ✓ ')
  expect((await ui.find({ type: 'Text', text: /pnpm build/ }))?.text).toBe('Background command "pnpm build" completed · 5s')
  await ui.unmount()
})

test('each call lands in its loop ledger file; an Agent call names the subagent it started', async ($, on) => {
  const files = new Map<string, string>()
  on('env.get', ($, e) => ({ value: e.name === 'HOME' ? '/home/t' : undefined }) as never)
  on('fs.write', ($, e) => (files.set(e.path, e.text), { value: undefined }) as never)
  on('fs.read', ($, e) => {
    if (!files.has(e.path)) throw new Error('ENOENT')
    return { value: files.get(e.path) } as never
  })
  on('tool.call', ($, e) =>
    (e.tool === 'Agent' ? { result: { agentId: 'a42', status: 'async_launched' }, text: 'started' } : { result: { stdout: 'ok', stderr: '', interrupted: false }, text: 'ok' }) as never)

  await $.tool.call({ tool: 'Bash', command: 'ls', description: 'List' } as never)
  await $.tool.call({ tool: 'Agent', subagent_type: 'Explore', prompt: 'look', description: 'Look around' } as never)

  const main = [...files].find(([p]) => p.endsWith('/main.jsonl'))?.[1] ?? ''
  expect([...files.keys()].some(p => p.startsWith('/home/t/.local/state/hush/'))).toBe(true)
  const lines = main.trim().split('\n').map(l => JSON.parse(l))
  expect(lines.map(l => [l.v, l.label, l.spawned ?? null])).toEqual([[1, 'LS', null], [1, 'EXPLORE', 'a42']])
})

test('a big whole-file Read is refused once with the cheaper way; repeating it passes', async ($, on) => {
  on('fs.stat', () => ({ value: { kind: 'file', size: 120_000, mtimeMs: 0 } }) as never)
  on('tool.call', () => ({ result: { type: 'text', file: { filePath: '/r/big.ts', content: 'x', numLines: 1, startLine: 1, totalLines: 1 } } }) as never)

  const first = await $.tool.call({ tool: 'Read', file_path: '/r/big.ts' } as never)
  const again = await $.tool.call({ tool: 'Read', file_path: '/r/big.ts' } as never)

  expect(first.deny).toContain('Read an outline first')
  expect(again.deny).toBeUndefined()
})

test('parallel calls both land in the ledger; an unreadable existing file is never overwritten', async ($, on) => {
  const files = new Map<string, string>()
  on('env.get', ($, e) => ({ value: e.name === 'HOME' ? '/home/t' : undefined }) as never)
  on('fs.exists', ($, e) => ({ value: files.has(e.path) }) as never)
  on('fs.write', ($, e) => (files.set(e.path, e.text), { value: undefined }) as never)
  on('fs.read', ($, e) => ({ value: files.get(e.path) }) as never)
  on('tool.call', () => ({ result: { stdout: 'ok', stderr: '', interrupted: false }, text: 'ok' }) as never)

  await Promise.all([
    $.tool.call({ tool: 'Bash', command: 'ls a', description: 'A' } as never),
    $.tool.call({ tool: 'Bash', command: 'ls b', description: 'B' } as never),
  ])

  const main = [...files].find(([p]) => p.endsWith('/main.jsonl'))?.[1] ?? ''
  expect(main.trim().split('\n').map(l => JSON.parse(l).what).sort()).toEqual(['A', 'B'])
})

test('a short output with repeated lines passes whole; three different failures are not a loop', async ($, on) => {
  const repeated = 'a\n\n\n\n\nb'
  let n = 0
  on('tool.call', ($, e) =>
    ((e as { command?: string }).command === 'cat x'
      ? { result: { stdout: repeated, stderr: '', interrupted: false }, text: repeated }
      : { isError: true, result: `Exit code 1\nerror ${++n}`, text: `Exit code 1\nerror ${n}` }) as never)

  const cat = await $.tool.call({ tool: 'Bash', command: 'cat x', description: 'Show x' } as never)
  expect((cat.result as { stdout: string }).stdout).toBe(repeated)
  let last
  for (let i = 0; i < 3; i++) last = await $.tool.call({ tool: 'Bash', command: 'pnpm test', description: 'Run tests' } as never)
  expect((last?.context ?? []).join(' ')).not.toContain('failed 3 times')
})

test('after /clear a re-read returns the text, not a pointer to a context that is gone', async ($, on) => {
  const content = 'y'.repeat(1000)
  on('tool.call', () => ({ result: { type: 'text', file: { filePath: '/r/b.ts', content, numLines: 1, startLine: 1, totalLines: 1 } } }) as never)
  on('session.end', () => ({ sessionId: 's2' }) as never)

  await $.tool.call({ tool: 'Read', file_path: '/r/b.ts' } as never)
  await $.session.end({ reason: 'clear' } as never)
  const after = await $.tool.call({ tool: 'Read', file_path: '/r/b.ts' } as never)

  expect((after.result as { file: { content: string } }).file.content).toBe(content)
})
