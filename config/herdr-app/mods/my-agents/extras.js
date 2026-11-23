// my-agents extras: everything this clone adds to Herdr's shipped `agents` mod, kept out of main.js so an update is
// "re-clone agents, re-add the `// my:` hooks" (README.md).
//   - Claude's own work under each agent: subagents and workflow agents (failed first; click: zoe follows its log),
//     a runner's steps folded into one row per task (click: its steps), and `claude --bg` jobs, which run in
//     Claude's daemon and never reach herdr (click: claude attach), from bin/claude-live. A failed or blocked one
//     ranks its row under "Needs you".
//   - Worktrees: each row says its branch and worktree; a "By worktree" view groups everything by repo → worktree with
//     changed files, conflicts and open hunk notes, per-worktree actions (hunk review, send notes, lazygit, new agent),
//     a runner's task under its task's worktree, and the repo's open PRs that have no worktree.
//   - Pull requests: each worktree shows its branch's open PR (checks, review, conflicts) from `gh pr list`.
//   - Right-click any row (agent, worktree, bg job, subagent, PR) for its menu.
//   - keys.json "my-agents.worktree-new|open|remove" open the worktree dialog (mods/my-worktree).
import { div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { exec, hc, panes, spaces, run, shared, setShared, openOverlay, closeOverlay, props, notify, checking, nextCommand } from "herdr";

export const SORT = { id: "worktree", label: "By worktree", icon: "git-branch" };
const sh = (s) => `'${String(s).replace(/'/g, `'\\''`)}'`;
const KID = { failed: "blocked", running: "working", done: "idle" };

export function init(v, cx) {
  v.live = []; // claude-live sessions
  v.git = {}; // cwd → { top, repo, branch }
  v.trees = {}; // worktree path → { branch, changed, conflicts } from `hunk status`
  v.notes = {}; // worktree path → your notes in its open hunk review
  v.prs = {}; // repo → open PRs
  v.open = new Set(); // task rows showing their steps
  v.panel = Boolean(props()?.prs); // the Pull requests panel: git and PRs only, no keys
  if (checking()) return;
  if (!v.panel) readLive(v, cx);
  readGit(v, cx);
  if (!v.panel) cx.timer.every(3000, (cx) => readLive(v, cx));
  cx.timer.every(8000, (cx) => readGit(v, cx));
  // shortcut: polls GitHub every 60 s; a webhook would be instant but needs a server.
  cx.timer.every(60000, (cx) => readPrs(v, cx));
  if (v.panel) return; // keys reach every shown copy: only the agents list answers them
  cx.spawn(async (cx) => {
    for (;;) {
      const cmd = String(await nextCommand());
      const action = cmd.replace(/^worktree-/, "");
      if (!["new", "open", "remove"].includes(action)) continue;
      const pane = panes().find((p) => p.focused);
      const space = spaces().find((s) => s.tabs.some((t) => t.id === pane?.tab));
      openOverlay({ mod: "my-worktree", kind: "dialog", width: action === "open" ? 560 : 460, height: action === "open" ? 480 : 280,
        props: { space: space?.id, folder: pane?.cwd, action } });
    }
  });
}

function readLive(v, cx) {
  cx.spawn(async (cx) => {
    const r = await exec("claude-live", []).catch(() => null);
    if (r?.code !== 0) return;
    if (r.stdout === v.liveRaw) return;
    v.liveRaw = r.stdout;
    v.live = JSON.parse(r.stdout).sessions;
    if (liveCwds(v).some((c) => !(c in v.git))) readGit(v, cx); // a session or task moved to a folder not placed yet
    cx.notify();
  });
}

// Which worktree each folder is in, every repo's worktrees (one `hunk status` per repo covers its siblings), and
// how many notes each open hunk review holds.
const liveCwds = (v) => v.live.flatMap((s) => [s.cwd, ...s.kids.map((k) => k.cwd)]).filter(Boolean);
function readGit(v, cx) {
  const cwds = [...new Set([...panes().map((p) => p.cwd), ...liveCwds(v)].filter(Boolean))];
  cx.spawn(async (cx) => {
    for (const cwd of cwds) {
      const r = await exec("git", ["rev-parse", "--path-format=absolute", "--show-toplevel", "--git-common-dir", "--abbrev-ref", "HEAD"], { cwd }).catch(() => null);
      const [top, common, branch] = (r?.code === 0 ? r.stdout : "").trim().split("\n");
      v.git[cwd] = top ? { top, repo: common.replace(/\/\.git$/, ""), branch } : null;
    }
    const trees = {};
    for (const repo of new Set(Object.values(v.git).filter(Boolean).map((g) => g.repo))) {
      const r = await exec("hunk", ["status", "--json"], { cwd: repo }).catch(() => null);
      if (r?.code !== 0) continue;
      const s = JSON.parse(r.stdout);
      trees[s.worktree.path] = { repo, branch: s.head?.name, changed: s.changedPathCount ?? 0, conflicts: 0 };
      for (const w of s.siblings?.value?.worktrees ?? []) trees[w.worktree.path] = { repo, branch: w.branch, changed: w.status?.changedPathCount ?? 0, conflicts: w.status?.conflictCount ?? 0 };
    }
    const notes = {};
    const open = await exec("hunk", ["session", "list", "--json"]).catch(() => null);
    for (const s of open?.code === 0 ? JSON.parse(open.stdout).sessions ?? [] : []) {
      const c = await exec("hunk", ["session", "comment", "list", s.sessionId, "--type", "user", "--json"]).catch(() => null);
      notes[s.repoRoot] = (notes[s.repoRoot] ?? 0) + (c?.code === 0 ? (JSON.parse(c.stdout).comments ?? []).length : 0);
    }
    const first = !Object.keys(v.trees).length;
    v.trees = trees;
    v.notes = notes;
    if (first) readPrs(v, cx);
    cx.notify();
  });
}

const PR_FIELDS = "number,title,headRefName,isDraft,reviewDecision,mergeable,statusCheckRollup,url,author";
function readPrs(v, cx) {
  const repos = [...new Set(Object.values(v.trees).map((w) => w.repo))];
  cx.spawn(async (cx) => {
    const prs = {};
    for (const repo of repos) {
      const r = await exec("gh", ["pr", "list", "--state", "open", "--limit", "50", "--json", PR_FIELDS], { cwd: repo }).catch(() => null);
      prs[repo] = r?.code === 0 ? JSON.parse(r.stdout) : [];
    }
    v.prs = prs;
    cx.notify();
  });
}

// A PR's checks in one word: fail beats pending beats pass.
export function checks(pr) {
  const runs = pr.statusCheckRollup ?? [];
  if (!runs.length) return "none";
  const word = (c) => String(c.conclusion || c.state || c.status || "").toUpperCase();
  if (runs.some((c) => ["FAILURE", "ERROR", "CANCELLED", "TIMED_OUT", "ACTION_REQUIRED"].includes(word(c)))) return "fail";
  if (runs.some((c) => ["PENDING", "IN_PROGRESS", "QUEUED", "EXPECTED", "WAITING", ""].includes(word(c)))) return "pending";
  return "pass";
}
export const prOf = (v, repo, branch) => (v.prs[repo] ?? []).find((p) => p.headRefName === branch);

// "#12 ✓" in the colour of what it needs: conflicts and failed checks first.
export function prChip(t, pr, wide = false) {
  const c = checks(pr);
  const mark = { pass: "✓", fail: "✕", pending: "●", none: "" }[c];
  const color = pr.mergeable === "CONFLICTING" || c === "fail" || pr.reviewDecision === "CHANGES_REQUESTED" ? t.blocked : c === "pending" ? t.working : pr.reviewDecision === "APPROVED" ? t.done : t.muted;
  const words = [pr.isDraft && "draft", pr.mergeable === "CONFLICTING" && "conflict", { APPROVED: "approved", CHANGES_REQUESTED: "changes asked", REVIEW_REQUIRED: "needs review" }[pr.reviewDecision]].filter(Boolean);
  return h_flex().flex_none().gap(4).items_center().text_size(11).text_color(color)
    .child(`#${pr.number}${mark ? ` ${mark}` : ""}`)
    .when(wide && words.length > 0, (el) => el.child(div().text_color(t.dim).child(words.join(" · "))));
}

