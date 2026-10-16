# ---
v() {
  local cfg="$2"
  case "$1" in
    up)      openvpn3 session-start --config "$cfg" ;;
    down)    openvpn3 session-manage --config "$cfg" --disconnect ;;
    down!)   openvpn3 session-manage --config "$cfg" --disconnect --force ;;
    pause)   openvpn3 session-manage --config "$cfg" --pause ;;
    resume)  openvpn3 session-manage --config "$cfg" --resume ;;
    stat)    openvpn3 session-stat --config "$cfg" ;;
    log)     openvpn3 log --config "$cfg" ;;
    show)    openvpn3 config-show --config "$cfg" ;;
    ls)      openvpn3 sessions-list ;;
    cfgs)    openvpn3 configs-list ;;
    import)  openvpn3 config-import --config "$2" --name "$3" --persistent ;;
    *) echo "usage: v {up|down|down!|pause|resume|stat|log|show|ls|cfgs|import} [config-name]" ;;
  esac
}
_v() {
  local -a subcmds
  subcmds=(
    'up:start a VPN session'
    'down:disconnect a session'
    'down\!:force-disconnect a stuck session'
    'pause:pause a session'
    'resume:resume a paused session'
    'stat:show live session stats'
    'log:tail session logs'
    'show:show config details'
    'ls:list active sessions'
    'cfgs:list imported configs'
    'import:import a new .ovpn config'
    'help:show usage'
  )

  local curcontext="$curcontext" state

  _arguments -C \
    '1: :->cmd' \
    '2: :->cfg'

  case $state in
    cmd)
      _describe -t commands 'v subcommand' subcmds
      ;;
    cfg)
      local -a cfgs
      cfgs=(${(f)"$(openvpn3 configs-list 2>/dev/null | awk 'NR>2{print $1}')"})
      compadd -a cfgs
      ;;
  esac
}

compdef _v v
# ---
