// Context menus (Herdr's items). Opened as a popup with
// props { tab: "pane" | "tab" | "space" | "global", target }.
// ↑/↓ move, Enter runs, Esc closes. An item is [label, command, args];
// a command "worktree" opens the worktree dialog instead.
// my-menu: a space's menu also has New tab, Copy path, Open in Obsidian and Plans › (docs/plans/active of the
// space's checkout: a plan, then its .md files, one opens in Obsidian via bin/ob). Local spaces only for those.
// New agent in worktree…: the space stays on the repo's main checkout (dev); each agent gets its own scope:
// `claude --worktree <slug>` makes .claude/worktrees/<slug> on branch worktree-<slug> and starts there as a tab of the space.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { run, props, closeOverlay, openOverlay, theme, keys, terminals, spaces, panes, exec, notify } from "herdr";

// Where a space is now: its first terminal's live folder, else where it was made.
function place(s) {
  const tabs = new Set((s.tabs ?? []).map((c) => c.id));
  return panes().find((p) => tabs.has(p.tab) && p.cwd)?.cwd || s.folder;
}

// A space's checkout: "main" (a repo's own), "linked" (a worktree), or null.
async function checkout(folder, on) {
  const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd: folder, on });
  const common = await exec("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], { cwd: folder, on });
  if (top.code !== 0 || common.code !== 0) return null;
  return common.stdout.trim() === `${top.stdout.trim()}/.git` ? "main" : "linked";
}

const PLANS = "docs/plans/active";
// "2026-11-10-backlog" reads "backlog"
const planName = (n) => n.replace(/\.md$/, "").replace(/^\d{4}-\d{2}-\d{2}-/, "");

// Menu levels below a space: its plans, then one plan's markdown files.
function subItems(sub) {
  if (sub.files) return [["‹ Plans", "back", {}], ...sub.files.map((f) => [f, "obs", { file: `${sub.dir}/${f}` }])];
  return [["‹ Back", "back", {}], ...(sub.plans.length ? sub.plans.map((n) => [planName(n), "plan", { name: n }]) : [["No active plans", "none", {}]])];
}

function items(p, git, local) {
  p = p ?? {};
  const tg = p.target ?? {};
  switch (p.tab) {
    case "pane": {
      // A kept sub-agent can go back under its parent, still running.
      const all = terminals();
      const term = all.find((t) => t.address === tg.terminal);
      const parent = term?.parent && all.find((t) => t.address === term.parent);
      // Once they go to the program, Shift+right-click still opens this menu.
      const toProgram = term?.labels?.["herdr.right-click"] === "program";
      // A terminal shown outside a tab (a layout terminal block, a window) has
      // no pane to split, zoom or close: its pane is the block's id.
      const inTab = panes().some((pane) => pane.pane === tg.pane);
      return [
        ...(inTab
          ? [
              ["Split right", "pane.split", { direction: "right", pane: tg.pane }],
              ["Split down", "pane.split", { direction: "down", pane: tg.pane }],
              ["Zoom", "pane.zoom", { pane: tg.pane }],
            ]
          : []),
        ...(term
          ? [
              toProgram
                ? ["Use Herdr right-click menu", "terminal.right_click", { terminal: term.address, to: "menu" }]
                : ["Send right-clicks to pane", "terminal.right_click", { terminal: term.address, to: "program" }],
            ]
          : []),
        ...(parent ? [[`Send back to ${parent.name || parent.address}`, "terminal.park", { terminal: term.address }]] : []),
        ...(inTab ? [["Close pane", "pane.close", { pane: tg.pane }]] : []),
      ];
    }
    case "tab":
      return [
        ["Rename", "tab.rename", { id: tg.id }],
        ["New tab", "tab.new", { space: tg.space }],
        ["Close", "tab.close", { id: tg.id }],
      ];
    case "space":
      return [
        ["New tab", "tab.new", { space: tg.id }],
        ["Rename", "space.rename", { id: tg.id }],
        ...(local ? [["Copy path", "copy", {}], ["Open in Obsidian", "obs", {}]] : []),
        ...(local && git ? [["New agent in worktree…", "agent", {}]] : []),
        ...(local?.plans ? [["Plans ›", "plans", {}]] : []),
        ...(git ? [["New worktree", "worktree", { space: tg.id, action: "new" }], ["Open worktree", "worktree", { space: tg.id, action: "open" }]] : []),
        ...(git === "linked" ? [["Remove worktree", "worktree", { space: tg.id, action: "remove" }]] : []),
        ["Close", "space.close", { id: tg.id }],
      ];
    default:
      return [
        ["New space", "space.new", {}],
        ["Keybinds", "app.help", {}],
        ["Theme: graphite", "app.theme", { name: "graphite" }],
        ["Theme: ink", "app.theme", { name: "ink" }],
        ["Theme: moss", "app.theme", { name: "moss" }],
        ["Theme: atom one dark", "app.theme", { name: "atom-one-dark" }],
      ];
  }
}

