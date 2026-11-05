// The main loop's last request: what the footer shows as model and effort.
export type Step = { model: string; effort?: string | number }
// The live context window, as session.measure reports it, with what the local breakdown adds:
// where auto-compaction runs and what the skill listing costs.
export type Ctx = { percent?: number; tokens?: number; window: number; compactAt?: number; skillList?: number }

// One line of the harness table: a /context category, or an item of a detail section.
export type Row = { name: string; tokens: number; kind?: 'used' | 'free' | 'buffer' | 'deferred'; note?: string }
// The context window as the local breakdown last counted it, ready to draw.
export type Harness = { rows: Row[]; mcp: Row[]; memory: Row[]; agents: Row[]; skills: Row[]; total: number; max: number }

declare module 'claude-code' {
  interface PluginState {
    footer: {
      // Row ids of the prompts typed this session, oldest first, the last 500.
      prompts: string[]
      // The prompt the jumpers last revealed; null while at the bottom.
      cursor: number | null
      step: Step | null
      ctx: Ctx | null
      // The session directory's git branch; null outside a repository.
      branch: string | null
      // The main loop's last finished turn: how long it ran and when it ended (epoch ms).
      turn: { ms: number; at: number } | null
      // Estimated tokens of each skill body loaded since the last compaction, by skill name.
      skills: Record<string, number>
      // Compactions this session (manual, auto or a plugin's; never a precompute).
      compactions: number
      harness: Harness | null
      // Each category's tokens when the main loop's current turn began: the base of the table's growth column.
      base: Record<string, number>
    }
  }
}