// A program in the popup window (mods/popup). modal: only its ✕ closes it (hunk holds unsent notes).
export function popup(title, argv, cwd, modal = false) {
  setShared("popup.next", { title, argv, cwd, modal });
  run("popup.run");
}

// This worktree's whole branch in hunk: everything since it left the default branch, uncommitted work included.
export function review(cwd) {
  popup(`hunk · ${cwd.split("/").pop()}`, ["sh", "-c", 'b=$(git merge-base HEAD origin/HEAD 2>/dev/null || git merge-base HEAD origin/dev 2>/dev/null || echo HEAD); exec hunk diff "$b" --watch'], cwd, true);
}

// Your hunk notes on a worktree, as one prompt to the agent working there; sent notes leave hunk.
async function sendNotes(dir, terminal) {
  const list = await exec("hunk", ["session", "comment", "list", "--repo", dir, "--type", "user", "--json"], { cwd: dir });
  const notes = list.code === 0 ? JSON.parse(list.stdout).comments ?? [] : [];
  if (!notes.length) return notify({ title: "Send review notes", body: "No notes in hunk for this worktree", level: "warning" });
  const text = "Review notes on your changes, fix each one:\n" + notes.map((n) => `- ${n.filePath}:${n.line}: ${n.summary}${n.rationale ? ` (${n.rationale})` : ""}`).join("\n");
  const sent = await hc(["send", terminal, text]);
  if (sent.code !== 0) return notify({ title: "Send review notes", body: sent.stderr.trim() || "hc send failed", level: "error" });
  for (const n of notes) await exec("hunk", ["session", "comment", "rm", "--repo", dir, n.commentId], { cwd: dir });
  notify({ title: "Review notes sent", body: `${notes.length} to ${terminal}` });
}

