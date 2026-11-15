import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Worktree } from '../types'
import { cell, fit } from './format'
import { togglePane } from './pane'
import { WORKTREES } from './state'
import { ago, countDirty } from './usage'

// Shared values, declared here as the loader reads each file's own (the same plugin and key in every file).
const tick = atom({ plugin: 'footer', key: 'tick' } as const, 0);
const treeSel = atom({ plugin: 'footer', key: 'treeSel' } as const, 0);
const trees = atom({ plugin: 'footer', key: 'trees' } as const, null as Worktree[] | null);
const treesAt = atom({ plugin: 'footer', key: 'treesAt' } as const, null as number | null);
const treesBusy = atom({ plugin: 'footer', key: 'treesBusy' } as const, false);


// The worktrees pane: every worktree of the repository in one table (branch, changed files, ahead/behind its upstream,
// last commit, what herdr has open there), read when the pane opens or on `r`, never on a turn: git runs once per
// worktree, in parallel. The keys act on the picked row (j/k): `g` opens lazygit there in a herdr split, `o` opens or
// focuses its herdr workspace. Nothing here removes a worktree.
type On = Parameters<Register>[0]

const GIT_MS = 3000
const BRANCH = 34

// `git worktree list --porcelain`: blocks of `worktree <path>`, `HEAD <sha>`, `branch refs/heads/<name>` or `detached`.
export function parseWorktrees(stdout: string): { path: string; branch: string | null }[] {
  return stdout
    .split('\n\n')
    .map(block => {
      const path = /^worktree (.+)$/m.exec(block)?.[1]
      const branch = /^branch refs\/heads\/(.+)$/m.exec(block)?.[1] ?? null
      return path ? { path, branch } : undefined
    })
    .filter((t): t is { path: string; branch: string | null } => !!t)
}

// `rev-list --left-right --count @{u}...HEAD`: `<behind>\t<ahead>`.
export function parseAheadBehind(stdout: string): { ahead: number; behind: number } | undefined {
  const m = /^(\d+)\s+(\d+)/.exec(stdout.trim())
  return m ? { behind: Number(m[1]), ahead: Number(m[2]) } : undefined
}

// The worktree a directory belongs to: the longest worktree path it sits in (the main checkout holds the others).
export function ownerOf(dir: string, paths: readonly string[]): string | undefined {
  return paths.filter(p => dir === p || dir.startsWith(`${p}/`)).sort((a, b) => b.length - a.length)[0]
}

// The busiest agent state among a worktree's herdr panes.
const RANK = ['working', 'blocked', 'idle', 'done', 'unknown']
const rank = (state: string) => (RANK.includes(state) ? RANK.indexOf(state) : RANK.length)
export const busiest = (states: readonly string[]) => [...states].sort((a, b) => rank(a) - rank(b))[0]

// `↑2 ↓1`, `↑2`, `even`, `no upstream`.
export function drift(t: Worktree): string {
  if (t.ahead === undefined || t.behind === undefined) return 'no upstream'
  if (!t.ahead && !t.behind) return 'even'
  return [t.ahead ? `↑${t.ahead}` : '', t.behind ? `↓${t.behind}` : ''].filter(Boolean).join(' ')
}

type Herdr = { worktrees?: { path: string; open_workspace_id?: string }[]; panes?: { cwd: string; agent?: string; agent_status?: string }[] }

async function run($: EngineInterface, argv: string[]) {
  return $.process
    .run(argv, { timeoutMs: GIT_MS })
    .then(r => (r.exitCode === 0 ? r.stdout : undefined))
    .catch(() => undefined)
}

async function herdrJson($: EngineInterface, args: string[]): Promise<Herdr> {
  const out = await run($, ['herdr', ...args])
  try {
    return out ? (JSON.parse(out) as { result?: Herdr }).result ?? {} : {}
  } catch {
    return {}
  }
}

