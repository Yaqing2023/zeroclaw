# API Reference

This document covers ZeroClaw's HTTP API endpoints exposed by the gateway server.

## Quick Summary

| Endpoint | Method | Auth | Tool Execution | Description |
|----------|--------|------|----------------|-------------|
| `/webhook` | POST | Bearer / X-Webhook-Secret | ❌ No | Simple chat (no tools) |
| `/pair` | POST | — | — | Pairing authentication |
| `/health` | GET | — | — | Health check |
| `/metrics` | GET | — | — | Prometheus metrics |
| `/api/status` | GET | Bearer | — | System status |
| `/api/config` | GET | Bearer | — | Get config (masked) |
| `/api/config` | PUT | Bearer | — | Update config |
| `/api/tools` | GET | Bearer | — | List tools (read-only) |
| `/api/cron` | GET | Bearer | — | List cron jobs |
| `/api/cron` | POST | Bearer | — | Add cron job |
| `/api/cron/{id}` | DELETE | Bearer | — | Delete cron job |
| `/api/integrations` | GET | Bearer | — | List integrations |
| `/api/doctor` | POST | Bearer | — | Run diagnostics |
| `/api/memory` | GET | Bearer | — | List/search memory |
| `/api/memory` | POST | Bearer | — | Store memory |
| `/api/memory/{key}` | DELETE | Bearer | — | Delete memory |
| `/api/cost` | GET | Bearer | — | Cost statistics |
| `/api/cli-tools` | GET | Bearer | — | Discovered CLI tools |
| `/api/health` | GET | Bearer | — | Component health |
| `/api/chat` | POST | Bearer | ⚠️ TODO | Simple chat (WIP) |
| `/api/events` | GET | Bearer | — | SSE event stream |
| `/ws/chat` | WebSocket | Query token | ✅ Yes | Full agent with tools |
| `/whatsapp` | GET/POST | — | ✅ Yes | WhatsApp webhook |
| `/linq` | POST | — | ✅ Yes | Linq webhook |
| `/nextcloud-talk` | POST | — | ✅ Yes | Nextcloud Talk webhook |

---

## Authentication

### Bearer Token (Pairing)

Most `/api/*` endpoints require a bearer token obtained via `/pair`:

```bash
# Get token
curl -X POST http://localhost:3000/pair

# Use token
curl -H "Authorization: Bearer <token>" http://localhost:3000/api/status
```

### Webhook Secret (Optional)

For `/webhook`, you can configure an additional `X-Webhook-Secret` header:

```toml
[channels_config.webhook]
secret = "your-secret-here"
```

```bash
curl -X POST http://localhost:3000/webhook \
  -H "Authorization: Bearer <token>" \
  -H "X-Webhook-Secret: your-secret-here" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello"}'
```

---

## Endpoints

### POST /webhook

Simple chat endpoint. **Does not execute tools** — designed for backward compatibility and testing.

**Request:**
```json
{"message": "your prompt"}
```

**Headers:**
- `Authorization: Bearer <token>` (if pairing enabled)
- `X-Webhook-Secret: <secret>` (optional)
- `X-Idempotency-Key: <key>` (optional, for deduplication)

**Response:**
```json
{
  "response": "LLM response text",
  "model": "claude-sonnet-4-20250514"
}
```

**Note:** This endpoint calls `run_gateway_chat_simple()` which explicitly skips tool execution. For full agent capabilities, use WebSocket `/ws/chat` or a real channel (Telegram, Discord, etc.).

---

### GET /ws/chat

WebSocket endpoint for full agent chat **with tool execution**.

**Connection:**
```
ws://localhost:3000/ws/chat?token=<bearer_token>
```

**Protocol:**
```
Client → Server: {"type":"message","content":"Hello"}
Server → Client: {"type":"chunk","content":"Hi! "}
Server → Client: {"type":"tool_call","name":"shell","args":{...}}
Server → Client: {"type":"tool_result","name":"shell","output":"..."}
Server → Client: {"type":"done","full_response":"..."}
```

