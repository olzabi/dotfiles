export PATH=/usr/bin:$PATH llmfit
export PATH=$DEV/llama.cpp/build/bin:$PATH

export LOCAL_HOST="http://localhost:11434"

export OLLAMA_HOST="${OLLAMA_HOST:-0.0.0.0:11434}"
export OLLAMA_TIMEOUT_MS=10000
export OLLAMA_KEEP_ALIVE=10m

export ANTHROPIC_AUTH_TOKEN="ollama"
export ANTHROPIC_API_KEY="local"
export ANTHROPIC_BASE_URL="${LOCAL_HOST}"
