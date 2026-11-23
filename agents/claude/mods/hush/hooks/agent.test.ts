import { expect, test } from 'claude-code/testing'

import { isBounded, loopNote, openFailures, queryTrace, recapOf, tidyOutput, trimOutput, turnLine, turnStats } from '../core/agent.ts'
import type { CallEntry } from '../core/agent.ts'
import { capByLoop } from '../core/ledger.ts'
import { groupMatches } from '../core/format.ts'
import { brief, contextAudit, effectText, lessons, refusals, sessionFacts } from '../core/report.ts'
import type { LedgerEntry } from '../core/ledger.ts'
import { compactFacts, conflictNote, repeatNote, reportsNote, runawayNote } from '../core/agent.ts'

const entry = (o: Partial<CallEntry>): CallEntry => ({ id: 'i', tool: 'Bash', label: 'GIT', what: 'git status', at: 0, ms: 5, ok: true, bytes: 10, files: [], ...o })

test('tidy drops colour codes and redraws, and counts a run of 4+ identical lines', () => {
  expect(tidyOutput('\x1b[32mok\x1b[0m\n10%\r50%\r100%\nx\nx\nx\nx\ny')).toBe('ok\n100%\nx\n[hush: line above repeated 3 more times]\ny')
  expect(tidyOutput('a\na\nb')).toBe('a\na\nb')
})

test('a long output keeps head and tail and names where the whole is', () => {
  const long = Array.from({ length: 500 }, (_, i) => `line ${i}`).join('\n')
  const cut = trimOutput(long, '/c/x.txt') ?? ''
  expect(cut.split('\n')).toHaveLength(101)
  expect(cut).toContain('[hush: 400 lines cut; whole output: /c/x.txt]')
  expect(cut.startsWith('line 0\n')).toBe(true)
  expect(cut.endsWith('line 499')).toBe(true)
  expect(trimOutput('short', '/c/x.txt')).toBeNull()
})

test('an output the command bounded on purpose is not trimmed', () => {
  expect(isBounded('sed -n 1,400p a.ts')).toBe(true)
  expect(isBounded('git log --oneline | head -50')).toBe(true)
  expect(isBounded('pnpm build')).toBe(false)
})

test('the ledger answers by failure, file and tool', () => {
  const all = [
    entry({ id: 'a', at: 0 }),
    entry({ id: 'b', tool: 'Read', label: 'READ', what: 'a.ts', files: ['/r/a.ts'], at: 1000 }),
    entry({ id: 'c', label: 'PNPM', what: 'pnpm build', ok: false, err: 'Exit code 1', at: 2000 }),
  ]
  const failed = queryTrace(all, { failed: true }, 62000)
  expect(failed).toContain('1 of 3 calls match; 1 failed')
  expect(failed).toContain('1m ✗ PNPM pnpm build')
  expect(failed).toContain('✗ Exit code 1')
  expect(queryTrace(all, { file: 'a.ts' }, 2000)).toContain('READ a.ts')
  expect(queryTrace(all, { tool: 'git' }, 2000)).toContain('1 of 3')
})

test('a failure followed by a success of the same row is no longer open', () => {
  const all = [entry({ ok: false, err: 'e' }), entry({}), entry({ label: 'PNPM', what: 'x', ok: false, err: 'f' })]
  expect(openFailures(all).map(e => e.label)).toEqual(['PNPM'])
})

test('the recap names edits, reads and open failures of the main loop', () => {
  const all = [
    entry({ tool: 'Edit', label: 'EDIT', files: ['/r/a.ts'] }),
    entry({ tool: 'Read', label: 'READ', files: ['/r/b.ts'] }),
    entry({ label: 'PNPM', what: 'pnpm build', ok: false, err: 'Exit code 1' }),
    entry({ agentId: 'sub', tool: 'Edit', files: ['/r/c.ts'] }),
  ]
  const r = recapOf(all) ?? ''
  expect(r).toContain('3 calls so far (1 in subagents)')
  expect(r).toContain('Edited: /r/a.ts.')
  expect(r).toContain('Read: /r/b.ts.')
  expect(r).toContain('Still failing: PNPM pnpm build (Exit code 1)')
  expect(recapOf([])).toBeNull()
})