// The worktree a folder is in, once known.
export const treeOf = (v, cwd) => v.git[cwd]?.top ?? null;

const byTree = () => shared("agents.sort") === SORT.id;

// "⎇ branch · worktree" under an agent's name; the worktree only for a linked checkout. Not in "By worktree",
// where the worktree's own row says it.
export function where(v, cwd) {
  const g = v.git[cwd];
  if (!g?.branch || byTree()) return null;
  return `⎇ ${g.branch}${g.top !== g.repo ? ` · ${g.top.split("/").pop()}` : ""}`;
}
// Whether a row keeps room for that line: also while git hasn't answered yet, so rows don't jump when it does.
export const hasLine = (v, cwd) => !byTree() && Boolean(cwd) && (!(cwd in v.git) || Boolean(where(v, cwd)));

// A kid that works in another worktree than its session (a runner's task): "By worktree" shows it there instead.
const elsewhere = (v, s, k) => Boolean(k.cwd && treeOf(v, k.cwd)) && treeOf(v, k.cwd) !== (treeOf(v, s.cwd) ?? s.cwd);
export const kidsHere = (v, s) => (byTree() ? s.kids.filter((k) => !elsewhere(v, s, k)) : s.kids);

// Claude's subagents and workflow agents under a herdr terminal. `--bg` jobs inherit the terminal that started
// them, so only interactive sessions count.
export function kidsOf(v, address) {
  const s = v.live.find((s) => s.kind !== "bg" && s.terminal === address);
  return s ? kidsHere(v, s) : [];
}
export const kidStatus = (k) => KID[k.state];

// A Claude terminal's real folder (it follows `cd` into a worktree; the pane's shell folder doesn't).
export const sessionCwd = (v, address) => v.live.find((s) => s.kind !== "bg" && s.terminal === address)?.cwd;

function button(t, id, label, tip, fn) {
  return div().id(id).flex_none().px(3).rounded(4).text_size(12).text_color(t.dim).cursor_pointer()
    .hover((s) => s.bg(t.hover).text_color(t.foreground)).tooltip(tip)
    .on_click((_e, cx) => { cx.stop_propagation(); fn(cx); })
    .child(label);
}

