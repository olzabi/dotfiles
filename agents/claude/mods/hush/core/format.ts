const HIT = /^([^\s:][^:]*):(\d+):(.*)$/

// `rg -n` / `grep -rn` output as one header per file and `line: text` rows under it;
// null unless every line is a match, so ordinary output keeps its own drawing.
// shortcut: context lines (`path-12-text`) are not matches, so -A/-B/-C output falls through.
export function groupMatches(output: string): string[] | null {
  const lines = output.split('\n').filter(l => l.trim() && l !== '--')
  const hits = lines.map(l => HIT.exec(l))
  // A path of digits alone is a clock (`10:15:02 started`), not a file.
  if (lines.length < 2 || hits.some(h => !h || /^\d+$/.test(h[1] ?? ''))) return null
  const rows: string[] = []
  let file = ''
  for (const h of hits) {
    const [, path = '', line = '', text = ''] = h ?? []
    if (path !== file) rows.push((file = path))
    rows.push(`  ${line}: ${text.trimStart()}`)
  }
  return rows
}

// The first `max` rows; when rows are left out the marker rides the last row, never a row of its own.
export function capRows(rows: string[], max: number): string[] {
  if (rows.length <= max) return rows
  const shown = rows.slice(0, max)
  shown[max - 1] += ' [...]'
  return shown
}

// An MCP tool's result as preview rows: JSON text pretty-printed, other text as it is;
// null for any shape that is not a string or text blocks (images, structured records).
export function mcpPreview(output: unknown, max: number): string[] | null {
  const blocks = Array.isArray(output) ? output : typeof output === 'string' ? [output] : null
  if (!blocks?.length) return null
  const texts: string[] = []
  for (const b of blocks) {
    const t = typeof b === 'string' ? b : b?.type === 'text' && typeof b.text === 'string' ? b.text : null
    if (t === null) return null
    texts.push(t)
  }
  let text = texts.join('\n')
  try {
    text = JSON.stringify(JSON.parse(text), null, 2)
  } catch {
    // not JSON: the text stays as it came
  }
  return capRows(text.split('\n').filter(l => l.trim()), max)
}

// ── TOON ────────────────────────────────────────────────────────────────────
// Token-Oriented Object Notation: YAML-ish objects, `key[N]: a,b` primitive lists and
// `key[N]{f,g}:` tables for lists of flat records that share their keys.
type J = null | boolean | number | string | J[] | { [k: string]: J }
const isPrim = (v: J): v is null | boolean | number | string => v === null || typeof v !== 'object'
const SAFE_KEY = /^[A-Za-z_][\w.]*$/
const key = (k: string) => (SAFE_KEY.test(k) ? k : JSON.stringify(k))

