# Dotfiles

```sh
git clone https://github.com/olzabi/dotfiles ~/Dotfiles
```

## Layout

| Path      | What                                   | Linked to                 |
| --------- | -------------------------------------- | ------------------------- |
| `config/` | one folder or file per app             | `~/.config/<same name>`   |
| `home/`   | files that live directly in `$HOME`    | `~/<same name>`           |
| `agents/` | Claude, omp, pi, skills                | see `symlinks.conf`       |
| `system/` | packages and `/etc` (aconfmgr), pacman |                           |
| `themes/` | darkvoid dark/ + generated light/, per tool | see `themes/README.md`    |
| `bin/`    | scripts, on `$PATH` via `.zshenv`      |                           |
| `infra/`  | dev containers (`mise tasks | grep infra:`) |                           |
| `assets/` | source artwork (cursors)               |                           |

`symlinks.conf` lists only exceptions; `!<name>` keeps `config/<name>` out of the
automatic rule.

## Installation

On a fresh Arch install, logged in as your user:

```sh
sudo pacman -S --needed git base-devel zsh
git clone https://github.com/olzabi/dotfiles ~/Dotfiles && cd ~/Dotfiles
curl https://mise.run | sh && export PATH="$HOME/.local/bin:$PATH"
mise trust && mise run install
```

`mise run install` runs these steps in order. Each one can also be run alone, and
re-running is safe:

| Task              | Does                                                                  |
| ----------------- | --------------------------------------------------------------------- |
| `symlinks:create` | links `config/`, `home/` and the `symlinks.conf` entries              |
| (`mise install`)  | installs every tool in `config/mise/mise.toml`                        |
| `plugins:install` | yazi plugins, television channels, bat cache, tmux plugins (tpack)    |
| `services:enable` | enables the systemd user units (keypoints, hush digest)               |
| `shell:zsh`       | makes zsh the login shell                                             |

Optional and separate: `mise run system:apply` installs pacman/AUR packages and
`/etc` files from `system/aconfmgr` (needs `aconfmgr` from the AUR). After
installing packages by hand, use `mise run system:save` to record them.

`mise run update` upgrades tools and runs every `*:update` task (yazi plugins,
television channels, pi extensions).

Left to do by hand: `gh auth login`, SSH/GPG keys, `atuin login` for history sync.

## Shell pickers

| Key      | Where     | Does                                                            |
| -------- | --------- | --------------------------------------------------------------- |
| `Ctrl-R` | zsh       | atuin history (scoped to the git repo first; `Ctrl-R` cycles)   |
| `Alt-T`  | zsh       | television: picks a channel from the command typed so far       |
| `Ctrl-O` | zsh       | yazi here; quitting with `q` cds the shell to where yazi was    |
| `Ctrl-P` | yazi      | find a file (tv) and reveal it                                  |
| `g /`    | yazi      | find a directory (tv) and cd into it                            |
| `Ctrl-S` | yazi      | grep with tv + rg, open the hit in `$EDITOR` at that line       |
| `g b`    | yazi      | git branches (tv)                                               |
| `c s`    | yazi      | paste the selected paths as `@` mentions into the last focused agent |
| `S-Enter`| yazi      | Markdown in Obsidian (`ob`); other files: choose how to open    |
| `Z`      | yazi      | zoxide directories; yazi visits also feed zoxide                |
| `ctrl-space f` | herdr-app | yazi file picker; paths go into the focused terminal as `@` mentions |
| `!`      | yazi      | `$SHELL` in the current directory                               |

### Yazi

Existing keys: `g w` worktree picker (worktrunk), `g l` lazygit, `L` hunk diff,
`g s` open as a herdr space, `m`/`'` bookmarks.
Text previews use `bat` with the darkvoid theme; media metadata and trash
restoration use `mediainfo` and `trash-cli`.
Projects use `~/.local/state/yazi/projects.json` for startup restoration;
unlike DDS storage, changes are not synchronized between running instances.
Set `YAZI_SKIP_PROJECT_RESTORE=1` when starting Yazi to keep the requested
directory instead; the Herdr shortcut sets it automatically.

## Herdr shortcuts

- `Alt+Y` opens Yazi in a popup, starting in the current pane's directory.