// Hover actions for anything that has a folder: review it in hunk; with notes waiting and an agent there, send them.
export function actions(v, t, id, cwd, terminal) {
  const dir = treeOf(v, cwd) ?? cwd;
  return h_flex().flex_none().gap(1)
    .child(button(t, `rv-${id}`, "⧉", "Review this worktree in hunk", () => review(dir)))
    .when(Boolean(terminal && v.notes[dir]), (el) => el.child(button(t, `sn-${id}`, "➤", `Send ${v.notes[dir]} hunk notes to this agent`, (cx) => cx.spawn(async () => sendNotes(dir, terminal)))));
}

// A kid's rows: a task is one row (its live or failed step) that opens to its steps.
export function kidRows(v, t, k, depth) {
  if (!k.steps) return [kidRow(t, k, depth)];
  const open = v.open.has(k.id);
  const done = k.steps.filter((s) => s.state === "done").length;
  const task = {
    ...k, label: k.now ? `${k.label} · ${k.now}` : k.label, count: `${done}/${k.steps.length}`,
    tip: `${k.workflow} · ${k.label}: ${done} of ${k.steps.length} steps done; click: ${open ? "hide" : "show"} them`,
    click: (cx) => { open ? v.open.delete(k.id) : v.open.add(k.id); cx.notify(); },
  };
  return [kidRow(t, task, depth), ...(open ? k.steps.map((s) => kidRow(t, { ...s, label: s.step, workflow: null }, depth + 14)) : [])];
}

function kidRow(t, k, depth) {
  const mark = k.state === "running"
    ? svg("mods/workspace-chrome/spinner.svg").size(12).mx(1).flex_none().text_color(t.working).spin(900)
    : k.state === "failed"
      ? div().flex_none().text_size(11).font_bold().text_color(t.blocked).child("✕")
      : div().size(7).mx(3).flex_none().rounded(4).bg(t.dim);
  const steps = Boolean(k.steps);
  return h_flex()
    .id(`kid-${k.id}`)
    .pl(depth)
    .pr(8)
    .rounded(8)
    .h(24)
    .flex_none()
    .gap(6)
    .items_center()
    .text_size(12)
    .cursor_pointer()
    .hover((s) => s.bg(t.hover))
    .tooltip(k.tip ?? `${k.phase ? `${k.phase}: ` : ""}${k.label} — ${k.state}; click: follow it in zoe`)
    .on_click((_e, cx) => (steps ? k.click(cx) : popup(`zoe · ${k.label}`, ["zoe", k.log, "--follow"])))
    .when(!steps, (el) => onMenu(el, { kind: "kid", log: k.log, label: k.label }))
    .child(div().flex_none().text_color(t.dim).child("↳"))
    .child(div().flex_1().min_w(0).truncate().text_color(k.state === "failed" ? t.blocked : k.state === "running" ? t.foreground : t.muted).child(k.workflow && !steps ? `${k.workflow} · ${k.label}` : k.label))
    .when(Boolean(k.count), (el) => el.child(div().flex_none().text_size(10.5).text_color(t.dim).child(k.count)))
    .child(mark);
}

// A `claude --bg` job: click attaches to it in the popup.
export function bgRow(v, t, s, statusMark, hovered, setHovered) {
  const st = bgStatus(s);
  const line = [where(v, s.cwd), s.detail].filter(Boolean).join(" · ");
  return h_flex()
    .id(`bg-${s.id}`)
    .px(8)
    .h(line ? 40 : 30)
    .flex_none()
    .rounded(8)
    .items_center()
    .gap(9)
    .cursor_pointer()
    .hover((el) => el.bg(t.hover))
    .on_hover((on, cx) => setHovered(s.id, on, cx))
    .tooltip(s.detail ?? s.name ?? s.id)
    .on_click(() => popup(`claude · ${s.name ?? s.job}`, ["claude", "attach", s.job], s.cwd))
    .when(true, (el) => onMenu(el, { kind: "bg", job: s.job, id: s.id, name: s.name ?? s.job, cwd: s.cwd, tree: treeOf(v, s.cwd), log: s.log }))
    .child(div().flex_none().text_size(10).text_color(t.dim).child("bg"))
    .child(v_flex().flex_1().min_w(0)
      .child(div().min_w(0).truncate().text_color(st === "idle" ? t.muted : t.foreground).child(s.name || s.job))
      .when(Boolean(line), (el) => el.child(div().min_w(0).truncate().text_size(11).text_color(t.dim).child(line))))
    .when(hovered === s.id, (el) => el.child(actions(v, t, s.id, s.cwd, null)))
    .child(statusMark({ status: st }));
}