function prim(v: null | boolean | number | string): string {
  if (typeof v !== 'string') return String(v)
  const risky = !v || v !== v.trim() || /[,:"\\\n\r\t[\]{}]/.test(v) || /^-/.test(v) ||
    /^(true|false|null)$/.test(v) || /^-?\d+(\.\d+)?(e[+-]?\d+)?$/i.test(v)
  return risky ? JSON.stringify(v) : v
}

// The shared keys of a list of flat records, or null when it is not one.
function tableKeys(a: J[]): string[] | null {
  if (!a.length || !a.every(x => x && typeof x === 'object' && !Array.isArray(x))) return null
  const ks = Object.keys(a[0] as object)
  const same = (o: object) => Object.keys(o).length === ks.length && ks.every(k => k in o)
  const ok = ks.length > 0 && a.every(o => same(o as object) && Object.values(o as object).every(v => isPrim(v as J)))
  return ok ? ks : null
}

function lines(name: string, v: J, pad: string, out: string[]): void {
  const head = `${pad}${name}`
  if (isPrim(v)) return void out.push(`${head}: ${prim(v)}`)
  if (!Array.isArray(v)) {
    if (!Object.keys(v).length) return void out.push(`${head}: {}`)
    out.push(`${head}:`)
    for (const [k, x] of Object.entries(v)) lines(key(k), x, `${pad}  `, out)
    return
  }
  if (v.every(isPrim)) return void out.push(`${head}[${v.length}]: ${v.map(x => prim(x as never)).join(',')}`.trimEnd())
  const ks = tableKeys(v)
  if (ks) {
    out.push(`${head}[${v.length}]{${ks.map(key).join(',')}}:`)
    for (const o of v) out.push(`${pad}  ${ks.map(k => prim((o as Record<string, null>)[k] ?? null)).join(',')}`)
    return
  }
  out.push(`${head}[${v.length}]:`)
  for (const x of v) {
    if (isPrim(x)) {
      out.push(`${pad}  - ${prim(x)}`)
      continue
    }
    const sub: string[] = []
    if (Array.isArray(x)) lines('', x, `${pad}    `, sub)
    else for (const [k, y] of Object.entries(x)) lines(key(k), y, `${pad}    `, sub)
    // `- ` takes the item's first line; the rest stay indented under it.
    out.push(`${pad}  - ${(sub[0] ?? '{}').trimStart()}`, ...sub.slice(1))
  }
}

export function toToon(value: unknown): string {
  const v = value as J
  if (isPrim(v)) return prim(v)
  const out: string[] = []
  if (Array.isArray(v)) lines('', v, '', out)
  else for (const [k, x] of Object.entries(v)) lines(key(k), x, '', out)
  return out.join('\n')
}

// JSON text as TOON, or null when the text is not a JSON object or list, or TOON saves nothing.
export function jsonToToon(text: string): string | null {
  const t = text.trim()
  if (!/^[[{]/.test(t)) return null
  // JSON.parse rounds integers past 2^53: an id like 12345678901234567890 would reach the model changed.
  if (/[:[,]\s*-?[\d.]{16,}/.test(t)) return null
  try {
    const toon = toToon(JSON.parse(t))
    return toon.length < t.length ? toon : null
  } catch {
    return null
  }
}

// ── Outlines ────────────────────────────────────────────────────────────────
const DECL = [
  // JS / TS
  /^\s*(export\s+)?(default\s+)?(declare\s+)?(abstract\s+)?(async\s+)?(function\*?|class|interface|type|enum|namespace)\s+[\w$]/,
  /^\s*export\s+(const|let|var)\s+[\w$]+/,
  /^\s*(const|let)\s+[\w$]+\s*=\s*(async\s+)?(\([^)]*\)|[\w$]+)\s*=>/,
  // Python, Ruby
  /^\s*(async\s+)?def\s+\w/, /^\s*(class|module)\s+[A-Z]/,
  // Go, Rust, Lua, shell
  /^func\s/, /^type\s+\w+\s+(struct|interface)/,
  /^\s*(pub(\([^)]*\))?\s+)?(async\s+)?(fn|struct|enum|trait|impl|mod)\b/,
  /^\s*(local\s+)?function\s+[\w.:]+\s*\(/, /^\s*(function\s+)?[\w-]+\s*\(\)\s*\{/,
]
// Class members: an indented `name(args) {` that is no control statement.
const METHOD = /^\s+(static\s+|async\s+|get\s+|set\s+|public\s+|private\s+|protected\s+|readonly\s+)*[\w$]+\s*(<[^>]*>)?\([^)]*\)\s*(:[^={]+)?\{\s*$/
const KEYWORD = /^\s*(if|for|while|switch|catch|return|else|do|with|function)\b/
const HEADING = /^#{1,6}\s+\S/

const isDecl = (l: string, md: boolean) =>
  md ? HEADING.test(l) : DECL.some(r => r.test(l)) || (METHOD.test(l) && !KEYWORD.test(l))

const tidy = (l: string) => l.replace(/\s*[{:]?\s*$/, '').replace(/\s*=>.*$/, ' =>').replace(/\s+/g, ' ')

// Declaration rows of a file: `  12 class Shop`, indented as the source nests them.
export function outline(content: string, path = '', startLine = 1): string[] {
  const md = /\.(md|mdx|markdown)$/i.test(path)
  const rows: string[] = []
  const all = content.split('\n')
  for (const [n, l] of all.entries()) {
    if (!isDecl(l, md)) continue
    const depth = md ? (l.match(/^#+/)?.[0].length ?? 1) - 1 : Math.floor((l.match(/^\s*/)?.[0].replace(/\t/g, '  ').length ?? 0) / 2)
    rows.push(`${String(n + startLine).padStart(4)} ${'  '.repeat(Math.min(depth, 6))}${tidy(l.trim())}`)
  }
  return rows
}

// The declarations an edit touched: for each hunk, the nearest one at or above its first
// changed line in the original, and any the new text declares itself.
export function touched(
  original: string | null,
  hunks: readonly { oldStart: number; newStart: number; lines: readonly string[] }[],
  path = '',
): string[] {
  const md = /\.(md|mdx|markdown)$/i.test(path)
  const src = (original ?? '').split('\n')
  const out = new Set<string>()
  for (const h of hunks) {
    const firstChange = h.lines.findIndex(l => l[0] === '-' || l[0] === '+')
    let at = h.oldStart - 1 + Math.max(0, h.lines.slice(0, firstChange).filter(l => l[0] !== '+').length)
    for (; at >= 0; at--) if (src[at] !== undefined && isDecl(src[at] as string, md)) break
    if (at >= 0) out.add(tidy((src[at] as string).trim()))
    for (const l of h.lines) if (l[0] === '+' && isDecl(l.slice(1), md)) out.add(tidy(l.slice(1).trim()))
  }
  return [...out]
}

// ── @@agent mentions ────────────────────────────────────────────────────────
// `@@name` words outside backtick code, as written (no case change), each once.
export function mentions(text: string): string[] {
  const prose = text.replace(/```[\s\S]*?```/g, ' ').replace(/`[^`\n]*`/g, ' ')
  const found = [...prose.matchAll(/(?:^|\s)@@([\w:.-]*\w)/g)].map(m => m[1] as string)
  return [...new Set(found)]
}

// ── Compact diffs ───────────────────────────────────────────────────────────
type Hunk = { oldStart: number; newStart: number; lines: readonly string[] }
export type DiffRow = { text: string; kind: 'head' | 'gap' | 'add' | 'del' | 'ctx' }

// An edit as `path +N -M`, then its changed lines alone (old numbers on removals, new on
// additions), one `···` between hunks, the indentation they share trimmed. With `context`,
// the unchanged lines of each hunk too (the viewer's whole diff).
export function compactDiff(path: string, hunks: readonly Hunk[], context = false): DiffRow[] {
  const changes: { n: number; mark: '+' | '-' | ' '; code: string; isFirst: boolean }[] = []
  for (const h of hunks) {
    let oldN = h.oldStart
    let newN = h.newStart
    let isFirst = true
    for (const l of h.lines) {
      const mark = l[0]
      if (mark === '-' || mark === '+' || (context && mark === ' ')) {
        changes.push({ n: mark === '-' ? oldN : newN, mark, code: l.slice(1).replace(/\t/g, '  '), isFirst })
        isFirst = false
      }
      if (mark !== '+') oldN++
      if (mark !== '-') newN++
    }
  }
  if (!changes.some(c => c.mark !== ' ')) return []
  const indent = Math.min(...changes.filter(c => c.code.trim()).map(c => c.code.match(/^ */)?.[0].length ?? 0))
  const width = String(Math.max(...changes.map(c => c.n))).length
  const adds = changes.filter(c => c.mark === '+').length
  const dels = changes.filter(c => c.mark === '-').length
  const rows: DiffRow[] = [{ text: `${path} +${adds} -${dels}`, kind: 'head' }]
  for (const [i, c] of changes.entries()) {
    if (c.isFirst && i > 0) rows.push({ text: '···', kind: 'gap' })
    const code = Number.isFinite(indent) ? c.code.slice(indent) : c.code
    rows.push({ text: `${String(c.n).padStart(width)} ${c.mark} ${code}`, kind: c.mark === '+' ? 'add' : c.mark === '-' ? 'del' : 'ctx' })
  }
  return rows
}

// ── Shell rows ──────────────────────────────────────────────────────────────
// One shell word: quoted, `$(…)`, or plain characters up to a space or separator.
// The alternatives are disjoint (a plain character is never a quote or `$`), so a failed match
// backtracks linearly: overlapping ones went exponential on `cd "a""a"…`.
const WORD = String.raw`(?:"[^"]*"|'[^']*'|\$\([^)]*\)|\$(?!\()|[^\s;&|"'$])+`
// Setup that leads a command and says nothing about it: `cd dir;`, `VAR=x &&`, `export A=1 B=2;`.
const LEAD = new RegExp(String.raw`^\s*(?:cd\s+${WORD}|(?:export\s+)?\w+=${WORD}(?:\s+\w+=${WORD})*)\s*(?:&&|;)\s*`)
const WRAPPERS = new Set(['sudo', 'env', 'command', 'exec', 'nohup', 'time', 'timeout'])

export function stripLead(command: string): string {
  // Setup is short; a long command's head is all the row shows anyway.
  let c = command.length > 2000 ? command.slice(0, 2000) : command
  for (let m = LEAD.exec(c); m; m = LEAD.exec(c)) c = c.slice(m[0].length)
  return c.trim()
}

// Absolute paths as the reader knows them: under `root` relative, under the home `~`.
export function shortPaths(text: string, root = ''): string {
  const home = /^\/(?:home|Users)\/[^/]+/.exec(root)?.[0]
  let t = root ? text.split(`${root}/`).join('').split(root).join('.') : text
  if (home) t = t.split(home).join('~')
  return t
}

// A Bash call as `LABEL` + what it does, read from the command when it has no description:
// setup stripped, heredoc writes named WRITE, polling loops WAIT, inline scripts by their first line.
export function shellRow(command: string, root = ''): { label: string; what: string } {
  const [first = '', ...body] = stripLead(command).split('\n')
  const line = first.trim()
  const write = /^(?:cat\s+>>?\s*(\S+)\s*<<|cat\s+<<-?\s*\S+\s*>>?\s*(\S+)|tee\s+(?:-a\s+)?(\S+)\s*<<)/.exec(line)
  if (write) return { label: 'WRITE', what: shortPaths(write[1] ?? write[2] ?? write[3] ?? '', root) }
  const wait = /^(?:(?:until|while)\s+(.+?);\s*do\b|sleep\s+\d+\w*\s*(?:;|&&)\s*(.+))/.exec(line)
  if (wait) return { label: 'WAIT', what: shortPaths((wait[1] ?? wait[2] ?? '').trim(), root) }
  const words = line.split(/\s+/)
  const prog = words.find(w => !/^\w+=/.test(w) && !WRAPPERS.has(w) && !/^\d+[smh]?$/.test(w)) || 'bash'
  const name = (prog.replace(/^[({!]+/, '').split('/').pop() || 'bash').toUpperCase()
  if (/<<-?\s*['"]?\w+/.test(line) && body.length) {
    const n = body.length - 1
    // `python3 - <<E` says nothing before its script: show the script's first line instead.
    const head = line.replace(/\s*<<-?\s*['"]?\w+['"]?.*$/, '')
    if (!/^\S+(\s+-)?$/.test(head)) return { label: name, what: shortPaths(`${head} … +${n} lines`, root) }
    const lead = body.find(l => l.trim() && !/^\s*(import|from|#|use |require)\b/.test(l))?.trim() ?? ''
    return { label: name, what: shortPaths(`${n} lines: ${lead}`, root) }
  }
  return { label: name, what: shortPaths(line, root) }
}

// ── Call rows ───────────────────────────────────────────────────────────────
// `LABEL  what` for any tool call; shared by the mod and `bin/replay.ts`.
export type Call = { tool: string; input: unknown; isRunning: boolean; isErrored: boolean }

export const str = (v: unknown) => (typeof v === 'string' ? v : undefined)
export const base = (p: string) => p.split('/').pop() ?? p
export const args = (c: Call) => (c.input ?? {}) as Record<string, unknown>

export function label(c: Call): string {
  const i = args(c)
  if (c.tool === 'Bash') return shellRow(str(i.command) ?? '').label
  if (c.tool === 'Skill') return `/${str(i.skill) ?? 'skill'}`
  if (c.tool.startsWith('mcp__')) return c.tool.split('__').slice(1).join(':').toUpperCase()
  // A subagent is named for its type, past a plugin prefix (`plugin-dev:agent-creator`).
  if (c.tool === 'Agent' || c.tool === 'Task') return (str(i.subagent_type)?.split(':').pop() || 'agent').toUpperCase()
  return c.tool.toUpperCase()
}

// An MCP call with none of the usual fields: its first short string argument (`function`, `uid`),
// so two different calls never read as the same row.
const ENVELOPE = new Set(['tool', 'tool_use_id', 'agentId', 'requestMeta', 'consent'])
function firstArg(i: Record<string, unknown>): string | undefined {
  for (const [k, v] of Object.entries(i)) {
    if (ENVELOPE.has(k)) continue
    if (typeof v === 'string' && v.trim()) return `${k}=${v.replace(/\s+/g, ' ').trim().slice(0, 60)}`
    if (typeof v === 'number' || typeof v === 'boolean') return `${k}=${v}`
  }
  return undefined
}

// shortcut: per-tool field guesses, no local-model intent line; upgrade by reading `description` from more tools.
// The row's Text truncates to the terminal width; only the first line is taken here.
export function describe(c: Call, root = ''): string {
  const i = args(c)
  const file = str(i.file_path) ?? str(i.notebook_path) ?? str(i.path)
  const what =
    str(i.description) ??
    (c.tool === 'Bash' ? shellRow(str(i.command) ?? '', root).what : undefined) ??
    str(i.pattern) ?? str(i.query) ?? str(i.url) ?? str(i.prompt) ?? str(i.args) ??
    (c.tool.startsWith('mcp__') ? firstArg(i) : undefined)
  return [what?.split('\n')[0], file && base(file)].filter(Boolean).join('  ')
}
