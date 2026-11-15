import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, ThemeKey } from 'claude-code'

import type { CacheStep, Ctx, Harness, Repo, Step, Usage } from '../types'
import { ctxColor, duration, estimate, fit, shortModel, tokens } from './format'
import { baseOf, snapshot } from './harness'
import { disarmCompact, registerSession, stopSessionTick, toggleSession } from './session'
import { SESSION } from './state'
import { registerTrace, startTrace, traceNav } from './trace'
import { cacheStep, countDirty, hitOf, meter, parseRevParse } from './usage'
import { registerWorktrees, settleTrees, toggleWorktrees } from './worktrees'

// Shared values, declared here as the loader reads each file's own (the same plugin and key in every file).
const base = atom({ plugin: 'footer', key: 'base' } as const, {} as Record<string, number>);
const cacheLog = atom({ plugin: 'footer', key: 'cacheLog' } as const, [] as CacheStep[]);
const compactions = atom({ plugin: 'footer', key: 'compactions' } as const, 0);
const ctx = atom({ plugin: 'footer', key: 'ctx' } as const, null as Ctx | null);
const harness = atom({ plugin: 'footer', key: 'harness' } as const, null as Harness | null);
const repo = atom({ plugin: 'footer', key: 'repo' } as const, null as Repo | null);
const skills = atom({ plugin: 'footer', key: 'skills' } as const, {} as Record<string, number>);
const step = atom({ plugin: 'footer', key: 'step' } as const, null as Step | null);
const turn = atom({ plugin: 'footer', key: 'turn' } as const, null as { ms: number; at: number } | null);
const usage = atom({ plugin: 'footer', key: 'usage' } as const, null as Usage | null);


const CACHE_STEPS = 24

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
// A cache share this low (most of the last prompt re-sent) shows in the warning colour.
const CACHE_LOW = 50
const GAP = '    '

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

async function openAgent($: EngineInterface, agentId: string) {
  const r = await $.ui.view({ agentId })
  if (r.deny) $.ui.toast(`Could not open that agent (${r.deny})`)
}

// Branch, worktree and the uncommitted state against HEAD; a git call that fails or times out leaves its part out.
async function readRepo($: EngineInterface) {
  const git = (...args: string[]) =>
    $.process
      .run(['git', ...args], { timeoutMs: 2000 })
      .then(r => (r.exitCode === 0 ? r.stdout : undefined))
      .catch(() => undefined)
  const [rev, current, status, list] = await Promise.all([
    git('rev-parse', '--path-format=absolute', '--show-toplevel', '--git-dir', '--git-common-dir'),
    git('branch', '--show-current'),
    git('status', '--porcelain'),
    git('worktree', 'list', '--porcelain'),
  ])
  const head = rev === undefined ? null : parseRevParse(rev, current)
  const next: Repo | null = head && {
    ...head,
    ...(status === undefined ? {} : { dirty: countDirty(status) }),
    ...(list === undefined ? {} : { trees: list.split('\n').filter(l => l.startsWith('worktree ')).length }),
  }
  await update($, repo, () => next)
}

