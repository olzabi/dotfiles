// Vim Preview: insert/replace mode -> Source mode (raw markdown), normal/visual -> Live Preview.
// Both stay editable, so vim keeps working. Reading view has no editor: j/k scroll it instead.
// shortcut: listens on the vim adapter's "vim-mode-change" (editor.cm.cm, @replit/codemirror-vim internals); re-check after Obsidian updates.
const { Plugin, MarkdownView } = require("obsidian");

module.exports = class VimPreview extends Plugin {
  onload() {
    this.hooked = new WeakSet();
    const attachAll = () => this.app.workspace.getLeavesOfType("markdown").forEach((l) => this.attach(l.view));
    this.app.workspace.onLayoutReady(attachAll);
    this.registerEvent(this.app.workspace.on("layout-change", attachAll));
    this.registerEvent(this.app.workspace.on("active-leaf-change", attachAll));
    this.registerDomEvent(document, "keydown", (e) => this.scroll(e));
  }

  // Reading view: j/k scroll a line-ish step, like vim normal mode.
  scroll(e) {
    const step = { j: 60, k: -60 }[e.key];
    if (!step || e.ctrlKey || e.metaKey || e.altKey || e.target.closest?.("input, textarea, [contenteditable=true]")) return;
    const view = this.app.workspace.getActiveViewOfType(MarkdownView);
    if (view?.getMode() !== "preview") return;
    view.contentEl.querySelector(".markdown-preview-view")?.scrollBy({ top: step });
    e.preventDefault();
  }

  attach(view) {
    const vim = view instanceof MarkdownView && view.editor?.cm?.cm;
    if (!vim?.on || this.hooked.has(vim)) return;
    this.hooked.add(vim);
    const onMode = ({ mode }) => {
      const source = mode === "insert" || mode === "replace";
      const state = view.getState();
      if (state.mode !== "source" || state.source === source) return;
      view.setState({ ...state, source }, { history: false });
    };
    vim.on("vim-mode-change", onMode);
    this.register(() => vim.off("vim-mode-change", onMode));
  }
};
