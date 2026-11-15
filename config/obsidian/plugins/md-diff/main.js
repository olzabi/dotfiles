// md-diff: rendered diff of a note against git HEAD. Word-level changes are marked <del>/<ins> inside the markdown,
// then the merged text is rendered, so a changed table cell shows as a highlighted cell in a real table.
// Markdown structure (table pipes and separator rows, fences, heading/list/quote markers) is never wrapped: the new
// version of it is kept as is, so tables and lists still render.
// shortcut: inside code blocks and inline code the <ins>/<del> tags show literally; good enough for prose and tables.
const fs = require("fs");
const path = require("path");
const { execFile } = require("child_process");

const VIEW = "md-diff";
const STRUCT = /^(\||:?-{3,}:?|```.*|~~~.*|#{1,6}|[-*+]|\d+[.)]|>|\[.\])$/;

// git --word-diff=porcelain output -> markdown with <ins>/<del> around changed words.
function merge(porcelain) {
  let out = "";
  let body = false;
  for (const line of porcelain.split("\n")) {
    if (line.startsWith("@@")) {
      body = true;
      continue;
    }
    if (!body || line === "" || line[0] === "\\") continue;
    const op = line[0];
    const text = line.slice(1);
    if (op === "~") out += "\n";
    else if (op === " ") out += text;
    else out += mark(op === "+" ? "ins" : "del", text);
  }
  return out;
}

// Wrap changed words; structural tokens are kept raw when added and dropped when removed.
function mark(tag, text) {
  return text
    .split(/(\s+)/)
    .map((tok) => {
      if (!tok.trim()) return tok;
      if (STRUCT.test(tok)) return tag === "ins" ? tok : "";
      return `<${tag}>${tok}</${tag}>`;
    })
    .join("")
    .replace(new RegExp(`</${tag}>(\\s+)<${tag}>`, "g"), "$1"); // one span per changed run
}

function gitDiff(abs) {
  const args = ["-C", path.dirname(abs), "diff", "--no-color", "--no-ext-diff", "--word-diff=porcelain"];
  args.push("--word-diff-regex=[^[:space:]|]+|[|]", "-U1000000", "HEAD", "--", path.basename(abs));
  return new Promise((resolve, reject) =>
    execFile("git", args, { maxBuffer: 64 << 20 }, (err, stdout, stderr) => (err ? reject(new Error(stderr || err.message)) : resolve(stdout))),
  );
}

let obsidian;
try {
  obsidian = require("obsidian");
} catch {
  module.exports = { merge }; // plain node: main.test.js
}

if (obsidian) {
  const { Plugin, ItemView, MarkdownRenderer, debounce } = obsidian;

  class DiffView extends ItemView {
    getViewType() {
      return VIEW;
    }
    getDisplayText() {
      return `Diff: ${this.file?.basename ?? ""}`;
    }
    getIcon() {
      return "file-diff";
    }
    getState() {
      return { file: this.file?.path };
    }
    async setState(state, result) {
      this.file = state.file && this.app.vault.getFileByPath(state.file);
      await this.refresh();
      return super.setState(state, result);
    }
    async onOpen() {
      this.contentEl.addClass("md-diff");
      const again = debounce(() => this.refresh(), 500, true);
      this.registerEvent(this.app.vault.on("modify", (f) => f === this.file && again()));
    }
    async refresh() {
      const el = this.contentEl;
      if (!this.file) return;
      let md;
      try {
        const abs = fs.realpathSync(path.join(this.app.vault.adapter.getBasePath(), this.file.path));
        md = merge(await gitDiff(abs));
      } catch (e) {
        el.empty();
        el.createEl("p", { text: `git diff failed: ${e.message}` });
        return;
      }
      el.empty();
      if (!md) return void el.createEl("p", { text: "No changes against HEAD (or the file is untracked)." });
      const body = el.createDiv({ cls: "markdown-rendered" });
      await MarkdownRenderer.render(this.app, md, body, this.file.path, this);
    }
  }

  module.exports = class MdDiff extends Plugin {
    onload() {
      this.registerView(VIEW, (leaf) => new DiffView(leaf));
      this.addCommand({
        id: "open",
        name: "Rendered diff against HEAD",
        checkCallback: (checking) => {
          const file = this.app.workspace.getActiveFile();
          if (file?.extension !== "md") return false;
          if (!checking) this.app.workspace.getLeaf("split").setViewState({ type: VIEW, active: true, state: { file: file.path } });
          return true;
        },
      });
    }
  };
}