// On a reload session.start runs before the screen is bound and register throws, so each command
// is tried at start and again on a timer until it holds (as hush does); the buttons work meanwhile.
const COMMANDS = [
  { name: 'harness', description: 'Session pane: context, plugins and cache, on keys 1-3' },
  { name: 'worktrees', description: 'Worktrees pane: every worktree with its changes and upstream; lazygit or herdr workspace on a key' },
]
const registered = new Set<string>()
async function ensureCommands($: EngineInterface, left = 20): Promise<void> {
  try {
    for (const c of COMMANDS) {
      if (registered.has(c.name)) continue
      await $.command.register(c)
      registered.add(c.name)
    }
    if (!registered.has('trace')) {
      await startTrace($)
      registered.add('trace')
    }
  } catch {
    if (left > 0) $.clock.after(1000, () => void ensureCommands($, left - 1))
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const r = await next(e)
    await ensureCommands($)
    // A reload mid-read or mid-arm leaves these set with nothing left to clear them.
    await settleTrees($).catch(() => undefined)
    await disarmCompact($).catch(() => undefined)
    await readRepo($).catch(() => undefined)
    return r
  })

  // The command toggles like the footer's context item does.
  on('command.run', { command: 'harness' }, async $ => {
    await toggleSession($)
    return { text: 'Session pane toggled.' }
  })

  on('command.run', { command: 'worktrees' }, async $ => {
    await toggleWorktrees($)
    return { text: 'Worktrees pane toggled.' }
  })

  on('ui.close', async ($, e, next) => {
    const r = await next(e)
    if (e.id === SESSION) stopSessionTick()
    return r
  })

  // The table's growth column counts from here.
  on('turn.start', async ($, e, next) => {
    if (!e.agentId) {
      const snap = await read($, harness)
      if (snap) await update($, base, () => baseOf(snap))
    }
    return next(e)
  })

  // A turn may have edited files, committed or switched branches through Bash.
  on('turn.complete', async ($, e, next) => {
    const r = await next(e)
    if (!e.agentId) {
      await update($, turn, () => ({ ms: e.durationMs, at: Date.now() }))
      await readRepo($)
    }
    return r
  })

  registerTrace(on)
  registerSession(on)
  registerWorktrees(on)

  on('turn.step', async function* ($, e, next) {
    if (!e.agentId) await update($, step, () => ({ model: e.model, effort: e.effort }))
    const r = yield* next(e)
    // Every request of the main loop lands here as it finishes, so the cache figures move while a turn runs;
    // a step with no usage keeps the last reading.
    const seen = !e.agentId && r.usage ? cacheStep(r.usage, Date.now()) : undefined
    if (seen) await update($, cacheLog, log => [...log, seen].slice(-CACHE_STEPS))
    return r
  })

  on('session.measure', async ($, e, next) => {
    // The summary breakdown is a local estimate: no request is sent for it.
    const b = (await $.session.usage({ breakdown: 'summary' }).catch(() => null))?.context.breakdown
    await update($, ctx, () => ({
      percent: e.context.percent,
      tokens: e.context.tokens,
      window: e.context.window,
      compactAt: b?.isAutoCompactEnabled ? b.autoCompactThreshold : undefined,
    }))
    if (e.changed.includes('rateLimits') || e.changed.includes('cost')) {
      await update($, usage, () => ({
        limits: e.rateLimits.map(l => ({ kind: l.kind, percentUsed: l.percentUsed, resetsAt: l.resetsAt })),
        usd: e.cost?.usd,
      }))
    }
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

  // One quiet line; only what a glance needs, the rest in the session pane (click the context meter):
  //   INSERT  AUTO  ‹ prompt 3/7 ›  ✗ 2 failed  research the API  esc to interrupt    dev ●3    opus 5.5 medium    context ▰▰▰▱▱▱▱▱ 104k/164k · 92% cached
  // The left side is the engine's own line (modes as badges, one button per live agent), cut first when narrow.
  // shortcut: other pills are drawn from the hint's text and lose their click; give each its own button when one matters.
  on('ui.render', { component: 'PromptHint' }, async ($, e) => {
    const hint = parseHint(e.props.hint)
    const [st, cx, rp, log, tn] = await Promise.all([read($, step), read($, ctx), read($, repo), read($, cacheLog), read($, turn)])
    const lastStep = log.at(-1)
    const hit = lastStep ? hitOf(lastStep) : undefined
    // The hint redraws when its agent count changes, so the list read here stays current.
    const agents = (await $.agent.list().catch(() => [])).filter(a => !a.parentId && LIVE.has(a.status))
    const rest = agents.length ? hint.rest.filter(part => !AGENT_PILL.test(part)) : hint.rest
    const model = st?.model ?? (await $.session.model().catch(() => ''))
    const cap = cx ? (cx.compactAt ?? cx.window) : 0
    const fill = cx?.tokens !== undefined && cap ? cx.tokens / cap : undefined
    const ui = $.ui.resolve(e)
    const { Box, Button, Text } = ui
    const nav = await traceNav($, ui)
    return (
      <Box height={1} overflow="hidden">
        <Box flexGrow={1} flexShrink={1} overflow="hidden">
          {hint.vim ? (
            <Text bold color="inverseText" backgroundColor={VIM_COLOR[hint.vim] ?? 'planMode'}>{` ${hint.vim} `}</Text>
          ) : null}
          {hint.vim && hint.perm ? <Text>{' '}</Text> : null}
          {hint.perm ? (
            <Text bold color="inverseText" backgroundColor={hint.perm.color}>{` ${hint.perm.label} `}</Text>
          ) : null}
          {nav ? <Text>{hint.vim || hint.perm ? '  ' : ''}</Text> : null}
          {nav}
          {agents.slice(0, MAX_AGENTS).map(a => (
            <Button key={`agent-${a.id}`} plain onPress={() => openAgent($, a.id)}>
              <Text color="suggestion">{`  ${fit(a.name ?? a.description, 24)}`}</Text>
            </Button>
          ))}
          {agents.length > MAX_AGENTS ? <Text color="subtle">{`  +${agents.length - MAX_AGENTS}`}</Text> : null}
          {rest.length ? (
            <Text color="subtle" wrap="truncate-end">{`${hint.vim || hint.perm || nav || agents.length ? '  ' : ''}${rest.join('  ')}`}</Text>
          ) : null}
        </Box>
        <Box flexShrink={0}>
          {rp ? (
            <Box>
              <Text>{GAP}</Text>
              {/* The pointer inverts a whole Button, so each holds just its label: one text, one colour, no padding. */}
              <Button key="worktrees" plain onPress={() => toggleWorktrees($)}>
                <Text color="remember">{rp.branch ?? 'detached'}</Text>
              </Button>
              {rp.dirty ? <Text color="warning">{` ●${rp.dirty}`}</Text> : null}
              {rp.trees && rp.trees > 1 ? <Text color="subtle">{` ·${rp.trees}wt`}</Text> : null}
            </Box>
          ) : null}
          <Text color="claude">{`${GAP}${shortModel(model)}`}</Text>
          {st?.effort !== undefined ? <Text color="subtle">{` ${st.effort}`}</Text> : null}
          {/* The last turn's time: hush draws nothing for the transcript's own `✻ Brewed for 6s` row. */}
          {tn ? <Text color="subtle">{` · ${duration(tn.ms)}`}</Text> : null}
          {/* One context reading, opening the session pane: how full (meter), how much (tokens used of where
              compaction runs, or of the window), and how much of the last prompt the cache served. */}
          {fill !== undefined && cx ? (
            <Box>
              <Text>{GAP}</Text>
              <Button key="session" plain onPress={() => toggleSession($)}>
                <Text color={ctxColor(cx.tokens ?? 0, cap)}>{`context ${meter(fill)} ${tokens(cx.tokens ?? 0)}/${tokens(cap)}`}</Text>
              </Button>
              {hit !== undefined ? <Text color="subtle">{' · '}</Text> : null}
              {hit !== undefined ? <Text color={hit < CACHE_LOW ? 'warning' : 'subtle'}>{`${hit}% cached`}</Text> : null}
            </Box>
          ) : null}
        </Box>
      </Box>
    )
  })
}
