// A program in a floating window over the layout, like tmux's display-popup: lazygit, gh dash, a diff.
// keys.json: "popup.<tool>" (TOOLS below). A 0-px block of this mod in the layout receives those commands (they
// reach shown copies only); it starts the tool in the focused pane's folder and opens a window holding it, with
// this mod as its title bar ({bar}). The bar closes the window when the program exits (q in
// lazygit) and kills the program when you close the window. A modal dialog: it takes the keyboard, dims the window,
// and (holding a terminal) passes Esc to the program; a window would leave the keyboard where it was.
import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
const TOOLS = {
  lazygit: ["lazygit"],
  dash: ["gh", "dash"],
  yazi: ["yazi"],
  shell: ["zsh"],
  // read-only review of this branch against its base, by a fresh Claude in plan mode (can't edit)
  review: ["claude", "--permission-mode", "plan", "Review the changes on this branch against its base (the closest of origin/dev and origin/HEAD by git merge-base, or `git config herdr.base`) and anything uncommitted. Read-only: report bugs, risky spots and missing tests, most severe first, with file:line."],
};

import { props, nextCommand, panes, focused, hc, exec, openOverlay, closeOverlay, terminals, theme, shared, setShared } from "herdr";

export default class Popup extends View {
  init(_props, cx) {
    const p = props() ?? {};
    if (p.bar) {
      // shortcut: polls every 500 ms for the exit, fine while one popup is open; a core event would be cheaper.
      cx.timer.every(500, () => {
        if (!terminals().some((t) => t.address === p.terminal && t.state === "live")) closeOverlay(shared(`popup.${p.terminal}`));
      });
      return;
    }
    cx.spawn(async (cx) => {
      for (;;) {
        const name = String(await nextCommand());
        // "run": what another mod asked for in shared("popup.next") = {argv, title, cwd}
        if (name === "run") { const n = shared("popup.next"); if (n?.argv) await this.open(cx, n.title ?? n.argv[0], n.argv, n.cwd).catch((e) => console.log(`popup run: ${e}`)); continue; }
        // "pick": yazi as a file picker; the chosen paths are pasted as @-mentions into the terminal focused now
        if (name === "pick") { const t = focused()?.terminal; if (t) await this.open(cx, "pick files", ["herdr-paths", "--to", t, "--pick"]).catch((e) => console.log(`popup pick: ${e}`)); continue; }
        if (TOOLS[name]) await this.open(cx, name, TOOLS[name]).catch((e) => console.log(`popup ${name}: ${e}`));
      }
    });
  }

  async open(cx, title, argv, at) {
      const f = focused();
      const pane = panes().find((x) => x.pane === f?.pane);
      const cwd = at ?? (await this.liveCwd(pane?.terminal ?? f?.terminal)) ?? pane?.cwd ?? f?.cwd ?? undefined;
      const r = await hc(["run", "--bg", "--json", ...(cwd ? ["--cwd", cwd] : []), "--", ...argv]);
      const terminal = JSON.parse(r.stdout).address;
      const id = openOverlay({ kind: "dialog", modal: true, width: 0.86, height: 0.84, layout: { type: "column", children: [
        { type: "block", size: { px: 28 }, content: { mod: "popup", props: { bar: true, terminal, title, cwd } } },
        { id: `popup-${terminal}`, type: "block", content: { terminal } },
      ] } });
      setShared(`popup.${terminal}`, id); // the bar closes the window by this id
  }

  // Where the focused terminal really is: a pane's cwd is its shell's (OSC 7), stale while an agent like Claude runs
  // in it after a cd. Walk from the terminal's process down through shells to the program and read its cwd.
  async liveCwd(terminal) {
    if (!terminal || terminal.includes("/")) return null; // another machine: no /proc here
    try {
      const pid = JSON.parse((await hc(["get", terminal, "--json"])).stdout).pid;
      const r = await exec("sh", ["-c", 'p=$1; while case $(cat /proc/$p/comm 2>/dev/null) in zsh|bash|sh|dash|fish) true;; *) false;; esac && c=$(pgrep -n -P $p); do p=$c; done; readlink /proc/$p/cwd', "_", String(pid)]);
      return r.code === 0 && r.stdout.trim() ? r.stdout.trim() : null;
    } catch { return null; }
  }

  close() {
    const p = props() ?? {};
    if (p.bar && terminals().some((t) => t.address === p.terminal && t.state === "live")) return hc(["kill", p.terminal]);
  }

  render() {
    const p = props() ?? {};
    const t = theme();
    if (!p.bar) return div();
    return h_flex().id("bar").size_full().px(10).gap(8).items_center().bg(t.chrome).text_size(12)
      .child(div().text_color(t.foreground).font_semibold().child(p.title))
      .child(div().flex_1().min_w(0).truncate().text_color(t.dim).child(p.cwd ?? ""))
      .child(div().id("x").px(6).rounded(4).text_color(t.muted).cursor_pointer().hover((s) => s.bg(t.hover))
        .on_click((_e, cx) => { cx.stop_propagation(); closeOverlay(shared(`popup.${p.terminal}`)); })
        .child("✕"));
  }
}
