// The main loop's last request: what the footer shows as model and effort.
export type Step = { model: string; effort?: string | number };
// The live context window, as session.measure reports it, with what the local breakdown adds:
// where auto-compaction runs.
export type Ctx = { percent?: number; tokens?: number; window: number; compactAt?: number };

// One line of the harness table: a /context category, or an item of a detail section.
export type Row = { name: string; tokens: number; kind?: 'used' | 'free' | 'buffer' | 'deferred'; note?: string };
// The context window as the local breakdown last counted it, ready to draw.
export type Harness = {
  rows: Row[];
  mcp: Row[];
  memory: Row[];
  agents: Row[];
  skills: Row[];
  // What each plugin puts in the window (skills, agents, MCP tools); absent in a snapshot an older version stored.
  plugins?: Row[];
  // What each plugin brings, by plugin name: its skills, agents and MCP servers (note `skill`, `agent`, `MCP`), largest first.
  pluginItems?: Record<string, Row[]>;
  total: number;
  max: number;
};

// One rate-limit window as session.measure reports it: `five_hour`, `seven_day` or a gateway's `spend_limit`.
export type Limit = { kind: string; percentUsed: number; resetsAt?: string };
// The account's windows and what the session has cost; either may be missing (off a subscription, no ledger).
export type Usage = { limits: Limit[]; usd?: number };
// A tool call of the main loop that errored or was denied: its tool_use_id (the transcript row to jump to),
// the tool, the first line of what went wrong, and when (epoch ms).
export type Fault = { id: string; tool: string; summary: string; at: number };
// One frame of the trace: a typed prompt (its message id and gist), when, and what its turn's tool calls came to.
export type Trace = { id: string; text: string; at: number; tools: number; faults: Fault[] };
// One main-loop request's prompt as the cache saw it: tokens read from it, written to it, sent fresh; when (epoch ms).
export type CacheStep = { read: number; written: number; fresh: number; at: number };
// The session directory's repository after the last turn: branch (null when detached), the linked worktree's
// folder name when it differs from the branch, how many paths are changed (undefined when git timed out),
// and how many worktrees the repository has.
export type Repo = { branch: string | null; worktree?: string; dirty?: number; trees?: number };
// One worktree of the repository as the worktrees pane last read it: where, which branch, whether it is the session's
// own; changed files, commits ahead of and behind its upstream (none: no upstream), the last
// commit (epoch s); and what herdr has open there: a workspace id and the busiest agent's state.
export type Worktree = {
  path: string;
  branch: string | null;
  isCurrent: boolean;
  dirty?: number;
  ahead?: number;
  behind?: number;
  lastCommit?: number;
  workspace?: string;
  agent?: string;
};

declare module 'claude-code' {
  interface PluginState {
    footer: {
      // The prompts typed this session, oldest first, the last 200, each with its tool calls and failures.
      trail: Trace[];
      // The prompt the jumpers last revealed; null while at the bottom.
      cursor: number | null;
      // The failure the badge last revealed, in faultsOf's order; null before the first jump since the last prompt.
      faultAt: number | null;
      step: Step | null;
      ctx: Ctx | null;
      // The session directory's repository; null outside one.
      repo: Repo | null;
      usage: Usage | null;
      // The main loop's last requests as the cache saw them, oldest first, the last 24.
      cacheLog: CacheStep[];
      // Bumped every few seconds once the session pane has opened, so its "N ago" figures age on screen.
      tick: number;
      // The main loop's last finished turn: how long it ran and when it ended (epoch ms).
      turn: { ms: number; at: number } | null;
      // Estimated tokens of each skill body loaded since the last compaction, by skill name.
      skills: Record<string, number>;
      // Compactions this session (manual, auto or a plugin's; never a precompute).
      compactions: number;
      harness: Harness | null;
      // Each category's tokens when the main loop's current turn began: the base of the table's growth column.
      base: Record<string, number>;
      // The session pane's tab (1 Context, 2 Plugins, 3 Cache); anything else reads as 1.
      sessionTab: number;
      // The Context tab's section opened to its rows (`memory`, `mcp`, `skills`, `agents`); null when all are folded.
      ctxOpen: string | null;
      // Plugin rows opened in the Plugins tab, by plugin name.
      pluginOpen: Record<string, boolean>;
      // The Plugins tab row the keys act on.
      pluginSel: number;
      // True between a first `c` and the second that compacts (it lapses after a few seconds).
      compactArmed: boolean;
      // The worktrees as last read (on opening the pane or a refresh); null before the first reading.
      trees: Worktree[] | null;
      // When that reading finished (epoch ms).
      treesAt: number | null;
      // True while a reading runs.
      treesBusy: boolean;
      // The worktrees row the keys act on.
      treeSel: number;
    };
  }
}
