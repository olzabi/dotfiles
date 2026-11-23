// Code View: any vault file whose extension has no viewer (bin/ob mirrors files READMEs link to, e.g. scripts/x.py)
// opens in Obsidian as a read-only, syntax-highlighted code block instead of in an external app.
// shortcut: uses app.viewRegistry.isExtensionRegistered (internal API); re-check after Obsidian updates.
const { Plugin, TextFileView, MarkdownRenderer } = require("obsidian");

const TYPE = "code-view";

// Fence one backtick longer than any run inside, so the file can't close it early.
const fenced = (text, lang) => {
  const fence = "`".repeat(Math.max(3, ...(text.match(/`+/g) || []).map((r) => r.length + 1)));
  return `${fence}${lang}\n${text}\n${fence}`;
};

class CodeView extends TextFileView {
  getViewType() { return TYPE; }
  // only claimed extensions: returning true kept .md files in this view when a code tab navigated to them
  canAcceptExtension(ext) { return this.app.viewRegistry.getTypeByExtension(ext) === TYPE; }
  getViewData() { return this.data; }
  clear() { this.contentEl.empty(); }
  setViewData(data) {
    this.data = data;
    this.clear();
    const el = this.contentEl.createDiv({ cls: "markdown-rendered" });
    el.style.userSelect = "text";
    MarkdownRenderer.render(this.app, fenced(data, this.file?.extension ?? ""), el, this.file?.path ?? "", this);
  }
  async save() {} // read-only: never write back
}

module.exports = class CodeViewPlugin extends Plugin {
  onload() {
    this.registerView(TYPE, (leaf) => new CodeView(leaf));
    const claim = (file) => {
      const ext = file.extension?.toLowerCase();
      if (ext && !this.app.viewRegistry.isExtensionRegistered(ext)) this.registerExtensions([ext], TYPE);
    };
    this.app.workspace.onLayoutReady(() => {
      this.app.vault.getFiles().forEach(claim);
      this.registerEvent(this.app.vault.on("create", claim));
    });
  }
};
