export type Mode = 'cards' | 'lines' | 'group'
export type Toggle = 'prompt' | 'thinking' | 'mentions' | 'toon' | 'outlines' | 'previews' | 'spinner' | 'narration' | 'tight' | 'errors'
// Partial: a toggle missing from an older saved value reads as its default.
export type Toggles = Partial<Record<Toggle, boolean>>
export type Target = 'assistant' | 'tool'
// Each target's background: a preset name or `#rrggbb`; absent is off.
export type Backgrounds = Partial<Record<Target, string>>

declare module 'claude-code' {
  interface PluginState {
    hush: {
      mode: Shaped<Mode>
      toggles: Toggles
      lastPrompt: string | null
      thought: string | null
      // Failed calls of the main loop this session, the last 20.
      failures: { id: string; label: string; what: string }[]
      // tool_use_ids (and `say-…` ids of folded text) unfolded in place.
      expanded: string[]
      // Text of main-loop steps that ended in tool calls (flattened), the last 200.
      narration: string[]
      // Answers that followed a turn's tool calls (flattened), the last 200.
      finals: string[]
      backgrounds: Backgrounds
    }
  }
}
