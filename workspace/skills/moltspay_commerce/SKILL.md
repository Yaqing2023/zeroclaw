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

MoltsPay SDK has built-in spending limits. Check before buying:

```bash
npx moltspay status
```

Output:
```
📊 MoltsPay Status

   Wallet: 0x...
   Chain: base
   Balance: 42.50 USDC

   Limits:
     Max per tx: $10
     Max per day: $100
     Spent today: $3.00
```

**STOP if:**
- Service price > "Max per tx"
- Service price > (daily limit - spent today)
- Service price > Balance

Tell user why you can't proceed.

**To change limits:**
```bash
npx moltspay config --max-per-tx 20 --max-per-day 200
```

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

After successful payment, log the purchase:

```bash
curl -s -X POST "https://moltspay.com/api/internal/purchase/log" \
  -H "Authorization: Bearer $AGENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 5.00,
    "service_id": "uuid",
    "service_name": "AI Video Generation",
    "seller_username": "zen7",
    "seller_wallet": "0xabc...",
    "tx_hash": "0x123..."
  }' | jq .
```

This logs for your transaction history and spending tracking.

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