export const bgSessions = (v) => v.live.filter((s) => s.kind === "bg");
// The job's own state first: a job waiting on a question or one that failed needs you.
export const bgStatus = (s) => (["blocked", "failed"].includes(s.state) ? "blocked" : s.status === "busy" || s.state === "working" ? "working" : "idle");

// One worktree's header row: branch, its folder when that differs, changed files, conflicts, hunk notes; hover:
// review, lazygit, a new Claude there. Click: the first agent working in it.
export function treeRow(v, t, path, info, members, hovered, setHovered) {
  const name = path.split("/").pop();
  const notes = v.notes[path];
  const first = members.find((m) => m.pane);
  const badge = (text, color) => div().flex_none().text_size(10.5).text_color(color).child(text);
  return h_flex()
    .id(`wt-${path}`)
    .px(8)
    .h(28)
    .flex_none()
    .rounded(8)
    .items_center()
    .gap(6)
    .text_size(12.5)
    .cursor_pointer()
    .hover((el) => el.bg(t.hover))
    .on_hover((on, cx) => setHovered(path, on, cx))
    .on_click(() => first && run("pane.focus", { pane: first.pane }))
    .when(true, (el) => onMenu(el, { kind: "tree", tree: path, terminal: members.find((m) => m.address && !m.job)?.address, notes, repo: info?.repo, pr: info && prOf(v, info.repo, info.branch) }))
    .child(svg("mods/workspace-chrome/git-branch.svg").size(12).flex_none().text_color(t.muted))
    .child(div().min_w(0).truncate().text_color(t.foreground).child(info?.branch ?? name))
    .when(Boolean(info?.branch) && !info.branch.endsWith(name), (el) => el.child(div().flex_1().min_w(0).truncate().text_size(11).text_color(t.dim).child(name)))
    .child(div().flex_1())
    .when(!info && v.git[path] === null, (el) => el.child(badge("removed", t.dim)))
    .when(Boolean(info && prOf(v, info.repo, info.branch)), (el) => el.child(prChip(t, prOf(v, info.repo, info.branch))))
    .when(Boolean(info?.conflicts), (el) => el.child(badge(`!${info.conflicts}`, t.blocked)))
    .when(Boolean(info?.changed), (el) => el.child(badge(`±${info.changed}`, t.muted)))
    .when(Boolean(notes), (el) => el.child(badge(`✎${notes}`, t.accent)))
    .when(hovered === path, (el) => el.child(h_flex().flex_none().gap(1)
      .child(actions(v, t, `wt-${path}`, path, members.find((m) => m.address && !m.job)?.address))
      .child(button(t, `lg-${path}`, "⎇", "lazygit here", () => popup("lazygit", ["lazygit"], path)))
      .child(button(t, `cl-${path}`, "+", "New Claude in this worktree", () => run("tab.new", { folder: path, argv: ["claude"] })))));
}

