// Compact Folders: one-line rows instead of nesting. Display only — vault paths stay untouched.
//  - a single-child folder chain ending in one file is shown as that file: "A/B/C/file"
//  - a single-child folder chain ending in several entries is one folder row: "A/B/C"
// shortcut: patches the file explorer's internal item classes (Obsidian 1.15); re-check after Obsidian updates.
const { Plugin, TFolder, TFile, debounce } = require("obsidian");

const onlyChild = (f) => (f.children.length === 1 ? f.children[0] : null);

// Follow single-folder children down from f.
function chain(f) {
  const names = [f.name];
  for (let c; (c = onlyChild(f)) instanceof TFolder; ) {
    f = c;
    names.push(f.name);
  }
  return { end: f, names };
}

// The file a folder collapses into, if its whole subtree is one file.
const soleFile = (folder) => {
  const c = onlyChild(chain(folder).end);
  return c instanceof TFile ? c : null;
};

// Folder names above a file that collapse into its row (parents with exactly one child).
function filePrefix(file) {
  const names = [];
  for (let p = file.parent; p && !p.isRoot() && p.children.length === 1; p = p.parent) names.unshift(p.name);
  return names;
}

module.exports = class CompactFolders extends Plugin {
  onload() {
    this.app.workspace.onLayoutReady(() => this.patch());
    this.registerEvent(this.app.workspace.on("layout-change", () => this.patch()));
    // A change deep in a chain can turn a file row back into a folder row higher up: re-render everything.
    const refresh = debounce(() => (this.patch(), this.orig && this.resort()), 100, true);
    for (const ev of ["create", "delete", "rename"]) this.registerEvent(this.app.vault.on(ev, refresh));
  }

  explorer() {
    return this.app.workspace.getLeavesOfType("file-explorer")[0]?.view;
  }

  patch() {
    if (this.orig) return;
    const view = this.explorer();
    const items = view?.fileItems && Object.values(view.fileItems);
    const folderItem = items?.find((i) => i.file instanceof TFolder && !i.file.isRoot());
    const fileItem = items?.find((i) => i.file instanceof TFile);
    if (!folderItem || !fileItem) return;

    const folderProto = Object.getPrototypeOf(folderItem);
    const fileProto = Object.getPrototypeOf(fileItem);
    const viewProto = Object.getPrototypeOf(view);
    const orig = (this.orig = {
      sort: folderProto.sort,
      folderTitle: folderProto.getTitle,
      fileTitle: fileProto.getTitle,
      sorted: viewProto.getSortedFolderItems,
    });

    // Children list: swap each folder whose subtree is one file for that file's row.
    viewProto.getSortedFolderItems = function (folder) {
      return orig.sorted.call(this, folder).map((i) => {
        const f = i.file instanceof TFolder && soleFile(i.file);
        return (f && this.fileItems[f.path]) || i;
      });
    };
    fileProto.getTitle = function () {
      return [...filePrefix(this.file), orig.fileTitle.call(this)].join("/");
    };
    folderProto.getTitle = function () {
      return this.file.isRoot() ? orig.folderTitle.call(this) : chain(this.file).names.join("/");
    };
    folderProto.sort = function () {
      const f = this.file;
      if (f.isRoot()) return orig.sort.call(this);
      this.updateTitle();
      const { end } = chain(f);
      if (end === f) return orig.sort.call(this);
      this.vChildren.setChildren(this.view.getSortedFolderItems(end));
    };

    this.register(() => {
      folderProto.sort = orig.sort;
      folderProto.getTitle = orig.folderTitle;
      fileProto.getTitle = orig.fileTitle;
      viewProto.getSortedFolderItems = orig.sorted;
      this.resort();
    });
    this.resort();
  }

  resort() {
    const view = this.explorer();
    if (!view?.fileItems) return;
    for (const i of Object.values(view.fileItems)) i.updateTitle?.();
    for (const i of Object.values(view.fileItems)) if (i.file instanceof TFolder) i.sort();
  }
};
