// my-menu: the context menus. Opened as a popup with props { tab: "pane" | "tab" | "space" | "global", target };
// with no props (`mod.open my-menu`, a key) it is the focused space's menu.
// Rows are grouped under section labels and rules; destructive ones are red; the bound key or a › sits on the right.
// Every list (Worktrees, a worktree's actions, Plans, a plan's files, Obsidian's worktrees) opens as a column beside
// the menu, level with its row, while the pointer rests on that row or in the list; resting elsewhere closes it.
// The popup is wide and see-through (frame "none", custom-spaces) so the columns fit; each draws its own panel.
// Keys: ↑/↓ move in a column (labels and rules are skipped), → opens a list and goes into it, ← back to its row,
// Enter runs, typing filters every list at hand into one column, Esc clears the filter, then closes.
// Space: New tab, New Claude here, New agent in worktree… (`claude --worktree <slug>` as a tab: the space stays on
// the main checkout, the agent gets .claude/worktrees/<slug> on branch worktree-<slug>); its checkout (review the
// branch in hunk, lazygit, GitHub); Worktrees (each: review, lazygit, Claude, shell, Obsidian, its plans, copy,
// remove; then New/Open worktree); Open in Obsidian (click: this checkout's vault; its list: each worktree's, via
// bin/ob); Plans (docs/plans/active: a plan, then its .md files, in Obsidian); copy path/branch, Rename, Remove
// worktree, Close. Folder rows are for spaces on this machine.
// Pane: split/zoom, its folder (copy path, yazi, hunk, lazygit, copy branch), right-click routing, close.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, ScrollHandle } from "gpui-base";
import { run, props, closeOverlay, openOverlay, theme, keys, terminals, spaces, panes, focused, home, exec, notify, setShared } from "herdr";

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
// `git worktree list --porcelain` → [{ path, name, branch }], main checkout first; prunable ones (folder gone) left out.
function worktrees(out) {
  return out.split("\n\n").map((b) => b.split("\n")).filter((l) => l[0]?.startsWith("worktree ") && !l.some((x) => x.startsWith("prunable")))
    .map((l) => {
      const path = l[0].slice(9);
      const ref = l.find((x) => x.startsWith("branch "));
      return { path, name: path.split("/").pop(), branch: ref ? ref.slice(18) : "detached" };
    });
}
// "2026-11-10-backlog" reads "backlog"
const planName = (n) => n.replace(/\.md$/, "").replace(/^\d{4}-\d{2}-\d{2}-/, "");
// A checkout's active plans (folders or .md files), null when it keeps none.
async function plansOf(top) {
  const ls = await exec("ls", ["-1", `${top}/${PLANS}`]).catch(() => null);
  return ls?.code === 0 ? ls.stdout.split("\n").filter(Boolean) : null;
}

const tilde = (p) => (p.startsWith(home()) ? `~${p.slice(home().length)}` : p);
const copy = (text) => exec("wl-copy", [text]);
const ob = (top, file) => exec("setsid", ["-f", "ob", top, ...(file ? [file] : [])]);
// A program in the popup window (mods/popup), as mods/my-agents does. modal: only its ✕ closes it (hunk holds unsent notes).
function popup(title, argv, cwd, modal = false) {
  setShared("popup.next", { title, argv, cwd, modal });
  run("popup.run");
}
// A checkout's whole branch in hunk: everything since it left the default branch, uncommitted work included.
const review = (cwd) => popup(`hunk · ${cwd.split("/").pop()}`, ["sh", "-c", 'b=$(git merge-base HEAD origin/HEAD 2>/dev/null || git merge-base HEAD origin/dev 2>/dev/null || echo HEAD); exec hunk diff "$b" --watch'], cwd, true);
const lazygit = (cwd) => popup("lazygit", ["lazygit"], cwd);
const worktreeDialog = (p) => openOverlay({ mod: "my-worktree", kind: "dialog", ...(p.action === "open" ? { width: 560, height: 480 } : { width: 440, height: 260 }), props: p });
async function github(top) {
  const r = await exec("gh", ["browse"], { cwd: top }).catch((e) => ({ code: 1, stderr: String(e) }));
  if (r.code !== 0) notify({ title: "Open on GitHub", body: (r.stderr || r.stdout || "").trim(), level: "warning" });
}

