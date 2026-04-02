# Bitget Wallet — AI Plugin for Cursor & Claude Code

> Multi-chain DeFi tools + DApp code generation, powered by Bitget Wallet

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## What This Plugin Does

| Skill | Description | Source |
|-------|-------------|--------|
| **DeFi Trading** | Token swap, cross-chain bridge, gasless mode — 8 chains | [bitget-wallet-skill](https://github.com/bitget-wallet-ai-lab/bitget-wallet-skill) |
| **Token Analysis** | Market data, security audits, smart money tracking, KOL addresses | [bitget-wallet-skill](https://github.com/bitget-wallet-ai-lab/bitget-wallet-skill) |
| **Social Wallet** | Social Login Wallet with TEE signing — no local private key | [bitget-wallet-skill](https://github.com/bitget-wallet-ai-lab/bitget-wallet-skill) |
| **RWA Trading** | Real-World Asset stock discovery and trading | [bitget-wallet-skill](https://github.com/bitget-wallet-ai-lab/bitget-wallet-skill) |
| **x402 Payments** | HTTP 402 USDC payment protocol (EIP-3009 on EVM; Solana sign-only) | [bitget-wallet-skill](https://github.com/bitget-wallet-ai-lab/bitget-wallet-skill) |
| **DApp Integration** | Generate production-ready DApp code with Bitget Wallet, 8+ chains | [developer-skill](https://github.com/bitget-wallet-ai-lab/bitget-wallet-developer-skill) |
| **API Debugging** | Debug Bitget Wallet APIs: HMAC, Partner-Code, and Agent auth models | [partner-skill](https://github.com/bitget-wallet-ai-lab/bitget-wallet-partner-skill) |

**Supported chains by feature:**

| Feature | Chains |
|---------|--------|
| Swap / DeFi Trading | Ethereum · BNB · Arbitrum · Base · Polygon · Solana · Morph · Tron |
| Market Data / Token Analysis | All major chains (32+) |
| DApp Integration | Ethereum · BNB · Arbitrum · Base · Polygon · Solana · Tron · Bitcoin · Aptos · Cosmos · TON · Sui |

## Quick Start

### Cursor IDE

1. Clone this repository into your project:
   ```bash
   git clone https://github.com/bitget-wallet-ai-lab/bitget-wallet.git .bitget-wallet
   ```

2. Cursor auto-discovers the plugin from `.cursor-plugin/plugin.json`.

4. (Optional) To use Python CLI scripts for swap execution:
   ```bash
   cd .bitget-wallet
   python3 -m venv .venv && source .venv/bin/activate
   pip install -r requirements.txt
   ```

### Claude Code

1. Clone and place in your workspace.
2. Claude Code detects `.claude-plugin/plugin.json` and loads all skills and agents.
3. MCP tools configured via `.mcp.json`.

## Repository Structure

```
.cursor-plugin/
  plugin.json              # Cursor plugin manifest
.claude-plugin/
  plugin.json              # Claude Code plugin manifest
skills/
  defi-trading/            # Swap, bridge, gasless — 8 chains
    SKILL.md
    references/            # swap.md, wallet-signing.md, commands.md, first-time-setup.md
  token-analysis/          # Market data, security, smart money
    SKILL.md
    references/            # market-data.md, token-analyze.md, address-find.md
  social-wallet/           # Social Login Wallet (TEE signing)
    SKILL.md
    references/            # social-wallet.md
  rwa-trading/             # Real-World Asset stocks
    SKILL.md
    references/            # rwa.md
  x402-payments/           # HTTP 402 USDC payments
    SKILL.md
    references/            # x402-payments.md
  dapp-integration/        # Multi-chain DApp code generation
    SKILL.md
    references/            # 23 files — per-chain + DApp patterns
  api-debugging/           # Bitget Wallet API debugging (HMAC, Partner-Code, Agent auth)
    SKILL.md
    references/            # auth, swap-order, market-data, token
scripts/                   # Python CLI tools from wallet-skill
  bitget-wallet-agent-api.py
  order_make_sign_send.py
  social_order_make_sign_send.py
  order_sign.py
  social-wallet.py
  x402_pay.py
  key_utils.py
rules/
  provider-namespace.mdc   # Enforces window.bitkeep.* (alwaysApply)
  security-practices.mdc   # Prevents key leaks, unsafe approvals (alwaysApply)
  swap-safety.mdc          # Swap safety rules (alwaysApply)
agents/
  defi-operator.md         # DeFi operations agent
  dapp-developer.md        # DApp code generation agent
  api-debugger.md          # API debugging agent
.mcp.json                  # MCP server config (bitget-wallet-mcp)
CLAUDE.md                  # Claude Code project context
CHANGELOG.md               # Version history
reviews/                   # Audit & review artifacts (not part of plugin)
  SUBMISSION-REVIEW.md     # Main submission document
  security-audit-slowmist-v1.0.md
  REVIEW-v1.0.md
  AUDIT-REPORT-v1.*.md    # Independent audit reports (v1.0–v1.13)
```

## MCP Tools

The `bitget-wallet-mcp` server provides **36 tools** across 5 categories. No API key required — uses SHA256 hash signing (BKHmacAuth).

| Category | Tools | Examples |
|----------|-------|---------|
| Market Data | 21 | `token_info`, `search_tokens`, `kline`, `security_audit`, `rankings` |
| Smart Money | 1 | `smart_money_addresses` |
| RWA Stock Trading | 6 | `rwa_ticker_list`, `rwa_stock_info`, `rwa_order_price` |
| Swap | 7 | `swap_quote`, `swap_confirm`, `swap_make_order`, `swap_send` |
| Balance | 1 | `balance` |

Install:
```bash
pip install bitget-wallet-mcp
# or
uvx bitget-wallet-mcp
```

## Architecture

This plugin uses a **progressive disclosure** pattern:

1. Each `SKILL.md` acts as a lightweight router (~100-200 lines)
2. Detailed knowledge lives in `references/*.md` (loaded on demand)
3. Rules (`.mdc`) are auto-applied whenever matching files are active
4. Python scripts provide CLI-based execution when MCP is not available

## vs Phantom Connect Plugin

| Dimension | Phantom | Bitget Wallet |
|-----------|---------|---------------|
| Skills | 8 | **7** |
| Rules | 3 | **3** |
| Agents | 2 | **3** |
| Reference files | 7 | **37** |
| Chains (swap) | 4 | **8** |
| Chains (DApp) | 1 (Solana) | **8+** |
| Gasless | No | **Yes (EIP-7702)** |
| Cross-chain | No | **Yes** |
| Token analysis | No | **Yes (security + smart money)** |
| Social wallet | Yes | **Yes (TEE)** |
| RWA trading | No | **Yes** |
| CLI tools | No | **Yes (7 scripts)** |

## Links

- [Bitget Wallet](https://web3.bitget.com)
- [Wallet Skill (171 stars)](https://github.com/bitget-wallet-ai-lab/bitget-wallet-skill)
- [Developer Skill](https://github.com/bitget-wallet-ai-lab/bitget-wallet-developer-skill)
- [Wallet MCP Server](https://github.com/bitget-wallet-ai-lab/bitget-wallet-mcp)
- [Partner Skill](https://github.com/bitget-wallet-ai-lab/bitget-wallet-partner-skill)
- [Wallet CLI](https://github.com/bitget-wallet-ai-lab/bitget-wallet-cli)

## License

[MIT](LICENSE) © 2026 Bitget Wallet AI Lab
