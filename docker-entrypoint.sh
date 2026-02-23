#!/bin/sh
# ZeroClaw Docker entrypoint v3 - uses inline table format for discord
# Version 3: Uses inline format to avoid duplicate key issues

CONFIG_DIR="${ZEROCLAW_CONFIG_DIR:-/zeroclaw-data/.zeroclaw}"
CONFIG_FILE="${CONFIG_DIR}/config.toml"

echo "[entrypoint v3] Starting..."

# Ensure directory exists and remove any existing config
mkdir -p "$CONFIG_DIR"
rm -f "$CONFIG_FILE" 2>/dev/null || true

echo "[entrypoint v3] Generating fresh config.toml..."

# Build Discord config inline if set
DISCORD_INLINE=""
if [ -n "$ZEROCLAW_DISCORD_BOT_TOKEN" ]; then
    echo "[entrypoint v3] Building Discord config..."
    DISCORD_INLINE="discord = { bot_token = \"$ZEROCLAW_DISCORD_BOT_TOKEN\""
    
    if [ -n "$ZEROCLAW_DISCORD_GUILD_ID" ]; then
        DISCORD_INLINE="$DISCORD_INLINE, guild_id = \"$ZEROCLAW_DISCORD_GUILD_ID\""
    fi
    
    DISCORD_INLINE="$DISCORD_INLINE, allowed_users = [], listen_to_bots = false, mention_only = false }"
fi

# Create config with optional Discord inline
cat > "$CONFIG_FILE" << EOF
workspace_dir = "/zeroclaw-data/workspace"
config_path = "/zeroclaw-data/.zeroclaw/config.toml"
api_key = ""
default_provider = "anthropic"
default_model = "claude-sonnet-4-5-20250929"
default_temperature = 0.7

[gateway]
port = 8080
host = "[::]"
allow_public_bind = true
require_pairing = false

[channels_config]
cli = true
message_timeout_secs = 300
$DISCORD_INLINE
EOF

echo "[entrypoint v3] Config generated:"
echo "----------------------------------------"
cat "$CONFIG_FILE"
echo "----------------------------------------"
echo "[entrypoint v3] Starting ZeroClaw..."

exec "$@"