// Repo → worktree → members: herdr agents (by their pane's folder) and `--bg` jobs. Worktrees with nothing running
// and no changes stay out; a repo with nothing left drops too.
export function byWorktree(v, list, paneCwd) {
  const repos = new Map();
  const add = (cwd, m) => {
    // A folder git can't place (a removed worktree) still sorts under its repo by the worktree path layout.
    const wt = /^(.*)\/\.claude\/worktrees\/[^/]+/.exec(cwd ?? "");
    const path = treeOf(v, cwd) ?? wt?.[0] ?? cwd ?? "?";
    const repo = v.git[cwd]?.repo ?? v.trees[path]?.repo ?? wt?.[1] ?? path;
    if (!repos.has(repo)) repos.set(repo, new Map());
    const trees = repos.get(repo);
    if (!trees.has(path)) trees.set(path, []);
    if (m) trees.get(path).push(m);
  };
  for (const a of list) add(paneCwd(a), a);
  for (const s of bgSessions(v)) add(s.cwd, { ...s, job: s.job });
  // A task its session runs in another worktree sits there; the session's own row no longer lists it.
  const shown = new Set(list.map((a) => a.address));
  for (const s of v.live) if (s.kind === "bg" || shown.has(s.terminal)) for (const k of s.kids) if (elsewhere(v, s, k)) add(k.cwd, { ...k, kid: true });
  for (const [path, info] of Object.entries(v.trees)) if (info.changed || info.conflicts || v.notes[path]) add(path, null);
  return repos;
}

// A PR in one word, as the agents' states: failing checks, conflicts or changes asked need you.
export function prStatus(pr) {
  const c = checks(pr);
  return pr.mergeable === "CONFLICTING" || c === "fail" || pr.reviewDecision === "CHANGES_REQUESTED" ? "blocked" : c === "pending" ? "working" : "idle";
}
const PR_RANK = { blocked: 0, working: 1, idle: 2 };

// Every repo's open PRs, the ones needing you first, each with the worktree that has its branch (if one does).
export function openPrs(v) {
  const treeOf = (repo, branch) => Object.entries(v.trees).find(([, w]) => w.repo === repo && w.branch === branch)?.[0] ?? null;
  return Object.entries(v.prs).flatMap(([repo, prs]) => prs.map((pr) => ({ repo, pr, tree: treeOf(repo, pr.headRefName) })))
    .sort((x, y) => PR_RANK[prStatus(x.pr)] - PR_RANK[prStatus(y.pr)] || y.pr.number - x.pr.number);
}

// One PR row: "#12 ✓ title", the repo when there are several, ⎇ when a worktree has it. Click or right-click: its menu.
export function prRow(t, { repo, pr, tree }, showRepo) {
  const desc = { kind: "pr", repo, pr, tree };
  const menu = (cx) => { cx.stop_propagation(); openOverlay({ mod: "my-agents", kind: "popup", width: 236, height: items(desc).length * 30 + 12, props: { menu: desc } }); };
  return h_flex().id(`pr-${repo}-${pr.number}`).px(8).h(26).flex_none().gap(6).items_center().rounded(8).text_size(12).cursor_pointer()
    .hover((el) => el.bg(t.hover)).tooltip(`${repo.split("/").pop()} · ${pr.headRefName}${tree ? ` (worktree ${tree.split("/").pop()})` : ""}: ${pr.title}`)
    .on_click((_e, cx) => menu(cx)).on_mouse_down("right", (_e, cx) => menu(cx))
    .child(prChip(t, pr))
    .child(div().flex_1().min_w(0).truncate().text_color(prStatus(pr) === "idle" ? t.muted : t.foreground).child(pr.title))
    .when(showRepo, (el) => el.child(div().flex_none().text_size(10.5).text_color(t.dim).child(repo.split("/").pop())))
    .when(Boolean(tree), (el) => el.child(svg("mods/workspace-chrome/git-branch.svg").size(11).flex_none().text_color(t.dim)));
}

