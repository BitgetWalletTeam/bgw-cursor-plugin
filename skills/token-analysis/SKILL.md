---
name: token-analysis
description: >
  Token discovery, market data analysis, security audits, and smart money tracking
  via Bitget Wallet API. Covers token search, launchpad scanning (pump.fun),
  rankings (topGainers/topLosers/Hotpicks), K-line charts, trading dynamics,
  holder analysis, profit tracking, honeypot detection, rug pull checks, whale
  tracking, KOL address discovery, market cap, FDV, pool scanner, and liquidity.
  Use when user asks about token prices, market data, security checks, token
  rankings, smart money, whale tracking, KOL addresses, honeypot detection,
  or wants to analyze any token on any chain.
license: MIT
metadata:
  author: Bitget Wallet
  version: 1.0.0
  tags: [token, analysis, security, market-data, smart-money, kol, honeypot]
---

# Token Analysis Skill

## ⚠️ MANDATORY: Load Domain Knowledge Before Any API Call

| Domain | Must Load First | Before Calling |
|--------|----------------|----------------|
| Market Data / Token Check | [`references/market-data.md`](references/market-data.md) | coin-market-info, security, coin-dev, kline, tx-info, liquidity, rankings, launchpad-tokens, search-tokens-v3 |
| Token Deep Analysis | [`references/token-analyze.md`](references/token-analyze.md) | simple-kline, trading-dynamics, transaction-list, holders-info, profit-address-analysis, top-profit, compare-tokens |
| Address Discovery | [`references/address-find.md`](references/address-find.md) | recommend-address-list |

## Tool Architecture

### bgw_token_find — Token Discovery

| Use Case | Command | Description |
|----------|---------|-------------|
| Scan new pools | `launchpad-tokens` | Filter by platform/stage/MC/LP/holders/progress |
| Search tokens | `search-tokens-v3` | Keyword or contract search with ordering |
| Rankings | `rankings` | topGainers / topLosers / Hotpicks |
| New launches | `historical-coins` | Discover tokens by timestamp, paginated |

**Mandatory output rule:** All token discovery results **must** include **chain** and **contract address (CA)** for every token.

### bgw_token_check — Token Analysis

| Use Case | Command | Description |
|----------|---------|-------------|
| Security audit | `security` | Honeypot/mint/proxy + buy/sell tax + risk level |
| Dev analysis | `coin-dev` | Dev's historical projects + rug status + migration info |
| Market overview | `coin-market-info` | Price/MC/FDV/pool list/price changes/narratives |
| Token info | `token-info` | Basic info + social links |
| K-line | `kline` | OHLC + buy/sell volume |
| Tx stats | `tx-info` | Buy/sell volume and trader count |
| Liquidity | `liquidity` | Pool details |

**Recommended check order:** coin-market-info → security → coin-dev → (kline + tx-info)

**Pre-trade mandatory:** check-swap-token → security

### bgw_token_analyze — Token Deep Analysis

| Use Case | Command | Description |
|----------|---------|-------------|
| K-line + signals | `simple-kline` | K-line with KOL/smart money trade signals + hot level |
| Trading dynamics | `trading-dynamics` | 4-window (5m/1h/4h/24h) buy/sell pressure + address quality |
| Transactions | `transaction-list` | Tagged trades (smart money/KOL/dev), direction/time filtering |
| Holders | `holders-info` | Top100 distribution + PnL + tag classification |
| Profit analysis | `profit-address-analysis` | Profitable address stats + position dynamics |
| Top profit | `top-profit` | Top profitable address list with PnL details |
| Compare | `compare-tokens` | Side-by-side K-line comparison of two tokens |

**Recommended analysis order:** trading-dynamics → simple-kline → holders-info → transaction-list → profit analysis

### bgw_address_find — Address Discovery

| Use Case | Command | Description |
|----------|---------|-------------|
| Find by role | `recommend-address-list` | Find KOL / smart money addresses with performance filters |

**Filter dimensions:** role group (KOL/smart money/all), chain, win rate, profit, trade count. Sort by profit/win rate/trade count/last activity. Time windows: 24h/7d/30d.

## Quick Reference

```bash
# Token discovery
python3 scripts/bitget-wallet-agent-api.py launchpad-tokens --chain sol --platforms pump.fun --stage 1 --mc-min 10000 --holder-min 100
python3 scripts/bitget-wallet-agent-api.py search-tokens-v3 --keyword pepe --chain sol --order-by market_cap
python3 scripts/bitget-wallet-agent-api.py rankings --name Hotpicks

# Token check
python3 scripts/bitget-wallet-agent-api.py coin-market-info --chain sol --contract <addr>
python3 scripts/bitget-wallet-agent-api.py security --chain bnb --contract <addr>
python3 scripts/bitget-wallet-agent-api.py coin-dev --chain sol --contract <addr>

# Token deep analysis
python3 scripts/bitget-wallet-agent-api.py simple-kline --chain sol --contract <addr> --period 1h --size 24
python3 scripts/bitget-wallet-agent-api.py trading-dynamics --chain sol --contract <addr>
python3 scripts/bitget-wallet-agent-api.py holders-info --chain sol --contract <addr>
python3 scripts/bitget-wallet-agent-api.py compare-tokens --chain-a sol --contract-a <addr1> --chain-b sol --contract-b <addr2> --period 1h --size 24

# Address discovery
python3 scripts/bitget-wallet-agent-api.py recommend-address-list --group-ids 1 --filter-chain sol --sort-field win_rate
```

## Common Pitfalls

1. **Batch format**: `batch-token-info` uses `--tokens "sol:<addr1>,eth:<addr2>"` (chain:address, comma-separated)
2. **Chain code**: Use `sol` not `solana`, `bnb` not `bsc`
3. **Always include chain + CA** in discovery output for actionability
