// obs-git: lets obsidian-git (blame gutter, diff view, hunk signs) work in `obs` mirror vaults.
// A mirror vault is symlinks into the real repo with the same relative paths, so pointing git at the real repo
// (GIT_DIR + GIT_WORK_TREE) while obsidian-git keeps using vault-relative paths lines up: git resolves paths
// against the work tree when cwd is outside it.
// shortcut: writes obsidian-git's per-vault "envVars" localStorage key and patches its checkRequirements (internals); re-check after obsidian-git updates.
const { Plugin, TFile } = require("obsidian");
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const { execFileSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const KEY = "obsidian-git:envVars";

module.exports = class ObsGit extends Plugin {
  onload() {
    this.app.workspace.onLayoutReady(() => this.wire());
  }

  async wire() {
    const base = this.app.vault.adapter.getBasePath();
    if (fs.existsSync(path.join(base, ".git"))) return; // a real repo vault: obsidian-git works as is
    const file = this.app.vault.getFiles().find((f) => f instanceof TFile && fs.lstatSync(path.join(base, f.path)).isSymbolicLink());
    if (!file) return;
    const dir = path.dirname(fs.realpathSync(path.join(base, file.path)));
    let top, gitDir;
    try {
      [top, gitDir] = execFileSync("git", ["-C", dir, "rev-parse", "--show-toplevel", "--absolute-git-dir"], { encoding: "utf8" }).trim().split("\n");
    } catch {
      return; // target not in a git repo
    }
    this.app.saveLocalStorage(KEY, JSON.stringify([`GIT_DIR=${gitDir}`, `GIT_WORK_TREE=${top}`]));

    // Wait for obsidian-git's own first init to settle, then fix its repo check and re-init.
    let p;
    for (let i = 0; i < 50 && !((p = this.app.plugins.plugins["obsidian-git"])?.gitManager && (p.gitReady || p.repositoryMissing)); i++)
      await sleep(200);
    if (!p?.gitManager || p.gitReady) return;
    // Its check is `rev-parse --is-inside-work-tree`, which says false because cwd (the vault) is outside the
    // work tree; blame/diff/status still work. Accept the repo when GIT_DIR resolves.
    const proto = Object.getPrototypeOf(p.gitManager);
    if (!proto.obsPatched) {
      const orig = proto.checkRequirements;
      proto.checkRequirements = async function () {
        const r = await orig.call(this);
        return r === "missing-repo" && (await this.git?.raw(["rev-parse", "--git-dir"]).catch(() => "")) ? "valid" : r;
      };
      proto.obsPatched = true;
    }
    p.unloadPlugin();
    await p.init({ fromReload: true }); // rebuilds the git client too, so the envVars above apply this launch
    // Notes opened before this got a "no repo" blame gutter; rebuild them.
    for (const leaf of this.app.workspace.getLeavesOfType("markdown")) leaf.rebuildView?.();
  }
};
