// Tokens: status bar item like core Word Count — tokens of the selection, else the whole note.
// Id is "tokens", not "token-count": that id belongs to a community plugin and its updater overwrote this one.
// GPT count is exact: o200k_base (GPT-4o / GPT-5 / o-series), vendored in o200k.js.
// Rebuild o200k.js: echo 'module.exports=require("gpt-tokenizer/encoding/o200k_base").countTokens' > e.js
//   && bun build e.js --format=cjs --minify --target=browser --outfile=o200k.js
// shortcut: Claude has no public offline tokenizer, so its number is GPT × CLAUDE_RATIO; use Anthropic's count_tokens API if you need it exact.
const { Plugin, MarkdownView, debounce } = require("obsidian");
const { EditorView } = require("@codemirror/view");

const CLAUDE_RATIO = 1.2;
const fmt = (n) => n.toLocaleString();

module.exports = class Tokens extends Plugin {
  onload() {
    this.el = this.addStatusBarItem();
    this.refresh = debounce(() => this.update(), 300, true);
    this.registerEditorExtension(EditorView.updateListener.of((u) => (u.docChanged || u.selectionSet) && this.refresh()));
    this.registerEvent(this.app.workspace.on("active-leaf-change", this.refresh));
    this.registerEvent(this.app.workspace.on("file-open", this.refresh));
    this.registerEvent(this.app.vault.on("modify", (f) => f === this.app.workspace.getActiveFile() && this.refresh()));
    this.app.workspace.onLayoutReady(this.refresh);
  }

  // Lazy: the 2 MB rank table is only evaluated once a note is shown. Relative require() is unreliable in plugins.
  async counter() {
    this.count ??= this.app.vault.adapter.read(`${this.manifest.dir}/o200k.js`).then((src) => {
      const m = { exports: {} };
      new Function("module", "exports", src)(m, m.exports);
      return m.exports;
    });
    return this.count;
  }

  async update() {
    const file = this.app.workspace.getActiveFile();
    if (file?.extension !== "md") return this.el.hide();
    const view = this.app.workspace.getActiveViewOfType(MarkdownView);
    const editor = view?.getMode() === "source" ? view.editor : null;
    const text = editor?.somethingSelected() ? editor.getSelection() : editor ? editor.getValue() : await this.app.vault.cachedRead(file);
    const count = await this.counter();
    // Notes may literally contain "<|endoftext|>": count it as text instead of throwing.
    const gpt = count(text, { disallowedSpecial: new Set() });
    this.el.setText(`${fmt(gpt)} tokens · Claude ~${fmt(Math.round(gpt * CLAUDE_RATIO))}`);
    this.el.setAttr("aria-label", "GPT-4o/5 (o200k_base), exact\nClaude: estimate");
    this.el.show();
  }
};
