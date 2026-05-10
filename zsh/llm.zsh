export PATH=/usr/bin:$PATH llmfit
export PATH=$DEV/llama.cpp/build/bin:$PATH
export PATH=$XDG_CONFIG_HOME/.opencode/bin:$PATH

export PI_CONFIG_DIR="$XDG_CONFIG_HOME/.pi"
export PI_CODING_AGENT_DIR=$XDG_CONFIG_HOME/.agents
export CLAUDE_CONFIG_DIR=$XDG_CONFIG_HOME/.claude

export LOCAL_HOST="http://localhost:11434"

export OLLAMA_HOST="${OLLAMA_HOST:-0.0.0.0:11434}"
export OLLAMA_TIMEOUT_MS=10000
export OLLAMA_KEEP_ALIVE=10m

export ANTHROPIC_AUTH_TOKEN="ollama"
export ANTHROPIC_API_KEY="local"
export ANTHROPIC_BASE_URL="${LOCAL_HOST}"
