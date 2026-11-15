// Inject jj/mise rules once per session, only when the repo uses them (see ~/Dotfiles/agents/rules/detect.sh).
import type { HookAPI } from "@oh-my-pi/pi-coding-agent/extensibility/hooks";

const TYPE = "tooling-rules";

export default function toolingRules(pi: HookAPI): void {
  pi.on("before_agent_start", async (_event, ctx) => {
    // The message is persisted to the session, so resumed sessions already have it.
    if (ctx.sessionManager.getBranch().some((e: any) => e.type === "custom_message" && e.customType === TYPE)) return;
    try {
      const { stdout, code } = await pi.exec(`${process.env.HOME}/Dotfiles/agents/rules/detect.sh`, [ctx.cwd], { cwd: ctx.cwd });
      if (code === 0 && stdout.trim()) return { message: { customType: TYPE, content: stdout.trim(), display: false } };
    } catch {
      // Missing rules must never block the session.
    }
  });
}
