// What needs you, most urgent first (port of herdr-side's 00-attention). Always shown (a hidden block never starts),
// so its header (search, new tab, new space) stays reachable.
//   ▲ agent blocked   ✕ agent exited   ? plan decision waiting for you   ◆ agent done, not seen yet
//   ⚑ plan blocker you do outside the code
// Plan blockers come from herdr-side's plans section ($XDG_RUNTIME_DIR/herdr-side/blockers.tsv).
//   ✓ agent ready for review (it ran `herdr-ready "summary"`, bin/herdr-ready; label herdr.ready)
//   ⌫ worktree whose branch is merged into its base (or whose upstream is gone): click twice to `git worktree remove`
// An agent's `herdr-ready --status` line (label herdr.status) replaces its title on its rows.
// Click: go to it (an exited row is dismissed once visited, a ready one cleared); a blocker opens its plan in Obsidian.
// Inbox parts (after T3 Code's): an idle agent stays listed (○) until you settle it; ✓ on an agent row settles its tab
// (Herdr's own tab.settle, ctrl-shift-s for the shown one: lists and tab.next skip it, and it comes back when shown or
// when an agent in it needs you). Below, folded: Working (busy agents) and Settled (↺ brings one back). The header's
// buttons search the rows, open a new tab and start a new space.
import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { agents, terminals, panes, spaces, run, theme, exec, hc, notify, openOverlay } from "herdr";

const AGENTS = new Set(["claude", "claude-code", "codex", "pi", "omp", "opencode", "gemini", "amp", "cursor-agent"]);
// A shell's exit code is just its last command's: never news.
const SHELLS = new Set(["zsh", "bash", "fish", "sh", "dash", "nu", "xonsh"]);

export default class Attention extends View {
  init(_props, cx) {
    this.blockers = [];
    this.finished = [];
    this.merged = [];
    this.arm = null;
    cx.timer.every(60000, (cx) => this.worktrees(cx));
    this.worktrees(cx);
    this.dismissed = new Set(JSON.parse(localStorage.getItem("dismissed") ?? "[]"));
    this.open = JSON.parse(localStorage.getItem("open") ?? "{}"); // folded sections: { working, settled }
    this.hover = null;
    this.query = "";
    this.searching = false;
    this.search = InputState.new({ placeholder: "Search" });
    this.search.on("change", (_e, cx) => { this.query = this.search.value().trim().toLowerCase(); cx.notify(); });
    cx.timer.every(5000, (cx) => this.poll(cx));
    this.poll(cx);
  }

  poll(cx) {
    cx.spawn(async (cx) => {
      const env = await exec("sh", ["-c", "cat \"${XDG_RUNTIME_DIR:-/tmp}/herdr-side/blockers.tsv\""]).catch(() => null);
      this.blockers = (env?.stdout ?? "").split("\n").filter(Boolean).map((l) => l.split("\t"));
      // terminals() lists live ones only; finished ones need --all.
      const all = await exec("hc", ["ls", "--all", "--json"]).catch(() => null);
      try { this.finished = JSON.parse(all?.stdout ?? "{}").terminals?.filter((x) => x.state !== "live") ?? []; } catch { this.finished = []; }
      // Working again: the old "ready" no longer holds.
      const labels = this.labels();
      for (const a of agents()) if (a.status === "working" && labels[a.address]?.["herdr.ready"]) hc(["label", a.address, "herdr.ready="]);
      cx.notify();
    });
  }

  labels() {
    return Object.fromEntries(terminals().map((x) => [x.address, x.labels ?? {}]));
  }

  // Linked worktrees of the repos agents work in whose branch is merged into the closest of origin's default / dev,
  // or whose upstream was deleted (squash-merged PRs). No fetch here: as fresh as your last fetch.
  worktrees(cx) {
    const cwds = [...new Set(panes().filter((p) => p.status && p.cwd).map((p) => p.cwd))];
    cx.spawn(async (cx) => {
      const out = [], done = new Set();
      for (const cwd of cwds) {
        const g = (args) => exec("git", ["-C", cwd, ...args]).catch(() => ({ code: 1, stdout: "" }));
        const common = (await g(["rev-parse", "--path-format=absolute", "--git-common-dir"])).stdout.trim();
        if (!common || done.has(common)) continue;
        done.add(common);
        const def = (await g(["symbolic-ref", "--short", "refs/remotes/origin/HEAD"])).stdout.trim();
        const bases = [...new Set([(await g(["config", "herdr.base"])).stdout.trim(), def, "origin/dev"].filter(Boolean))];
        const gone = new Set((await g(["for-each-ref", "--format=%(refname:short) %(upstream:track)", "refs/heads"])).stdout
          .split("\n").filter((l) => l.endsWith("[gone]")).map((l) => l.split(" ")[0]));
        const list = (await g(["worktree", "list", "--porcelain"])).stdout.split("\n\n").map((b) => ({
          path: /^worktree (.*)$/m.exec(b)?.[1], branch: /^branch refs\/heads\/(.*)$/m.exec(b)?.[1] }));
        for (const w of list.slice(1)) {
          if (!w.path || !w.branch) continue;
          let merged = gone.has(w.branch) ? "upstream gone" : null;
          for (const b of bases) {
            if (merged) break;
            // in the base, and not a fresh branch that never got a commit (its reflog has only its creation)
            const anc = await g(["merge-base", "--is-ancestor", w.branch, b]);
            const moves = (await g(["reflog", "show", "--format=%H", `refs/heads/${w.branch}`])).stdout.trim().split("\n").filter(Boolean).length;
            if (anc.code === 0 && moves > 1) merged = `merged into ${b}`;
          }
          if (merged) out.push({ ...w, merged });
        }
      }
      this.merged = out;
      cx.notify();
    });
  }

