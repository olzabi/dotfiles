import type { SessionContextBreakdown } from 'claude-code';

import type { Harness, Row } from '../types';

const bySize = (a: Row, b: Row) => b.tokens - a.tokens;

// `/home/me/proj/.claude/CLAUDE.md` → `.claude/CLAUDE.md`: enough of a path to tell files apart.
const tail = (path: string) => path.split('/').slice(-2).join('/');

// The breakdown as the table draws it: categories in /context's order, each detail section largest first.
export function snapshot(b: SessionContextBreakdown): Harness {
  const servers = new Map<string, { tokens: number; loaded: number; all: number }>();
  for (const t of b.mcpTools) {
    const s = servers.get(t.serverName) ?? { tokens: 0, loaded: 0, all: 0 };
    s.all += 1;
    if (t.isLoaded) ((s.loaded += 1), (s.tokens += t.tokens));
    servers.set(t.serverName, s);
  }
  return {
    rows: b.categories.map((c) => ({ name: c.name, tokens: c.tokens, kind: c.kind })),
    mcp: [...servers].map(([name, s]) => ({ name, tokens: s.tokens, note: `${s.loaded}/${s.all} tools` })).sort(bySize),
    memory: b.memoryFiles.map((f) => ({ name: tail(f.path), tokens: f.tokens, note: f.type })).sort(bySize),
    agents: b.agents.map((a) => ({ name: a.agentType, tokens: a.tokens, note: a.source })).sort(bySize),
    skills: (b.skills?.skillFrontmatter ?? [])
      .map((s) => ({ name: s.name, tokens: s.tokens, note: 'listed' }))
      .sort(bySize),
    plugins: pluginRows(b),
    pluginItems: pluginItems(b),
    total: b.totalTokens,
    max: b.rawMaxTokens,
  };
}

// A plugin's MCP server as /mcp names it: `plugin:ecc:chrome-devtools`.
const PLUGIN_SERVER = /^plugin:([^:]+):/;

// Each plugin's share of the window: its listed skills, its agents (`ecc:architect`) and its loaded MCP tools,
// largest first, noted with what it brings: `314 skills · 71 agents · 1 MCP`.
export function pluginRows(b: SessionContextBreakdown): Row[] {
  const by = new Map<string, { tokens: number; skills: number; agents: number; mcp: Set<string> }>();
  const of = (name: string) =>
    by.get(name) ?? by.set(name, { tokens: 0, skills: 0, agents: 0, mcp: new Set() }).get(name)!;
  for (const s of b.skills?.skillFrontmatter ?? []) {
    if (s.pluginName) ((of(s.pluginName).tokens += s.tokens), (of(s.pluginName).skills += 1));
  }
  for (const a of b.agents) {
    const name = a.source === 'plugin' && a.agentType.includes(':') ? a.agentType.split(':')[0] : undefined;
    if (name) ((of(name).tokens += a.tokens), (of(name).agents += 1));
  }
  for (const t of b.mcpTools) {
    const name = PLUGIN_SERVER.exec(t.serverName)?.[1];
    if (name && t.isLoaded) ((of(name).tokens += t.tokens), of(name).mcp.add(t.serverName));
  }
  const count = (n: number, one: string) => (n ? `${n} ${one}${n === 1 || one === 'MCP' ? '' : 's'}` : '');
  return [...by]
    .map(([name, p]) => ({
      name,
      tokens: p.tokens,
      note: [count(p.skills, 'skill'), count(p.agents, 'agent'), count(p.mcp.size, 'MCP')].filter(Boolean).join(' · '),
    }))
    .sort(bySize);
}

// What each plugin brings, item by item, for a row opened in the Plugins tab: its skills and agents by name
// (`architect` for `ecc:architect`), its MCP servers by name with their loaded tools summed; largest first.
export function pluginItems(b: SessionContextBreakdown): Record<string, Row[]> {
  const out: Record<string, Row[]> = {};
  const add = (plugin: string, row: Row) => (out[plugin] ??= []).push(row);
  for (const s of b.skills?.skillFrontmatter ?? [])
    if (s.pluginName) add(s.pluginName, { name: s.name, tokens: s.tokens, note: 'skill' });
  for (const a of b.agents) {
    const [plugin, name] = a.agentType.split(':');
    if (a.source === 'plugin' && plugin && name) add(plugin, { name, tokens: a.tokens, note: 'agent' });
  }
  const servers = new Map<string, Row & { plugin: string }>();
  for (const t of b.mcpTools) {
    const m = /^plugin:([^:]+):(.+)$/.exec(t.serverName);
    if (!m?.[1] || !m[2] || !t.isLoaded) continue;
    const s = servers.get(t.serverName) ?? { plugin: m[1], name: m[2], tokens: 0, note: 'MCP' };
    s.tokens += t.tokens;
    servers.set(t.serverName, s);
  }
  for (const { plugin, ...row } of servers.values()) add(plugin, row);
  for (const rows of Object.values(out)) rows.sort(bySize);
  return out;
}

// The skills section: bodies loaded since the last compaction first, then the listing's entries.
export function skillRows(listed: Row[], loaded: Record<string, number>): Row[] {
  const bodies = Object.entries(loaded).map(([name, tokens]) => ({ name, tokens, note: 'loaded' }));
  return [...bodies.sort(bySize), ...listed];
}

// Growth of a category since the turn began; undefined where there is no base or nothing changed.
export function growth(row: Row, base: Record<string, number>): number | undefined {
  const was = base[row.name];
  return was === undefined || was === row.tokens ? undefined : row.tokens - was;
}

export const baseOf = (h: Harness) => Object.fromEntries(h.rows.map((r) => [r.name, r.tokens]));
