import { expect, test } from 'claude-code/testing'

import { callKey, cleanOutput, isBounded, isReadLike, repeatNote, routeRead, TRIM, TRIM_READ, trimOutput } from '../core/agent.ts'
import { describe, jsonToToon, stripLead } from '../core/format.ts'
import { capByLoop, parseLedger } from '../core/ledger.ts'
import type { CallEntry } from '../core/agent.ts'
import type { LedgerEntry } from '../core/ledger.ts'
import { callsOf, parseTranscript } from '../core/readers.ts'
import { habits, project, redact, savings, suggestions, tree } from '../core/report.ts'

const j = (o: unknown) => JSON.stringify(o)
const CLAUDE = [
  j({ type: 'user', cwd: '/r', timestamp: '2026-11-10T10:00:00Z', message: { content: 'no, fix the build' } }),
  j({ type: 'assistant', message: { usage: {}, content: [{ type: 'tool_use', id: 't1', name: 'Bash', input: { command: 'pnpm build' } }] } }),
  j({ type: 'user', message: { content: [{ type: 'tool_result', tool_use_id: 't1', is_error: true, content: 'Exit code 1' }] } }),
  j({ type: 'assistant', timestamp: '2026-11-10T10:00:30Z', message: { usage: {}, content: [{ type: 'tool_use', id: 't2', name: 'Edit', input: { file_path: '/r/a.ts' } }] } }),
  j({ type: 'user', message: { content: [{ type: 'tool_result', tool_use_id: 't2', content: 'ok' }] } }),
  j({ type: 'user', message: { content: '[Request interrupted by user]' } }),
].join('\n')
const PI = [
  j({ type: 'session', v: 3, cwd: '/p' }),
  j({ type: 'message', timestamp: 1, message: { role: 'user', content: [{ type: 'text', text: 'look' }] } }),
  j({ type: 'message', message: { role: 'assistant', content: [{ type: 'toolCall', id: 'c1', name: 'bash', arguments: { command: 'ls' }, intent: 'List files' }] } }),
  j({ type: 'message', message: { role: 'toolResult', toolCallId: 'c1', isError: false, content: [{ type: 'text', text: 'a\nb' }] } }),
].join('\n')

test('Claude and pi-family transcripts read into the same calls', () => {
  const c = parseTranscript(CLAUDE)
  const p = parseTranscript(PI)
  expect([c.harness, p.harness]).toEqual(['claude', 'pi'])
  expect(callsOf(c).map(x => [x.label, x.isErrored])).toEqual([['PNPM', true], ['EDIT', false]])
  expect(callsOf(p).map(x => [x.tool, x.label, x.what, x.result])).toEqual([['Bash', 'LS', 'List files', 'a\nb']])
  expect(c.items.some(i => i.kind === 'interrupt')).toBe(true)
})

test('habits count corrections, interruptions, descriptions and time to first edit', () => {
  const h = habits([parseTranscript(CLAUDE), parseTranscript(PI)])
  expect([h.prompts, h.corrections, h.interruptions, h.bash, h.described, h.medianToFirstEditS]).toEqual([2, 1, 1, 2, 1, 30])
  const p = project([parseTranscript(CLAUDE)])
  expect(p.edited).toEqual([['a.ts', 1]])
  expect(p.failing).toEqual([['PNPM pnpm build', 1]])
  expect(savings([parseTranscript(CLAUDE)]).trimTokens).toBe(0)
  expect(suggestions(h, p)).toEqual([])
})

test('a span tree folds each subagent under the call that started it', () => {
  const e = (o: Partial<LedgerEntry>): LedgerEntry => ({ v: 1, session: 's', id: 'i', tool: 'Bash', label: 'LS', what: 'ls', at: 0, ms: 1000, ok: true, bytes: 1, files: [], ...o })
  const loops = new Map([
    ['main', [e({ turn: 'T1' }), e({ turn: 'T1', tool: 'Agent', label: 'EXPLORE', what: 'look', spawned: 'a1' })]],
    ['a1', [e({ agentId: 'a1', files: ['/x'] }), e({ agentId: 'a1', ok: false, err: 'boom' })]],
  ])
  expect(tree({ v: 1, session: 'abcdefgh1', harness: 'claude', cwd: '/r', startedAt: 0 }, loops)).toEqual([
    'session abcdefgh · claude · /r',
    'turn T1',
    '  ✓ LS ls (1000ms)',
    '  ✓ EXPLORE look (1000ms)',
    '    └ a1: 2 calls · 1 failed · 1 files · 2s',
  ])
})

