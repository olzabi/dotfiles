# niri workspaces, startup, Firefox side profile, podman autostart — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Login opens every app on its own workspace in a fixed priority order, dev focused, videos on the small monitor, containers up.

**Architecture:** Named niri workspaces (declared in priority order) plus window rules route apps; name-based keybinds keep Mod+3 = dev however many dynamic workspaces appear. Startup spawns the apps unfocused except dev. Firefox runs two profiles sharing one user.js/chrome/policies.

**Tech Stack:** niri 26.04 KDL config, Firefox user.js + `/etc/firefox/policies/policies.json`, podman-compose + `podman-restart.service`.

**Spec:** the design approved in conversation on 2026-11-25, restated here:

```
LG HDMI-A-2 (big)                       ASUS HDMI-A-1 (small)
1   empty (empty-workspace-above-first)  video: firefox-side profile, mpv, vlc
2   secondary  podman desktop
3   dev        main firefox, herdr-app, kitty, editors (everything unmatched)
4   chat       telegram, discord
5   games      steam, steam_app_*, gamescope
6+  dynamic
```

## Global Constraints

- Workspace names exactly: `secondary`, `dev`, `chat`, `games`, declared in that order, all `open-on-output "HDMI-A-2"`.
- Mod+2/3/4/5 → secondary/dev/chat/games by name (focus, Mod+Ctrl column move, Mod+Shift window move). Mod+1 and Mod+6..0 stay index-based.
- Mod+Alt+Shift+Left/Right = move-workspace-to-monitor-left/right; Mod+Alt+Shift+Up/Down = move-workspace-up/down.
- Chats and podman desktop open at login with `open-focused false`; dev is focused after login.
- Side Firefox: profile dir `~/.config/mozilla/firefox/side`, app-id `firefox-side`; same `user.js` and `chrome/` as main profile `2c8j0ju3.default-release`. Both restore last session (`browser.startup.page` = 3).
- Containers that start at boot: `postgres`, `searxng` (`restart: always`), via user `podman-restart.service`.
- Dotfiles checkout is live: edit in this worktree; merge to main only by fast-forward or a rebase that never checks out older trees in the main worktree.

## Review Focus

1. Startup `niri msg action focus-workspace dev` runs before niri's IPC is ready → dev not focused. Expect dev focused after a fresh login; verify in Task 2 Step 4.
2. `firefox --profile side --name firefox-side` while the main Firefox runs must start a second instance with app-id `firefox-side`, not open a window in the main one. Verify in Task 3 Step 4.
3. A named workspace moved to the other monitor with Mod+Alt+Shift+← should stay there after `niri msg action load-config-file`. Verify in Task 1 Step 4; if niri moves it back, note it in the final report (niri behaviour, not fixed here).
4. Telegram's app-id carries a per-install suffix (`org.telegram.desktop...`): match by prefix regex, verify in Task 2 Step 4.
5. Existing containers keep `unless-stopped` until recreated: Task 4 must recreate them, verify with `podman inspect`.

---

### Task 1: Named workspaces, routing rules, keybinds

**Files:**
- Modify: `config/niri/workspaces.kdl` (whole file)
- Modify: `config/niri/binds/ws.kdl:3-6,14-17,25-28`
- Modify: `config/niri/binds/nav.kdl` (append four binds)

**Interfaces:**
- Produces: workspace names `secondary`, `dev`, `chat`, `games` used by Task 2.

- [ ] **Step 1:** `workspaces.kdl`: declare `workspace "secondary"`, `"dev"`, `"chat"`, `"games"`, each `open-on-output "HDMI-A-2"`. Rules: games rule unchanged; `^io\.podman_desktop\.PodmanDesktop$` → `open-on-workspace "secondary"`, `open-focused false`; `^org\.telegram\.desktop` and `^discord$` (excluding title `^(Media viewer|Discord Updater)$`) → `open-on-workspace "chat"`, `open-focused false`; HDMI-A-1 rule keeps only `^firefox-side$` and `^(mpv|vlc)$`. Rnote and Obsidian rules unchanged. Update the header comment to the new layout.
- [ ] **Step 2:** `ws.kdl`: Mod+2..5 → `focus-workspace "secondary"|"dev"|"chat"|"games"`; same for `move-column-to-workspace` (Mod+Ctrl) and `move-window-to-workspace` (Mod+Shift). `nav.kdl`: add the four Mod+Alt+Shift binds from Global Constraints.
- [ ] **Step 3:** Run `niri validate -c config/niri/config.kdl`. Expected: `config is valid`.
- [ ] **Step 4:** Live check after merge (Task 5): `niri msg workspaces` lists the four names on HDMI-A-2 in order; Mod+Alt+Shift+↑ on dev swaps it with secondary; Mod+3 still focuses dev.
- [ ] **Step 5:** Commit `niri: named workspaces by priority (secondary, dev, chat, games), name keys, workspace move binds`.

