ZSH_THEME_NVM_PROMPT=true
ZSH_THEME_GIT_PROMPT_PREFIX="%F{cyan}%B"
ZSH_THEME_GIT_PROMPT_SUFFIX="%f%b "
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY="%F{red}*%f"
ZSH_THEME_NVM_PROMPT_PREFIX="[node: %F{70}"
ZSH_THEME_NVM_PROMPT_SUFFIX="%f]"
# ---------
nvm_info() {
  [[ -f package.json || -f .nvmrc || -f .node-version ]] || return;
  echo "$(nvm_prompt_info)"
}

php_prompt_info() {
  [[ -f composer.json || -f composer.lock || -f artisan || -f index.php ]] || return
  type phpenv &>/dev/null || return
  local php_version
  php_version=$(phpenv version-name 2>/dev/null)
  [[ -z "$php_version" || "$php_version" == "system" ]] && return
  echo "%F{white}[php: %F{magenta}${php_version}%f%F{white}]%f"
}

go_prompt_info() {
  [[ -f go.mod || -f go.sum ]] || return
  type go &>/dev/null || return
  local go_ver
  go_ver=$(go version 2>/dev/null | sed -E 's/.*go([0-9]+\.[0-9]+).*/\1/')
  [[ -z $go_ver ]] && return
  echo "%F{white}[go: %F{yellow}${go_ver}%f%F{white}]%f"
}

rust_prompt_info() {
    [[ -f Cargo.toml || -f Cargo.lock ]] || return
  type rustc &>/dev/null || return
  local rust_version
  rust_version=$(rustc --version 2>/dev/null | awk '{print $2}')
  [[ -z $rust_version ]] && return
  echo "%F{white}[rust: %F{yellow}${rust_version}%f%F{white}]%f"
}

kubectx_prompt_info() {
  local current=$(kubectl config current-context 2>/dev/null)
  [[ -z $current ]] && return
  local cluster=${current##*/}
  echo "%F{white}[kctx: %F{red}${cluster}%f%F{white}]%f"
}

  # ---------
aws_prompt_info() {
  local profile="${AWS_PROFILE:-default}"
  [[ $profile == default ]] && return
  echo "%F{white}[aws: %F{yellow}${profile}%f%F{white}]%f"
}

virtualenv_info() {
  [[ -z $VIRTUAL_ENV ]] && return
  echo "%F{white}[venv: %F{cyan}${VIRTUAL_ENV:t}%f%F{white}]%f"
}

ssh_info() {
    [[ -n $SSH_TTY ]] && echo "%F{white}[ssh: %m]%f"
}

# ---------
get_space() {
  local STR=$1$2
  local zero='%([BSUbfksu]|([FB]|){*})'
  local LENGTH=${#${(S%%)STR//$~zero/}}
  local SPACES=""
  (( LENGTH = ${COLUMNS} - $LENGTH - 1))
  for i in {0..$LENGTH}
    do
      SPACES="$SPACES "
    done
  echo $SPACES
}
_1LEFT="$(git_prompt_info)$(virtualenv_info)"
_1RIGHT="$(aws_prompt_info)$(ssh_info)"

precmd() {
  _1SPACES=`get_space $_1LEFT $_1RIGHT`
  print
  print -rP "$_1LEFT$_1SPACES$_1RIGHT"
}

prompt_char() {
  echo "%(?.%F{green}.%F{red})::%f "
}

# ---------
setopt PROMPT_SUBST
PROMPT="%B%F{yellow}%20<...<%~%f%b
$(prompt_char)"
RPROMPT="$(aws_prompt_info)$(kubectx_prompt_info)$(rust_prompt_info)$(php_prompt_info)$(go_prompt_info)$(nvm_info)"
# ---------

autoload -U add-zsh-hook

