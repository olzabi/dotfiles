# shellcheck shell=bash disable=SC2154
# herdr-core respawns a lost terminal (reboot, core crash) as a bare shell in its last folder. If Claude was
# running in it (label set by agents/claude/hooks/herdr-claude-session.sh), resume that session at the first prompt.
if [[ -o interactive && -n $HC_TERMINAL_ID && -z $CLAUDE_JOB_DIR ]] && (( $+commands[hc] && $+commands[jq] )); then
  _hc_claude_resume() {
    add-zsh-hook -d precmd _hc_claude_resume
    unfunction _hc_claude_resume
    local -a v
    v=("${(@f)$(hc get --json "$HC_TERMINAL_ID" 2>/dev/null |
      jq -r '.pid, (.labels["claude.session"] // ""), (.labels["claude.cwd"] // "")')}")
    # only the terminal's own shell, not a zsh started inside it
    [[ $v[1] == "$$" && -n $v[2] ]] || return 0
    [[ -d $v[3] ]] && cd -- "$v[3]"
    claude --resume "$v[2]"
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _hc_claude_resume
fi