function menuIcon(command) {
  const own = { agent: "git-branch", plans: "layers", plan: "folder", obs: "file-text", copy: "files", back: "chevron-left", none: "minus" }[command];
  if (own) return `mods/workspace-chrome/${own}.svg`;
  const name = command.endsWith(".close") ? "x" : command.endsWith(".rename") ? "square-pen" : command.endsWith(".new") ? "plus" : command === "worktree" ? "git-branch" : command === "app.help" ? "terminal" : command === "app.theme" ? "settings" : command === "pane.split" ? "panel-right" : command === "pane.zoom" ? "square" : "terminal";
  return `mods/workspace-chrome/${name}.svg`;
}

// The key bound to a command, for the hint on the right.
function shortcut(name, args) {
  // `pane.split:right` binds pane.split with { direction: "right" }.
  const value = args && Object.values(args)[0];
  const k = keys().find((b) => b.section === "global" && (b.action === name || b.action === `${name}:${value}`));
  return k ? k.keys : "";
}

export default class Menu extends View {
  init(_props, cx) {
    this.at = 0;
    this.git = null;
    this.local = null; // { top, plans } for a space on this machine
    this.sub = null; // { plans } or { plans, dir, files }
    this.handle = cx.focus_handle();
    this.handle.focus();
    const p = props();
    const space = p?.tab === "space" && spaces().find((s) => s.id === p.target?.id);
    const folder = space && place(space);
    if (folder)
      cx.spawn(async (cx) => {
        this.git = await checkout(folder, space.machine).catch(() => null);
        if (!space.machine) {
          const top = (await exec("git", ["rev-parse", "--show-toplevel"], { cwd: folder }).catch(() => null))?.stdout.trim() || folder;
          const ls = await exec("ls", ["-1", `${top}/${PLANS}`]).catch(() => null);
          this.local = { top, plans: ls?.code === 0 ? ls.stdout.split("\n").filter(Boolean) : null };
        }
        cx.notify();
      });
  }

  // A worktree off the base branch for one agent, then Claude in it as a new tab of this space.
  agent(name) {
    const slug = name.toLowerCase().replace(/[^a-z0-9._/-]+/g, "-").split("/").pop().replace(/^-+|-+$/g, "");
    if (!slug) return;
    const space = props()?.target?.id;
    closeOverlay(props()?.overlay);
    const fail = (what, r) => notify({ title: `New agent: ${what}`, body: (r?.stderr || r?.stdout || "").trim(), level: "warning" });
    (async () => {
      const g = (args) => exec("git", ["-C", this.local.top, ...args], { timeout: 30000 }).catch((e) => ({ code: 1, stderr: String(e) }));
      const common = (await g(["rev-parse", "--path-format=absolute", "--git-common-dir"])).stdout.trim();
      if (!common) return fail("not a git checkout", {});
      // keep agent worktrees out of the main checkout's git status
      if ((await g(["check-ignore", "-q", ".claude/worktrees/x"])).code !== 0)
        await exec("sh", ["-c", 'grep -qxF ".claude/worktrees/" "$1" 2>/dev/null || echo ".claude/worktrees/" >> "$1"', "sh", `${common}/info/exclude`]);
      // Claude makes the worktree itself (.claude/worktrees/<slug>, branch worktree-<slug>, the repo's
      // worktree.baseRef / sparsePaths / symlinkDirectories); wt lists, merges and removes it afterwards.
      run("tab.new", { space, folder: this.local.top, name: slug, argv: ["claude", "--worktree", slug] });
    })();
  }

