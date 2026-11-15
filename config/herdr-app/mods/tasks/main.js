// mise tasks of the focused terminal's folder (else the shown space's), in a sidebar of their own.
// Click: run it in a new tab (`mise run <task>`; the shell stays open after it). ⇣ on hover: run it in a split below.
// Re-read when the folder changes, and on ↻. mise's own error (an untrusted config, say) shows instead of the list.
import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { focused, spaces, run, exec, theme } from "herdr";

export default class Tasks extends View {
  init() {
    this.dir = null;
    this.tasks = [];
    this.error = null;
    this.hover = null;
  }

  folder() {
    const s = spaces().find((x) => x.active);
    return s?.machine ? null : focused()?.cwd || s?.folder || null; // shortcut: local spaces only; pass `on` to exec for remote ones
  }

  load(dir, cx) {
    this.dir = dir;
    cx.spawn(async (cx) => {
      const r = await exec("mise", ["tasks", "ls", "--json"], { cwd: dir, timeout: 15000 }).catch((e) => ({ code: 1, stderr: String(e) }));
      if (dir !== this.dir) return; // the folder changed meanwhile
      try {
        if (r.code !== 0) throw new Error((r.stderr || r.stdout || "mise failed").trim());
        this.tasks = JSON.parse(r.stdout).filter((x) => !x.hide).sort((a, b) => a.name.localeCompare(b.name));
        this.error = null;
      } catch (e) { this.tasks = []; this.error = e.message; }
      cx.notify();
    });
  }

  start(task, split) {
    const argv = ["mise", "-C", this.dir, "run", task.name]; // -C: a split has no folder of its own
    if (split) run("pane.split", { direction: "down", argv });
    else run("tab.new", { name: task.name, folder: this.dir, argv });
  }

  render(cx) {
    const t = theme();
    const dir = this.folder();
    if (dir !== this.dir) dir ? this.load(dir, cx) : (this.dir = null, this.tasks = [], this.error = null);
    const icon = (name) => svg(`mods/workspace-chrome/${name}.svg`).size(13).text_color(t.muted);
    return v_flex().id("tasks").size_full().px(8).pt(6).gap(1).text_size(12).overflow_y_scrollbar()
      .child(h_flex().h(22).flex_none().pl(8).gap(4).items_center()
        .child(div().flex_none().text_color(t.muted).child("Tasks"))
        .child(div().flex_1().min_w(0).truncate().text_color(t.dim).child(dir ? dir.split("/").pop() : ""))
        .child(div().id("tasks-reload").flex_none().p(3).rounded(5).cursor_pointer().text_color(t.muted).hover((s) => s.bg(t.hover))
          .on_click((_e, cx) => { if (this.dir) this.load(this.dir, cx); }).child("↻")))
      .when(Boolean(this.error), (el) => el.child(div().px(8).py(4).text_color(t.blocked).child(this.error)))
      .when(!this.error && Boolean(dir) && !this.tasks.length, (el) => el.child(div().px(8).text_color(t.dim).child("No mise tasks here")))
      .children(this.tasks.map((task, i) => {
        const key = `task-${i}`;
        return h_flex().id(key).min_h(24).flex_none().px(8).gap(8).items_center().rounded(6).cursor_pointer()
          .hover((s) => s.bg(t.hover))
          .on_hover((on, cx) => { if (on) this.hover = key; else if (this.hover === key) this.hover = null; cx.notify(); })
          .on_click(() => this.start(task, false))
          .child(icon("terminal"))
          .child(div().flex_none().text_color(t.foreground).child(task.name))
          .child(div().flex_1().min_w(0).truncate().text_color(t.dim).child(task.description || (task.run ?? []).join(" && ")))
          .when(this.hover === key, (el) => el.child(div().id(`${key}-split`).flex_none().px(5).rounded(4).text_color(t.muted)
            .hover((s) => s.bg(t.selected).text_color(t.foreground))
            .on_click((_e, cx) => { cx.stop_propagation(); this.start(task, true); }).child("⇣")));
      }));
  }
}
