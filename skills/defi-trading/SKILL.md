---
name: defi-trading
description: >
  Execute DeFi operations through Bitget Wallet: token swap (same-chain & cross-chain),
  gasless transactions (EIP-7702), balance queries, DEX aggregator quotes, slippage
  control, and order management via Order Mode API.
  Supports 8 chains: ETH, SOL, BNB, Base, Arbitrum, Polygon, Morph, Tron.
  Use when user wants to swap tokens, bridge assets, cross-chain transfer, check balance,
  get swap quote, confirm trade, execute gasless swap, or perform any on-chain trading.
  Works with bitget-wallet-mcp tools when available, falls back to Python CLI scripts.
license: MIT
metadata:
  author: Bitget Wallet
  version: 1.0.0
  tags: [swap, bridge, gasless, defi, cross-chain, trading, eip-7702]
---

# DeFi Trading Skill

## ⚠️ MANDATORY: Load Domain Knowledge Before Any API Call

**Before calling ANY swap/trade API, you MUST first load the corresponding reference file.**

| Domain | Must Load First | Before Calling |
|--------|----------------|----------------|
| Swap / Trade | [`references/swap.md`](references/swap.md) | quote, confirm, make-order, send, get-order-details |
| Wallet / Signing | [`references/wallet-signing.md`](references/wallet-signing.md) | Any signing operation, key derivation |
| First-Time Setup | [`references/first-time-setup.md`](references/first-time-setup.md) | New wallet creation, first swap config |
| Command Reference | [`references/commands.md`](references/commands.md) | When unsure about subcommand parameters |

## Supported Chains

| Chain | Code | Native Token |
|-------|------|-------------|
| Ethereum | `eth` | ETH |
| BNB Chain | `bnb` | BNB |
| Base | `base` | ETH |
| Arbitrum | `arbitrum` | ETH |
| Polygon | `matic` | MATIC |
| Solana | `sol` | SOL |
| Morph | `morph` | ETH |
| Tron | `trx` | TRX |

> Use chain codes exactly. Common mistakes: `solana` → `sol`, `bsc` → `bnb`, `ethereum` → `eth`.

## Key Rules

- All amounts are **human-readable**: `"0.1"` means 0.1 tokens, NOT wei/lamports
- Use empty string `""` as contract address for native tokens (ETH, SOL, BNB, etc.)
- **Human-in-the-loop**: NEVER execute a swap without showing the quote and getting explicit user confirmation
- Private keys must never appear in conversation, prompts, logs, or any output

## Common Stablecoin Addresses

| Chain | USDT | USDC |
|-------|------|------|
| Ethereum (`eth`) | `0xdAC17F958D2ee523a2206206994597C13D831ec7` | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` |
| BNB Chain (`bnb`) | `0x55d398326f99059fF775485246999027B3197955` | `0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d` |
| Base (`base`) | `0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2` | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` |
| Arbitrum (`arbitrum`) | `0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9` | `0xaf88d065e77c8cC2239327C5EDb3A432268e5831` |
| Polygon (`matic`) | `0xc2132D05D31c914a87C6611C10748AEb04B58e8F` | `0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359` |
| Solana (`sol`) | `Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB` | `EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v` |
| Morph (`morph`) | `0xe7cd86e13AC4309349F30B3435a9d337750fC82D` | `0xCfb1186F4e93D60E60a8bDd997427D1F33bc372B` |
| Tron (`trx`) | `TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t` | - |

## Swap Flow (Strict Order — No Shortcuts)

1. **Balance check** — `batch-v2` to verify fromToken + native token balance
2. **Token risk check** — `check-swap-token` for both fromToken and toToken
3. **Quote** — display ALL market results, recommend the first, let user choose
4. **Confirm** — show `outAmount`, `minAmount`, `gasTotalAmount`; check `recommendFeatures` for gas sufficiency
5. **User confirmation** — do NOT sign until user explicitly confirms
6. **makeOrder + sign + send** — execute as one atomic operation via `order_make_sign_send.py` (mnemonic/private-key) or `social_order_make_sign_send.py` (Social Login Wallet)
7. **Query status** — `get-order-details` to check result

Gas mode decision at Step 1:
- Native balance sufficient → `--feature user_gas` (preferred)
- Native balance near zero → `--feature no_gas` (gasless, requires swap ≥ ~$5 USD)

## MCP Tools (when available)

| Tool | Use For |
|------|---------|
| `bgw_swap` | Execute full swap flow |
| `bgw_check_token` | Check token safety before swap |
| `bgw_get_balance` | Query token balances |
| `bgw_get_supported_chains` | List supported chains |

When MCP tools are available, prefer them over CLI scripts.

## Scripts (when MCP not available)

```bash
# Balance check
python3 scripts/bitget-wallet-agent-api.py batch-v2 --chain bnb --address <addr> --contract "" --contract <token>

# Token risk check
python3 scripts/bitget-wallet-agent-api.py check-swap-token --from-chain ... --from-contract ... --from-symbol ... --to-chain ... --to-contract ... --to-symbol ...

# Swap flow
python3 scripts/bitget-wallet-agent-api.py quote --from-chain bnb --from-contract <addr> --from-symbol USDT --from-amount 5 --to-chain bnb --to-contract "" --to-symbol BNB --from-address <wallet> --to-address <wallet>
python3 scripts/bitget-wallet-agent-api.py confirm ... --market <id> --protocol <proto> --slippage <val> --feature user_gas

# One-shot swap (mnemonic/private-key wallet)
python3 scripts/order_make_sign_send.py --private-key-file /tmp/.pk_evm --order-id <id> --from-chain bnb ...

# One-shot swap (Social Login Wallet — no private key needed)
python3 scripts/social_order_make_sign_send.py --wallet-id <walletId> --order-id <id> --from-chain bnb ...

# Query order status
python3 scripts/bitget-wallet-agent-api.py get-order-details --order-id <id>
```

## Common Pitfalls

1. **Chain code**: Use `sol` not `solana`, `bnb` not `bsc`
2. **Stale quotes**: Re-quote if >30 seconds before execute
3. **Insufficient gas**: Check native token balance before swap
4. **Token approval (EVM)**: ERC-20 must be approved for the router; see `references/swap.md`
5. **Key security**: Derive private keys on-the-fly, write to temp file (`mktemp`), pass via `--private-key-file`; script auto-deletes
6. **API-returned values**: Pass `market.id`, `market.protocol`, `orderId` etc. verbatim — never guess or transform
7. **Human-readable amounts**: Pass `0.01` not wei/lamports
8. **API errors**: Re-read the corresponding `references/*.md` before retrying

## Safety Rules

- Mnemonic and private keys must never appear in conversation, prompts, logs, or any output
- For large trades, always show quote first and ask for user confirmation
- Present security audit results before recommending any token action
- Use API-returned values exactly as-is — never guess or substitute

## Confirmation Architecture

**Human confirmation is enforced at the agent layer, not inside scripts.** The execution scripts (`order_make_sign_send.py`, `order_sign.py`) are CLI tools designed to be called by the agent AFTER the user has explicitly confirmed. The agent must:

1. Present quote details (output amount, min amount, gas, slippage, route) to the user
2. Wait for explicit confirmation ("yes", "confirm", "execute")
3. Only then call the signing/sending script

This separation follows the standard AI agent tool design: the agent owns the interaction, the script owns the execution. The scripts themselves do not prompt for input because they are invoked programmatically by the agent, not run interactively by users.
