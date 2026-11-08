# herdr-side colours. Sourced by bin/herdr-side and side/lib.sh; edit here to restyle every section.
# Palette = herdr's [theme.custom] in editor/herdr/config.toml.
hex() { printf '\033[38;2;%d;%d;%dm' "0x${1:1:2}" "0x${1:3:2}" "0x${1:5:2}"; } # hex "#83b7ad" -> fg escape

R=$'\033[0m' B=$'\033[1m' IT=$'\033[3m'
TEXT=$(hex "#c0c0c0")  # fg
MUTED=$(hex "#585858") # comment: secondary text, repo sub-headers, rules
ACC=$(hex "#83b7ad")   # accent: focused workspace/agent
WARN=$(hex "#ffffba")  # warning: attention section, working agents
ERR=$(hex "#dea6a0")   # error: blocked, failed
OK=$(hex "#baffc9")    # ok: idle, passed
INFO=$(hex "#7fa1c3")  # info: done/unseen

# Sections that keep their colours; every other section is drawn plain (bold/italic/dim stay).
SIDE_COLORED="attention agents"
# Per-section title colour (default: TEXT) and a rule drawn under the section.
SIDE_TITLE_attention=$WARN
SIDE_RULE_attention=1
