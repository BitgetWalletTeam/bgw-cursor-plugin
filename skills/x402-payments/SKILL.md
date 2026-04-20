---
name: x402-payments
description: >
  HTTP 402 payment protocol for Bitget Wallet — pay for API access and paywalled
  content using USDC on-chain via EIP-3009 (EVM) or Solana partial-sign.
  Enables micropayments, pay-per-request API monetization, and content purchases.
  Use when user encounters HTTP 402 responses, wants to pay for API access,
  asks about x402 payment protocol, paywalls, micropayments, or USDC payments.
license: MIT
metadata:
  author: Bitget Wallet
  version: 1.0.0
  tags: [x402, payments, micropayment, usdc, eip-3009]
---

# x402 Payments Skill

## ⚠️ MANDATORY: Load Domain Knowledge First

Before ANY x402 operation, load [`references/x402-payments.md`](references/x402-payments.md) for EIP-3009 signing, Solana partial-sign, and HTTP 402 payment flow details.

## Overview

x402 enables HTTP-native USDC payments. When an API returns HTTP 402, the agent can sign a USDC payment — after explicit user approval — and retry the request.

## Supported Payment Schemes

| Scheme | Chain | Status |
|--------|-------|--------|
| EIP-3009 (`exact`) | EVM (Base, Ethereum, etc.) | ✅ Fully implemented |
| Solana partial-sign | Solana | ✅ Sign-only (`sign-solana` subcommand); full `pay` flow requires pre-built transaction |

## Flow

```
1. API returns HTTP 402 with `payment-required` header (base64-encoded JSON)
2. Parse payment details (amount, recipient, network, scheme)
3. Sign USDC transfer authorization (EIP-3009 for EVM)
4. Retry original request with `PAYMENT-SIGNATURE` header (base64-encoded payload)
5. API returns the paid content + `payment-response` header (settlement receipt)
```

## Quick Reference

The CLI uses subcommands:

```bash
# Full HTTP 402 flow: fetch → parse 402 → sign EIP-3009 → retry (EVM chains)
python3 scripts/x402_pay.py pay \
  --url <api_url> --private-key-file /tmp/.pk --chain-id 8453

# Sign EIP-3009 only (no HTTP request)
python3 scripts/x402_pay.py sign-eip3009 \
  --private-key-file /tmp/.pk --token <USDC_contract> \
  --chain-id 8453 --to <payTo> --amount <smallest_unit>

# Sign Solana partial transaction only
python3 scripts/x402_pay.py sign-solana \
  --private-key-file /tmp/.pk --transaction <base64_tx>
```

## Key Rules

- User must confirm payment amount before signing
- Only USDC is supported for x402 payments
- Payment proof is included in the `PAYMENT-SIGNATURE` header on retry
- The `pay` subcommand includes an interactive confirmation prompt (`Pay? [y/N]`) by default
