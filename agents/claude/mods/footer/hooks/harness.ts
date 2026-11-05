import type { SessionContextBreakdown } from 'claude-code'

import type { Harness, Row } from '../types'

const bySize = (a: Row, b: Row) => b.tokens - a.tokens

// `/home/me/proj/.claude/CLAUDE.md` → `.claude/CLAUDE.md`: enough of a path to tell files apart.
const tail = (path: string) => path.split('/').slice(-2).join('/')

// The breakdown as the table draws it: categories in /context's order, each detail section largest first.
export function snapshot(b: SessionContextBreakdown): Harness {
  const servers = new Map<string, { tokens: number; loaded: number; all: number }>()
  for (const t of b.mcpTools) {
    const s = servers.get(t.serverName) ?? { tokens: 0, loaded: 0, all: 0 }
    s.all += 1
    if (t.isLoaded) (s.loaded += 1), (s.tokens += t.tokens)
    servers.set(t.serverName, s)
  }
  return {
    rows: b.categories.map(c => ({ name: c.name, tokens: c.tokens, kind: c.kind })),
    mcp: [...servers].map(([name, s]) => ({ name, tokens: s.tokens, note: `${s.loaded}/${s.all} tools` })).sort(bySize),
    memory: b.memoryFiles.map(f => ({ name: tail(f.path), tokens: f.tokens, note: f.type })).sort(bySize),
    agents: b.agents.map(a => ({ name: a.agentType, tokens: a.tokens, note: a.source })).sort(bySize),
    skills: (b.skills?.skillFrontmatter ?? []).map(s => ({ name: s.name, tokens: s.tokens, note: 'listed' })).sort(bySize),
    total: b.totalTokens,
    max: b.rawMaxTokens,
  }
}

// The skills section: bodies loaded since the last compaction first, then the listing's entries.
export function skillRows(listed: Row[], loaded: Record<string, number>): Row[] {
  const bodies = Object.entries(loaded).map(([name, tokens]) => ({ name, tokens, note: 'loaded' }))
  return [...bodies.sort(bySize), ...listed]
}

// Growth of a category since the turn began; undefined where there is no base or nothing changed.
export function growth(row: Row, base: Record<string, number>): number | undefined {
  const was = base[row.name]
  return was === undefined || was === row.tokens ? undefined : row.tokens - was
}

export const baseOf = (h: Harness) => Object.fromEntries(h.rows.map(r => [r.name, r.tokens]))
