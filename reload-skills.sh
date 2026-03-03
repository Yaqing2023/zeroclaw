#!/bin/sh
# Reload skills from MoltsPay backend
# Called by /api/reload-skills endpoint

WORKSPACE_DIR="${ZEROCLAW_WORKSPACE:-/zeroclaw-data/workspace}"
MOLTSPAY_API_URL="${MOLTSPAY_API_URL:-https://moltspay.com}"
AGENT_TOKEN="${AGENT_TOKEN:-}"

if [ -z "$AGENT_TOKEN" ]; then
    echo '{"error": "AGENT_TOKEN not set"}'
    exit 1
fi

echo "[reload-skills] Fetching skills from $MOLTSPAY_API_URL..."

SKILLS_RESPONSE=$(curl -s "$MOLTSPAY_API_URL/api/v1/agents/internal/skills" \
    -H "Authorization: Bearer $AGENT_TOKEN" 2>/dev/null)

if [ -z "$SKILLS_RESPONSE" ]; then
    echo '{"error": "Failed to fetch skills"}'
    exit 1
fi

SKILL_COUNT=$(printf '%s' "$SKILLS_RESPONSE" | jq -r '.skills | length' 2>/dev/null) || true

if [ -z "$SKILL_COUNT" ] || [ "$SKILL_COUNT" = "null" ] || [ "$SKILL_COUNT" -eq 0 ]; then
    echo '{"ok": true, "installed": 0, "message": "No skills to install"}'
    exit 0
fi

mkdir -p "$WORKSPACE_DIR/skills"
INSTALLED=0

for i in $(seq 0 $((SKILL_COUNT - 1))); do
    SKILL_NAME=$(printf '%s' "$SKILLS_RESPONSE" | jq -r ".skills[$i].name" 2>/dev/null) || true
    SKILL_CONTENT=$(printf '%s' "$SKILLS_RESPONSE" | jq -r ".skills[$i].content" 2>/dev/null) || true
    
    if [ -n "$SKILL_NAME" ] && [ "$SKILL_NAME" != "null" ] && [ -n "$SKILL_CONTENT" ] && [ "$SKILL_CONTENT" != "null" ]; then
        SAFE_NAME=$(echo "$SKILL_NAME" | sed 's/[^a-zA-Z0-9_-]//g' | cut -c1-50)
        [ -z "$SAFE_NAME" ] && SAFE_NAME="skill_$i"
        
        SKILL_DIR="$WORKSPACE_DIR/skills/$SAFE_NAME"
        mkdir -p "$SKILL_DIR"
        echo "$SKILL_CONTENT" > "$SKILL_DIR/SKILL.md"
        INSTALLED=$((INSTALLED + 1))
        echo "[reload-skills] Installed: $SKILL_NAME -> $SAFE_NAME"
    fi
done

echo "{\"ok\": true, \"installed\": $INSTALLED}"