  list() {
    return this.sub ? subItems(this.sub) : items(props(), this.git, this.local);
  }

  choose(i, cx) {
    const it = this.list()[i];
    if (!it) return;
    const [, cmd, args] = it;
    if (cmd === "none") return;
    if (cmd === "agent") {
      this.ask = InputState.new({ placeholder: "agent name, e.g. fix-login" });
      this.ask.on("submit", () => this.agent(this.ask.value().trim()));
      this.ask.focus();
      cx.notify();
      return;
    }
    if (cmd === "plans" || (cmd === "back" && this.sub?.files)) { this.sub = { plans: this.local.plans }; this.at = 0; cx.notify(); return; }
    if (cmd === "back") { this.sub = null; this.at = 0; cx.notify(); return; }
    if (cmd === "plan") {
      const dir = `${PLANS}/${args.name}`;
      cx.spawn(async (cx) => {
        // a plan is a folder (README.md first) or a single .md file
        const r = await exec("find", [".", "-name", "*.md", "-type", "f"], { cwd: `${this.local.top}/${dir}` }).catch(() => null);
        const files = r?.code === 0
          ? r.stdout.split("\n").filter(Boolean).map((f) => f.slice(2)).sort((a, b) => (b === "README.md") - (a === "README.md") || a.localeCompare(b))
          : null;
        this.sub = files ? { plans: this.sub.plans, dir, files } : { plans: this.sub.plans, dir: PLANS, files: [args.name] };
        this.at = 0;
        cx.notify();
      });
      return;
    }
    closeOverlay(props()?.overlay);
    if (cmd === "obs") { exec("setsid", ["-f", "ob", this.local.top, ...(args.file ? [args.file] : [])]); return; }
    if (cmd === "copy") { exec("wl-copy", [this.local.top]); return; }
    if (it[1] === "worktree") openOverlay({ mod: "my-worktree", kind: "dialog", ...(it[2].action === "open" ? { width: 560, height: 480 } : { width: 440, height: 260 }), props: it[2] });
    else run(it[1], it[2]);
  }

  render(cx) {
    const t = theme();
    if (this.ask) return v_flex().id("menu").w_full().p(8).gap(6).bg(t.popover).text_size(12.8).text_color(t.foreground)
      .on_key_down((e) => { if (e.key === "escape") closeOverlay(props().overlay); })
      .child(div().text_size(11.5).text_color(t.dim).child("New agent in its own worktree (Enter)"))
      .child(div().h(30).px(8).flex().items_center().rounded(6).border_1().border_color(t.accent).child(Input.new(this.ask).h_full()));
    const list = this.list();
    return v_flex()
      .id("menu")
      .track_focus(this.handle)
      .w_full()
      .max_h(420)
      .overflow_y_scrollbar()
      .p(5)
      .bg(t.popover)
      .text_size(12.8)
      .on_key_down((e, cx) => {
        if (e.key === "down") this.at = (this.at + 1) % list.length;
        else if (e.key === "up") this.at = (this.at + list.length - 1) % list.length;
        else if (e.key === "enter") this.choose(this.at, cx);
        else if (e.key === "escape") closeOverlay(props().overlay);
        else return;
        cx.notify();
      })
      .children(
        list.map((it, i) =>
          v_flex()
            .when(i > 0 && (it[1].endsWith(".close") || it[1] === "app.help" || (it[1] === "app.theme" && list[i - 1][1] !== "app.theme")), el => el.child(div().mx(7).my(4).h(1).bg(t.border)))
            .child(h_flex()
            .id(`mi-${i}`)
            .h(31)
            .px(8)
            .gap(9)
            .rounded(7)
            .items_center()
            .justify_between()
            .text_color(t.foreground)
            .when(i === this.at, (el) => el.bg(t.selected))
            .hover((s) => s.bg(t.hover))
            .on_click((_e, cx) => this.choose(i, cx))
            .child(svg(menuIcon(it[1])).size(14).flex_none().text_color(t.muted))
            .child(div().flex_1().child(it[0]))
            .child(div().text_size(11).text_color(t.dim).child(shortcut(it[1], it[2])))),
        ),
      );
  }
}
