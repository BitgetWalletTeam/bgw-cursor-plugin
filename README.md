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

### Option A: Global Install (Recommended)

Install once → works in **every** Cursor project you open. No per-project setup.

```bash
# 1. Clone the plugin repo (anywhere you like)
git clone https://github.com/bitget-wallet-ai-lab/bitget-wallet.git ~/bitget-wallet-plugin

# 2. Run the installer
bash ~/bitget-wallet-plugin/install.sh

# 3. Restart Cursor (Cmd+Shift+P → "Reload Window" or quit & reopen)
```

The installer registers the plugin in `~/.cursor/plugins/` and `~/.claude/` so Cursor loads it automatically. If your Cursor version has a "Include third-party Plugins" toggle under Settings → Features, make sure it's enabled.

**To update:** `cd ~/bitget-wallet-plugin && git pull`
**To uninstall:** `bash ~/bitget-wallet-plugin/install.sh --uninstall`

### Option B: Single-Project Install

For when you only want the plugin in one specific project.

```bash
# 1. Clone into your project (as a hidden subdirectory)
cd your-project
git clone https://github.com/bitget-wallet-ai-lab/bitget-wallet.git .bitget-wallet

# 2. Create workspace-level symlinks
bash .bitget-wallet/install.sh --project

# 3. Add the symlinks to .gitignore (the installer prints the list)
```

This creates symlinks (`.cursor-plugin/`, `skills/`, `rules/`, etc.) at your project root pointing into `.bitget-wallet/`. Cursor discovers them when you open the project.

**To remove:** `bash .bitget-wallet/install.sh --uninstall-project`

### Verify Installation

After installing and restarting Cursor, the plugin loads silently — **it will not appear in the Extensions panel or the marketplace**. That's expected for local plugins.

To confirm it's working, open any project in Cursor and ask the Agent:

> "What Bitget Wallet skills do you have?"

The Agent should list all 7 skills (DeFi Trading, Token Analysis, Social Wallet, etc.). If it doesn't recognize the question, check:

1. You restarted Cursor after running `install.sh`
2. Settings → Features → "Include third-party Plugins" is enabled (if the toggle exists)
3. Run `cat ~/.claude/settings.json | grep bitget` — should show `"bitget-wallet@local": true`

### Try It

Once verified, try these prompts:

- "Swap 1 USDT to USDC on BNB Chain" → DeFi Trading skill activates
- "Is this token safe? 0x..." → Token Analysis skill runs security audit
- "Build a Solana DApp that connects Bitget Wallet" → DApp Integration generates code
- "Help me debug my Bitget Wallet API signature" → API Debugging skill guides you

### Optional: Python CLI & MCP Tools

```bash
# CLI tools (swap signing, key management)
cd ~/bitget-wallet-plugin   # or .bitget-wallet for project install
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# MCP server (36 tools, no API key needed)
pip install bitget-wallet-mcp
```

Cursor reads `.mcp.json` automatically. The agent can then call tools like `swap_quote`, `balance`, `security_audit` directly.

### Claude Code

```bash
# Claude Code uses --plugin-dir for local plugins
claude --plugin-dir ~/bitget-wallet-plugin
```

Claude Code detects `.claude-plugin/plugin.json` and loads all skills and agents. `CLAUDE.md` provides project context. MCP tools are configured via `.mcp.json`.

### What Works Without MCP or CLI?

Even without installing MCP or Python dependencies, the plugin provides:

- **7 skills** with detailed domain knowledge (swap flows, chain guides, API docs)
- **3 rules** that auto-apply when you write code (provider namespace, security, swap safety)
- **3 agent personas** (DeFi operator, DApp developer, API debugger)

The agent can answer questions, generate code, and guide you through workflows using just the skill knowledge. MCP and CLI tools add execution capabilities (actual API calls, swap signing).

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
install.sh                 # Plugin installer (global / per-project)
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
- [Wallet Skill](https://github.com/bitget-wallet-ai-lab/bitget-wallet-skill)
- [Developer Skill](https://github.com/bitget-wallet-ai-lab/bitget-wallet-developer-skill)
- [Wallet MCP Server](https://github.com/bitget-wallet-ai-lab/bitget-wallet-mcp)
- [Partner Skill](https://github.com/bitget-wallet-ai-lab/bitget-wallet-partner-skill)
- [Wallet CLI](https://github.com/bitget-wallet-ai-lab/bitget-wallet-cli)

## License

[MIT](LICENSE) © 2026 Bitget Wallet AI Lab
