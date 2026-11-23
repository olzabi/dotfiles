# themes

darkvoid for every app, in two modes: darkvoid (dark) and darkvoid dim-light (light).

```
dark/       darkvoid, hand-edited: the only files you change
light/      dim-light, generated from dark/ by ./build
auto/       generated files holding both modes, for apps that switch inside one file (CSS media queries, noctalia)
current     link to dark/ or light/, set by bin/darkvoid-mode (not tracked)
build       dark/ -> light/ + auto/   (./build --check fails when the tracked output is stale)
darkvoid-light.py   the colour rule every light file goes through (--test checks it)
telegram.py         Telegram's Night palette -> darkvoid (dark/telegram.night-palette)
mode.d/     what a link can't do on a switch: reload a running app, rebuild a cache
darkvoid.md the dark palette, exported for other terminals/editors
```

Change a theme: edit `dark/<app>`, run `./build`, commit both. Apps pick it up through links (`symlinks.conf`).

## How a switch reaches each app

Noctalia owns the mode (`[theme] mode` dark | light | auto in `config/noctalia/config.toml`, or
`noctalia msg theme-mode-toggle`). On a change it switches its own palette, sets the system
`color-scheme`, and runs `bin/darkvoid-mode`, which points `current` at `dark/` or `light/` and runs `mode.d/`.

- **Follow the system themselves**, linked to both `dark/` and `light/`: kitty (`*-theme.auto.conf`), nvim
  (`background`), herdr-app, pi, omp, IntelliJ (sync with OS), Telegram (import both once, "match the system theme").
- **One file, both modes** (`auto/`): GTK 4, Firefox chrome + about: pages, Obsidian, Noctalia.
- **Through `current`**: niri (focus ring), bat (and yazi previews, fzf-tab), delta, yazi, television, atuin, starship, eza, glow,
  lazygit, lazyjj, hunk, rofi, posting, ai-usagebar, Claude Code. New processes read the new file; running
  ones keep theirs until restarted, except where `mode.d/` reloads them (nvim, niri, bat cache, Claude Code, monitor profile).

## The dim-light rule (`darkvoid-light.py`)

- **Paper, not white.** Warm neutral paper `#d3ceca`, no white anywhere; panels and selections sit darker than the page.
- **Same ladder as darkvoid.** Greys keep darkvoid's order and ratios (comments 3:1, text 7.6:1, keywords 12.2:1:
  keywords stand 1.6x above text in both modes); bold stays where darkvoid has it.
- **Ink, not neon.** Accents keep their hue, chroma is capped, and they keep darkvoid's brightness order
  (3.3:1 .. 6:1, always lighter than text), so mint operators, teal constants, amber warnings and red errors stay apart (`--test` asserts it).
- Tune the rule (`BG`, `RAMP`, `CMAX`), never single colours; then `./build`.
