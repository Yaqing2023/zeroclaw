#!/bin/sh
# ZeroClaw Docker entrypoint - handles config injection from env vars

CONFIG_FILE="${ZEROCLAW_CONFIG_DIR:-/zeroclaw-data/.zeroclaw}/config.toml"

# Add Discord config if env vars are set
if [ -n "$ZEROCLAW_DISCORD_BOT_TOKEN" ]; then
    echo "" >> "$CONFIG_FILE"
    echo "[channels_config.discord]" >> "$CONFIG_FILE"
    echo "bot_token = \"$ZEROCLAW_DISCORD_BOT_TOKEN\"" >> "$CONFIG_FILE"
    
    if [ -n "$ZEROCLAW_DISCORD_GUILD_ID" ]; then
        echo "guild_id = \"$ZEROCLAW_DISCORD_GUILD_ID\"" >> "$CONFIG_FILE"
    fi
    
    # allowed_users - comma-separated list or empty for open
    if [ -n "$ZEROCLAW_DISCORD_ALLOWED_USERS" ]; then
        # Convert comma-separated to TOML array: "a,b,c" -> ["a", "b", "c"]
        USERS_ARRAY=$(echo "$ZEROCLAW_DISCORD_ALLOWED_USERS" | sed 's/,/", "/g')
        echo "allowed_users = [\"$USERS_ARRAY\"]" >> "$CONFIG_FILE"
    else
        echo "allowed_users = []" >> "$CONFIG_FILE"
    fi
    
    echo "listen_to_bots = ${ZEROCLAW_DISCORD_LISTEN_TO_BOTS:-false}" >> "$CONFIG_FILE"
    echo "mention_only = ${ZEROCLAW_DISCORD_MENTION_ONLY:-false}" >> "$CONFIG_FILE"
    
    echo "[entrypoint] Discord config injected"
fi

# Execute the main command
exec "$@"
