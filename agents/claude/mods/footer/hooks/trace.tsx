import { atom, read, update } from 'claude-code'
import type { ApiContentBlock, EngineInterface, Register } from 'claude-code'

import type { Fault, Trace } from '../types'
import { togglePane } from './pane'

// The trace: each prompt typed this session with the tool calls its turn made and the ones that failed,
// stepped through from the footer (prompt by prompt, failure by failure) and laid out in the trace pane
// like a debugger's call stack: newest prompt first, its failures under it, each row a jump to the transcript.
type On = Parameters<Register>[0]
type Ui = ReturnType<EngineInterface['ui']['resolve']>

const trail = atom({ plugin: 'footer', key: 'trail' } as const, [] as Trace[])
const cursor = atom({ plugin: 'footer', key: 'cursor' } as const, null as number | null)
const faultAt = atom({ plugin: 'footer', key: 'faultAt' } as const, null as number | null)
export const TRACE = 'trace'
const KEEP = 200
const FAULTS_PER_PROMPT = 20
const STACK_ROWS = 40

// The first line of a text, cut to `n`: a prompt's or an error's gist.
export function gist(text: string | undefined, n = 80): string {
  const line = (text ?? '').split('\n').map(s => s.trim()).find(Boolean) ?? ''
  return line.length > n ? `${line.slice(0, n - 1)}…` : line
}

// A prompt's text from its content blocks, the text ones joined.
export const promptText = (content: readonly ApiContentBlock[]) =>
  gist(content.flatMap(b => (b.type === 'text' ? [b.text] : [])).join(' ').replace(/\s+/g, ' '), 120)

// Every failure, oldest first, with the prompt it belongs to.
export const faultsOf = (t: readonly Trace[]) => t.flatMap((p, i) => p.faults.map(f => ({ ...f, prompt: i })))

// Where a prompt jump lands: from the bottom (null) back to the last prompt, never past either end.
export function target(at: number | null, count: number, dir: -1 | 1): number | null {
  if (!count) return null
  if (at === null) return dir === -1 ? count - 1 : null
  return Math.max(0, Math.min(count - 1, at + dir))
}

// Where a failure jump lands: the newest first, then each older one, back round to the newest (an IDE's next problem).
export function nextFault(at: number | null, count: number): number | null {
  if (!count) return null
  return at === null || at === 0 ? count - 1 : at - 1
}

const clock = (at: number) => new Date(at).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })

// Brings a transcript row (a prompt by its message id, a tool call by its tool_use_id) to the top of the window.
// Allowed: it answers the person's press. A row hush folds still scrolls by its id.
async function reveal($: EngineInterface, id: string) {
  const r = await $.ui.scroll({ to: { requestId: id }, block: 'start' })
  if (r.deny) $.ui.toast(`Could not jump there (${r.deny})`)
}

async function jumpPrompt($: EngineInterface, dir: -1 | 1) {
  const t = await read($, trail)
  let to: number | null = null
  await update($, cursor, at => (to = target(at, t.length, dir)))
  const id = to === null ? undefined : t[to]?.id
  if (id) await reveal($, id)
}

async function jumpFault($: EngineInterface) {
  const all = faultsOf(await read($, trail))
  let to: number | null = null
  await update($, faultAt, at => (to = nextFault(at, all.length)))
  const f = to === null ? undefined : all[to]
  if (!f) return
  await update($, cursor, () => f.prompt)
  await reveal($, f.id)
}

async function toggleTrace($: EngineInterface) {
  await togglePane($, TRACE, 'Trace')
}

// The footer's navigator: `‹ prompt 3/7 ›  ✗ 2 failed`; the count opens the trace, the badge steps through failures.
export async function traceNav($: EngineInterface, { Box, Button, Text }: Ui) {
  const [t, at, fa] = await Promise.all([read($, trail), read($, cursor), read($, faultAt)])
  if (!t.length) return null
  const faults = faultsOf(t).length
  return (
    <Box flexShrink={0}>
      <Button key="prev" plain onPress={() => jumpPrompt($, -1)}>
        <Text color="suggestion">‹</Text>
      </Button>
      <Text>{' '}</Text>
      <Button key="trace" plain onPress={() => toggleTrace($)}>
        <Text color="subtle">{`prompt ${at === null ? t.length : at + 1}/${t.length}`}</Text>
      </Button>
      <Text>{' '}</Text>
      <Button key="next" plain onPress={() => jumpPrompt($, 1)}>
        <Text color="suggestion">›</Text>
      </Button>
      {faults ? (
        <Box>
          <Text>{'  '}</Text>
          <Button key="fault" plain onPress={() => jumpFault($)}>
            <Text color="error">{`✗ ${fa === null ? faults : `${fa + 1}/${faults}`} failed`}</Text>
          </Button>
        </Box>
      ) : null}
    </Box>
  )
}