test('the third identical failure in a row gets a note; a different error does not', () => {
  const fail = entry({ ok: false, err: 'boom' })
  expect(loopNote([fail, fail], fail)).toBeNull()
  expect(loopNote([fail, fail, fail], fail)).toContain('failed 3 times in a row')
  expect(loopNote([fail, entry({ ok: false, err: 'other' }), fail], fail)).toBeNull()
})

test('a turn line counts calls, failures, edits, subagents and savings', () => {
  const s = turnStats([entry({}), entry({ ok: false }), entry({ tool: 'Edit', files: ['/r/a.ts'], agentId: 'x' })], 2048)
  expect(turnLine(s)).toBe('3 calls · 1 failed · edited 1 (a.ts) · 1 subagent · saved 2.0kB')
})

test('the state copy keeps the main loop whole against a swarm of subagents', () => {
  const all = [
    ...Array.from({ length: 5 }, (_, i) => ({ id: `m${i}` }) as { id: string; agentId?: string }),
    ...Array.from({ length: 100 }, (_, i) => ({ id: `s${i}`, agentId: 'w1' })),
  ]
  const kept = capByLoop(all, 300, 40)
  expect(kept.filter(e => !('agentId' in e)).length).toBe(5)
  expect(kept.filter(e => 'agentId' in e).map(e => e.id).slice(0, 1)).toEqual(['s60'])
})

test('long lines are cut by characters even past the line count', () => {
  const long = Array.from({ length: 130 }, () => 'x'.repeat(2000)).join('\n')
  const cut = trimOutput(long, '/c/x.txt') ?? ''
  expect(cut.length).toBeLessThan(11_000)
  expect(cut).toContain('characters cut; whole output: /c/x.txt')
})

test('a limiter bounds its own pipeline only, and jq is no limiter', () => {
  expect(isBounded('pnpm test 2>&1; wc -l a.ts')).toBe(false)
  expect(isBounded('cat big.json | jq .')).toBe(false)
  expect(isBounded('cd app && git log | head -5')).toBe(true)
  expect(isBounded("sed -n '1,5p;10p' a.ts")).toBe(true)
})

test('a refusal is never open, and a later success of the row closes a failure with other arguments', () => {
  const all = [
    entry({ ok: false, err: 'nope', denied: true }),
    entry({ label: 'MKDIR', ok: false, err: 'This session is isolated in the worktree /w, but this command is too complex' }),
    entry({ tool: 'Edit', label: 'EDIT', files: ['/r/a.ts'], sig: 's1', ok: false, err: 'String to replace not found' }),
    entry({ tool: 'Edit', label: 'EDIT', files: ['/r/a.ts'], sig: 's2' }),
    entry({ tool: 'Edit', label: 'EDIT', files: ['/r/b.ts'], sig: 's3', ok: false, err: 'String to replace not found' }),
  ]
  expect(openFailures(all).map(e => e.files[0])).toEqual(['/r/b.ts'])
})

test('a search repeated after an edit is a check, not a repeat', () => {
  const g = entry({ tool: 'Grep', label: 'GREP', what: 'foo', sig: 'g' })
  const edit = entry({ tool: 'Edit', label: 'EDIT', at: 5 })
  expect(repeatNote([g, g, edit, { ...g, at: 9 }], { ...g, at: 9 })).toBeNull()
  expect(repeatNote([g, g, { ...edit, agentId: 'a1' }, g], g)).toContain('ran 3 times')
})

test('a subagent gets the recap of its own loop', () => {
  const all = [entry({ tool: 'Edit', files: ['/r/main.ts'] }), entry({ agentId: 'a1', tool: 'Edit', files: ['/r/sub.ts'] })]
  const r = recapOf(all, 'a1') ?? ''
  expect(r).toContain('1 calls so far.')
  expect(r).toContain('/r/sub.ts')
  expect(r.includes('/r/main.ts')).toBe(false)
})

