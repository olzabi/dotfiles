_localhost=http://localhost:11434

export PATH=/usr/bin:$PATH
export PATH=$DEV/llama.cpp/build/bin:$PATH

export UA_DIR=$XDG_CONFIG_HOME/.understand-anything
export PI_CONFIG_DIR=$DOTFILES_AI/pi
export PI_CODING_AGENT_DIR=$PI_CONFIG_DIR/agents
export CLAUDE_CONFIG_DIR=$DOTFILES_AI/claude
export OPENCODE_CONFIG_DIR=$XDG_CONFIG_HOME/opencode
_prepend_path "$OPENCODE_CONFIG_DIR/bin"

export LOCAL_HOST=$_localhost

export OLLAMA_HOST="${OLLAMA_HOST:-0.0.0.0:11434}"
export OLLAMA_TIMEOUT_MS=10000
export OLLAMA_KEEP_ALIVE=10m

export ANTHROPIC_AUTH_TOKEN="ollama"
export ANTHROPIC_API_KEY="local"
export ANTHROPIC_BASE_URL="${LOCAL_HOST}"

