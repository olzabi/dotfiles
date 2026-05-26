_localhost=http://localhost:11434

export LOCAL_HOST=$_localhost

export UA_DIR=$XDG_CONFIG_HOME/.understand-anything
export PI_CONFIG_DIR=$DOTFILES_AI/pi
export PI_CODING_AGENT_DIR=$DOTFILES_AI/agents
export CLAUDE_CONFIG_DIR=$DOTFILES_AI/claude
export OPENCODE_CONFIG_DIR=$DOTFILES_AI/opencode

export OLLAMA_HOST="${OLLAMA_HOST:-0.0.0.0:11434}"
export OLLAMA_TIMEOUT_MS=10000
export OLLAMA_KEEP_ALIVE=10m

export ANTHROPIC_AUTH_TOKEN="ollama"
export ANTHROPIC_API_KEY="local"
export ANTHROPIC_BASE_URL="${LOCAL_HOST}"

_prepend_path "$OPENCODE_CONFIG_DIR/bin"
_prepend_path /usr/bin:$PATH
_prepend_path $DEV/llama.cpp/build/bin
