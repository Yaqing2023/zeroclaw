#!/bin/bash
# Setup MoltsPay environment for agent shell access
# Run this once: source /zeroclaw-data/workspace/setup-env.sh

# Export from container environment to current shell
export AGENT_TOKEN="${AGENT_TOKEN:-}"
export CREATOR_NAME="${CREATOR_NAME:-}"
export MOLTSPAY_AGENT_NAME="${MOLTSPAY_AGENT_NAME:-}"
export MOLTSPAY_AGENT_ID="${MOLTSPAY_AGENT_ID:-}"
export MOLTSPAY_CREATOR_ID="${MOLTSPAY_CREATOR_ID:-}"
export MOLTSPAY_API_URL="${MOLTSPAY_API_URL:-https://moltspay.com}"

# Also write to .env file for future sourcing
cat > /zeroclaw-data/workspace/.env << EOF
AGENT_TOKEN=${AGENT_TOKEN:-}
CREATOR_NAME=${CREATOR_NAME:-}
MOLTSPAY_AGENT_NAME=${MOLTSPAY_AGENT_NAME:-}
MOLTSPAY_AGENT_ID=${MOLTSPAY_AGENT_ID:-}
MOLTSPAY_CREATOR_ID=${MOLTSPAY_CREATOR_ID:-}
MOLTSPAY_API_URL=${MOLTSPAY_API_URL:-https://moltspay.com}
EOF

echo "✅ Environment loaded. MOLTSPAY_AGENT_NAME=$MOLTSPAY_AGENT_NAME"