// Called from the module's one session.start hook (the engine takes one per event without a matcher).
export async function startTrace($: EngineInterface) {
  await $.command.register({ name: 'trace', description: 'Trace pane: each prompt with its tool calls and failures, newest first' })
}

export function registerTrace(on: On) {
  on('command.run', { command: 'trace' }, async $ => {
    await toggleTrace($)
    return { text: 'Trace toggled.' }
  })

  // A typed prompt opens a new frame; the cursors go back to the bottom.
  on('session.append', async ($, e, next) => {
    const r = await next(e)
    if (!e.agentId && e.door === 'prompt' && e.origin.kind === 'composer' && !e.message.isMeta) {
      const frame: Trace = { id: e.uuid, text: promptText(e.message.content), at: Date.now(), tools: 0, faults: [] }
      await update($, trail, t => [...t, frame].slice(-KEEP))
      await update($, cursor, () => null)
      await update($, faultAt, () => null)
    }
    return r
  }).catch(($, e, next) => next(e))

  // Each main-loop tool call counts toward the open frame; one that errored or was denied is kept as a failure.
  on('tool.call', async ($, e, next) => {
    const r = await next(e)
    if (!e.agentId) {
      const why = 'deny' in r && r.deny ? `denied: ${gist(r.deny)}` : r.isError ? gist(r.text ?? String(r.result ?? 'error')) || 'error' : undefined
      const fault: Fault | undefined = why === undefined ? undefined : { id: e.tool_use_id, tool: e.tool, summary: why, at: Date.now() }
      await update($, trail, t => {
        const open = t.at(-1)
        if (!open) return t
        const faults = fault && open.faults.length < FAULTS_PER_PROMPT ? [...open.faults, fault] : open.faults
        return [...t.slice(0, -1), { ...open, tools: open.tools + 1, faults }]
      })
    }
    return r
  }).catch(($, e, next) => next(e))

  on('ui.render', { component: 'Pane', requestId: TRACE }, async ($, e) => {
    const t = await read($, trail)
    const { Box, Button, Text } = $.ui.resolve(e)
    if (!t.length) return <Text color="subtle">No prompts yet: the trace starts with the next one you type.</Text>
    const width = Math.max(20, e.props.bodyColumns - 26)
    const frames = t.map((p, i) => ({ p, i })).reverse().slice(0, STACK_ROWS)
    return (
      <Box flexDirection="column">
        {frames.map(({ p, i }) => (
          <Box key={p.id} flexDirection="column">
            <Box>
              <Button key={`prompt-${p.id}`} plain onPress={() => update($, cursor, () => i).then(() => reveal($, p.id))}>
                <Text color={p.faults.length ? 'error' : 'suggestion'}>{`#${i + 1}`.padEnd(5)}</Text>
              </Button>
              <Box flexGrow={1} flexShrink={1}>
                <Text color="text" wrap="truncate-end">{p.text ? gist(p.text, width) : '(no text)'}</Text>
              </Box>
              <Text color="subtle">{`  ${clock(p.at)}  ${p.tools} tool${p.tools === 1 ? '' : 's'}`}</Text>
            </Box>
            {p.faults.map(f => (
              <Box key={f.id}>
                <Text>{'     '}</Text>
                <Button key={`fault-${f.id}`} plain onPress={() => reveal($, f.id)}>
                  <Text color="error">{`✗ ${f.tool}`}</Text>
                </Button>
                <Box flexShrink={1}>
                  <Text color="subtle" wrap="truncate-end">{`  ${f.summary}`}</Text>
                </Box>
              </Box>
            ))}
          </Box>
        ))}
        {t.length > STACK_ROWS ? <Text color="inactive">{`${t.length - STACK_ROWS} older prompts`}</Text> : null}
      </Box>
    )
  })
}