export async function refreshTrees($: EngineInterface) {
  if (await read($, treesBusy)) return
  await update($, treesBusy, () => true)
  try {
    const [list, top] = await Promise.all([run($, ['git', 'worktree', 'list', '--porcelain']), run($, ['git', 'rev-parse', '--show-toplevel'])])
    const found = list ? parseWorktrees(list) : []
    const [wt, panes] = await Promise.all([herdrJson($, ['worktree', 'list']), herdrJson($, ['pane', 'list'])])
    const paths = found.map(t => t.path)
    const agents = new Map<string, string[]>()
    for (const p of panes.panes ?? []) {
      const owner = p.agent ? ownerOf(p.cwd, paths) : undefined
      if (owner && p.agent_status) agents.set(owner, [...(agents.get(owner) ?? []), p.agent_status])
    }
    const read1 = async (t: { path: string; branch: string | null }): Promise<Worktree> => {
      const git = (...args: string[]) => run($, ['git', '-C', t.path, ...args])
      const [status, counts, last] = await Promise.all([
        git('status', '--porcelain'),
        git('rev-list', '--left-right', '--count', '@{u}...HEAD'),
        git('log', '-1', '--format=%ct'),
      ])
      const ab = counts === undefined ? undefined : parseAheadBehind(counts)
      const workspace = wt.worktrees?.find(w => w.path === t.path)?.open_workspace_id
      return {
        ...t,
        isCurrent: t.path === top?.trim(),
        ...(status === undefined ? {} : { dirty: countDirty(status) }),
        ...(ab ?? {}),
        ...(last?.trim() ? { lastCommit: Number(last.trim()) } : {}),
        ...(workspace ? { workspace } : {}),
        ...(agents.has(t.path) ? { agent: busiest(agents.get(t.path)!) } : {}),
      }
    }
    const next = await Promise.all(found.map(t => read1(t)))
    await update($, trees, () => next)
    await update($, treesAt, () => Date.now())
  } finally {
    await update($, treesBusy, () => false)
  }
}

// Called at session.start: a reload in the middle of a reading leaves `treesBusy` set for good.
export async function settleTrees($: EngineInterface) {
  await update($, treesBusy, () => false)
}

export async function toggleWorktrees($: EngineInterface) {
  if (await togglePane($, WORKTREES, 'Worktrees')) await refreshTrees($)
}

// Moves the pick and scrolls the pane just enough to keep that row in view.
async function moveTree($: EngineInterface, dir: -1 | 1) {
  const all = (await read($, trees)) ?? []
  let to = 0
  await update($, treeSel, at => (to = Math.max(0, Math.min(all.length - 1, at + dir))))
  const path = all[to]?.path
  if (path) await $.ui.scroll({ in: WORKTREES, to: { key: `tree-row-${path}` }, block: 'nearest' })
}

async function picked($: EngineInterface): Promise<Worktree | undefined> {
  const [all, sel] = await Promise.all([read($, trees), read($, treeSel)])
  return all?.[sel]
}

// lazygit in a herdr split to the right of this pane, started in the worktree; outside herdr, the command to run.
async function lazygit($: EngineInterface) {
  const t = await picked($)
  if (!t) return
  const split = await run($, ['herdr', 'pane', 'split', '--current', '--direction', 'right', '--cwd', t.path, '--focus'])
  let id: string | undefined
  try {
    id = split ? (JSON.parse(split) as { result?: { pane?: { pane_id?: string } } }).result?.pane?.pane_id : undefined
  } catch {
    id = undefined
  }
  if (!id) {
    $.ui.toast(`Could not open a herdr split; run: lazygit -p ${t.path}`)
    return
  }
  if ((await run($, ['herdr', 'pane', 'run', id, 'lazygit'])) === undefined) $.ui.toast('The split opened, but lazygit did not start in it')
}

// Focus the herdr workspace already open on the worktree, or open one there.
async function openWorkspace($: EngineInterface) {
  const t = await picked($)
  if (!t) return
  const ok = t.workspace
    ? await run($, ['herdr', 'workspace', 'focus', t.workspace])
    : await run($, ['herdr', 'worktree', 'open', '--path', t.path, '--focus'])
  if (ok === undefined) $.ui.toast(`herdr could not open ${t.branch ?? t.path}`)
  else if (!t.workspace) await refreshTrees($)
}

