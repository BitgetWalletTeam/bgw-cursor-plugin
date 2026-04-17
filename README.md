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

> **Platform:** Tested on macOS and Linux. Windows is not currently validated (symlinks and Bash paths may differ).

### Option A: Global Install (Recommended)

Install once → **Cursor:** every project. **Claude Code:** user-wide via marketplace (needs `claude` on `PATH` when you run the script).

```bash
# 1. Clone (path can differ; adjust later commands)
git clone https://github.com/BitgetWalletTeam/bgw-cursor-plugin.git ~/bgw-cursor-plugin

# 2. Install
bash ~/bgw-cursor-plugin/install.sh

# 3–4. Restart Cursor and Claude Code so both reload plugins
```

**What `install.sh` does**

- **Cursor:** Symlink `~/.cursor/plugins/bitget-wallet` → your clone.
- **Claude Code:** `claude plugin marketplace add <repo>` then `claude plugin install bitget-wallet@bitget-wallet-plugins` using [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json). The enabled plugin is copied into `~/.claude/plugins/cache/` (not loaded from the symlink alone). If `claude` is missing from `PATH`, the script prints those two commands to run by hand.

**Ad-hoc (one session only):** `claude --plugin-dir /path/to/bgw-cursor-plugin` — no substitute for marketplace install if you want skills every session.

**Cursor Settings:** Search for **third-party** and enable **Include third-party Plugins, Skills, and other configs** if your build shows that toggle.

**To update:** `cd ~/bgw-cursor-plugin && git pull && bash install.sh` (refreshes Claude’s cached copy).

**To uninstall:** `bash ~/bgw-cursor-plugin/install.sh --uninstall`

### Option B: Single-Project Install

For when you only want the plugin in one specific project.

```bash
# 1. Clone into your project (as a hidden subdirectory)
cd your-project
git clone https://github.com/BitgetWalletTeam/bgw-cursor-plugin.git .bitget-wallet

# 2. Create workspace-level symlinks
bash .bitget-wallet/install.sh --project

# 3. Add the symlinks to .gitignore (the installer prints the list)
```

This creates symlinks (`.cursor-plugin/`, `skills/`, `rules/`, etc.) at your project root pointing into `.bitget-wallet/`. Cursor discovers them when you open the project. **Claude Code** does not use those symlinks by itself — either run **Option A** once for a global Claude install, or use `claude --plugin-dir /path/to/your-project/.bitget-wallet` when working in that repo.

> **Note:** If your project already has files like `skills/`, `rules/`, `scripts/`, `.mcp.json`, or `CLAUDE.md`, the installer skips them to avoid overwriting. Check the output for any `Skipped` entries — if core items like `.cursor-plugin` or `skills` are skipped, use Option A (global install) instead.

**To remove:** `bash .bitget-wallet/install.sh --uninstall-project`

### Verify Installation

Local plugins **do not** show up in Cursor’s Extensions marketplace — that is expected.

**Cursor:** Restart after `install.sh`, confirm third-party toggle (see Option A), then ask the Agent e.g. *“What Bitget Wallet skills do you have?”* — expect all 7 skill areas to be recognized.

**Claude Code:** `claude plugin list` must show **`bitget-wallet@bitget-wallet-plugins`** enabled. If empty, re-run `bash install.sh` from your clone (with `claude` on `PATH`), or:

```bash
claude plugin marketplace add /path/to/bgw-cursor-plugin
claude plugin install bitget-wallet@bitget-wallet-plugins
```

Hand-edited `bitget-wallet@local` entries in `settings.json` / `installed_plugins.json` are **not** a supported load path in current Claude Code.

Optional: `claude plugin validate /path/to/clone` (or the `~/.cursor/plugins/bitget-wallet` symlink) should pass. Namespaced slash commands often look like `bitget-wallet:…`; check `/help` after restart.

### Try It

Once verified, try these prompts:

- "Swap 1 USDT to USDC on BNB Chain" → DeFi Trading skill activates
- "Is this token safe? 0x..." → Token Analysis skill runs security audit
- "Build a Solana DApp that connects Bitget Wallet" → DApp Integration generates code
- "Help me debug my Bitget Wallet API signature" → API Debugging skill guides you

### Optional: Python CLI & MCP Tools

