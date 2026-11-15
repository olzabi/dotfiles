export type Mode = 'cards' | 'lines' | 'group'
export type Toggle = 'prompt' | 'thinking' | 'mentions' | 'toon' | 'outlines' | 'previews' | 'spinner' | 'narration' | 'tight' | 'trim' | 'trace' | 'guards' | 'summary' | 'route' | 'brief'
// Partial: a toggle missing from an older saved value reads as its default.
export type Toggles = Partial<Record<Toggle, boolean>>
export type Target = 'assistant' | 'tool'
// Each target's background: a preset name or `#rrggbb`; absent is off.
export type Backgrounds = Partial<Record<Target, string>>

// One tool call in the ledger (`hooks/agent.ts`).
export type CallEntry = {
  id: string;
  // Absent on the main loop.
  agentId?: string;
  tool: string;
  label: string;
  what: string;
  at: number;
  ms: number;
  ok: boolean;
  bytes: number;
  files: string[];
  // First line of a failure.
  err?: string;
  // The failure was a refusal (permission, policy), not the tool's own error.
  denied?: boolean;
  // A hash of the call's exact arguments: guards and open failures key on it, not on `what`.
  sig?: string;
};

export type TurnStats = { calls: number; failed: number; edited: string[]; agents: number; saved: number };

declare module 'claude-code' {
  interface PluginState {
    hush: {
      mode: Shaped<Mode>
      toggles: Toggles
      lastPrompt: string | null
      thought: string | null
      // tool_use_ids (and `say-…` ids of folded text) unfolded in place.
      expanded: string[]
      // Text of main-loop steps that ended in tool calls (flattened), the last 200.
      narration: string[]
      // Answers that followed a turn's tool calls (flattened), the last 200.
      finals: string[]
      backgrounds: Backgrounds
      // Tool calls of the session for the UI and mcp__hush__trace: the main loop's last 300, each subagent's last 40.
      // The whole history is the ledger on disk (core/ledger.ts).
      trace: CallEntry[]
      // Characters kept from the model, by rule (trim, read, toon).
      saved: Record<string, number>
      // A compaction happened; the next main-loop call or prompt carries the recap.
      pendingRecap: boolean
      // When the current main turn started (ms); its calls are the ledger's from then.
      turnFrom: number
      lastTurn: TurnStats | null
      // The main turn now running and the saved total when it began (survive a reload mid-turn).
      turnState: { id: string | null; savedAtStart: number }
      // When each loop ('' main) last compacted: searches before it are out of context.
      compactedAt: Record<string, number>
    }
  }
}