// The Pull requests panel (this mod again, props {prs: true}, its own sidebar block): each space's open PRs under
// its name, a space's being those of the repos its terminals are in; PRs of repos no space shows go under "Other".
// Click a space's name: fold it.
export function prPanel(v, t) {
  const prs = openPrs(v);
  const all = panes();
  const groups = spaces().map((s) => {
    const tabs = new Set(s.tabs.map((x) => x.id));
    const repos = new Set(all.filter((p) => tabs.has(p.tab)).map((p) => v.git[p.cwd]?.repo).filter(Boolean));
    return { id: s.id, name: s.name, repos, prs: prs.filter((p) => repos.has(p.repo)) };
  });
  const placed = new Set(groups.flatMap((g) => [...g.repos]));
  groups.push({ id: "other", name: "Other", repos: new Set(), prs: prs.filter((p) => !placed.has(p.repo)) });
  v.foldPr ??= new Set();
  const rows = groups.filter((g) => g.prs.length).flatMap((g) => {
    const open = !v.foldPr.has(g.id);
    const top = g.prs.some((p) => prStatus(p.pr) === "blocked") ? "blocked" : null;
    return [
      h_flex().id(`prs-${g.id}`).px(8).pt(8).h(30).flex_none().gap(6).items_center().text_size(11).font_medium().cursor_pointer()
        .hover((s) => s.text_color(t.foreground))
        .on_click((_e, cx) => { open ? v.foldPr.add(g.id) : v.foldPr.delete(g.id); cx.notify(); })
        .child(div().truncate().text_color(t.dim).child(g.name))
        .child(div().text_color(t.dim).child(String(g.prs.length)))
        .child(div().flex_1())
        .when(!open && Boolean(top), (el) => el.child(div().text_size(10.5).font_bold().text_color(t.blocked).child("!")))
        .when(!open, (el) => el.child(svg("mods/workspace-chrome/chevron-right.svg").size(11).flex_none().text_color(t.dim))),
      ...(open ? g.prs.map((p) => prRow(t, p, g.repos.size > 1 || g.id === "other")) : []),
    ];
  });
  return v_flex().size_full().min_h(0).bg(t.chrome).border_t(1).border_color(t.border).text_size(13)
    .child(h_flex().px(16).h(41).pt(14).pb(5).flex_none().items_center()
      .child(div().text_size(11.5).font_medium().text_color(t.dim).child("Pull requests")))
    .when(!rows.length, (el) => el.child(div().px(16).text_size(12).text_color(t.dim).child(Object.keys(v.prs).length ? "No open pull requests" : "Loading…")))
    .child(v_flex().id("prs-list").flex_1().min_h(0).px(8).overflow_y_scrollbar().children(rows));
}

// Right-click menus. The menu is this mod opened again as a popup (props().menu): a plain description of the row,
// since the popup copy has none of the list's state.
export function onMenu(el, desc) {
  return el.on_mouse_down("right", (_e, cx) => {
    cx.stop_propagation();
    openOverlay({ mod: "my-agents", kind: "popup", width: 236, height: items(desc).length * 30 + 12, props: { menu: desc } });
  });
}

const copy = (text) => exec("wl-copy", [text]);
const shell = (folder) => run("tab.new", { folder });
const newClaude = (folder) => run("tab.new", { folder, argv: ["claude"] });
const removeTree = (folder) => openOverlay({ mod: "my-worktree", kind: "dialog", width: 460, height: 280,
  props: { folder, action: "remove", space: spaces().find((s) => s.active)?.id } });

