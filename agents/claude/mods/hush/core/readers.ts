// Transcript readers, pure (text in, items out): Claude Code sessions and the pi family (pi, OMP).
// Every surface (replay, stats, analysis, the MCP server) works on `Transcript`, never on a harness's own shape.
import { describe, label } from './format.ts';

export type CallItem = {
  kind: 'call';
  id: string;
  tool: string;
  label: string;
  what: string;
  input: Record<string, unknown>;
  isErrored: boolean;
  result: string;
  // ms since epoch when the call was made, when the transcript says.
  at?: number;
  // How many model calls the session had made when this call was made (for cache-read estimates).
  modelCall: number;
};
export type Item =
  | { kind: 'user'; text: string; at?: number }
  | { kind: 'text'; text: string }
  | { kind: 'bg'; text: string }
  | { kind: 'interrupt'; at?: number }
  | CallItem;

export type Transcript = { harness: 'claude' | 'pi'; cwd: string; items: Item[]; modelCalls: number };

type Block = {
  type: string;
  text?: string;
  id?: string;
  name?: string;
  input?: unknown;
  tool_use_id?: string;
  is_error?: boolean;
  content?: unknown;
  arguments?: unknown;
  intent?: string;
};

const ts = (v: unknown) => (typeof v === 'string' ? Date.parse(v) || undefined : typeof v === 'number' ? v : undefined);
const textOf = (c: unknown): string =>
  typeof c === 'string'
    ? c
    : Array.isArray(c)
      ? c.map((b) => (typeof b?.text === 'string' ? b.text : '')).join('\n')
      : '';
const flat = (s: string) => s.replace(/\s+/g, ' ').trim();

function lines(text: string): Record<string, unknown>[] {
  const out: Record<string, unknown>[] = [];
  for (const l of text.split('\n')) {
    if (!l.trim()) continue;
    try {
      out.push(JSON.parse(l));
    } catch {
      // a line cut mid-write by a running session
    }
  }
  return out;
}

function callOf(
  id: string,
  tool: string,
  input: Record<string, unknown>,
  cwd: string,
  modelCall: number,
  at?: number,
): CallItem {
  const c = { tool, input, isRunning: false, isErrored: false };
  return {
    kind: 'call',
    id,
    tool,
    label: label(c),
    what: describe(c, cwd),
    input,
    isErrored: false,
    result: '',
    modelCall,
    ...(at ? { at } : {}),
  };
}

export function parseClaude(text: string): Transcript {
  const seenIds = new Set<string>();
  const items: Item[] = [];
  const calls = new Map<string, CallItem>();
  let cwd = '';
  let modelCalls = 0;
  for (const e of lines(text)) {
    cwd ||= typeof e.cwd === 'string' ? e.cwd : '';
    const m = (e.message ?? {}) as { content?: unknown; usage?: unknown };
    const at = ts(e.timestamp);
    // One API response is written as one line per content block: count distinct message ids.
    const mid = (m as { id?: unknown }).id;
    if (e.type === 'assistant' && m.usage && !(typeof mid === 'string' && seenIds.has(mid))) {
      modelCalls++;
      if (typeof mid === 'string') seenIds.add(mid);
    }
    const content = m.content;
    // A subagent's task (sidechain) and a compaction summary are not prompts the user typed.
    if (e.type === 'user' && typeof content === 'string' && !e.isMeta && !e.isSidechain && !e.isCompactSummary) {
      const note = /<task-notification>[\s\S]*?<status>(\w+)<\/status>[\s\S]*?<summary>([\s\S]*?)<\/summary>/.exec(
        content,
      );
      if (note) items.push({ kind: 'bg', text: `${note[1]} ${flat(note[2] ?? '')}` });
      else if (content.startsWith('[Request interrupted')) items.push({ kind: 'interrupt', ...(at ? { at } : {}) });
      else if (!content.startsWith('<')) items.push({ kind: 'user', text: content, ...(at ? { at } : {}) });
      continue;
    }
    if (!Array.isArray(content)) continue;
    for (const b of content as Block[]) {
      if (e.type === 'assistant' && b.type === 'text' && b.text?.trim()) items.push({ kind: 'text', text: b.text });
      if (e.type === 'assistant' && b.type === 'tool_use' && b.id && b.name) {
        const call = callOf(b.id, b.name, (b.input ?? {}) as Record<string, unknown>, cwd, modelCalls, at);
        calls.set(b.id, call);
        items.push(call);
      }
      if (e.type === 'user' && b.type === 'text' && b.text?.startsWith('[Request interrupted'))
        items.push({ kind: 'interrupt', ...(at ? { at } : {}) });
      if (b.type === 'tool_result' && b.tool_use_id) {
        const call = calls.get(b.tool_use_id);
        if (call) Object.assign(call, { isErrored: !!b.is_error, result: textOf(b.content) });
      }
    }
  }
  return { harness: 'claude', cwd, items, modelCalls };
}

// pi and OMP: `{type:"message", message:{role, content:[{type:"toolCall", id, name, arguments, intent}]}}`,
// results as `role:"toolResult"` with toolCallId / isError; tool names lower-case (`bash`, `edit`).
export const PI_TOOLS: Record<string, string> = {
  bash: 'Bash',
  read: 'Read',
  edit: 'Edit',
  write: 'Write',
  grep: 'Grep',
  glob: 'Glob',
  ls: 'LS',
  find: 'Glob',
};

export function parsePi(text: string): Transcript {
  const items: Item[] = [];
  const calls = new Map<string, CallItem>();
  let cwd = '';
  let modelCalls = 0;
  for (const e of lines(text)) {
    if (!cwd && typeof e.cwd === 'string') cwd = e.cwd;
    if (e.type !== 'message') continue;
    const m = (e.message ?? {}) as {
      role?: string;
      content?: unknown;
      toolCallId?: string;
      isError?: boolean;
      usage?: unknown;
    };
    const at = ts(e.timestamp);
    if (m.role === 'user') {
      const t = textOf(m.content);
      if (t.trim()) items.push({ kind: 'user', text: t, ...(at ? { at } : {}) });
    }
    if (m.role === 'assistant') {
      modelCalls++;
      for (const b of Array.isArray(m.content) ? (m.content as Block[]) : []) {
        if (b.type === 'text' && b.text?.trim()) items.push({ kind: 'text', text: b.text });
        if (b.type === 'toolCall' && b.id && b.name) {
          const args = (b.arguments ?? {}) as Record<string, unknown>;
          const input = {
            ...args,
            ...(b.intent ? { description: b.intent } : {}),
            file_path: args.file_path ?? args.path,
          };
          const call = callOf(b.id, PI_TOOLS[b.name] ?? b.name, input, cwd, modelCalls, at);
          calls.set(b.id, call);
          items.push(call);
        }
      }
    }
    if (m.role === 'toolResult' && m.toolCallId) {
      const call = calls.get(m.toolCallId);
      if (call) Object.assign(call, { isErrored: !!m.isError, result: textOf(m.content) });
    }
  }
  return { harness: 'pi', cwd, items, modelCalls };
}

// pi-family files open with a `{type:"title"|"session", v}` header; Claude's never do.
export function parseTranscript(text: string): Transcript {
  const first = text.slice(0, text.indexOf('\n') > 0 ? text.indexOf('\n') : text.length);
  return /^\{"type":"(title|session)"/.test(first) ? parsePi(text) : parseClaude(text);
}

export const callsOf = (t: Transcript) => t.items.filter((i): i is CallItem => i.kind === 'call');