test('a whole-file Read of a big code file is routed; ranges, small files and docs pass', () => {
  expect(routeRead('/r/big.ts', 90_000, false)).toContain('Read an outline first')
  expect(routeRead('/r/big.ts', 90_000, true)).toBeNull()
  expect(routeRead('/r/small.ts', 9_000, false)).toBeNull()
  expect(routeRead('/r/notes.md', 90_000, false)).toBeNull()
})

test('the third identical search in a loop gets a note', () => {
  const g = { id: 'g', tool: 'Grep', label: 'GREP', what: 'foo', at: 0, ms: 1, ok: true, bytes: 1, files: [] } as CallEntry
  expect(repeatNote([g, g], g)).toBeNull()
  expect(repeatNote([g, g, g], g)).toContain('ran 3 times')
})

test('report rows drop secrets from commands', () => {
  expect(redact('curl -H "Authorization: Bearer abc.def" API_KEY=sk-123 x')).toBe('curl -H "Authorization: Bearer … API_KEY=… x')
  expect(redact(`git push https://${'a'.repeat(40)}@github.com`)).toBe('git push https://…@github.com')
})

test('review fixes: bounded words, disjoint shell words, big ints, call keys', () => {
  expect(isBounded('grep -m 100 foo x')).toBe(true)
  expect(isBounded('grep -m20 foo x')).toBe(true)
  expect(isBounded('git commit -m "more tests"')).toBe(false)
  expect(isBounded('pnpm build | tail -20')).toBe(true)
  const t0 = Date.now()
  stripLead(`cd ${'"a"'.repeat(40)} || true`)
  expect(Date.now() - t0).toBeLessThan(200)
  expect(jsonToToon('{"items":[{"id":12345678901234567890,"n":"a"},{"id":2,"n":"b"}]}')).toBeNull()
  const a = { tool: 'Edit', label: 'EDIT', what: 'index.ts', sig: 'x' }
  expect(callKey(a)).not.toBe(callKey({ ...a, sig: 'y' }))
  expect(redact('curl --token abc https://me:pw@host/x')).toBe('curl --token … https://…@host/x')
})

test('round 2: sidechain and summary prompts, CR text, bounded words, read-like limits, ledger defaults', () => {
  const side = [
    j({ type: 'user', isSidechain: true, message: { content: 'review the diff' } }),
    j({ type: 'user', isCompactSummary: true, message: { content: 'This session is being continued…' } }),
  ].join('\n')
  expect(parseTranscript(side).items.filter(i => i.kind === 'user')).toEqual([])
  expect(cleanOutput('a\rb\n\x1b[31mc\x1b[0m')).toBe('a\rb\nc')
  expect(isBounded('tailscale status')).toBe(false)
  expect(isBounded('ls | head -5')).toBe(true)
  expect(isReadLike('cat src/a.ts')).toBe(true)
  const mid = Array.from({ length: 300 }, (_, i) => `l${i}`).join('\n')
  expect(trimOutput(mid, '/x', TRIM)).not.toBeNull()
  expect(trimOutput(mid, '/x', TRIM_READ)).toBeNull()
  expect(jsonToToon('{"items":[{"p":12345678.123456789012,"n":"a"},{"p":1,"n":"b"}]}')).toBeNull()
  expect(parseLedger('{"id":"x","tool":"Bash"}')[0]).toMatchObject({ what: '', files: [], label: 'Bash' })
  const swarm = Array.from({ length: 30 }, (_, i) => ({ agentId: `w${i}` }))
  expect(new Set(capByLoop(swarm, 300, 40, 20).map(e => e.agentId)).size).toBe(20)
  expect(describe({ tool: 'mcp__cd__evaluate_script', input: { function: '() => 1' }, isRunning: false, isErrored: false })).toBe('function=() => 1')
})

test('a subagent started by a subagent nests under it in the tree', () => {
  const e = (o: Partial<LedgerEntry>): LedgerEntry => ({ v: 1, session: 's', id: 'i', tool: 'Bash', label: 'LS', what: 'ls', at: 0, ms: 1000, ok: true, bytes: 1, files: [], ...o })
  const loops = new Map([
    ['main', [e({ turn: 'T', tool: 'Agent', label: 'GP', what: 'lead', spawned: 'a1' })]],
    ['a1', [e({ agentId: 'a1', tool: 'Agent', label: 'R', what: 'review', spawned: 'a2' })]],
    ['a2', [e({ agentId: 'a2' })]],
  ])
  const out = tree(null, loops)
  expect(out.filter(l => l.includes('└')).map(l => l.trim().split(':')[0])).toEqual(['└ a1', '└ a2'])
  expect(out.some(l => l.includes('no parent'))).toBe(false)
})