test('the brief names what failed three times or more, refusals as one row, never the user\'s own no', () => {
  const led = (o: Partial<CallEntry>) => ({ v: 1, session: 's', ...entry({ ok: false, ...o }) })
  const all = [
    ...[1, 2, 3].map(n => led({ label: 'PNPM', err: 'ERR_PNPM_NO_SCRIPT Missing script: lint' , id: `p${n}` })),
    ...['/w/one', '/w/two', '/w/three'].map(w => led({ label: 'MKDIR', err: `This session is isolated in the worktree ${w}, but no` })),
    ...[1, 2, 3].map(() => led({ err: "The user doesn't want to proceed with this tool use" })),
    led({ label: 'GIT', err: 'fatal: once' }),
  ]
  const b = brief(all) ?? ''
  expect(b).toContain('- PNPM ×3: ERR_PNPM_NO_SCRIPT Missing script: lint')
  expect(b).toContain('- REFUSED ×3: This session is isolated')
  expect(b.includes('GIT')).toBe(false)
  expect(b.includes('proceed')).toBe(false)
  expect(brief([])).toBeNull()
})

test('clock lines are not grep hits', () => {
  expect(groupMatches('10:15:02 started\n10:15:03 done')).toBeNull()
})

const led = (o: Partial<LedgerEntry>): LedgerEntry => ({ v: 1, session: 's1', ...entry(o), ...o })

test('a failure recurring across sessions becomes a rule naming what worked next; an accepted one is not repeated', () => {
  const fail = (session: string, at: number) => led({ session, at, ok: false, label: 'PNPM', what: 'pnpm test', err: 'ERR_PNPM_NO_SCRIPT Missing script: test' })
  const fixed = (session: string, at: number) => led({ session, at, label: 'PNPM', what: 'pnpm run test:unit' })
  const all = [fail('s1', 1), fixed('s1', 2), fail('s1', 3), fail('s2', 1), fixed('s2', 2)]
  const [l] = lessons(all)
  expect(l?.rule).toBe('`pnpm test` (PNPM) fails with "ERR_PNPM_NO_SCRIPT Missing script: test"; what worked next: `pnpm run test:unit`.')
  expect(lessons(all.filter(e => e.session === 's1'))).toEqual([])
  expect(lessons(all, 2, 3, `## Lessons from hush\n\n- ${l?.rule}\n`)).toEqual([])
  expect(brief(all, 3, 5, `- ${l?.rule}`)).toBeNull()
  // one success after it is chance, not a fix; a refusal gets no workaround
  expect(lessons(all.slice(0, 4))[0]?.fix).toBeNull()
  const refused = (session: string) => led({ session, ok: false, denied: true, err: 'Permission for this action was denied. Reason: [Merge Without Review]' })
  expect(lessons([refused('a'), refused('b'), refused('c')])[0]?.rule).toContain('ask the user instead of retrying')
})

test('session facts count repeated failures and subagent re-reads of what the main loop read; effect groups by holdout', () => {
  const loops = new Map([
    ['main', [led({ tool: 'Read', label: 'Read', files: ['/r/a.ts'], at: 1 }), led({ ok: false, err: 'x', sig: 'k', at: 2 }), led({ ok: false, err: 'x', sig: 'k', at: 3 })]],
    ['a1', [led({ agentId: 'a1', tool: 'Read', label: 'Read', files: ['/r/a.ts'], at: 4 })]],
  ])
  const f = sessionFacts({ v: 1, session: 's1', harness: 'claude', cwd: '/r', startedAt: 0, heldOut: 'trim', usage: { input: 100, output: 50, cacheRead: 1000, cacheWrite: 50 } }, loops)
  expect(f).toEqual({ session: 's1', heldOut: 'trim', calls: 4, failed: 2, repeated: 1, tokens: 300, handoffRereads: 1, subagents: 1 })
  const g = { ...f, calls: 5 }
  const text = effectText([g, { ...g, session: 's2', heldOut: null }, { ...g, session: 's3', heldOut: undefined }, { ...f, session: 's4', calls: 4 }])
  expect(text).toContain('4 sessions, 2 with a recorded holdout')
  expect(text).toMatch(/none \(all on\)\s+1\s+60\s+40\.0\s+50\.0\s+1\.0/)
  expect(text).toMatch(/\ntrim/)
})