  rows() {
    const t = theme();
    const out = [];
    const labels = this.labels();
    const focus = (a) => () => run("pane.focus", { pane: a.pane });
    const settled = this.settledTabs(), shownTab = new Set(spaces().filter((s) => s.active).flatMap((s) => s.tabs.filter((x) => x.active).map((x) => x.id)));
    for (const a of agents()) {
      if (settled.has(a.tab) && a.status !== "blocked") continue;
      const where = this.context(a);
      const l = labels[a.address] ?? {};
      const what = l["herdr.status"] || a.title;
      if (a.status === "blocked") out.push({ rank: 0, icon: "▲", color: t.blocked, text: "blocked", where, what, go: focus(a) });
      else if (l["herdr.ready"] && a.status !== "working") out.push({ rank: 0.5, icon: "✓", color: t.done, text: "ready", where, what: l["herdr.ready"], go: () => {
        run("pane.focus", { pane: a.pane });
        hc(["label", a.address, "herdr.ready="]);
      } });
      else if (a.status === "done") out.push({ rank: 3, icon: "◆", color: t.done, text: "done", where, what, go: focus(a) });
      else if (a.status === "idle" && !shownTab.has(a.tab)) out.push({ rank: 4, icon: "○", color: t.muted, text: "idle", where, what, go: focus(a) });
      else continue;
      Object.assign(out[out.length - 1], { tab: a.tab, key: a.address });
    }
    for (const x of this.finished) {
      // Only agents, or a program that failed: a tool you quit (lazygit, a shell, Ctrl-C/hangup) isn't news.
      const failed = x.exit_code != null && ![0, 129, 130].includes(x.exit_code) && !SHELLS.has(x.agent);
      if (!x.agent || this.dismissed.has(x.address) || !(AGENTS.has(x.agent) || failed)) continue;
      out.push({ rank: 1, icon: "✕", color: t.blocked, text: `${x.agent} ${x.exit_code ? `failed (${x.exit_code})` : "exited"}`, where: x.where ?? "", what: x.cwd ?? "", go: () => {
        run("pane.focus", { terminal: x.address });
        this.dismissed.add(x.address);
        localStorage.setItem("dismissed", JSON.stringify([...this.dismissed].slice(-200)));
      } });
    }
    for (const w of this.merged) {
      const armed = this.arm === w.path;
      out.push({ rank: 6, icon: "⌫", color: armed ? t.blocked : t.muted, text: armed ? "remove?" : w.branch, where: w.merged, what: w.path.split("/").pop(), go: () => {
        if (!armed) { this.arm = w.path; return; }
        this.arm = null;
        // no --force: git refuses a worktree with uncommitted or untracked work
        exec("git", ["-C", w.path, "worktree", "remove", w.path]).then((r) => {
          notify({ title: r.code === 0 ? `Removed worktree ${w.branch}` : `Kept worktree ${w.branch}`, body: r.code === 0 ? w.path : (r.stderr || r.stdout).trim(), level: r.code === 0 ? "info" : "warning" });
          this.merged = this.merged.filter((m) => m.path !== w.path);
        });
      } });
    }
    for (const [kind, slug, id, num, title] of this.blockers) {
      const decision = kind === "decision";
      const [checkout, file] = [id.split("|")[0], id.slice(id.indexOf("|") + 1)];
      out.push({ rank: decision ? 2 : 5, icon: decision ? "?" : "⚑", color: decision ? t.working : t.accent, text: slug, where: num, what: title,
        go: () => exec("setsid", ["-f", "ob", checkout, file]) });
    }
    return out.sort((a, b) => a.rank - b.rank);
  }

  settledTabs() {
    return new Set(spaces().flatMap((s) => s.tabs.filter((x) => x.settled).map((x) => x.id)));
  }

  // An agent's second line: space · tab · branch of its pane.
  context(a) {
    const branch = panes().find((p) => p.pane === a.pane)?.branch;
    return [a.space_name, a.tab_name, branch && `⎇ ${branch}`].filter(Boolean).join(" · ");
  }

  working() {
    const settled = this.settledTabs(), labels = this.labels(), t = theme();
    return agents().filter((a) => a.status === "working" && !settled.has(a.tab)).map((a) => ({ icon: "●", color: t.working,
      text: "working", where: this.context(a), what: labels[a.address]?.["herdr.status"] || a.title, tab: a.tab, key: a.address, go: () => run("pane.focus", { pane: a.pane }) }));
  }

