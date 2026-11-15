// Feed herdr sidebar $branch / $worktrees / $jj tokens (see ~/Dotfiles/bin/herdr-vcs).
import type { HookAPI } from "@oh-my-pi/pi-coding-agent/extensibility/hooks";

export default function herdrVcs(pi: HookAPI): void {
  const report = async (_event: unknown, ctx: { cwd: string }): Promise<void> => {
    try {
      await pi.exec("herdr-vcs", [ctx.cwd], { cwd: ctx.cwd });
    } catch {
      // Sidebar metadata must never interrupt the session.
    }
  };
  pi.on("session_start", report);
  pi.on("agent_start", report);
  pi.on("agent_end", report);
}