test('the recap lists kept subagent reports, skipping ones with no file yet', () => {
  expect(reportsNote([{ what: 'Explore: find callers', path: '/c/agent-a1.md' }, { what: 'pending', path: '' }])).toContain('- Explore: find callers → /c/agent-a1.md')
  expect(reportsNote([{ path: '' }])).toBeNull()
})

test('the compaction is told the edited files, open failures and kept reports', () => {
  const all = [entry({ tool: 'Edit', label: 'Edit', files: ['/r/a.ts'] }), entry({ ok: false, err: 'boom', at: 1 }), entry({ agentId: 'a1', tool: 'Edit', files: ['/r/b.ts'] })]
  const f = compactFacts(all, undefined, [{ what: 'Explore: callers', path: '/c/agent-a1.md' }]) ?? ''
  expect(f).toContain('- files edited: /r/a.ts\n')
  expect(f).toContain('- still failing: GIT git status: boom')
  expect(f).toContain('saved whole at /c/agent-a1.md')
  expect(compactFacts(all, 'a1')).toBe('Facts from the hush call ledger; keep them in the summary as written:\n- files edited: /r/b.ts')
  expect(compactFacts([])).toBeNull()
})

test('runaway and edit-clash notes fire past their bounds only', () => {
  expect(runawayNote(119, 60_000, true)).toBeNull()
  expect(runawayNote(120, 60_000, true)).toContain('120 calls over 1m in this subagent run')
  expect(runawayNote(10, 31 * 60_000, true)).toContain('31m')
  expect(runawayNote(249, 0, false)).toBeNull()
  const at = 1_000_000
  const prev = { owner: 's1|', at, path: '/r/a.ts' }
  expect(conflictNote(prev, 's2|', at + 60_000)).toContain('another session (s1')
  expect(conflictNote(prev, 's2|', at + 16 * 60_000)).toBeNull()
  expect(conflictNote(prev, 's1|a1', at)).toBeNull()
  expect(conflictNote({ ...prev, owner: 's1|a1' }, 's1|a2', at)).toContain('a parallel subagent (a1)')
  expect(conflictNote(null, 's1|', at)).toBeNull()
})

test('the context audit counts plugin, server and skill use; refusals group by reason', () => {
  const t = { harness: 'claude' as const, cwd: '/r', modelCalls: 1, firstContext: 30_000, items: [
    { kind: 'call' as const, id: '1', tool: 'mcp__chrome-devtools__click', label: '', what: '', input: {}, isErrored: false, result: '', modelCall: 1 },
    { kind: 'call' as const, id: '2', tool: 'Skill', label: '', what: '', input: { skill: 'ponytail:ponytail' }, isErrored: false, result: '', modelCall: 1 },
  ] }
  const text = contextAudit([t as never], { plugins: ['chrome-devtools-mcp', 'ponytail', 'telegram'], servers: ['memory'], skills: ['ast-grep'] })
  expect(text).toContain('median 30k tokens')
  expect(text).toMatch(/0 {2}telegram[\s\S]*1 {2}chrome-devtools-mcp/)
  expect(text).toMatch(/1 {2}ponytail/)
  expect(text).toMatch(/0 {2}memory/)
  const deny = (err: string, what: string) => led({ ok: false, denied: true, err, what })
  expect(refusals([deny('denied. Reason: [Merge Without Review]', 'merge'), deny('Reason: [Merge Without Review]', 'merge 2'), deny('was rejected', 'x')]))
    .toEqual(['    2  Merge Without Review  e.g. merge | merge 2'])
})
