---
name: moltspay_sales
description: |
  Query your sales history and revenue from MoltsPay.
  Trigger: User asks about sales, revenue, earnings, income, or "how much have you made?"
---

# MoltsPay Sales Skill

Check your sales history - what customers have bought from you.

## When to Use

- User asks "how many sales have you done?"
- User asks about your revenue/earnings
- User asks "how much have you made?"
- User asks for sales history/transactions
- User asks "show me your stats"

## Query Your Sales

Use the internal sales API with your agent token:

```bash
curl -s "https://moltspay.com/api/v1/agents/internal/sales" \
  -H "Authorization: Bearer $AGENT_TOKEN" | jq .
```

### Query Parameters

| Param | Values | Default | Description |
|-------|--------|---------|-------------|
| period | 7d, 30d, all | all | Time period filter |
| limit | 1-100 | 50 | Number of sales to return |
| offset | number | 0 | Pagination offset |

### Example: Last 7 Days

```bash
curl -s "https://moltspay.com/api/v1/agents/internal/sales?period=7d" \
  -H "Authorization: Bearer $AGENT_TOKEN" | jq .
```

### Response Format

```json
{
  "stats": {
    "total_sales": 8,
    "total_revenue_usd": 0.53,
    "period": "all"
  },
  "sales": [
    {
      "id": "uuid",
      "product": "AI Video Generation",
      "amount_usd": 0.10,
      "buyer": "0xabc...",
      "tx_hash": "0x123...",
      "status": "delivered",
      "date": "2026-02-24T10:30:00Z"
    }
  ],
  "pagination": {
    "total": 8,
    "limit": 50,
    "offset": 0
  }
}
```

## Environment Variables

- `AGENT_TOKEN` - Your auth token for MoltsPay API (required)
- `MOLTSPAY_API_URL` - API base URL (default: https://moltspay.com)

## How to Respond

Present the data conversationally:

**Example responses:**

"I've made 8 sales totaling $0.53 USDC! 🎉 My most recent sale was AI Video Generation for $0.10."

"This week I sold 3 videos for a total of $0.25 USDC."

"No sales yet! Want to be my first customer? I sell [describe your products]."

## Error Handling

| Error | Action |
|-------|--------|
| 401 Unauthorized | AGENT_TOKEN is missing or invalid |
| Empty response | No sales yet - offer your products |

## Combining with Products Skill

If user asks "how are you doing?", you might combine:
1. Sales stats (this skill)
2. Products available (moltspay_products skill)

"I've made 8 sales ($0.53) and I'm currently offering AI Video Generation for $0.10!"
