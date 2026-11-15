import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, Scrollbar, v_virtual_list } from "gpui-base";
import { spaces, panes, focused, exec, readTextFile, watchFolder, theme, settings, run, setShared } from "herdr";

// my-changes: the shipped Changes panel, plus
//   Branch mode (everything since this branch left origin's default branch, what the PR will hold) beside Uncommitted;
//   files grouped by folder, foldable; generated files (lockfiles, builds, `-diff` in .gitattributes) folded apart;
//   word diff for prose (.md tables, docs); groups start folded, one button folds or opens them all; per-file stage / revert / nvim / delta (a popup, see mods/popup);
//   big diffs say so and offer delta. Commit commits what's staged, else everything.
const GENERATED = /(^|\/)(pnpm-lock\.yaml|package-lock\.json|yarn\.lock|bun\.lockb?|Cargo\.lock|poetry\.lock|uv\.lock|go\.sum|composer\.lock|mise\.lock)$|(^|\/)(dist|build|out|coverage|\.angular)\/|\.(min\.js|map|snap)$/;
const PROSE = /\.(md|mdx|markdown|txt|rst|adoc)$/i;
const BIG = 1500; // diff lines shown; past this, delta
const sh = (s) => `'${String(s).replace(/'/g, `'\\''`)}'`;

function location() {
  const space = spaces().find((s) => s.active), f = focused();
  const pane = f?.pane ? panes().find(p => p.pane === f.pane) : null;
  const on = f?.pane === null ? (f.terminal?.includes("/") ? f.terminal.split("/")[0] : null) : space?.machine ?? null;
  return { cwd: pane?.cwd || f?.cwd || space?.folder, on };
}
const key = () => JSON.stringify(location());
// Same walk as mods/popup: from the terminal's process down through shells to the program, then its cwd.
async function liveCwd(terminal) {
  if (!terminal || terminal.includes("/")) return null;
  try {
    const pid = JSON.parse((await exec("hc", ["get", terminal, "--json"])).stdout).pid;
    const r = await exec("sh", ["-c", 'p=$1; while case $(cat /proc/$p/comm 2>/dev/null) in zsh|bash|sh|dash|fish) true;; *) false;; esac && c=$(pgrep -n -P $p); do p=$c; done; readlink /proc/$p/cwd', "_", String(pid)]);
    return r.code === 0 && r.stdout.trim() ? r.stdout.trim() : null;
  } catch { return null; }
}
// Reads write nothing under .git (no index refresh or lock, no fsmonitor cookie):
// the folder watch would see it, and every refresh would start the next one.
const READ = ["--no-optional-locks", "-c", "core.fsmonitor=false", "-c", "diff.autoRefreshIndex=false"];
const countLines = (text) => text ? text.split("\n").length - Number(text.endsWith("\n")) : 0;

// Text draws a tab as nothing: pad each to the next 4-column stop.
const untab = (text) => text.replace(/[^\t]*\t/g, (s) => s.slice(0, -1).padEnd((s.length - 1) - (s.length - 1) % 4 + 4));

// Numbers each diff line once, so a frame only draws the rows on screen.
function diffRows(lines) {
  let old = 0, next = 0;
  return lines.map((line) => {
    const match = /^@@ -(\d+)(?:,\d+)? \+(\d+)/.exec(line);
    if (match) { old = +match[1]; next = +match[2]; return { kind: "@", text: line }; }
    const kind = line[0];
    if (/\[-.*?-\]|\{\+.*?\+\}/.test(line)) { old++; return { kind: "~", number: next++, text: untab(line.slice(1)) || " " }; }
    if (kind === "-") return { kind, number: old++, text: untab(line.slice(1)) || " " };
    if (kind === "+") return { kind, number: next++, text: untab(line.slice(1)) || " " };
    if (kind === " ") { old++; return { kind, number: next++, text: untab(line.slice(1)) || " " }; }
    return { kind: "", text: line };
  });
}

export default class Changes extends View {
  init(_props, cx) {
    this.files = []; this.rows = []; this.diffWidth = 0; this.message = "";
    this.mode = localStorage.getItem("mode") ?? "uncommitted"; this.folded = new Set(); this.foldNext = true; this.hover = null; this.arm = null; this.handle = cx.focus_handle();
    this.input = InputState.new({ placeholder: "Commit message" });
    this.input.on("change", (_e, cx) => {
      const hadMessage = Boolean(this.message.trim());
      this.message = this.input.value();
      if (hadMessage !== Boolean(this.message.trim())) cx.notify();
    });
    this.input.on("submit", (_e, cx) => this.commit(cx));
    this.input.on("focus", (_e, cx) => { this.typing = true; cx.notify(); });
    this.input.on("blur", (_e, cx) => { this.typing = false; cx.notify(); });
    this.refresh(cx);
    cx.timer.every(10000, (cx) => this.refresh(cx));
  }

  watch(root, cx) {
    if (this.on || this.watched === root) return;
    this.watched = root;
    cx.spawn(async (cx) => {
      try {
        while (this.watched === root) {
          await watchFolder(root);
          if (this.watched === root) this.refresh(cx);
        }
      } catch { this.watched = null; }
    });
  }

  refresh(cx) {
    if (this.loading || this.busy) return;
    const { cwd, on } = location(), context = key();
    if (context !== this.context) {
      this.context = context; this.foldNext = true; this.root = null; this.files = []; this.open = null;
      this.setLines([]); this.message = ""; this.input.set_value(""); this.error = null; this.note = null; this.watched = null; this.closed = false; this.limited = false;
    }
    if (!cwd) return;
    this.loading = true;
    cx.spawn(async (cx) => {
      try {
        // A pane's cwd is its shell's and goes stale once an agent runs in it after a cd: ask the program itself.
        const live = on ? null : await liveCwd(focused()?.terminal);
        const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd: live ?? cwd, on });
        if (key() !== context) return;
        if (top.code !== 0) { this.root = null; this.files = []; this.setLines([]); this.open = null; this.error = "Not a git repository"; return; }
        const root = top.stdout.trim(), git = (args) => exec("git", [...READ, ...args], { cwd: root, on });
        const status = await git(["status", "--porcelain=v1", "-z", "--no-renames", "--untracked-files=all"]);
        if (status.code !== 0) throw new Error(status.stderr);
        const head = await git(["rev-parse", "--verify", "HEAD"]);
        // Branch mode: diff from where this branch left origin's default branch (working tree included).
        let base = head.code === 0 ? "HEAD" : null, baseName = "HEAD";
        if (this.mode === "branch" && head.code === 0) {
          // `git config herdr.base origin/dev` pins it; else the closest of origin's default, dev and develop
          // (for repos whose PRs go to dev while origin/HEAD is main).
          const pinned = (await git(["config", "herdr.base"])).stdout.trim();
          const def = (await git(["symbolic-ref", "--short", "refs/remotes/origin/HEAD"])).stdout.trim() || "origin/main";
          let best = null;
          for (const ref of pinned ? [pinned] : [...new Set([def, "origin/dev", "origin/develop"])]) {
            const mb = await git(["merge-base", "HEAD", ref]);
            if (mb.code !== 0) continue;
            const n = Number((await git(["rev-list", "--count", `${mb.stdout.trim()}..HEAD`])).stdout.trim());
            if (!best || n < best.n) best = { n, ref, mb: mb.stdout.trim() };
          }
          if (best) { base = best.mb; baseName = best.ref; }
        }
        const stats = {};
        const results = base ? [await git(["diff", base, "--numstat", "-z", "--no-renames"])] : [await git(["diff", "--cached", "--numstat", "-z", "--no-renames"]), await git(["diff", "--numstat", "-z", "--no-renames"])];
        for (const result of results) {
          if (result.code !== 0) throw new Error(result.stderr);
          for (const entry of result.stdout.split("\0")) {
            const [a, d, ...parts] = entry.split("\t");
            if (!parts.length) continue;
            const path = parts.join("\t"), old = stats[path] ?? { add: 0, del: 0 };
            stats[path] = { add: old.add + (Number(a) || 0), del: old.del + (Number(d) || 0), binary: a === "-" };
          }
        }
        const files = [];
        const entries = status.stdout.split("\0").filter(Boolean);
        const seen = new Set();
        for (const entry of entries.slice(0, 1000)) {
          const xy = entry.slice(0, 2), path = entry.slice(3), fresh = xy === "??";
          const conflict = xy.includes("U") || xy === "AA" || xy === "DD";
          const s = conflict ? "U" : xy.includes("D") ? "D" : fresh || xy.includes("A") ? "A" : "M";
          const stat = stats[path] ?? { add: 0, del: 0 };
          // staged: all of it in the index (X set, Y clean); partly: both
          files.push({ path, status: s, fresh, staged: !fresh && xy[0] !== " " && xy[1] === " ", partly: !fresh && xy[0] !== " " && xy[1] !== " ", ...stat });
          seen.add(path);
        }
        if (base && base !== "HEAD") {
          // committed on the branch, clean now: in the diff, not in status
          const ns = await git(["diff", base, "--name-status", "-z", "--no-renames"]);
          const parts = ns.stdout.split("\0");
          for (let i = 0; i + 1 < parts.length; i += 2) {
            const path = parts[i + 1];
            if (!path || seen.has(path)) continue;
            files.push({ path, status: parts[i][0] === "D" ? "D" : parts[i][0] === "A" ? "A" : "M", fresh: false, committed: true, ...(stats[path] ?? { add: 0, del: 0 }) });
          }
        }
        const attrs = files.length ? await git(["check-attr", "diff", "linguist-generated", "--", ...files.slice(0, 400).map((f) => f.path)]) : { stdout: "" };
        const unset = new Set(attrs.stdout.split("\n").filter((l) => / (diff: unset|linguist-generated: (set|true))$/.test(l)).map((l) => l.slice(0, l.indexOf(": "))));
        for (const f of files) f.generated = GENERATED.test(f.path) || unset.has(f.path);
        if (key() !== context) return;
        if (this.foldNext) { this.foldNext = false; this.folded = new Set(this.listRows(files).filter((x) => x.group).map((x) => x.group)); }
        this.root = root; this.on = on; this.hasHead = head.code === 0; this.base = base; this.baseName = baseName; this.files = files; this.limited = entries.length > 1000; this.error = null;
        this.watch(root, cx);
        if (this.open && !files.some((f) => f.path === this.open)) { this.open = null; this.setLines([]); }
        // The first file's diff shows until you pick another.
        if (!this.open && !this.closed && files.length) this.open = files[0].path;
        if (this.open) {
          try { await this.load(this.open, context); }
          catch { if (key() === context) this.setLines(["Cannot preview this diff (too large or unreadable)"]); }
        }
      } catch (e) { if (key() === context) this.error = String(e); }
      finally { this.loading = false; cx.notify(); }
    });
  }

  async load(path, context) {
    const file = this.files.find((f) => f.path === path), root = this.root, on = this.on;
    if (!file) return;
    let lines;
    if (file.fresh || (!this.hasHead && file.status === "A")) {
      const text = await readTextFile(`${root}/${path}`, { on }).catch(() => null);
      if (text === null) lines = ["Cannot preview this file (binary, too large, or unreadable)"];
      else if (text.includes("\0")) lines = ["Binary file · no text diff"];
      else {
        file.add = countLines(text);
        lines = [`@@ -0,0 +1,${file.add} @@`, ...text.slice(0, 400000).replace(/\n$/, "").split("\n").slice(0, 1500).map(l => `+${l}`)];
      }
    } else {
      const words = PROSE.test(path);
      const r = await exec("git", [...READ, "diff", ...(this.base ? [this.base] : []), "--no-ext-diff", "--no-textconv", "--no-color", ...(words ? ["--word-diff=plain"] : []), "--", path], { cwd: root, on });
      if (r.code !== 0) throw new Error(r.stderr);
      const all = r.stdout.replace(/\n$/, "").split("\n"), first = all.findIndex((l) => l.startsWith("@@"));
      lines = first < 0 ? [file.binary ? "Binary file changed" : "No text diff available"] : all.slice(first);
      if (lines.length > BIG) lines = [...lines.slice(0, BIG), `@@ ${lines.length - BIG} more lines: open it in delta (Δ) @@`];
    }
    if (key() === context && this.open === path) this.setLines(lines.slice(0, 1500).map(line => line.length > 4000 ? line.slice(0, 4000) + "… (line truncated)" : line));
  }

  setLines(lines) {
    this.rows = diffRows(lines);
    this.diffWidth = Math.max(300, ...this.rows.map(row => (row.text.length + 1) * 7 + 50));
  }

  pick(path, cx) {
    this.open = this.open === path ? null : path; this.setLines([]); this.note = null;
    this.closed = !this.open;
    const context = this.context;
    if (this.open) cx.spawn(async (cx) => {
      try { await this.load(path, context); }
      catch (e) { if (key() === context && this.open === path) this.note = `Cannot preview this diff (too large or unreadable): ${e}`; }
      cx.notify();
    });
    cx.notify();
  }

  commit(cx) {
    if (!this.message.trim() || !this.root || this.busy || this.loading || this.context !== key()) return;
    const root = this.root, on = this.on, context = this.context, message = this.message.trim();
    this.busy = true; this.note = null;
    cx.spawn(async (cx) => {
      try {
        const staged = this.files.some((f) => f.staged || f.partly);
        for (const args of staged ? [["commit", "-m", message]] : [["add", "-A"], ["commit", "-m", message]]) {
          const r = await exec("git", args, { cwd: root, on });
          if (r.code !== 0) throw new Error((r.stderr || r.stdout).trim());
        }
        if (key() === context) { this.message = ""; this.input.set_value(""); }
      } catch (e) { if (key() === context) this.note = `Commit failed: ${e}`; }
      finally { this.busy = false; this.refresh(cx); cx.notify(); }
    });
    cx.notify();
  }

  git(args, cx, note) {
    const root = this.root, on = this.on;
    cx.spawn(async (cx) => {
      const r = await exec("git", args, { cwd: root, on });
      this.note = r.code === 0 ? null : `${note}: ${(r.stderr || r.stdout).trim()}`;
      this.refresh(cx); cx.notify();
    });
  }

  popup(title, cmd) {
    setShared("popup.next", { title, argv: ["sh", "-c", cmd], cwd: this.root });
    run("popup.run");
  }

  actions(f, t, cx) {
    const btn = (id, label, tip, fn, color) => div().id(`${id}-${f.path}`).px(4).rounded(4).text_size(11).text_color(color ?? t.muted)
      .cursor_pointer().hover((s) => s.bg(t.raised).text_color(t.foreground)).tooltip(tip)
      .on_click((_e, cx) => { cx.stop_propagation(); fn(cx); cx.notify(); }).child(label);
    const p = sh(f.path), base = this.base ?? "HEAD";
    const out = [];
    if (!f.committed) out.push(f.staged
      ? btn("unstage", "−", "Unstage", (cx) => this.git(["restore", "--staged", "--", f.path], cx, "Unstage failed"))
      : btn("stage", "+", "Stage", (cx) => this.git(["add", "--", f.path], cx, "Stage failed")));
    if (!f.fresh && !f.committed) out.push(this.arm === f.path
      ? btn("revert-yes", "revert?", "Click again: drop this file's uncommitted changes", (cx) => { this.arm = null; this.git(["restore", "--source=HEAD", "--staged", "--worktree", "--", f.path], cx, "Revert failed"); }, t.ansi1)
      : btn("revert", "↺", "Revert to HEAD (asks once more)", () => { this.arm = f.path; }));
    if (f.status !== "D") out.push(btn("nvim", "✎", "Edit in nvim", () => this.popup(f.path, `nvim ${p}`)));
    out.push(btn("delta", "Δ", "Full diff in delta", () => this.popup(`diff ${f.path}`, `git diff ${sh(base)} -- ${p} | delta --paging=always`)));
    return out;
  }

  diffRow({ kind, number, text }, t) {
    if (kind === "@") return div().w_full().px(12).h(20).flex_none().truncate().bg(t.raised).text_color(t.dim).child(text);
    return h_flex().w_full().h(20).flex_none().gap(10).when(kind === "~", (e) => e.bg(t.ansi3 + "14")).when(kind === "+", (e) => e.bg(t.ansi2 + "18")).when(kind === "-", (e) => e.bg(t.ansi1 + "18"))
      .child(div().w(30).flex_none().text_right().text_color(t.dim).child(number === undefined ? "" : String(number)))
      .child(div().flex_1().min_w(0).truncate().child(text));
  }

  // Folder groups (generated files apart, folded), files under their group unless folded.
  listRows(files = this.files) {
    const groups = new Map();
    for (const f of files) {
      const g = f.generated ? "\u0000generated" : f.path.includes("/") ? f.path.slice(0, f.path.lastIndexOf("/")) : ".";
      if (!groups.has(g)) groups.set(g, []);
      groups.get(g).push(f);
    }
    const keys = [...groups.keys()].sort((a, b) => (a[0] === "\u0000") - (b[0] === "\u0000") || a.localeCompare(b));
    return keys.flatMap((g) => {
      const fs = groups.get(g);
      const head = { group: g, label: g === "\u0000generated" ? "generated · lockfiles, builds" : g === "." ? "(root)" : `${g}/`, count: fs.length,
        add: fs.reduce((n, f) => n + f.add, 0), del: fs.reduce((n, f) => n + f.del, 0) };
      return [head, ...(this.folded.has(g) ? [] : fs.map((file) => ({ file })))];
    });
  }

  render(cx) {
    if (key() !== this.context) this.refresh(cx);
    const t = theme(), add = this.files.reduce((n, f) => n + f.add, 0), del = this.files.reduce((n, f) => n + f.del, 0);
    const enabled = Boolean(this.message.trim() && this.root && !this.busy && !this.loading);
    return v_flex().id("changes").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13).track_focus(this.handle)
      .on_key_down((e, cx) => {
        if (e.key === "escape" && this.typing) { this.typing = false; this.handle.focus(); cx.stop_propagation(); cx.notify(); }
      })
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child("Changes"))
        .child(div().px(5).py(1).rounded(4).border_1().border_color(t.border).text_size(10).text_color(t.muted).child(`${this.files.length} files`))
        .child(h_flex().gap(2).text_size(11).children([["uncommitted", "Uncommitted"], ["branch", "Branch"]].map(([m, label]) =>
          div().id(`mode-${m}`).px(6).py(1).rounded(4).cursor_pointer().tooltip(m === "branch" ? `Since this branch left ${this.baseName && this.baseName !== "HEAD" ? this.baseName : "origin's default branch"}` : "Not committed yet")
            .when(this.mode === m, (e) => e.bg(t.selected).text_color(t.foreground)).when(this.mode !== m, (e) => e.text_color(t.dim).hover((s) => s.text_color(t.foreground)))
            .on_click((_e, cx) => { this.mode = m; localStorage.setItem("mode", m); this.context = null; this.refresh(cx); cx.notify(); }).child(label))))
        .child(div().flex_1())
        .child(div().id("fold-all").px(5).rounded(4).text_size(12).text_color(t.dim).cursor_pointer().hover((s) => s.bg(t.hover).text_color(t.foreground))
          .tooltip(this.folded.size ? "Open all folders" : "Fold all folders")
          .on_click((_e, cx) => { this.folded = this.folded.size ? new Set() : new Set(this.listRows().filter((x) => x.group).map((x) => x.group)); cx.notify(); })
          .child(this.folded.size ? "⊞" : "⊟"))
        .child(div().text_size(11).text_color(t.ansi2).child(`+${add}`)).child(div().text_size(11).text_color(t.ansi1).child(`−${del}`)))
      // overflow_y_scrollbar() wraps the list, so its flex sizing never reached the panel's layout.
      .child(div().flex_1().min_h(44).max_h(this.listRows().length * 28 + 12).relative().border_b(1).border_color(t.border)
        .child(v_flex().id("changes-list").absolute().inset_0().overflow_y_scroll().p(6).children(this.listRows().map((x) => {
        if (x.group) {
          const open = !this.folded.has(x.group);
          return h_flex().id(`grp-${x.group}`).h(24).flex_none().px(6).gap(6).items_center().rounded(6).cursor_pointer().text_size(11).text_color(t.muted)
            .hover((s) => s.bg(t.hover)).on_click((_e, cx) => { open ? this.folded.add(x.group) : this.folded.delete(x.group); cx.notify(); })
            .child(div().w(10).child(open ? "▾" : "▸")).child(div().flex_1().min_w(0).truncate().child(x.label))
            .child(div().text_color(t.dim).child(`${x.count}`))
            .when(x.add > 0, (e) => e.child(div().text_color(t.ansi2).child(`+${x.add}`))).when(x.del > 0, (e) => e.child(div().text_color(t.ansi1).child(`−${x.del}`)));
        }
        const f = x.file;
        const parts = f.path.replace(/\/$/, "").split("/"), name = parts.pop() + (f.path.endsWith("/") ? "/" : "");
        return h_flex().id(`change-${f.path}`).on_hover((on, cx) => { if (on) this.hover = f.path; else if (this.hover === f.path) { this.hover = null; if (this.arm === f.path) this.arm = null; } cx.notify(); }).h(28).flex_none().px(8).gap(8).items_center().rounded(7).cursor_pointer().when(this.open === f.path, (e) => e.bg(t.selected)).hover((s) => s.bg(t.hover)).on_click((_e, cx) => this.pick(f.path, cx))
          .child(div().w(14).text_size(11).text_color(f.status === "A" ? t.ansi2 : f.status === "D" ? t.ansi1 : f.status === "U" ? t.ansi1 : t.blocked).child(f.status))
          .child(h_flex().flex_1().min_w(0).pl(10).gap(6).child(div().max_w(260).min_w(0).truncate().text_color(f.committed ? t.muted : t.foreground).child(name))
            .when(f.staged || f.partly, (e) => e.child(div().text_size(10).text_color(t.accent).child(f.partly ? "◐" : "●"))))
          .when(this.hover === f.path, (e) => e.children(this.actions(f, t, cx)))
          .when(f.add > 0, (e) => e.child(div().text_size(11).text_color(t.ansi2).child(`+${f.add}`))).when(f.del > 0, (e) => e.child(div().text_size(11).text_color(t.ansi1).child(`−${f.del}`)));
      })).when(!this.files.length, (e) => e.child(div().p(8).text_color(t.dim).child(this.error || (this.loading ? "Loading changes…" : this.root ? (this.mode === "branch" ? "Nothing changed on this branch" : "No uncommitted changes") : "No folder")))))
        .child(Scrollbar.vertical("changes-list").absolute().inset_0()))
      .when(this.limited, el => el.child(div().px(12).py(4).text_size(11).text_color(t.dim).child("Showing the first 1,000 changed files")))
      .child(div().flex_1().min_h(0).relative().font_family(settings().font_family ?? "JetBrains Mono").text_size(11)
        .child(div().id("changes-diff-x").size_full().overflow_x_scrollbar()
          .child(div().w_full().min_w(this.diffWidth).h_full().child(v_virtual_list("changes-diff", this.rows.length, 20, (i) => String(i),
            (range) => this.rows.slice(range.start, range.end).map((row) => this.diffRow(row, t))).size_full())))
        .child(Scrollbar.vertical("changes-diff").viewport_from_layout().absolute().inset_0())
        .when(!this.open && this.files.length > 0, (e) => e.child(div().absolute().top(6).px(12).text_color(t.dim).child("Select a file to view its changes"))))
      .when(Boolean(this.note), (e) => e.child(div().px(10).pb(8).text_size(11).text_color(t.ansi1).child(this.note)))
      .child(h_flex().flex_none().p(10).gap(8).border_t(1).border_color(t.border)
        .child(div().id("commit-message").flex_1().min_w(0).h(32).px(10).flex().items_center().rounded(8).border_1().border_color(this.typing ? t.accent : t.border).cursor_text().on_mouse_down("left", (_e, cx) => cx.stop_propagation()).child(Input.new(this.input).h_full().text_size(12).text_color(t.foreground)))
        .child(div().id("commit").h(32).px(14).flex().items_center().rounded(8).bg(enabled ? t.solid : t.raised).text_color(enabled ? t.solid_foreground : t.dim).text_size(12).when(enabled, (e) => e.cursor_pointer()).on_click((_e, cx) => this.commit(cx)).child(this.busy ? "Committing…" : "Commit")));
  }
}