// The key bound to a command, for the hint on the right.
function shortcut(name, args) {
  // `pane.split:right` binds pane.split with { direction: "right" }.
  const value = args && Object.values(args)[0];
  const k = keys().find((b) => b.section === "global" && (b.action === name || b.action === `${name}:${value}`));
  return k ? k.keys : "";
}

// A row: { label, icon, go, hint?, danger?, kids?|load? (its list), stay? (the menu stays open) }; with neither go nor a list it is only text.
// { section } is a label, or a rule when "": the keys skip both.
const row = (label, icon, go, extra) => ({ label, icon, go, ...extra });
const cmd = (label, icon, name, args, extra) => row(label, icon, () => run(name, args), { hint: shortcut(name, args), ...extra });
const sec = (section = "") => ({ section });
const key = (it) => it.id ?? it.label;
// a row that drops a list below it: kids now, or load (async) on first open
const isList = (it) => Boolean(it?.kids || it?.load);
const live = (it) => Boolean(it.go || isList(it));
const W = 232, H = 520; // H: the popup's height (custom-spaces); one column; the popup is 5 columns wide (Worktrees › worktree › Plans › plan › file)
// a column's rows in px: a row 28, a rule 9, a label 20
// The full text of a row whose label or hint the column cuts off, for its tooltip; "" when it fits.
// shortcut: guesses width from length (~7 px a character at 12.8, ~6 px at 11); exact would need text measuring.
function full(it) {
  const hint = it.hint ? Math.min(it.hint.length * 6, 96) + 9 : 0;
  const room = W - 10 - 16 - 23 - hint - (isList(it) ? 21 : 0);
  const cut = it.label.length * 7 > room || (it.hint?.length ?? 0) * 6 > 96;
  return cut ? (it.hint ? `${it.label} · ${it.hint}` : it.label) : "";
}
const tall = (rows) => rows.reduce((h, it, i) => h + (it.section === undefined ? 28 : (i > 0 ? 9 : 0) + (it.section ? 20 : 0)), 0);
const icon = (name) => (name.includes("/") ? name : `mods/workspace-chrome/${name}.svg`);
const CLAUDE = "icons/claude.svg";

// Git work in one checkout: the space's own, and each worktree's submenu.
const gitRows = (top) => [
  row("Review branch in hunk", "git-compare", () => review(top)),
  row("lazygit", "icons/lazygit.svg", () => lazygit(top)),
];

export default class Menu extends View {
  init(_props, cx) {
    this.sel = null; // the selected row's key; null: the first one
    this.open = []; // keys of the rows whose lists are dropped down, outermost first
    this.cache = {}; // lists read on first open (a plan's files), by row key; null while reading
    this.query = "";
    this.git = null;
    this.local = null; // { cwd, top, repo, branch, github, plans, trees } for a folder on this machine
    this.scroll = ScrollHandle.new();
    this.handle = cx.focus_handle();
    this.handle.focus();
    const p = props() ?? {};
    // no props (mod.open, a key): the focused space's menu
    this.p = p.tab || !focused()?.space ? p : { ...p, tab: "space", target: { id: focused().space } };
    const tg = this.p.target ?? {};
    const space = this.p.tab === "space" && spaces().find((s) => s.id === tg.id);
    const pane = this.p.tab === "pane" && panes().find((x) => x.pane === tg.pane);
    this.name = space?.name;
    const folder = space ? place(space) : pane?.cwd;
    // another machine's ids are "<machine>/id": no folder rows there
    const remote = space ? space.machine : String(tg.pane ?? "").includes("/");
    if (folder)
      cx.spawn(async (cx) => {
        if (space) this.git = await checkout(folder, space.machine).catch(() => null);
        if (!remote) {
          const top = (await exec("git", ["rev-parse", "--show-toplevel"], { cwd: folder }).catch(() => null))?.stdout.trim();
          const at = top || folder;
          const [plans, wl, origin] = await Promise.all([
            plansOf(at),
            exec("git", ["-C", at, "worktree", "list", "--porcelain"]).catch(() => null),
            exec("git", ["-C", at, "remote", "get-url", "origin"]).catch(() => null),
          ]);
          const trees = wl?.code === 0 ? worktrees(wl.stdout) : [];
          const branch = trees.find((w) => w.path === at)?.branch;
          // each worktree's plans, for its Plans list
          const treePlans = Object.fromEntries(await Promise.all(trees.map(async (w) => [w.path, w.path === at ? plans : await plansOf(w.path)])));
          this.local = { cwd: folder, top: at, repo: Boolean(top), plans, trees, treePlans, branch: branch === "detached" ? null : branch, github: Boolean(origin?.stdout.includes("github.com")) };
        }
        cx.notify();
      });
  }