  settled() {
    const t = theme();
    return spaces().flatMap((s) => s.tabs.filter((x) => x.settled).map((x) => ({ icon: "✓", color: t.muted, text: "settled", where: `${s.name} · ${x.name}`,
      what: agents().filter((a) => a.tab === x.id).map((a) => a.title).join(", "), unsettle: x.id, key: x.id, go: () => run("tab.select", { id: x.id }) })));
  }

  match(r) {
    return !this.query || `${r.text} ${r.where} ${r.what}`.toLowerCase().includes(this.query);
  }

  row(r, key, t) {
    const over = this.hover === key;
    const act = r.unsettle ? ["↺", "Bring back", () => run("tab.unsettle", { id: r.unsettle })] : r.tab ? ["✓", "Settle", () => run("tab.settle", { id: r.tab })] : null;
    // line 1: status, then what it is about; line 2 (dim): where (space · tab · branch)
    return h_flex().id(key).h(38).flex_none().px(8).gap(8).items_center().rounded(6)
      .cursor_pointer().hover((s) => s.bg(t.hover))
      .on_hover((on, cx) => { if (on) this.hover = key; else if (this.hover === key) this.hover = null; cx.notify(); })
      .on_click((_e, cx) => { r.go(); cx.notify(); })
      .child(div().w(12).flex_none().self_start().pt(3).text_color(r.color).child(r.icon))
      .child(v_flex().flex_1().min_w(0)
        .child(h_flex().gap(6).min_w(0)
          .child(div().flex_none().text_color(r.color).child(r.text))
          .child(div().flex_1().min_w(0).truncate().text_color(t.foreground).child(r.what || "")))
        .child(div().min_w(0).truncate().text_size(11).text_color(t.dim).child(r.where || "")))
      .when(Boolean(act && over), (el) => el.child(div().id(`${key}-act`).flex_none().px(5).rounded(4).text_color(t.muted)
        .hover((s) => s.bg(t.selected).text_color(t.foreground))
        .on_click((_e, cx) => { cx.stop_propagation(); act[2](); this.hover = null; cx.notify(); }).child(act[0])));
  }

  // Working / Settled: folded unless toggled in the header (or searching); a thin label above when open.
  section(name, label, rows, t) {
    if (!rows.length || !(this.open[name] || this.query)) return [];
    return [div().h(18).flex_none().px(8).pt(4).text_size(11).text_color(t.muted).child(label),
      ...rows.map((r) => this.row(r, `${name}-${r.key}`, t))];
  }

  // A header toggle for a folded section: its mark and count, lit while open.
  fold(name, mark, color, n, t) {
    const on = this.open[name];
    return div().id(`fold-${name}`).flex_none().px(5).rounded(5).cursor_pointer().text_size(11)
      .bg(on ? t.selected : t.chrome).text_color(on ? t.foreground : n ? color : t.dim).hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => { this.open[name] = !on; localStorage.setItem("open", JSON.stringify(this.open)); cx.notify(); })
      .child(`${mark} ${n}`);
  }

  tool(id, icon, go, t) {
    return div().id(id).flex_none().p(3).rounded(5).cursor_pointer().hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => { go(cx); cx.notify(); }).child(svg(`mods/workspace-chrome/${icon}.svg`).size(13).text_color(t.muted));
  }

  render(cx) {
    const t = theme();
    const rows = this.rows().filter((r) => this.match(r));
    const working = this.working().filter((r) => this.match(r)), settled = this.settled().filter((r) => this.match(r));
    return v_flex().id("attention").size_full().px(8).pt(6).gap(1).text_size(12).overflow_y_scrollbar()
      .child(h_flex().h(22).flex_none().pl(8).gap(2).items_center()
        .child(div().flex_1().text_color(t.muted).child("Inbox"))
        .child(this.fold("working", "●", t.working, this.working().length, t))
        .child(this.fold("settled", "✓", t.muted, this.settled().length, t))
        .child(this.tool("att-search", "search", (cx) => {
          this.searching = !this.searching;
          if (this.searching) this.search.focus(); else { this.search.set_value(""); this.query = ""; }
        }, t))
        .child(this.tool("att-new-tab", "plus", () => openOverlay({ mod: "new-menu", kind: "popup", width: 250, height: 512 }), t))
        .child(this.tool("att-new-space", "folder-plus", () => run("space.new"), t)))
      .when(this.searching || Boolean(this.query), (el) => el.child(div().h(26).flex_none().mx(4).mb(2).px(8).flex().items_center().rounded(6)
        .border_1().border_color(t.border).on_key_down((e, cx) => {
          if (e.key !== "escape") return;
          this.search.set_value(""); this.query = ""; this.searching = false; cx.notify();
        })
        .child(Input.new(this.search).h_full().text_size(12).text_color(t.foreground))))
      .children(rows.map((r, i) => this.row(r, `att-${r.key ?? `${r.icon}${r.text}${r.where}${i}`}`, t)))
      .children(this.section("working", "Working", working, t))
      .children(this.section("settled", "Settled", settled, t));
  }
}
