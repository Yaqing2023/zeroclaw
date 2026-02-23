#!/bin/sh
# ZeroClaw Docker entrypoint v2 - creates config from env vars
# Version 2: Completely regenerates config each time

CONFIG_DIR="${ZEROCLAW_CONFIG_DIR:-/zeroclaw-data/.zeroclaw}"
CONFIG_FILE="${CONFIG_DIR}/config.toml"

echo "[entrypoint v2] Starting..."
echo "[entrypoint v2] CONFIG_DIR=$CONFIG_DIR"
echo "[entrypoint v2] CONFIG_FILE=$CONFIG_FILE"

# Ensure directory exists
mkdir -p "$CONFIG_DIR"

# Remove any existing config to start fresh
rm -f "$CONFIG_FILE" 2>/dev/null || true

echo "[entrypoint v2] Generating fresh config.toml..."

# Create base config
cat > "$CONFIG_FILE" << 'BASECONFIG'
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
BASECONFIG

# Add Discord config if env vars are set
if [ -n "$ZEROCLAW_DISCORD_BOT_TOKEN" ]; then
    echo "[entrypoint v2] Adding Discord config..."
    cat >> "$CONFIG_FILE" << EOF

[channels_config.discord]
bot_token = "$ZEROCLAW_DISCORD_BOT_TOKEN"
EOF

    if [ -n "$ZEROCLAW_DISCORD_GUILD_ID" ]; then
        echo "guild_id = \"$ZEROCLAW_DISCORD_GUILD_ID\"" >> "$CONFIG_FILE"
    fi
    
    if [ -n "$ZEROCLAW_DISCORD_ALLOWED_USERS" ] && [ "$ZEROCLAW_DISCORD_ALLOWED_USERS" != "" ]; then
        USERS_ARRAY=$(echo "$ZEROCLAW_DISCORD_ALLOWED_USERS" | sed 's/,/", "/g')
        echo "allowed_users = [\"$USERS_ARRAY\"]" >> "$CONFIG_FILE"
    else
        echo "allowed_users = []" >> "$CONFIG_FILE"
    fi
    
    echo "listen_to_bots = ${ZEROCLAW_DISCORD_LISTEN_TO_BOTS:-false}" >> "$CONFIG_FILE"
    echo "mention_only = ${ZEROCLAW_DISCORD_MENTION_ONLY:-false}" >> "$CONFIG_FILE"
fi

echo "[entrypoint v2] Config generated successfully:"
echo "----------------------------------------"
cat "$CONFIG_FILE"
echo "----------------------------------------"
echo "[entrypoint v2] Starting ZeroClaw..."

# Execute the main command
exec "$@"
