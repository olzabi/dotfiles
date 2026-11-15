// Writes each tool call to the hush ledger (~/.local/state/hush), so `hush trace | tree | board | brief`
// and the hush MCP tools cover OMP sessions live. The row is built by `hush log` (~/Dotfiles/bin/hush).
import type { HookAPI } from "@oh-my-pi/pi-coding-agent/extensibility/hooks";

export default function hushLedger(pi: HookAPI): void {
  const started = new Map<string, number>();
  pi.on("tool_call", (event) => {
    started.set(event.toolCallId, Date.now());
  });
  pi.on("tool_result", async (event, ctx) => {
    try {
      const at = started.get(event.toolCallId) ?? Date.now();
      started.delete(event.toolCallId);
      const session = ctx.sessionManager?.getSessionId?.();
      if (!session) return;
      const text = (event.content ?? []).map((b) => (b.type === "text" ? b.text : "")).join("\n");
      // Arguments cut short: the row needs a first line, not a written file's body.
      const input = Object.fromEntries(
        Object.entries(event.input ?? {}).map(([k, v]) => [k, typeof v === "string" ? v.slice(0, 400) : v]),
      );
      const call = {
        session,
        harness: "omp",
        cwd: ctx.cwd,
        id: event.toolCallId,
        tool: event.toolName,
        input,
        ok: !event.isError,
        ...(event.isError ? { err: text.split("\n").find((l) => l.trim())?.trim() } : {}),
        at,
        ms: Date.now() - at,
        bytes: text.length,
      };
      await pi.exec("hush", ["log", JSON.stringify(call)], { cwd: ctx.cwd });
    } catch {
      // The ledger must never interrupt the session.
    }
  });
}
