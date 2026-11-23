// Inbox: only what needs a decision from you and that the Agents list doesn't already say (it shows every agent's
// blocked/done/working/idle state, so those aren't repeated here). Most urgent first:
//   ✕ a Claude subagent or workflow agent that failed (bin/claude-live): click follows it in zoe
//   ✕ an agent that exited with an error
//   ✓ ready for review (the agent ran `herdr-ready "summary"`): click reviews its worktree's branch in hunk
//   ✎ hunk notes you left on a worktree: click sends them to the agent working there (no agent: opens the review)
//   ? plan decision / ⚑ plan blocker (herdr-side's blockers.tsv): opens the plan in Obsidian
//   ⌫ worktree whose branch is merged (or upstream gone): click twice to `git worktree remove`
// Click dismisses a ✕ row. Below, folded: Settled tabs (↺ brings one back). Header: search, new tab, new space.
import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { agents, terminals, panes, spaces, run, theme, exec, hc, notify, openOverlay, setShared } from "herdr";

const AGENTS = new Set(["claude", "claude-code", "codex", "pi", "omp", "opencode", "gemini", "amp", "cursor-agent"]);
// The branch since it left the default branch, uncommitted work included, in hunk (same as my-agents' ⧉).
const REVIEW = 'b=$(git merge-base HEAD origin/HEAD 2>/dev/null || git merge-base HEAD origin/dev 2>/dev/null || echo HEAD); exec hunk diff "$b" --watch';
const popup = (title, argv, cwd, modal = false) => { setShared("popup.next", { title, argv, cwd, modal }); run("popup.run"); };

export default class Attention extends View {
  init(_props, cx) {
    this.blockers = [];
    this.finished = [];
    this.merged = [];
    this.live = []; // claude-live sessions
    this.notes = []; // [{ dir, comments }] from open hunk reviews
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
      const live = await exec("claude-live", []).catch(() => null);
      try { this.live = JSON.parse(live?.stdout ?? "{}").sessions ?? []; } catch { this.live = []; }
      const notes = [];
      const open = await exec("hunk", ["session", "list", "--json"]).catch(() => null);
      for (const h of open?.code === 0 ? JSON.parse(open.stdout).sessions ?? [] : []) {
        const c = await exec("hunk", ["session", "comment", "list", h.sessionId, "--type", "user", "--json"]).catch(() => null);
        const comments = c?.code === 0 ? JSON.parse(c.stdout).comments ?? [] : [];
        if (comments.length) notes.push({ dir: h.repoRoot, comments });
      }
      this.notes = notes;
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
    // Where an agent works now: Claude's own folder (it follows cd into a worktree), else its pane's.
    const cwdOf = (a) => this.live.find((x) => x.kind !== "bg" && x.terminal === a.address)?.cwd ?? panes().find((p) => p.pane === a.pane)?.cwd;
    for (const a of agents()) {
      const l = labels[a.address] ?? {};
      if (!l["herdr.ready"] || a.status === "working") continue;
      const dir = cwdOf(a);
      out.push({ rank: 1, icon: "✓", color: t.done, text: "review", where: this.context(a), what: l["herdr.ready"], key: a.address, go: () => {
        hc(["label", a.address, "herdr.ready="]);
        if (dir) popup(`hunk · ${dir.split("/").pop()}`, ["sh", "-c", REVIEW], dir, true);
        else run("pane.focus", { pane: a.pane });
      } });
    }
    for (const x of this.live) for (const k of x.kids) {
      const key = `${x.id}:${k.id}`;
      if (k.state !== "failed" || this.dismissed.has(key)) continue;
      out.push({ rank: 0, icon: "✕", color: t.blocked, text: "failed", what: k.label, where: [x.name, k.workflow, k.phase].filter(Boolean).join(" · "), key, go: () => {
        popup(`zoe · ${k.label}`, ["zoe", k.log, "--follow"]);
        this.dismiss(key);
      } });
    }
    for (const x of this.finished) {
      // Agents only, and only an error: a clean exit or Ctrl-C isn't news, nor is any other program's exit.
      if (!AGENTS.has(x.agent) || this.dismissed.has(x.address) || x.exit_code == null || [0, 129, 130].includes(x.exit_code)) continue;
      out.push({ rank: 0, icon: "✕", color: t.blocked, text: `${x.agent} failed (${x.exit_code})`, where: x.where ?? "", what: x.cwd ?? "", go: () => {
        run("pane.focus", { terminal: x.address });
        this.dismiss(x.address);
      } });
    }
    for (const n of this.notes) {
      const agent = agents().find((a) => cwdOf(a)?.startsWith(n.dir));
      out.push({ rank: 2, icon: "✎", color: t.accent, text: `${n.comments.length} notes`, what: n.dir.split("/").pop(), where: agent ? `send to ${this.context(agent)}` : "no agent there: open the review", key: `notes-${n.dir}`, go: () => {
        if (!agent) return popup(`hunk · ${n.dir.split("/").pop()}`, ["sh", "-c", REVIEW], n.dir, true);
        this.sendNotes(n, agent);
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

  dismiss(key) {
    this.dismissed.add(key);
    localStorage.setItem("dismissed", JSON.stringify([...this.dismissed].slice(-200)));
  }

  // Your hunk notes on a worktree, as one prompt to the agent there; sent notes leave hunk.
  async sendNotes(n, agent) {
    const text = "Review notes on your changes, fix each one:\n" + n.comments.map((c) => `- ${c.filePath}:${c.line}: ${c.summary}${c.rationale ? ` (${c.rationale})` : ""}`).join("\n");
    const sent = await hc(["send", agent.address, text]);
    if (sent.code !== 0) return notify({ title: "Send review notes", body: sent.stderr.trim() || "hc send failed", level: "error" });
    for (const c of n.comments) await exec("hunk", ["session", "comment", "rm", "--repo", n.dir, c.commentId], { cwd: n.dir });
    this.notes = this.notes.filter((x) => x !== n);
    notify({ title: "Review notes sent", body: `${n.comments.length} to ${agent.address}` });
  }

  settledTabs() {
    return new Set(spaces().flatMap((s) => s.tabs.filter((x) => x.settled).map((x) => x.id)));
  }

  // An agent's second line: space · tab · branch of its pane.
  context(a) {
    const branch = panes().find((p) => p.pane === a.pane)?.branch;
    return [a.space_name, a.tab_name, branch && `⎇ ${branch}`].filter(Boolean).join(" · ");
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
    const settled = this.settled().filter((r) => this.match(r));
    return v_flex().id("attention").size_full().px(8).pt(6).gap(1).text_size(12).overflow_y_scrollbar()
      .child(h_flex().h(22).flex_none().pl(8).gap(2).items_center()
        .child(div().flex_1().text_color(t.muted).child("Inbox"))
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
      .when(!rows.length && !this.query, (el) => el.child(div().px(8).py(4).text_size(11.5).text_color(t.dim).child("Nothing needs you")))
      .children(this.section("settled", "Settled", settled, t));
  }
}
