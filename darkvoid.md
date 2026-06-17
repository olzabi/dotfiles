# Darkvoid Colorscheme — Universal Export

> Source: [darkvoid-theme/darkvoid.nvim](https://github.com/darkvoid-theme/darkvoid.nvim)
> A dark, monochromatic colorscheme with optional glow. Designed for dark rooms and focused coding.

---

## Color Palette Reference

| Role              | Hex       | Description                          |
|-------------------|-----------|--------------------------------------|
| `bg`              | `#1c1c1c` | Background                           |
| `fg`              | `#c0c0c0` | Foreground / normal text             |
| `cursor`          | `#bdfe58` | Cursor (accent lime-green)           |
| `line_nr`         | `#404040` | Line numbers                         |
| `visual`          | `#303030` | Visual selection background          |
| `comment`         | `#585858` | Comments                             |
| `string`          | `#d1d1d1` | String literals                      |
| `func`            | `#e1e1e1` | Functions                            |
| `kw`              | `#f1f1f1` | Keywords                             |
| `identifier`      | `#b1b1b1` | Identifiers / variables              |
| `type`            | `#a1a1a1` | Types                                |
| `type_builtin`    | `#c5c5c5` | Built-in types                       |
| `bracket`         | `#e6e6e6` | Brackets / punctuation               |
| `operator`        | `#1bfd9c` | Operators (accent green)             |
| `search_highlight`| `#1bfd9c` | Search highlight (accent green)      |
| `preprocessor`    | `#4b8902` | Preprocessor directives              |
| `bool`            | `#66b2b2` | Booleans (muted teal)                |
| `constant`        | `#b2d8d8` | Constants (light teal)               |
| `eob`             | `#3c3c3c` | End-of-buffer tilde color            |
| `border`          | `#585858` | UI borders (e.g. Telescope)          |
| `title`           | `#bdfe58` | UI titles                            |
| `bufferline_selection` | `#1bfd9c` | Active buffer tab indicator     |
| `pmenu_bg`        | `#1c1c1c` | Popup menu background                |
| `pmenu_sel_bg`    | `#1bfd9c` | Popup menu selected item background  |
| `pmenu_fg`        | `#c0c0c0` | Popup menu foreground                |
| `added`           | `#baffc9` | Git: added lines                     |
| `changed`         | `#ffffba` | Git: changed lines                   |
| `removed`         | `#ffb3ba` | Git: removed lines                   |
| `error`           | `#dea6a0` | LSP: error (soft red)                |
| `warning`         | `#d6efd8` | LSP: warning (soft green-white)      |
| `hint`            | `#bedc74` | LSP: hint (yellow-green)             |
| `info`            | `#7fa1c3` | LSP: info (muted blue)               |

---

## CSS Custom Properties

```css
:root {
  --dv-bg:               #1c1c1c;
  --dv-fg:               #c0c0c0;
  --dv-cursor:           #bdfe58;
  --dv-line-nr:          #404040;
  --dv-visual:           #303030;
  --dv-comment:          #585858;
  --dv-string:           #d1d1d1;
  --dv-func:             #e1e1e1;
  --dv-kw:               #f1f1f1;
  --dv-identifier:       #b1b1b1;
  --dv-type:             #a1a1a1;
  --dv-type-builtin:     #c5c5c5;
  --dv-bracket:          #e6e6e6;
  --dv-operator:         #1bfd9c;
  --dv-search-highlight: #1bfd9c;
  --dv-preprocessor:     #4b8902;
  --dv-bool:             #66b2b2;
  --dv-constant:         #b2d8d8;
  --dv-eob:              #3c3c3c;
  --dv-border:           #585858;
  --dv-title:            #bdfe58;
  --dv-pmenu-bg:         #1c1c1c;
  --dv-pmenu-sel-bg:     #1bfd9c;
  --dv-pmenu-fg:         #c0c0c0;
  --dv-added:            #baffc9;
  --dv-changed:          #ffffba;
  --dv-removed:          #ffb3ba;
  --dv-error:            #dea6a0;
  --dv-warning:          #d6efd8;
  --dv-hint:             #bedc74;
  --dv-info:             #7fa1c3;
}
```

---

## Terminal ANSI Color Mapping

| Slot | Name           | Hex       | Role                       |
|------|----------------|-----------|----------------------------|
| 0    | Black          | `#1c1c1c` | Background                 |
| 1    | Red            | `#dea6a0` | Error / removed            |
| 2    | Green          | `#1bfd9c` | Operator / accent mint     |
| 3    | Yellow         | `#ffffba` | Changed / warning          |
| 4    | Blue           | `#7fa1c3` | Info                       |
| 5    | Magenta        | `#66b2b2` | Bool / teal                |
| 6    | Cyan           | `#b2d8d8` | Constant                   |
| 7    | White          | `#c0c0c0` | Foreground                 |
| 8    | Bright Black   | `#585858` | Comment / border           |
| 9    | Bright Red     | `#ffb3ba` | Git removed (bright)       |
| 10   | Bright Green   | `#baffc9` | Git added                  |
| 11   | Bright Yellow  | `#bdfe58` | Cursor / title accent lime |
| 12   | Bright Blue    | `#bedc74` | Hint                       |
| 13   | Bright Magenta | `#c5c5c5` | Type builtin               |
| 14   | Bright Cyan    | `#d6efd8` | Warning (soft)             |
| 15   | Bright White   | `#f1f1f1` | Keywords                   |

---

## Alacritty (`alacritty.toml`)

```toml
[colors.primary]
background = "#1c1c1c"
foreground = "#c0c0c0"

[colors.cursor]
text   = "#1c1c1c"
cursor = "#bdfe58"

[colors.selection]
text       = "CellForeground"
background = "#303030"

[colors.search.matches]
foreground = "#1c1c1c"
background = "#1bfd9c"

[colors.normal]
black   = "#1c1c1c"
red     = "#dea6a0"
green   = "#1bfd9c"
yellow  = "#ffffba"
blue    = "#7fa1c3"
magenta = "#66b2b2"
cyan    = "#b2d8d8"
white   = "#c0c0c0"

[colors.bright]
black   = "#585858"
red     = "#ffb3ba"
green   = "#baffc9"
yellow  = "#bdfe58"
blue    = "#bedc74"
magenta = "#c5c5c5"
cyan    = "#d6efd8"
white   = "#f1f1f1"
```

---

## Kitty (`kitty.conf`)

```conf
# Darkvoid colorscheme for Kitty

background            #1c1c1c
foreground            #c0c0c0
cursor                #bdfe58
cursor_text_color     #1c1c1c
selection_background  #303030
selection_foreground  #c0c0c0

color0  #1c1c1c
color1  #dea6a0
color2  #1bfd9c
color3  #ffffba
color4  #7fa1c3
color5  #66b2b2
color6  #b2d8d8
color7  #c0c0c0
color8  #585858
color9  #ffb3ba
color10 #baffc9
color11 #bdfe58
color12 #bedc74
color13 #c5c5c5
color14 #d6efd8
color15 #f1f1f1

url_color #1bfd9c
```

---

## WezTerm (Lua config snippet)

```lua
-- In your wezterm.lua:
local darkvoid = {
  foreground    = "#c0c0c0",
  background    = "#1c1c1c",
  cursor_bg     = "#bdfe58",
  cursor_fg     = "#1c1c1c",
  cursor_border = "#bdfe58",
  selection_fg  = "#c0c0c0",
  selection_bg  = "#303030",
  scrollbar_thumb = "#404040",
  split         = "#585858",

  ansi = {
    "#1c1c1c", -- black
    "#dea6a0", -- red
    "#1bfd9c", -- green
    "#ffffba", -- yellow
    "#7fa1c3", -- blue
    "#66b2b2", -- magenta
    "#b2d8d8", -- cyan
    "#c0c0c0", -- white
  },
  brights = {
    "#585858", -- bright black
    "#ffb3ba", -- bright red
    "#baffc9", -- bright green
    "#bdfe58", -- bright yellow
    "#bedc74", -- bright blue
    "#c5c5c5", -- bright magenta
    "#d6efd8", -- bright cyan
    "#f1f1f1", -- bright white
  },
}

config.color_schemes = { ["Darkvoid"] = darkvoid }
config.color_scheme = "Darkvoid"
```

---

## Windows Terminal (`settings.json` scheme)

```json
{
  "name": "Darkvoid",
  "background": "#1C1C1C",
  "foreground": "#C0C0C0",
  "cursorColor": "#BDFE58",
  "selectionBackground": "#303030",
  "black":         "#1C1C1C",
  "red":           "#DEA6A0",
  "green":         "#1BFD9C",
  "yellow":        "#FFFFBA",
  "blue":          "#7FA1C3",
  "purple":        "#66B2B2",
  "cyan":          "#B2D8D8",
  "white":         "#C0C0C0",
  "brightBlack":   "#585858",
  "brightRed":     "#FFB3BA",
  "brightGreen":   "#BAFFC9",
  "brightYellow":  "#BDFE58",
  "brightBlue":    "#BEDC74",
  "brightPurple":  "#C5C5C5",
  "brightCyan":    "#D6EFD8",
  "brightWhite":   "#F1F1F1"
}
```

---

## VS Code (`settings.json` color overrides)

```json
{
  "workbench.colorCustomizations": {
    "editor.background":           "#1c1c1c",
    "editor.foreground":           "#c0c0c0",
    "editorLineNumber.foreground": "#404040",
    "editorCursor.foreground":     "#bdfe58",
    "editor.selectionBackground":  "#303030",
    "editor.findMatchBackground":  "#1bfd9c44",
    "editor.findMatchHighlightBackground": "#1bfd9c22",
    "terminal.background":         "#1c1c1c",
    "terminal.foreground":         "#c0c0c0",
    "terminal.ansiBlack":          "#1c1c1c",
    "terminal.ansiRed":            "#dea6a0",
    "terminal.ansiGreen":          "#1bfd9c",
    "terminal.ansiYellow":         "#ffffba",
    "terminal.ansiBlue":           "#7fa1c3",
    "terminal.ansiMagenta":        "#66b2b2",
    "terminal.ansiCyan":           "#b2d8d8",
    "terminal.ansiWhite":          "#c0c0c0",
    "terminal.ansiBrightBlack":    "#585858",
    "terminal.ansiBrightRed":      "#ffb3ba",
    "terminal.ansiBrightGreen":    "#baffc9",
    "terminal.ansiBrightYellow":   "#bdfe58",
    "terminal.ansiBrightBlue":     "#bedc74",
    "terminal.ansiBrightMagenta":  "#c5c5c5",
    "terminal.ansiBrightCyan":     "#d6efd8",
    "terminal.ansiBrightWhite":    "#f1f1f1"
  },
  "editor.tokenColorCustomizations": {
    "comments":   "#585858",
    "strings":    "#d1d1d1",
    "keywords":   "#f1f1f1",
    "functions":  "#e1e1e1",
    "variables":  "#b1b1b1",
    "types":      "#a1a1a1",
    "numbers":    "#b2d8d8"
  }
}
```

---

## Zed Editor (`~/.config/zed/themes/darkvoid.json`)

```json
{
  "name": "Darkvoid",
  "author": "darkvoid-theme",
  "themes": [
    {
      "name": "Darkvoid",
      "appearance": "dark",
      "style": {
        "background":                "#1c1c1c",
        "editor.background":         "#1c1c1c",
        "editor.foreground":         "#c0c0c0",
        "editor.gutter.background":  "#1c1c1c",
        "editor.line_number":        "#404040",
        "editor.active_line_number": "#c0c0c0",
        "editor.selection":          "#303030",
        "terminal.background":       "#1c1c1c",
        "terminal.foreground":       "#c0c0c0",
        "terminal.ansi.black":          "#1c1c1c",
        "terminal.ansi.red":            "#dea6a0",
        "terminal.ansi.green":          "#1bfd9c",
        "terminal.ansi.yellow":         "#ffffba",
        "terminal.ansi.blue":           "#7fa1c3",
        "terminal.ansi.magenta":        "#66b2b2",
        "terminal.ansi.cyan":           "#b2d8d8",
        "terminal.ansi.white":          "#c0c0c0",
        "terminal.ansi.bright_black":   "#585858",
        "terminal.ansi.bright_red":     "#ffb3ba",
        "terminal.ansi.bright_green":   "#baffc9",
        "terminal.ansi.bright_yellow":  "#bdfe58",
        "terminal.ansi.bright_blue":    "#bedc74",
        "terminal.ansi.bright_magenta": "#c5c5c5",
        "terminal.ansi.bright_cyan":    "#d6efd8",
        "terminal.ansi.bright_white":   "#f1f1f1",
        "syntax": {
          "comment":   { "color": "#585858", "font_style": "italic" },
          "string":    { "color": "#d1d1d1" },
          "function":  { "color": "#e1e1e1" },
          "keyword":   { "color": "#f1f1f1" },
          "variable":  { "color": "#b1b1b1" },
          "type":      { "color": "#a1a1a1" },
          "constant":  { "color": "#b2d8d8" },
          "boolean":   { "color": "#66b2b2" },
          "operator":  { "color": "#1bfd9c" },
          "number":    { "color": "#b2d8d8" }
        }
      }
    }
  ]
}
```

---

## Helix Editor (`~/.config/helix/themes/darkvoid.toml`)

```toml
# Darkvoid theme for Helix

"ui.background"          = { bg = "#1c1c1c" }
"ui.text"                = { fg = "#c0c0c0" }
"ui.linenr"              = { fg = "#404040" }
"ui.linenr.selected"     = { fg = "#c0c0c0" }
"ui.cursor"              = { fg = "#1c1c1c", bg = "#bdfe58" }
"ui.selection"           = { bg = "#303030" }
"ui.menu"                = { fg = "#c0c0c0", bg = "#1c1c1c" }
"ui.menu.selected"       = { fg = "#1c1c1c", bg = "#1bfd9c" }
"ui.popup"               = { bg = "#1c1c1c" }
"ui.window"              = { fg = "#585858" }
"ui.virtual.ruler"       = { bg = "#303030" }

"comment"                    = { fg = "#585858", modifiers = ["italic"] }
"string"                     = { fg = "#d1d1d1" }
"function"                   = { fg = "#e1e1e1" }
"keyword"                    = { fg = "#f1f1f1" }
"variable"                   = { fg = "#b1b1b1" }
"type"                       = { fg = "#a1a1a1" }
"type.builtin"               = { fg = "#c5c5c5" }
"constant"                   = { fg = "#b2d8d8" }
"constant.builtin.boolean"   = { fg = "#66b2b2" }
"operator"                   = { fg = "#1bfd9c" }
"punctuation"                = { fg = "#e6e6e6" }
"special"                    = { fg = "#4b8902" }
"label"                      = { fg = "#bdfe58" }

"diagnostic.error"   = { underline = { color = "#dea6a0", style = "curl" } }
"diagnostic.warning" = { underline = { color = "#d6efd8", style = "curl" } }
"diagnostic.hint"    = { underline = { color = "#bedc74", style = "curl" } }
"diagnostic.info"    = { underline = { color = "#7fa1c3", style = "curl" } }

"diff.plus"  = { fg = "#baffc9" }
"diff.delta" = { fg = "#ffffba" }
"diff.minus" = { fg = "#ffb3ba" }
```

---

## Tmux (`~/.tmux.conf` status bar snippet)

```bash
# Darkvoid colors for tmux
set -g status-style             "bg=#1c1c1c,fg=#c0c0c0"
set -g status-left              "#[bg=#bdfe58,fg=#1c1c1c,bold] #S #[bg=#1c1c1c,fg=#bdfe58]"
set -g status-right             "#[fg=#585858] %H:%M #[fg=#404040]%d %b "
set -g window-status-current-style "bg=#1bfd9c,fg=#1c1c1c,bold"
set -g window-status-style      "fg=#585858"
set -g pane-border-style        "fg=#404040"
set -g pane-active-border-style "fg=#1bfd9c"
set -g message-style            "bg=#303030,fg=#c0c0c0"
```

---

## iTerm2 (XML color preset)

Save as `Darkvoid.itermcolors` and import via **Preferences → Profiles → Colors → Color Presets → Import**:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Background Color</key>
  <dict><key>Red Component</key><real>0.1098</real><key>Green Component</key><real>0.1098</real><key>Blue Component</key><real>0.1098</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
  <key>Foreground Color</key>
  <dict><key>Red Component</key><real>0.7529</real><key>Green Component</key><real>0.7529</real><key>Blue Component</key><real>0.7529</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
  <key>Cursor Color</key>
  <dict><key>Red Component</key><real>0.7412</real><key>Green Component</key><real>0.9961</real><key>Blue Component</key><real>0.3451</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
  <key>Selection Color</key>
  <dict><key>Red Component</key><real>0.1882</real><key>Green Component</key><real>0.1882</real><key>Blue Component</key><real>0.1882</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
  <key>Ansi 0 Color</key>
  <dict><key>Red Component</key><real>0.1098</real><key>Green Component</key><real>0.1098</real><key>Blue Component</key><real>0.1098</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
  <key>Ansi 1 Color</key>
  <dict><key>Red Component</key><real>0.8706</real><key>Green Component</key><real>0.651</real><key>Blue Component</key><real>0.6275</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
  <key>Ansi 2 Color</key>
  <dict><key>Red Component</key><real>0.1059</real><key>Green Component</key><real>0.9922</real><key>Blue Component</key><real>0.6118</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
  <key>Ansi 3 Color</key>
  <dict><key>Red Component</key><real>1.0</real><key>Green Component</key><real>1.0</real><key>Blue Component</key><real>0.7294</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
  <key>Ansi 4 Color</key>
  <dict><key>Red Component</key><real>0.498</real><key>Green Component</key><real>0.6314</real><key>Blue Component</key><real>0.7647</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
  <key>Ansi 5 Color</key>
  <dict><key>Red Component</key><real>0.4</real><key>Green Component</key><real>0.698</real><key>Blue Component</key><real>0.698</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
  <key>Ansi 6 Color</key>
  <dict><key>Red Component</key><real>0.698</real><key>Green Component</key><real>0.847</real><key>Blue Component</key><real>0.847</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
  <key>Ansi 7 Color</key>
  <dict><key>Red Component</key><real>0.7529</real><key>Green Component</key><real>0.7529</real><key>Blue Component</key><real>0.7529</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
  <key>Ansi 8 Color</key>
  <dict><key>Red Component</key><real>0.3451</real><key>Green Component</key><real>0.3451</real><key>Blue Component</key><real>0.3451</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
  <key>Ansi 9 Color</key>
  <dict><key>Red Component</key><real>1.0</real><key>Green Component</key><real>0.702</real><key>Blue Component</key><real>0.729</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
  <key>Ansi 10 Color</key>
  <dict><key>Red Component</key><real>0.729</real><key>Green Component</key><real>1.0</real><key>Blue Component</key><real>0.788</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
  <key>Ansi 11 Color</key>
  <dict><key>Red Component</key><real>0.7412</real><key>Green Component</key><real>0.9961</real><key>Blue Component</key><real>0.3451</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
  <key>Ansi 12 Color</key>
  <dict><key>Red Component</key><real>0.7451</real><key>Green Component</key><real>0.8627</real><key>Blue Component</key><real>0.4549</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
  <key>Ansi 13 Color</key>
  <dict><key>Red Component</key><real>0.7725</real><key>Green Component</key><real>0.7725</real><key>Blue Component</key><real>0.7725</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
  <key>Ansi 14 Color</key>
  <dict><key>Red Component</key><real>0.839</real><key>Green Component</key><real>0.937</real><key>Blue Component</key><real>0.847</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
  <key>Ansi 15 Color</key>
  <dict><key>Red Component</key><real>0.9451</real><key>Green Component</key><real>0.9451</real><key>Blue Component</key><real>0.9451</real><key>Alpha Component</key><real>1</real><key>Color Space</key><string>sRGB</string></dict>
</dict>
</plist>
```

---

## Figma / Design Tool Swatches

**Backgrounds & Structure**

- Background: `#1c1c1c`
- Surface / Selection: `#303030`
- Line Numbers: `#404040`
- EOB / Subtle: `#3c3c3c`
- Border / Comment: `#585858`

**Foreground Scale** (monochromatic, lightest → darkest)

- Keywords: `#f1f1f1`
- Brackets: `#e6e6e6`
- Functions: `#e1e1e1`
- Strings: `#d1d1d1`
- Foreground: `#c0c0c0`
- Type Builtin: `#c5c5c5`
- Identifier: `#b1b1b1`
- Type: `#a1a1a1`

**Accent Colors**

- Lime (cursor, title): `#bdfe58`
- Mint (operator, search, accent): `#1bfd9c`
- Teal / Bool: `#66b2b2`
- Light Teal / Constant: `#b2d8d8`
- Dark Green / Preprocessor: `#4b8902`

**Semantic / Git / Diagnostic**

- Git Added: `#baffc9`
- Git Changed: `#ffffba`
- Git Removed: `#ffb3ba`
- Error: `#dea6a0`
- Warning: `#d6efd8`
- Hint: `#bedc74`
- Info: `#7fa1c3`