  // A worktree off the base branch for one agent, then Claude in it as a new tab of this space.
  agent(name) {
    const slug = name.toLowerCase().replace(/[^a-z0-9._/-]+/g, "-").split("/").pop().replace(/^-+|-+$/g, "");
    if (!slug) return;
    const space = this.p.target?.id;
    this.close();
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

  askAgent(cx) {
    this.ask = InputState.new({ placeholder: "agent name, e.g. fix-login" });
    this.ask.on("submit", () => this.agent(this.ask.value().trim()));
    this.ask.focus();
    cx.notify();
  }

  close() {
    const id = props()?.overlay;
    id ? closeOverlay(id) : run("overlay.close");
  }

  // The repo's worktrees when there is more than its own checkout: what "Open in Obsidian" drops below itself.
  trees() { return this.local?.trees?.length > 1 ? this.local.trees : []; }

  // docs/plans/active of one checkout: a single .md opens at once, a folder drops its .md files.
  plans(top, plans) {
    return plans.length
      ? plans.map((n) => n.endsWith(".md")
        ? row(planName(n), "file-text", () => ob(top, `${PLANS}/${n}`))
        : row(planName(n), "folder", null, { load: () => this.planFiles(top, n) }))
      : [row("No active plans", "minus")];
  }
  async planFiles(top, name) {
    const dir = `${PLANS}/${name}`;
    const r = await exec("find", [".", "-name", "*.md", "-type", "f"], { cwd: `${top}/${dir}` }).catch(() => null);
    // README.md first
    const files = (r?.code === 0 ? r.stdout.split("\n").filter(Boolean) : []).map((f) => f.slice(2)).sort((a, b) => (b === "README.md") - (a === "README.md") || a.localeCompare(b));
    return files.length ? files.map((f) => row(f, "file-text", () => ob(top, `${dir}/${f}`))) : [row("No markdown files", "minus")];
  }

  // Worktrees: every checkout of the repo (each drops its actions), then making and opening one.
  worktreeRows() {
    const space = this.p.target?.id;
    return [
      ...this.local.trees.map((w) => row(w.name, "git-branch", null, { hint: w.branch, kids: () => this.tree(w) })),
      sec(),
      row("New worktree…", "plus", () => worktreeDialog({ space, action: "new" })),
      row("Open worktree…", "folder", () => worktreeDialog({ space, action: "open" })),
    ];
  }
  // One worktree's actions; tabs it starts join this space.
  tree(w) {
    const space = this.p.target?.id, plans = this.local.treePlans?.[w.path];
    return [
      ...gitRows(w.path),
      row("New Claude here", CLAUDE, () => run("tab.new", { space, folder: w.path, argv: ["claude"] })),
      row("Shell here", "terminal", () => run("tab.new", { space, folder: w.path })),
      row("Open in Obsidian", "file-text", () => ob(w.path)),
      ...(plans ? [row("Plans", "layers", null, { kids: () => this.plans(w.path, plans) })] : []),
      row("Copy path", "files", () => copy(w.path)),
      ...(w.branch !== "detached" ? [row("Copy branch name", "git-branch", () => copy(w.branch))] : []),
      // the main checkout is not a worktree to remove
      ...(w.path !== this.local.trees[0].path ? [row("Remove worktree…", "x", () => worktreeDialog({ space, folder: w.path, action: "remove" }), { danger: true })] : []),
    ];
  }

  root() {
    const tg = this.p.target ?? {}, L = this.local;
    switch (this.p.tab) {
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
          ...(inTab ? [
            cmd("Split right", "panel-right", "pane.split", { direction: "right", pane: tg.pane }),
            cmd("Split down", "panel-right", "pane.split", { direction: "down", pane: tg.pane }),
            cmd("Zoom", "square", "pane.zoom", { pane: tg.pane }),
          ] : []),
          ...(L ? [
            sec(tilde(L.cwd)),
            row("Copy path", "files", () => copy(L.cwd)),
            row("Files in yazi", "folder", () => popup("yazi", ["yazi"], L.cwd)),
          ] : []),
          ...(L?.repo ? gitRows(L.top) : []),
          ...(L?.branch ? [row("Copy branch name", "git-branch", () => copy(L.branch), { hint: L.branch })] : []),
          ...(term ? [sec(), toProgram
            ? cmd("Use Herdr right-click menu", "terminal", "terminal.right_click", { terminal: term.address, to: "menu" })
            : cmd("Send right-clicks to pane", "terminal", "terminal.right_click", { terminal: term.address, to: "program" })] : []),
          ...(parent ? [cmd(`Send back to ${parent.name || parent.address}`, "chevron-left", "terminal.park", { terminal: term.address })] : []),
          ...(inTab ? [sec(), cmd("Close pane", "x", "pane.close", { pane: tg.pane }, { danger: true })] : []),
        ];
      }
      case "tab":
        return [
          cmd("New tab", "plus", "tab.new", { space: tg.space }),
          cmd("Rename", "square-pen", "tab.rename", { id: tg.id }),
          sec(),
          cmd("Close", "x", "tab.close", { id: tg.id }, { danger: true }),
        ];
      case "space": {
        const many = this.trees().length > 0;
        return [
          ...(this.name ? [sec(this.name)] : []),
          cmd("New tab", "plus", "tab.new", { space: tg.id }),
          ...(L ? [row("New Claude here", CLAUDE, () => run("tab.new", { space: tg.id, folder: L.top, argv: ["claude"] }))] : []),
          ...(L && this.git ? [row("New agent in worktree…", "git-branch", (cx) => this.askAgent(cx), { stay: true })] : []),
          ...(L?.repo ? [
            sec(L.branch ? `⎇ ${L.branch}` : "Checkout"),
            ...gitRows(L.top),
            ...(L.github ? [row("Open on GitHub", "icons/gh.svg", () => github(L.top))] : []),
            row("Worktrees", "layers", null, { hint: String(L.trees.length), kids: () => this.worktreeRows() }),
          ] : this.git ? [
            // another machine: no folder to list, the dialogs still work there
            sec("Worktrees"),
            row("New worktree…", "plus", () => worktreeDialog({ space: tg.id, action: "new" })),
            row("Open worktree…", "folder", () => worktreeDialog({ space: tg.id, action: "open" })),
          ] : []),
          ...(L ? [
            sec("Notes"),
            // clicked: this checkout's vault; its list: each worktree's
            row("Open in Obsidian", "file-text", () => ob(L.top), many ? { kids: () => this.trees().map((w) => row(w.name, "git-branch", () => ob(w.path), { hint: w.branch })) } : {}),
            ...(L.plans ? [row("Plans", "folder", null, { kids: () => this.plans(L.top, L.plans) })] : []),
          ] : []),
          sec(),
          ...(L ? [row("Copy path", "files", () => copy(L.top))] : []),
          ...(L?.branch ? [row("Copy branch name", "git-branch", () => copy(L.branch))] : []),
          cmd("Rename", "square-pen", "space.rename", { id: tg.id }),
          ...(this.git === "linked" ? [row("Remove worktree…", "x", () => worktreeDialog({ space: tg.id, action: "remove" }), { danger: true })] : []),
          cmd("Close", "x", "space.close", { id: tg.id }, { danger: true }),
        ];
      }
      default:
        return [
          cmd("New space", "plus", "space.new", {}),
          cmd("Keybinds", "terminal", "app.help", {}),
          cmd("Settings", "settings", "app.settings", {}),
          sec("Theme"),
          ...["graphite", "ink", "moss", "atom-one-dark"].map((name) => cmd(name.replaceAll("-", " "), "monitor", "app.theme", { name })),
        ];
    }
  }

  // With a filter: every list at hand in one column, then only matching actions.
  // A row's id is its parents' and its own, so the same action in two lists stays two rows.
  flat(rows, depth = 0, parents = []) {
    return rows.flatMap((it) => {
      const r = this.keyed(it, parents);
      if (!isList(it) || !(it.kids || this.cache[r.id])) return [r];
      return [r, ...this.flat(this.kidsOf(r), depth + 1, [...parents, r.id])];
    });
  }
  keyed(it, parents) { return { ...it, id: [...parents, key(it)].join("›"), parents }; }
  kidsOf(it) { return it.kids ? it.kids() : this.cache[it.id] ?? [row("Reading…", "spinner")]; }
  // The menu, then one column beside it per open list, its first row level with the row that opened it.
  columns() {
    const q = this.query.toLowerCase();
    if (q) return [{ rows: this.flat(this.root()).filter((it) => it.go && it.label.toLowerCase().includes(q)), y: 0 }];
    const cols = [{ rows: this.root().map((it) => this.keyed(it, [])), y: 0 }];
    for (const id of this.open) {
      const c = cols.at(-1), at = c.rows.findIndex((r) => r.id === id);
      if (at < 0) break;
      const p = c.rows[at], rows = this.kidsOf(p).map((it) => this.keyed(it, [...p.parents, p.id]));
      // shortcut: ignores how far the parent column is scrolled; fine while columns fit the popup's height
      cols.push({ rows, y: Math.max(0, Math.min(c.y + tall(c.rows.slice(0, at)), H - tall(rows) - 12)) });
    }
    return cols;
  }
  // The column the selection is in.
  current(cols) { return cols.find((c) => c.rows.some((r) => live(r) && r.id === this.sel)) ?? cols[0]; }
  at(list) {
    const i = list.findIndex((it) => live(it) && it.id === this.sel);
    return i >= 0 ? i : list.findIndex(live);
  }
  // The keys move the selection within its column; columns beside a row it leaves close.
  move(list, d) {
    let i = this.at(list);
    if (i < 0) return;
    do i = (i + d + list.length) % list.length; while (!live(list[i]));
    this.sel = list[i].id;
    this.open = list[i].parents;
    if (!list[i].parents.length) this.scroll.scroll_to_item(i);
  }
  // The pointer opens a list beside its row while it rests there (or in that list); resting elsewhere closes it.
  select(it, cx) {
    const open = [...it.parents, ...(isList(it) ? [it.id] : [])];
    if (this.sel === it.id && open.join("\n") === this.open.join("\n")) return;
    this.sel = it.id;
    this.open = open;
    this.load(it, cx);
    cx.notify();
  }
  toggle(it, cx) {
    const on = this.open.includes(it.id);
    this.sel = it.id;
    this.open = [...it.parents, ...(on ? [] : [it.id])];
    if (!on) this.load(it, cx);
    cx.notify();
  }
  load(it, cx) {
    if (!it.load || this.cache[it.id] !== undefined) return;
    this.cache[it.id] = null;
    cx.spawn(async (cx) => {
      this.cache[it.id] = await it.load().catch(() => [row("Couldn't read it", "minus")]);
      cx.notify();
    });
  }

  choose(it, cx) {
    if (!it?.go) return isList(it) && this.toggle(it, cx);
    if (it.stay) return it.go(cx);
    // close after the action: closing first could cancel one still awaiting (gh browse)
    cx.spawn(async () => { await it.go(); this.close(); });
  }

  onKey(e, cx) {
    const cols = this.columns(), list = this.current(cols).rows, it = list[this.at(list)];
    const mod = e.modifiers ?? {};
    if (e.key === "down") this.move(list, 1);
    else if (e.key === "up") this.move(list, -1);
    else if (e.key === "enter") return this.choose(it, cx);
    // → opens the list beside the row and goes into it; ← back to the row that opened it
    else if (e.key === "right" && isList(it) && !this.query) {
      this.open = [...it.parents, it.id];
      this.load(it, cx);
      const first = this.columns().at(-1).rows.find(live);
      this.sel = first && first.parents.at(-1) === it.id ? first.id : it.id;
    }
    else if (e.key === "left" && it?.parents.length && !this.query) { this.sel = it.parents.at(-1); this.open = it.parents.slice(0, -1); }
    else if (e.key === "escape") { if (!this.query) return this.close(); this.query = ""; }
    else if (e.key === "backspace" && this.query) this.query = this.query.slice(0, -1);
    else if (e.key_char?.length === 1 && e.key_char >= " " && !mod.control && !mod.alt && !mod.platform && (this.query || e.key_char !== " ")) { this.query += e.key_char; this.sel = null; }
    else return;
    cx.notify();
  }

  line(t, it, i, on) {
    if (it.section !== undefined)
      return v_flex().flex_none()
        .when(i > 0, (el) => el.child(div().mx(7).my(4).h(1).bg(t.border)))
        .when(Boolean(it.section), (el) => el.child(div().h(20).px(8).flex().items_center().text_size(10.5).font_medium().text_color(t.dim)
          .when(it.section.length * 6 > W - 26, (el) => el.id(`ms-${i}`).tooltip(it.section)).child(div().truncate().child(it.section))));
    const color = !live(it) ? t.dim : it.danger ? t.blocked : t.foreground;
    const open = this.open.includes(it.id);
    return h_flex()
      .id(`mi-${it.id}`)
      .h(28)
      .flex_none()
      .px(8)
      .gap(9)
      .rounded(7)
      .items_center()
      .text_color(color)
      .when(open && !on, (el) => el.bg(t.hover))
      .when(on, (el) => el.bg(t.selected))
      .when(Boolean(full(it)), (el) => el.tooltip(full(it)))
      .when(live(it), (el) => el.cursor_pointer()
        .on_click((_e, cx) => this.choose(it, cx))
        // the pointer selects, as the keys do: one highlight
        .on_hover((h, cx) => h && this.select(it, cx)))
      .child(svg(icon(it.icon)).size(14).flex_none().text_color(it.danger ? t.blocked : on ? t.foreground : t.muted))
      .child(div().flex_1().min_w(0).truncate().child(it.label))
      .when(Boolean(it.hint), (el) => el.child(div().flex_none().max_w(96).truncate().text_size(11).text_color(t.dim).child(it.hint)))
      .when(isList(it), (el) => el.child(svg(icon("chevron-right")).size(12).flex_none().text_color(open ? t.foreground : t.dim)));
  }

  render(cx) {
    const t = theme();
    const panel = (el) => el.bg(t.popover).border_1().border_color(t.border).rounded(8).shadow_lg().text_size(12.8).overflow_hidden();
    if (this.ask) return panel(v_flex().id("menu").w(W).p(5).gap(6).text_color(t.foreground))
      .on_key_down((e) => { if (e.key === "escape") this.close(); })
      .child(h_flex().h(28).px(8).gap(9).items_center()
        .child(svg(icon("git-branch")).size(14).flex_none().text_color(t.muted))
        .child(div().font_medium().child("New agent in worktree")))
      .child(div().h(30).mx(3).px(8).flex().items_center().rounded(6).border_1().border_color(t.accent).child(Input.new(this.ask).h_full()))
      .child(div().px(8).pb(4).text_size(11).text_color(t.dim).child("Enter: claude --worktree <name> as a new tab"));
    const cols = this.columns(), cur = this.current(cols);
    // frame "none": the popup is see-through; the menu and each list beside it draw their own panel
    return div()
      .id("menu")
      // sized by its columns, not size_full: opened without a size (mod.open) an all-absolute root would be 0×0
      .w(cols.length * (W - 4) + 4)
      .h(H)
      .relative()
      .track_focus(this.handle)
      .on_key_down((e, cx) => this.onKey(e, cx))
      .children(cols.map((c, k) => panel(v_flex().absolute().left(k * (W - 4)).top(c.y).w(W).max_h(H))
        .when(k === 0 && Boolean(this.query), (el) => el.child(h_flex().h(30).flex_none().px(13).gap(9).items_center().border_b(1).border_color(t.border)
          .child(svg(icon("search")).size(13).flex_none().text_color(t.accent))
          .child(div().flex_1().min_w(0).truncate().text_color(t.foreground).child(this.query))
          .child(div().flex_none().text_size(10.5).text_color(t.dim).child(c.rows.length ? "esc" : "no match"))))
        .child(v_flex()
          .id(`col-${k}`)
          .w_full()
          .max_h(H - 2 - (this.query ? 30 : 0)) // flex_1 would collapse to 0 in a column with no set height
          .overflow_y_scrollbar()
          .when(k === 0, (el) => el.track_scroll(this.scroll))
          .p(5)
          .children(c.rows.map((it, i) => this.line(t, it, i, c === cur && i === this.at(c.rows)))))));
  }
}