```bash
# CLI tools (swap signing, key management)
cd ~/bgw-cursor-plugin   # or .bitget-wallet for project install
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

To enable MCP tools (36 tools, no API key needed), the shipped `.mcp.json` launches MCP via `uvx`, which requires [`uv`](https://docs.astral.sh/uv/getting-started/installation/):

```bash
# Install uv (if not already installed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Verify — this is how .mcp.json starts the MCP server
uvx bitget-wallet-mcp
```

Cursor reads `.mcp.json` automatically. The agent can then call tools like `swap_quote`, `balance`, `security_audit` directly.

> If you prefer `pip install bitget-wallet-mcp` instead of `uvx`, update `.mcp.json` to use `{"command": "bitget-wallet-mcp", "args": []}` so Cursor invokes the pip-installed binary.

### What Works Without MCP or CLI?

Even without installing MCP or Python dependencies, the plugin provides:

- **7 skills** with detailed domain knowledge (swap flows, chain guides, API docs)
- **3 rules** that auto-apply when you write code (provider namespace, security, swap safety)
- **3 agent personas** (DeFi operator, DApp developer, API debugger)

The agent can answer questions, generate code, and guide you through workflows using just the skill knowledge. MCP and CLI tools add execution capabilities (actual API calls, swap signing).

## Repository Structure

Two manifests describe the same tree: **Cursor** uses `.cursor-plugin/plugin.json` (may include `rules`, `tags`, etc.); **Claude Code** uses `.claude-plugin/plugin.json` (stricter schema) plus `.claude-plugin/marketplace.json` for CLI install.

```
.cursor-plugin/
  plugin.json              # Cursor plugin manifest
.claude-plugin/
  plugin.json              # Claude Code manifest (stricter than .cursor-plugin)
  marketplace.json         # Catalog for `claude plugin marketplace add` / install
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
upstream.json              # Pinned upstream commit SHAs for drift detection
CLAUDE.md                  # Claude Code project context
CHANGELOG.md               # Version history
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

Install and run the server with [`uv`](https://docs.astral.sh/uv/getting-started/installation/) / `uvx` — see **Optional: Python CLI & MCP Tools** above (same `.mcp.json` entry Cursor uses).

## Upstream Sources

This plugin consolidates content from the following upstream repositories. All content was snapshot-copied at the pinned commits listed below.

| Upstream Repo | Pinned Commit | Commit Date | Content in Plugin |
|---------------|---------------|-------------|-------------------|
| [bitget-wallet-skill](https://github.com/bitget-wallet-ai-lab/bitget-wallet-skill) | [`2a4b6c5`](https://github.com/bitget-wallet-ai-lab/bitget-wallet-skill/tree/2a4b6c5) | 2026-04-03 | defi-trading, token-analysis, social-wallet, rwa-trading, x402-payments, scripts/*.py |
| [bitget-wallet-developer-skill](https://github.com/bitget-wallet-ai-lab/bitget-wallet-developer-skill) | [`34a02aa`](https://github.com/bitget-wallet-ai-lab/bitget-wallet-developer-skill/tree/34a02aa) | 2026-03-24 | dapp-integration: 13 chain-specific refs + 10 DApp pattern refs (from `dapp-common-skill/` subdirectory) |
| [bitget-wallet-partner-skill](https://github.com/bitget-wallet-ai-lab/bitget-wallet-partner-skill) | [`05814bd`](https://github.com/bitget-wallet-ai-lab/bitget-wallet-partner-skill/tree/05814bd) | 2026-03-31 | api-debugging |
| [bitget-wallet-mcp](https://github.com/bitget-wallet-ai-lab/bitget-wallet-mcp) | [`7d961f7`](https://github.com/bitget-wallet-ai-lab/bitget-wallet-mcp/tree/7d961f7) | 2026-03-31 | MCP tool names, auth model, .mcp.json config |

Machine-readable version: [`upstream.json`](upstream.json)

**Drift detection:** run `bash scripts/check-upstream.sh` to compare pinned commits against current upstream HEAD. Use `--update` to bump pins after reviewing changes.

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
- [Wallet CLI](https://github.com/bitget-wallet-ai-lab/bitget-wallet-cli) (optional; plugin ships its own `scripts/`)

Upstream repos for bundled skills and MCP are linked in **What This Plugin Does** and **Upstream Sources**.

## License

[MIT](LICENSE) © 2026 Bitget Wallet AI Lab