### Task 2: Startup apps

**Files:**
- Create: `bin/firefox-side` (exec the side profile; used by Mod+A and startup)
- Modify: `config/niri/startup.kdl:5,7`
- Modify: `config/niri/binds/binds.kdl:3`

- [ ] **Step 1:** `bin/firefox-side`: `mkdir -p ~/.config/mozilla/firefox/side && exec firefox --profile ~/.config/mozilla/firefox/side --name firefox-side "$@"`. Mod+A spawns `~/Dotfiles/bin/firefox-side`.
- [ ] **Step 2:** `startup.kdl`: remove `chromium` and `kitty -e tmux`. Add, in this order: `spawn-sh-at-startup "niri msg action focus-workspace dev"`, `firefox`, `herdr-app`, `~/Dotfiles/bin/firefox-side`, `Telegram`, `discord`, `podman-desktop`.
- [ ] **Step 3:** `niri validate -c config/niri/config.kdl` → valid. `systemctl --user disable waybar.service app-com.mitchellh.ghostty.service` (machine state, not repo).
- [ ] **Step 4:** After next login: dev focused with firefox + herdr-app; telegram/discord on chat; podman desktop on secondary; side Firefox on HDMI-A-1; `niri msg -j windows` app-ids confirm.
- [ ] **Step 5:** Commit `niri: startup opens firefox, herdr-app, side browser, chats, podman desktop; drop chromium and kitty`.

### Task 3: Firefox side profile shares the main profile's setup

**Files:**
- Modify: `config/firefox/user.js` (add `browser.startup.page` 3)
- Modify: `symlinks.conf:82-83` (add the same two links for `side`)

- [ ] **Step 1:** Add `user_pref("browser.startup.page", 3); // restore last session; both profiles` to `user.js`. Add `user.js` and `chrome` links targeting `$XDG_CONFIG_HOME/mozilla/firefox/side/`.
- [ ] **Step 2:** Run `bin/symlinks` (after merge, from main). Expected: two new links, no errors.
- [ ] **Step 3:** `readlink ~/.config/mozilla/firefox/side/user.js` → `config/firefox/user.js`.
- [ ] **Step 4:** With main Firefox running, run `bin/firefox-side`; `niri msg -j windows | jq -r '.[].app_id'` shows `firefox-side`; its window lands on HDMI-A-1.
- [ ] **Step 5:** Commit `firefox: side profile shares user.js and chrome; restore last session`.
- Manual, user: sign both profiles into Firefox Sync with one account (bookmarks, history, passwords, Send Tab between profiles).

### Task 4: Containers start at boot

**Files:**
- Modify: `infra/docker-compose.yml:8,52` (`restart: always`)

- [ ] **Step 1:** Set `restart: always` on `postgres` and `searxng`.
- [ ] **Step 2:** `systemctl --user enable podman-restart.service`; recreate: `cd infra && podman compose --profile postgres --profile searxng up -d`.
- [ ] **Step 3:** `podman inspect postgres searxng --format '{{.Name}} {{.HostConfig.RestartPolicy.Name}}'` → both `always`.
- [ ] **Step 4:** Commit `infra: postgres and searxng restart always (podman-restart.service starts them at boot)`.

### Task 5: Merge and live check

- [ ] **Step 1:** Fast-forward main to this branch from the main worktree (`git merge --ff-only`); if main moved, rebase this branch onto main here first.
- [ ] **Step 2:** `niri msg action load-config-file`; run the live checks in Task 1 Step 4 and Task 3 Steps 2–4. Task 2 Step 4 and Task 4 boot behaviour are confirmed at next login.
