// mini: display-only trims for built-in tool cards in the interactive TUI.
// Headless runs (print, json, rpc, ACP) render no transcript, so this entry
// stays a bare gate: the renderer code is imported only once a TUI session
// starts.
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import { type ToolRenderer, toolRenderers } from "@oh-my-pi/pi-tui/tools";
import bash from "./bash.ts";
import evaluate from "./eval.ts";
import { headerOnly, type Transform } from "./transforms.ts";

const overrides: Record<string, Transform> = {
  bash,
  eval: evaluate,
  edit: headerOnly,
  find: headerOnly,
  glob: headerOnly,
  grep: headerOnly,
  read: headerOnly,
  write: headerOnly,
};
const ORIGINAL = Symbol.for("mini.original");
type Patched = ToolRenderer & {
  [ORIGINAL]?: Pick<ToolRenderer, "renderCall" | "renderResult">;
};

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode !== "tui") return;
    // Dynamic import on purpose: headless modes must never load the renderer code.
    for (const [name, transform] of Object.entries(overrides)) {
      const renderer: Patched | undefined = toolRenderers[name];
      if (!renderer) continue;
      const original = (renderer[ORIGINAL] ??= {
        renderCall: renderer.renderCall,
        renderResult: renderer.renderResult,
      });
      renderer.renderCall = (args, options, theme) => {
        const component = original.renderCall.call(
          renderer,
          args,
          options,
          theme,
        );
        return component && transform(component, options, theme);
      };
      renderer.renderResult = (result, options, theme, args) => {
        const component = original.renderResult.call(
          renderer,
          result,
          options,
          theme,
          args,
        );
        return (
          component &&
          transform(component, options, theme, result.isError === true)
        );
      };
    }
  });
}