// [label, action] per row kind; null draws a divider.
function items(d) {
  const dir = d.tree ?? d.cwd;
  const notes = d.notes ? [[`Send ${d.notes} hunk notes`, () => sendNotes(dir, d.terminal)]] : [];
  if (d.kind === "agent") return [
    ["Go to agent", () => run("pane.focus", { pane: d.pane })],
    ["Peek", () => run("terminal.peek", { terminal: d.terminal })],
    ...(d.log ? [["Session in zoe", () => popup("zoe", ["zoe", d.log, "--follow"])]] : []),
    null,
    ["Review branch in hunk", () => review(dir)], ...notes,
    ["lazygit here", () => popup("lazygit", ["lazygit"], dir)],
    ["Shell here", () => shell(dir)],
    null,
    [d.pinned ? "Unpin" : "Pin to the top", () => run("terminal.pin", { terminal: d.terminal, pinned: !d.pinned })],
    ["Copy folder", () => copy(dir)],
  ];
  const pr = d.pr ? [null, ...prItems(d.pr, d.repo, dir)] : [];
  if (d.kind === "tree") return [
    ["Review branch in hunk", () => review(dir)], ...(d.terminal ? notes : []), ...pr, null,
    ["lazygit here", () => popup("lazygit", ["lazygit"], dir)],
    ["New Claude here", () => newClaude(dir)],
    ["Shell here", () => shell(dir)],
    ["Copy path", () => copy(dir)],
    null,
    ["Remove worktree…", () => removeTree(dir)],
  ];
  if (d.kind === "bg") return [
    ["Attach", () => popup(`claude · ${d.name}`, ["claude", "attach", d.job], d.cwd)],
    ["Follow in zoe", () => popup(`zoe · ${d.name}`, ["zoe", d.log, "--follow"])],
    ["Logs", () => popup(`logs · ${d.name}`, ["sh", "-c", `claude logs ${sh(d.job)}; read -r -p 'Enter to close ' _`])],
    null,
    ["Review branch in hunk", () => review(dir)],
    ["Shell here", () => shell(dir)],
    ["Copy session id", () => copy(d.id)],
    null,
    ["Stop job", () => exec("claude", ["stop", d.job]).then((r) => notify({ title: r.code === 0 ? "Stopped" : "Couldn't stop", body: d.name, level: r.code === 0 ? "info" : "error" }))],
  ];
  if (d.kind === "pr") return [
    ...prItems(d.pr, d.repo, d.tree ?? d.repo),
    ...(d.tree ? [] : [null, [`PR #${d.pr.number}: check out in a worktree`, () => openOverlay({ mod: "my-worktree", kind: "dialog", width: 460, height: 280,
      props: { space: spaces().find((s) => s.active)?.id, folder: d.repo, branch: d.pr.headRefName } })]]),
  ];
  return [ // kid
    ["Follow in zoe", () => popup(`zoe · ${d.label}`, ["zoe", d.log, "--follow"])],
    ["Copy log path", () => copy(d.log)],
  ];
}

export function menuView(t) {
  const d = props().menu;
  return v_flex().w_full().p(5).bg(t.popover).text_size(12.8).children(items(d).map((it, i) => it
    ? h_flex().id(`mi-${i}`).h(30).px(8).rounded(7).items_center().text_color(it[0].startsWith("Stop") || it[0].startsWith("Remove") ? t.blocked : t.foreground)
      .cursor_pointer().hover((el) => el.bg(t.hover))
      // close after the action: closing first would cancel an action still awaiting (sending notes)
      .on_click((_e, cx) => { const id = props().overlay; cx.spawn(async () => { await it[1](); closeOverlay(id); }); })
      .child(it[0])
    : div().h(1).my(3).mx(6).bg(t.border)));
}

// What you can do with a PR. Its diff goes through `gh pr diff`: hunk's own GitHub fetch has no token for private repos. Merge asks gh to squash once the checks pass (`--auto`); GitHub refuses what the repo forbids.
function prItems(pr, repo, dir) {
  const n = String(pr.number);
  return [
    [`PR #${n}: review in hunk`, () => popup(`PR #${n}`, ["sh", "-c", `gh pr diff ${n} | hunk patch`], repo, true)],
    [`PR #${n}: checks`, () => popup(`checks #${n}`, ["sh", "-c", `gh pr checks ${n} --watch; echo; read -r -p 'Enter to close ' _`], repo)],
    [`PR #${n}: ask Claude to fix`, () => run("tab.new", { folder: dir ?? repo, argv: ["claude", `PR #${n} (${pr.headRefName}): read \`gh pr view ${n} --comments\` and \`gh pr checks ${n}\`, then fix failing checks, merge conflicts with its base and requested changes, and push.`] })],
    [`PR #${n}: open on GitHub`, () => exec("xdg-open", [pr.url])],
    [`PR #${n}: merge when green…`, () => exec("gh", ["pr", "merge", n, "--auto", "--squash"], { cwd: repo }).then((r) => notify({ title: r.code === 0 ? `PR #${n} will merge` : `PR #${n} not merged`, body: (r.code === 0 ? r.stdout : r.stderr || r.stdout).trim(), level: r.code === 0 ? "info" : "error" }))],
  ];
}
