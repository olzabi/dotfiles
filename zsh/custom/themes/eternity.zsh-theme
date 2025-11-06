nvm_prompt_info() {
  # Check for Node.js project files
  if [[ ! -f "package.json" ]] && [[ ! -f ".nvmrc" ]] && [[ ! -f ".node-version" ]]; then
    return
  fi

  local nvm_prompt
  if type nvm &>/dev/null; then
    nvm_prompt=$(nvm current 2>/dev/null)
    [[ "$nvm_prompt" != "system" ]] && [[ "$nvm_prompt" != "none" ]] && echo "${ZSH_THEME_NVM_PROMPT_PREFIX}${nvm_prompt}${ZSH_THEME_NVM_PROMPT_SUFFIX}"
  elif type node &>/dev/null; then
    local node_version=$(node -v 2>/dev/null)
    [[ -n "$node_version" ]] && echo "${ZSH_THEME_NVM_PROMPT_PREFIX}${node_version}${ZSH_THEME_NVM_PROMPT_SUFFIX}"
  fi
}

python_prompt_info() {
  # Check for Python project files
  if [[ ! -f "requirements.txt" ]] && [[ ! -f "Pipfile" ]] && [[ ! -f "pyproject.toml" ]] && [[ ! -f "setup.py" ]] && [[ ! -f ".python-version" ]] && [[ -z "$VIRTUAL_ENV" ]]; then
    return
  fi

  local python_version
  if type python &>/dev/null; then
    python_version=$(python --version 2>&1 | awk '{print $2}')
    [[ -n "$python_version" ]] && echo "%{$fg[blue]%}🐍 ${python_version}%{$reset_color%}"
  fi
}

ruby_prompt_info() {
  # Check for Ruby project files
  if [[ ! -f "Gemfile" ]] && [[ ! -f ".ruby-version" ]] && [[ ! -f "Rakefile" ]]; then
    return
  fi

  if type ruby &>/dev/null; then
    local ruby_version=$(ruby -v 2>/dev/null | awk '{print $2}')
    [[ -n "$ruby_version" ]] && echo "%{$fg[red]%}💎 ${ruby_version}%{$reset_color%}"
  fi
}

go_prompt_info() {
  # Check for Go project files
  if [[ ! -f "go.mod" ]] && [[ ! -f "go.sum" ]]; then
    return
  fi

  if type go &>/dev/null; then
    local go_version=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')
    [[ -n "$go_version" ]] && echo "%{$fg[cyan]%}🐹 ${go_version}%{$reset_color%}"
  fi
}

rust_prompt_info() {
  # Check for Rust project files
  if [[ ! -f "Cargo.toml" ]] && [[ ! -f "Cargo.lock" ]]; then
    return
  fi

  if type rustc &>/dev/null; then
    local rust_version=$(rustc --version 2>/dev/null | awk '{print $2}')
    [[ -n "$rust_version" ]] && echo "%{$fg[yellow]%}🦀 ${rust_version}%{$reset_color%}"
  fi
}

java_prompt_info() {
  if [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]] || type java &>/dev/null; then
    local java_version=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')
    [[ -n "$java_version" ]] && echo "%{$fg[red]%}☕ ${java_version}%{$reset_color%}"
  fi
}

php_prompt_info() {
  if [[ -f "composer.json" ]] || type php &>/dev/null; then
    local php_version=$(php -v 2>/dev/null | head -n 1 | awk '{print $2}')
    [[ -n "$php_version" ]] && echo "%{$fg[magenta]%}🐘 ${php_version}%{$reset_color%}"
  fi
}

terraform_prompt_info() {
  if [[ -f "*.tf" ]] || type terraform &>/dev/null; then
    local tf_version=$(terraform version 2>/dev/null | head -n 1 | awk '{print $2}' | sed 's/v//')
    [[ -n "$tf_version" ]] && echo "%{$fg[magenta]%}🏗️  ${tf_version}%{$reset_color%}"
  fi
}

k8s_prompt_info() {
  if type kubectl &>/dev/null; then
    local k8s_context=$(kubectl config current-context 2>/dev/null)
    [[ -n "$k8s_context" ]] && echo "%{$fg[blue]%}☸️  ${k8s_context}%{$reset_color%}"
  fi
}

get_docker_host() {
  local logo="\uf21f"
  DOCKER_THEME_PROMPT="%{$fg_bold[blue]%}$logo%{$reset_color%}"
  DOCKER_LOCAL_COLOR="green"
  DOCKER_REMOTE_COLOR="red"
  local _docker_local="%{$fg_bold[$DOCKER_LOCAL_COLOR]%}local%{$reset_color%}"
  local _docker_remote="%{$fg_bold[$DOCKER_REMOTE_COLOR]%}$DOCKER_HOST%{$reset_color%}"
  local _docker_status="$_docker_remote"
  if [[ -z "$DOCKER_HOST" ]]; then
    _docker_status="$_docker_local"
  fi
  echo "$DOCKER_THEME_PROMPT :$_docker_status"
}

aws_prompt_info() {
  [[ -n "$AWS_PROFILE" ]] && echo "%{$fg[yellow]%}☁️  ${AWS_PROFILE}%{$reset_color%}"
}

all_versions_info() {
  local versions=""
  local node_info=$(nvm_prompt_info)
  local python_info=$(python_prompt_info)
  local ruby_info=$(ruby_prompt_info)
  local go_info=$(go_prompt_info)
  local rust_info=$(rust_prompt_info)
  local java_info=$(java_prompt_info)
  local php_info=$(php_prompt_info)
  local tf_info=$(terraform_prompt_info)
  local aws_info=$(aws_prompt_info)
  local k8s_info=$(k8s_prompt_info)

  # Concatenate non-empty version info
  [[ -n "$node_info" ]] && versions+=" $node_info"
  [[ -n "$python_info" ]] && versions+=" $python_info"
  [[ -n "$ruby_info" ]] && versions+=" $ruby_info"
  [[ -n "$go_info" ]] && versions+=" $go_info"
  [[ -n "$rust_info" ]] && versions+=" $rust_info"
  # [[ -n "$java_info" ]] && versions+=" $java_info"
  [[ -n "$php_info" ]] && versions+=" $php_info"
  [[ -n "$tf_info" ]] && versions+=" $tf_info"
  [[ -n "$aws_info" ]] && versions+=" $aws_info"
  [[ -n "$k8s_info" ]] && versions+=" $k8s_info"

  echo "$versions"
}

function prompt_char {
  git branch >/dev/null 2>/dev/null && echo '> ' && return
  hg root >/dev/null 2>/dev/null && echo 'Hg' && return
  echo '> '
}

function virtualenv_info {
  [[ -n "$VIRTUAL_ENV" ]] && echo '('${VIRTUAL_ENV:t}') '
}

username="%F{magenta}%B%n%b%{$reset_color%}"
working_dir="%B%F{green}%20<...<%~%f%b"
base="[$username:$working_dir]"
base_prompt="$base $(virtualenv_info)$reset_color"

PROMPT='${base_prompt}
$(git_prompt_info)$(prompt_char)'

RPROMPT='$(get_docker_host)$(all_versions_info)%{$reset_color%}'

ZSH_THEME_NVM_PROMPT_PREFIX="%{$fg[green]%}⬢ "
ZSH_THEME_NVM_PROMPT_SUFFIX=""
ZSH_THEME_NVM_PROMPT=true

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_no_bold[yellow]%}%B"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg_bold[red]%}*"