export function registerWorktrees(on: On) {
  on('ui.render', { component: 'Pane', requestId: WORKTREES }, async ($, e) => {
    const [all, at, busy, rawSel] = await Promise.all([read($, trees), read($, treesAt), read($, treesBusy), read($, treeSel), read($, tick)])
    // A worktree removed since the pick was made: the pick falls back to the last row.
    const sel = Math.max(0, Math.min(rawSel, (all?.length ?? 1) - 1))
    const { Box, Button, Text } = $.ui.resolve(e)
    const now = Date.now()
    const branch = Math.max(16, Math.min(BRANCH, e.props.bodyColumns - 52))
    const header = (
      <Box>
        <Box flexGrow={1}>
          <Text bold color="text">{`Worktrees${all ? ` (${all.length})` : ''}`}</Text>
          <Text color="subtle">{busy ? '   reading…' : at ? `   read ${ago(at, now)} ago` : ''}</Text>
        </Box>
        <Button key="refresh" plain hotkey="r" label="refresh" onPress={() => refreshTrees($)} />
        <Text>{'   '}</Text>
        <Button key="close" plain hotkey="x" label="close" role="dismiss" onPress={() => toggleWorktrees($)} />
      </Box>
    )
    if (!all) return <Box flexDirection="column">{header}<Text color="subtle">Reading the worktrees…</Text></Box>
    return (
      <Box flexDirection="column">
        {header}
        <Text color="inactive">{'─'.repeat(Math.max(10, e.props.bodyColumns))}</Text>
        {e.props.isFocused ? <Text>{' '}</Text> : <Text color="warning">Click inside the pane (or ctrl+x tab) to use its keys.</Text>}
        <Box>
          <Text bold color="text">{`   ${cell('branch', branch)}`}</Text>
          <Text bold color="text">{`${cell('changed', 9)}${cell('upstream', 13)}${cell('last commit', 13)}open`}</Text>
        </Box>
        {all.map((t, i) => {
          return (
          <Box key={`tree-${t.path}`}>
            <Text color="suggestion">{i === sel ? '› ' : '  '}</Text>
            {/* One text per Button: the pointer inverts all of it. */}
            <Button key={`tree-row-${t.path}`} plain onPress={() => update($, treeSel, () => i)}>
              <Text color={t.isCurrent ? 'remember' : i === sel ? 'suggestion' : 'text'}>{`${t.isCurrent ? '●' : ' '}${fit(t.branch ?? '(detached)', branch - 1)}`}</Text>
            </Button>
            <Text>{' '.repeat(Math.max(1, branch - fit(t.branch ?? '(detached)', branch - 1).length))}</Text>
            <Text color={t.dirty ? 'warning' : 'inactive'}>{cell(t.dirty === undefined ? '?' : t.dirty ? `${t.dirty}` : '—', 9)}</Text>
            <Text color={t.behind ? 'warning' : 'subtle'}>{cell(drift(t), 13)}</Text>
            <Text color="subtle">{cell(t.lastCommit ? `${ago(t.lastCommit * 1000, now)} ago` : '', 13)}</Text>
            <Text color={t.agent === 'working' ? 'claude' : 'subtle'}>
              {t.isCurrent ? 'here' : t.agent ? `agent ${t.agent}` : t.workspace ? 'workspace' : ''}
            </Text>
          </Box>
          )
        })}
        <Box>
          <Button key="tree-up" plain hotkey="k" label="up" onPress={() => moveTree($, -1)} />
          <Text>{'   '}</Text>
          <Button key="tree-down" plain hotkey="j" label="down" onPress={() => moveTree($, 1)} />
          <Text>{'   '}</Text>
          <Button key="tree-lazygit" plain hotkey="g" label="lazygit here" onPress={() => lazygit($)} />
          <Text>{'   '}</Text>
          <Button key="tree-open" plain hotkey="o" label="open workspace" onPress={() => openWorkspace($)} />
          <Text color="inactive">{`   ${sel + 1}/${all.length}`}</Text>
        </Box>
      </Box>
    )
  })
}
