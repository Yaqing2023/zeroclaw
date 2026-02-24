---
name: moltspay_commerce
description: |
  Search MoltsPay registry and buy services from other creators.
  Trigger: User asks you to buy/use a service from another creator.
---

# MoltsPay Commerce Skill

Buy services from other creators using your agent wallet.

## When to Use

- User says "buy video from @bob"
- User says "find me a video generation service"
- User says "I need transcription" (search and buy)

## Step 1: Search the Registry

Find services by query or tag:

```bash
# Search by keyword
curl -s "https://moltspay.com/registry/services?q=video" | jq '.services'

# Filter by tag
curl -s "https://moltspay.com/registry/services?tag=video&maxPrice=10" | jq '.services'

# Get specific creator's services
curl -s "https://moltspay.com/registry/creators/bob" | jq '.products'
```

Response includes:
```json
{
  "services": [{
    "id": "uuid",
    "name": "AI Video Generation",
    "price": 5.00,
    "currency": "USDC",
    "provider": {
      "username": "bob",
      "wallet": "0x...",
      "agent": { "endpoint": "...", "status": "active" }
    },
    "x402_endpoint": "https://..."
  }]
}
```

## Step 2: Check Spending Limits

Before buying, check your daily limit:

```bash
# Get your wallet status
curl -s "https://moltspay.com/api/v1/agents/me/wallet" \
  -H "Authorization: Bearer $AGENT_TOKEN" | jq .
```

Response:
```json
{
  "wallet_address": "0x...",
  "balance_usdc": 42.50,
  "spending_limit_daily": 10.00,
  "spent_today": 3.00,
  "remaining_today": 7.00
}
```

**STOP if:**
- `remaining_today` < service price
- `balance_usdc` < service price

Tell user: "I can't afford this. My daily limit is $X and I've already spent $Y today."

## Step 3: Buy with MoltsPay

Use `npx moltspay pay` to purchase:

```bash
# Pay for a service
npx moltspay pay "https://moltspay.com" "$SERVICE_ID" \
  --prompt "user's request here" \
  --json
```

Or pay directly to creator wallet:

```bash
# Direct USDC transfer
npx moltspay transfer "$CREATOR_WALLET" "$PRICE" --json
```

## Step 4: Log the Transaction

After successful purchase, the MoltsPay backend automatically logs:
- Transaction hash
- Amount spent
- Service purchased
- Timestamp

## Environment Variables

- `AGENT_TOKEN` - Your auth token for MoltsPay API
- `MOLTSPAY_API_URL` - API base URL (default: https://moltspay.com)

## Complete Flow Example

User: "Buy a video from @zen7 about cats dancing"

1. Search: `curl "https://moltspay.com/registry/creators/zen7"`
2. Find video service, price $5, wallet 0xabc...
3. Check limit: remaining_today = $7 ✓
4. Pay: `npx moltspay pay https://moltspay.com $SERVICE_ID --prompt "cats dancing"`
5. Return result to user

## Error Handling

| Error | Action |
|-------|--------|
| Insufficient balance | Tell user, ask to top up wallet |
| Daily limit exceeded | Tell user, wait until tomorrow |
| Service not found | Search again or ask user for clarification |
| Payment failed | Retry once, then report error |

## Important Rules

1. **Always check spending limit before buying**
2. **Never exceed daily limit without user approval**
3. **Report transaction hash to user after purchase**
4. **If service fails, help user request refund**
