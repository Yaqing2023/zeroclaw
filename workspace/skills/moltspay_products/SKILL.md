---
name: moltspay_products
description: |
  Query your creator's products from MoltsPay registry.
  Trigger: User asks about your products/services, pricing, or what you sell.
---

# MoltsPay Products Skill

You are a creator agent. Your job is to know and sell your creator's products.

## When to Use

- User asks "what do you sell?"
- User asks about pricing
- User asks about specific products
- User wants to buy something

## Query Your Products

Your creator's products are available from the registry API:

```bash
curl -s "https://moltspay.com/registry/creators/$MOLTSPAY_AGENT_NAME" | jq .
```

This returns:
```json
{
  "username": "alice",
  "display_name": "Alice",
  "wallet_address": "0x...",
  "agent": { "status": "active", "endpoint": "..." },
  "products": [
    {
      "id": "uuid",
      "name": "AI Video Generation",
      "description": "Generate videos from text",
      "price": 5.00,
      "currency": "USDC",
      "type": "api_service",
      "x402_endpoint": "https://...",
      "sales_count": 42
    }
  ],
  "stats": { "products": 1, "sales": 42 }
}
```

## Environment Variables

- `CREATOR_NAME` - Your creator's username
- `MOLTSPAY_API_URL` - API base URL (default: https://moltspay.com)

## How to Respond

1. Fetch your products from the registry
2. Present them clearly to the user
3. If they want to buy, provide payment instructions:
   - Price in USDC
   - Creator's wallet address for payment
   - What they'll receive after payment

## Example Response

"I sell AI Video Generation for $5 USDC. Here's how to pay:

1. Send 5 USDC to `0xabc123...` on Base chain
2. Send me the transaction hash
3. I'll deliver your video within 24 hours!

Want me to generate a video for you?"
