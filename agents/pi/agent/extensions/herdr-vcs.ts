// Feed the herdr sidebar $branch token for this pane (see ~/Dotfiles/bin/herdr-vcs); mirrors omp hooks/pre/herdr-vcs.ts.
export default function (pi) {
  if (process.env.HERDR_ENV !== "1") return;
  const report = async (_event, ctx) => {
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
