# Data Schema (Plan JSON)

The iOS app reads/writes a JSON Plan compatible with the Python desktop app.

Top-level fields
- last_updated: string (ISO8601/reasonable date)
- tiers: array of Tier

Tier
- name: string
- purpose: string
- target: number
- priority: integer (lower funds first)
- preferred_account: string|null
- accounts: array of Account

Account
- name: string
- balance: number
- apy_pct: number
- notes: string
- alloc_weight: number
- account_target: number|null

Example
```
{
  "last_updated": "2025-08-30",
  "tiers": [
    {
      "name": "Tier 1",
      "purpose": "Buffer",
      "target": 1000,
      "priority": 1,
      "preferred_account": "Savings",
      "accounts": [
        {"name":"Savings","balance":200,"apy_pct":0,"notes":"","alloc_weight":2,"account_target":null},
        {"name":"Checking","balance":100,"apy_pct":0,"notes":"","alloc_weight":1,"account_target":null}
      ]
    }
  ]
}
```

Notes
- Keys deliberately match snake_case used in Python output; Swift uses CodingKeys to map to camelCase.
- Rounding: Algorithms round outward-facing amounts to 2 decimals (matching Python).

