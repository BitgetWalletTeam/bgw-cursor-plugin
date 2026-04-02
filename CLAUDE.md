# Bitget Wallet — Cursor Plugin & Claude Code Project

This repository is the unified Bitget Wallet AI plugin, compatible with both Cursor IDE and Claude Code.

## Repository Structure

```
.cursor-plugin/plugin.json   — Cursor plugin manifest
.claude-plugin/plugin.json   — Claude Code plugin manifest
skills/                       — 7 Skill definitions (progressive disclosure pattern)
  defi-trading/               — Token swap, cross-chain bridge, gasless (from wallet-skill)
  token-analysis/             — Market data, security audit, smart money (from wallet-skill)
  social-wallet/              — Social Login Wallet, TEE signing (from wallet-skill)
  rwa-trading/                — Real-World Asset stock trading (from wallet-skill)
  x402-payments/              — HTTP 402 USDC payment protocol (from wallet-skill)
  dapp-integration/           — Multi-chain DApp code generation (from developer-skill)
  api-debugging/              — Bitget Wallet API debugging: HMAC, Partner-Code, Agent auth (from partner-skill)
rules/                        — .mdc rules auto-applied by Cursor (alwaysApply: true)
agents/                       — Agent personas for different use cases
scripts/                      — Python CLI tools from bitget-wallet-skill
.mcp.json                     — MCP server configuration (bitget-wallet-mcp)
```

## Key Conventions

- **Provider namespace**: Always use `window.bitkeep.*`, never generic `window.ethereum`. See `rules/provider-namespace.mdc`.
- **Swap amounts**: Always human-readable (e.g. `0.1` USDT, not wei). See `rules/swap-safety.mdc`.
- **Progressive disclosure**: Each skill's `SKILL.md` is a router. Load `references/*.md` only when needed — never load all references at once.
- **Security**: Follow `rules/security-practices.mdc`. No hardcoded keys, exact token approvals, always show tx details before signing.
- **Mandatory domain knowledge**: Before calling ANY API, load the corresponding `references/*.md` file first. See each skill's routing table.
- **Private key safety**: Mnemonic and private keys must never appear in conversation, prompts, logs, or any output.
- **Confirmation architecture**: Human confirmation is enforced at the agent layer. Scripts (`order_make_sign_send.py`, `order_sign.py`) are execution tools called AFTER the agent obtains explicit user approval. The agent must present quote details and wait for confirmation before invoking any signing script.

## Scripts

7 Python scripts (Python 3.9+) from bitget-wallet-skill:

| Script | Purpose |
|--------|---------|
| `bitget-wallet-agent-api.py` | Unified API client — balance, token find/check/analyze, swap flow |
| `order_make_sign_send.py` | One-shot swap (mnemonic/private-key wallet) |
| `social_order_make_sign_send.py` | One-shot swap (Social Login Wallet) |
| `order_sign.py` | Sign makeOrder data (EVM raw tx, EIP-712, Solana Ed25519, Tron secp256k1) |
| `social-wallet.py` | Social Login Wallet operations (TEE signing) |
| `x402_pay.py` | x402 USDC payment flow |
| `key_utils.py` | Secure read-and-delete key file handler |

## MCP Tools

When `bitget-wallet-mcp` is configured, these tools are available:
- `bgw_swap` — Execute token swap
- `bgw_check_token` — Check token safety
- `bgw_get_balance` — Query token balances
- `bgw_get_supported_chains` — List supported chains

Set `BGW_API_KEY` and `BGW_API_SECRET` in your environment before using.

## Supported Chains

**Swap (8)**: Ethereum · BNB Chain · Base · Arbitrum · Polygon · Solana · Morph · Tron

**Market Data (32+)**: All major chains

**DApp Integration (8+)**: EVM · Solana · Bitcoin · Aptos · Cosmos · TON · Tron · Sui