---

### POST /pair

Obtain a bearer token for API authentication.

**Response:**
```json
{
  "token": "abc123...",
  "expires_at": null
}
```

---

### GET /api/status

System status overview.

**Response:**
```json
{
  "provider": "anthropic",
  "model": "claude-sonnet-4-20250514",
  "temperature": 0.7,
  "uptime_seconds": 3600,
  "gateway_port": 3000,
  "memory_backend": "sqlite",
  "paired": true,
  "channels": {
    "telegram": true,
    "discord": false,
    "webhook": true
  },
  "health": {...}
}
```

---

### GET /api/tools

List registered tool specifications (read-only).

**Response:**
```json
{
  "tools": [
    {
      "name": "shell",
      "description": "Execute terminal commands...",
      "parameters": {...}
    }
  ]
}
```

**Note:** This endpoint only lists tools. There is no API to execute tools directly — tools are executed automatically within the agent loop.

---

### GET /api/memory

List or search memory entries.

**Query Parameters:**
- `query` — semantic search query
- `category` — filter by category (`core`, `daily`, `conversation`, or custom)

**Response:**
```json
{
  "entries": [
    {"key": "...", "content": "...", "category": "core"}
  ]
}
```

---

### POST /api/memory

Store a memory entry.

**Request:**
```json
{
  "key": "my-key",
  "content": "content to store",
  "category": "core"
}
```

---

### GET /api/cron

List cron jobs.

**Response:**
```json
{
  "jobs": [
    {"id": "...", "name": "...", "schedule": "0 9 * * *", "command": "..."}
  ]
}
```

---

### POST /api/cron

Add a cron job.

**Request:**
```json
{
  "name": "daily-check",
  "schedule": "0 9 * * *",
  "command": "check something"
}
```

---

### GET /api/cost

Cost tracking summary.

**Response:**
```json
{
  "cost": {
    "session_cost_usd": 0.05,
    "daily_cost_usd": 1.20,
    "monthly_cost_usd": 15.00,
    "total_tokens": 50000,
    "request_count": 100,
    "by_model": {...}
  }
}
```

---

### GET /api/events

Server-Sent Events (SSE) stream for real-time updates.

**Events:**
- `agent_start` — agent processing started
- `agent_end` — agent processing completed
- `tool_call` — tool invocation
- `tool_result` — tool result

---

## What's NOT Available

### No Session Management API

ZeroClaw does not expose session management endpoints:
- No `/api/sessions` list
- No `/api/session/:id` CRUD
- Sessions are managed internally per-channel

### No Direct Tool Execution API

Tools cannot be executed via API. They are:
- Executed automatically within the agent loop
- Triggered by LLM decisions during conversation
- Visible via WebSocket (`tool_call`/`tool_result` messages) but not controllable

If you need external tool triggering, consider:
1. Using WebSocket `/ws/chat` for full agent interaction
2. Extending the codebase to add custom endpoints

---

## Channel Comparison

| Channel | Tool Execution | Connection Type |
|---------|----------------|-----------------|
| CLI | ✅ Yes | Interactive |
| Telegram | ✅ Yes | Polling/Webhook |
| Discord | ✅ Yes | Gateway |
| Slack | ✅ Yes | Events API |
| WhatsApp | ✅ Yes | Cloud API/Web |
| Signal | ✅ Yes | signal-cli |
| Matrix | ✅ Yes | Sync |
| Email | ✅ Yes | IMAP/SMTP |
| IRC | ✅ Yes | IRC protocol |
| Lark/Feishu | ✅ Yes | Events API |
| DingTalk | ✅ Yes | Events API |
| QQ | ✅ Yes | Official Bot API |
| Nostr | ✅ Yes | Nostr protocol |
| **Webhook** | ❌ No | HTTP POST |

All real channels support the full agent loop with tool execution. Only the `/webhook` HTTP endpoint is simplified (no tools).
