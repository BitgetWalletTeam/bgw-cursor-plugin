---
name: rwa-trading
description: >
  Real-World Asset (RWA) tokenized stock trading via Bitget Wallet — buy and sell
  tokenized stocks (AAPL, TSLA, NVDA, etc.) on-chain using stablecoins.
  Discover stocks, get real-time buy/sell prices, check market status (NYSE/NASDAQ
  trading hours), place buy/sell orders, and manage holdings.
  Supported chains: BNB Chain and Ethereum.
  Use when user asks about buying stocks on-chain, tokenized equities, RWA trading,
  stock discovery, fractional shares, or real-world asset trading through Bitget Wallet.
license: MIT
metadata:
  author: Bitget Wallet
  version: 1.0.0
  tags: [rwa, stocks, tokenized-equities, trading, defi]
---

# RWA Stock Trading Skill

## ⚠️ MANDATORY: Load Domain Knowledge First

Before ANY RWA operation, load [`references/rwa.md`](references/rwa.md) for complete API parameters, response formats, and edge cases.

## Overview

RWA = tokenized real-world stocks (e.g. NVIDIA, Tesla) tradable on-chain. Users buy RWA stock tokens with stablecoins and sell them back to stablecoins. Trading uses the same swap backend — RWA stock is treated as a token.

**Supported chains**: `bnb`, `eth`

## Trading Flow (Strict Order)

```
Step 1: Discover — Search/list RWA stocks via rwa-get-user-ticker-selector
Step 2: Config   — Get allowed stablecoins via rwa-get-config
Step 3: Status   — Check market status via rwa-stock-info (markets have trading hours)
Step 4: Price    — Get buy/sell prices via rwa-stock-order-price
Step 5: Present  — Show user: market status, buy/sell price, limits, stablecoins
Step 6: Execute  — Reuse the standard swap flow (quote → confirm → makeOrder → sign → send)
Step 7: Verify   — Check updated holdings via rwa-get-my-holdings
```

**Key**: Step 6 uses the same swap flow as `defi-trading` skill. Set:
- **Buy RWA**: fromToken = stablecoin (USDT/USDC), toToken = RWA stock contract
- **Sell RWA**: fromToken = RWA stock contract, toToken = stablecoin

For signing, use `scripts/order_make_sign_send.py` (mnemonic wallet) or `scripts/social_order_make_sign_send.py` (Social Login Wallet), same as normal swaps.

## Quick Reference

```bash
# Discover/search RWA stocks
python3 scripts/bitget-wallet-agent-api.py rwa-get-user-ticker-selector --keyword NVDA
python3 scripts/bitget-wallet-agent-api.py rwa-get-user-ticker-selector --user-address <addr>

# Get RWA trading config (allowed stablecoins per chain)
python3 scripts/bitget-wallet-agent-api.py rwa-get-config --chain bnb --addresses '{"bnb":"0x...","eth":"0x..."}'

# Check market status
python3 scripts/bitget-wallet-agent-api.py rwa-stock-info --ticker NVDAon

# Get buy/sell price
python3 scripts/bitget-wallet-agent-api.py rwa-stock-order-price --ticker NVDAon --chain bnb --side buy --stable-contract <USDT_addr> --user-address <addr>

# View holdings
python3 scripts/bitget-wallet-agent-api.py rwa-get-my-holdings --chain bnb --address <addr>

# K-line data
python3 scripts/bitget-wallet-agent-api.py rwa-kline --ticker NVDAon --period 1d --size 30
```

## Key Rules

- **Always check market status** before placing orders — markets have trading hours (NYSE/NASDAQ)
- When market is closed, inform user of next open time (from `rwa-stock-info`)
- Show buy/sell price and trading limits to user before confirming
- RWA uses the same human-in-the-loop confirmation as normal swaps
- Trading amount limits per stock — check `tx_minimum_usd` / `tx_maximum_usd` from `rwa-stock-info`
- After successful trade, always show updated holdings
