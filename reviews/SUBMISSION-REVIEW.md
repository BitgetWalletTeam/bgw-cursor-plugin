# Bitget Wallet Cursor Plugin — Submission Review Document

> Version: 1.0.1 | Date: 2026-04-02 | Author: Bitget Wallet AI Lab
> Upstream sync verified: 2026-04-02 (star counts, MCP tool names, auth model)

---

## 1. Purpose & Background

### What is this?

A **Cursor IDE + Claude Code plugin** that gives AI agents the ability to:

1. Execute DeFi trades (swap, bridge, gasless) across 8 blockchains
2. Analyze tokens (market data, security audits, smart money tracking)
3. Generate production-ready DApp frontend code with Bitget Wallet integration
4. Trade tokenized real-world assets (stocks like AAPL, TSLA)
5. Process x402 USDC micropayments
6. Manage Social Login Wallets (TEE signing, no local private key)
7. Debug Bitget Wallet API integrations (HMAC, Partner-Code, Agent auth)

### Why this plugin?

Bitget Wallet AI Lab has 5 separate open-source repositories on GitHub:

| Repository | Stars | Content |
|-----------|-------|---------|
| [bitget-wallet-skill](https://github.com/bitget-wallet-ai-lab/bitget-wallet-skill) | 176+ | DeFi trading, token analysis, social wallet, RWA, x402 |
| [bitget-wallet-developer-skill](https://github.com/bitget-wallet-ai-lab/bitget-wallet-developer-skill) | — | DApp code generation, 8+ chains |
| [dapp-common-skill](https://github.com/bitget-wallet-ai-lab/dapp-common-skill) | — | DApp UI/UX patterns |
| [bitget-wallet-partner-skill](https://github.com/bitget-wallet-ai-lab/bitget-wallet-partner-skill) | 1 | API debugging (HMAC, Partner-Code, Agent auth) |
| [bitget-wallet-mcp](https://github.com/bitget-wallet-ai-lab/bitget-wallet-mcp) | 14+ | MCP server, 36 tools, no API key (SHA256 hash signing) |

This plugin **consolidates all 5 repositories** into a single, unified Cursor/Claude Code plugin with progressive disclosure architecture, auto-applied safety rules, and agent personas.

### Benchmark

Designed to match or exceed [Phantom Connect Cursor Plugin](https://github.com/phantom/phantom-connect-cursor-plugin) — the industry reference for Web3 AI plugins.

---

## 2. Plugin Specification Compliance

### Cursor Plugin Requirements

| Requirement | Status | Evidence |
|------------|--------|----------|
| `.cursor-plugin/plugin.json` exists | ✅ | 37 lines, valid JSON |
| `name` field | ✅ | `"bitget-wallet"` |
| `displayName` field | ✅ | `"Bitget Wallet"` |
| `version` field | ✅ | `"1.0.0"` (consistent in 9 locations) |
| `description` ≤ 120 chars | ✅ | 107 characters |
| `author.name` + `author.email` | ✅ | `"Bitget Wallet AI Lab"` / `"AiAgent@bitget.com"` |
| `homepage` | ✅ | `https://web3.bitget.com` |
| `repository` | ✅ | `https://github.com/bitget-wallet-ai-lab/bitget-wallet` |
| `license` | ✅ | `"MIT"` + LICENSE file |
| `logo` file exists at referenced path | ✅ | `assets/logo.svg` (256x256 SVG, official Bitget Wallet mark) |
| `keywords` array | ✅ | 10 items |
| `tags` array | ✅ | 5 items: developer-tools, web3, defi, wallet, multi-chain |
| `skills` path resolves | ✅ | `"./skills/"` → 7 subdirectories |
| `rules` path resolves | ✅ | `"./rules/"` → 3 `.mdc` files |
| `agents` path resolves | ✅ | `"./agents/"` → 3 `.md` files |
| `mcpServers` path resolves | ✅ | `".mcp.json"` → valid JSON with `bitget-wallet-mcp` |

### Claude Code Requirements

| Requirement | Status | Evidence |
|------------|--------|----------|
| `.claude-plugin/plugin.json` exists | ✅ | 29 lines, valid JSON (omits `rules`, `tags` per spec) |
| `CLAUDE.md` exists | ✅ | 64 lines, project context |
| All fields mirror Cursor manifest | ✅ | Same name, version, description, author, etc. |

---

## 3. Complete File Inventory

> **Snapshot date: 2026-03-31.** Line counts are approximate and may drift slightly as documentation is refined. Dependency counts and file lists are kept current.

**87 files total, ~18,000 lines of content (excluding .git)**

### Skills (7 skills, 37 reference files)

| # | Skill | References | Source Repo |
|---|-------|------------|-------------|
| 1 | `defi-trading` | `swap.md`, `wallet-signing.md`, `commands.md`, `first-time-setup.md` | bitget-wallet-skill |
| 2 | `token-analysis` | `market-data.md`, `token-analyze.md`, `address-find.md` | bitget-wallet-skill |
| 3 | `social-wallet` | `social-wallet.md` | bitget-wallet-skill |
| 4 | `rwa-trading` | `rwa.md` | bitget-wallet-skill |
| 5 | `x402-payments` | `x402-payments.md` | bitget-wallet-skill |
| 6 | `dapp-integration` | 23 files (see detail below) | developer-skill + dapp-common-skill |
| 7 | `api-debugging` | `authentication.md`, `swap-order.md`, `market-data.md`, `token.md` | partner-skill |

### dapp-integration Reference Detail (23 files)

| File | Content |
|------|---------|
| `evm.md` | EVM integration + React hook |
| `solana.md` | Solana + @solana/web3.js |
| `bitcoin.md` | Bitcoin + @noble/curves |
| `ton.md` | TON + TonConnect |
| `aptos.md` | Aptos SDK |
| `cosmos.md` | CosmJS |
| `tron.md` | TronWeb |
| `sui.md` | @mysten/sui |
| `adapters.md` | Wagmi, RainbowKit, WalletConnect, TonConnect, Web3-Onboard |
| `detection-and-setup.md` | Provider detection, EIP-6963 |
| `telegram-miniapp.md` | Telegram Mini App |
| `deeplink.md` | Mobile deep links |
| `bitget-exclusive.md` | Bitget-specific features |
| `dapp-layout.md` | DApp layout patterns |
| `dapp-wallet-connection.md` | Connection flow |
| `dapp-adapter-integration.md` | Adapter setup |
| `dapp-transfer.md` | Transfer forms |
| `dapp-token-approval.md` | ERC-20 approval UI |
| `dapp-chain-switching.md` | Chain switching UX |
| `dapp-signing.md` | Message/typed-data signing |
| `dapp-transaction-lifecycle.md` | Tx tracking + history |
| `dapp-gas-and-fees.md` | Gas estimation UX |
| `dapp-ux-patterns.md` | Error handling, loading states |

### Rules (3 files, all `alwaysApply: true`)

| File | Globs | Purpose |
|------|-------|---------|
| `provider-namespace.mdc` | `*.ts, *.tsx, *.js, *.jsx` | Enforce `window.bitkeep.*` namespace |
| `security-practices.mdc` | `*.ts, *.tsx, *.js, *.jsx, *.py` | Prevent key leaks, unsafe approvals |
| `swap-safety.mdc` | `*.py, *.ts, *.js` | Swap amount format, confirmation, chain codes |

### Agents (3 files)

| File | Persona |
|------|---------|
| `defi-operator.md` | DeFi operations agent — swap execution flow |
| `dapp-developer.md` | DApp code generation agent |
| `api-debugger.md` | API debugging agent |

### Scripts (7 Python files)

| File | Purpose |
|------|---------|
| `bitget-wallet-agent-api.py` | Unified API client (balance, token, swap, order) |
| `order_sign.py` | Sign makeOrder data (EVM, Solana, Tron) |
| `x402_pay.py` | x402 USDC payment (EIP-3009 + Solana partial-sign) |
| `social_order_make_sign_send.py` | One-shot swap for Social Login Wallet (TEE) |
| `social-wallet.py` | Social Login Wallet operations |
| `order_make_sign_send.py` | One-shot swap for mnemonic/private-key wallets |
| `key_utils.py` | Secure read-and-delete key file handler |

### Config & Meta

| File | Purpose |
|------|---------|
| `.cursor-plugin/plugin.json` | Cursor manifest |
| `.claude-plugin/plugin.json` | Claude Code manifest |
| `.mcp.json` | MCP server config |
| `CLAUDE.md` | Claude Code project context |
| `README.md` | Plugin documentation |
| `CHANGELOG.md` | Version history |
| `LICENSE` | MIT License |
| `.gitignore` | Excludes .env, .social-wallet-secret, etc. |
| `requirements.txt` | Python deps: requests, eth-account, cryptography, eth-utils, eth-abi, base58, solders |
| `assets/logo.svg` | Official Bitget Wallet logo (256x256) |
| `reviews/REVIEW-v1.0.md` | Internal review log |
| `reviews/security-audit-slowmist-v1.0.md` | SlowMist security audit report |

---

## 4. Architecture

### Progressive Disclosure

```
User query
  → Cursor matches intent via SKILL.md description
    → SKILL.md routing table selects specific references/*.md
      → Agent loads ONLY the needed reference (not all 37)
        → Rules auto-apply via alwaysApply: true
```

Each `SKILL.md` is a lightweight router (50–241 lines) that maps user intents to specific `references/*.md` files. This keeps the AI context window lean — a swap query loads ~350 lines instead of ~13,000.

### Dual Execution Path

```
Path A: MCP (preferred, 36 tools, no API key)
  Agent → swap_quote / check_swap_token / balance / ... → Bitget Wallet API

Path B: Python CLI (fallback)
  Agent → scripts/bitget-wallet-agent-api.py → Bitget Wallet API
  Agent → scripts/order_make_sign_send.py → local signing → API send
```

### Security Architecture

```
Private Key Lifecycle:
  Mnemonic in secure storage (never in context)
    → Agent writes key to tempfile.mkstemp() (chmod 0600)
      → key_utils.read_key_file() reads + deletes file
        → Script signs in memory
          → variable = None (explicit clear)

Social Login Wallet (no local key):
  Agent → social_order_make_sign_send.py → TEE API (server-side signing)
```

### Human-in-the-Loop (Agent-Orchestrated Confirmation)

Confirmation is **agent-orchestrated** — the agent obtains user approval before calling execution scripts. Scripts are execution tools, not interactive applications.

1. **SKILL.md level**: "WAIT → user explicitly confirms" before sign+send
2. **Rule level**: `swap-safety.mdc` rule 5: "Never sign transactions without explicit user confirmation"
3. **Agent level**: `defi-operator.md` step 4: "Confirm with user: Present all details, wait for explicit go-ahead"

> Note: Signing scripts (`order_make_sign_send.py`, `order_sign.py`) do not contain their own confirmation prompts. The confirmation gate is the agent's responsibility. `x402_pay.py pay` is the exception — it includes an interactive `Pay? [y/N]` prompt.

---

## 5. Skill-to-Source Traceability

Every file in this plugin traces back to a specific source repository on GitHub:

### From `bitget-wallet-skill` → 5 skills + 7 scripts

| Plugin Path | Source Path |
|-------------|------------|
| `skills/defi-trading/references/swap.md` | `docs/swap.md` |
| `skills/defi-trading/references/wallet-signing.md` | `docs/wallet-signing.md` |
| `skills/defi-trading/references/commands.md` | `docs/commands.md` |
| `skills/defi-trading/references/first-time-setup.md` | `docs/first-time-setup.md` |
| `skills/token-analysis/references/market-data.md` | `docs/market-data.md` |
| `skills/token-analysis/references/token-analyze.md` | `docs/token-analyze.md` |
| `skills/token-analysis/references/address-find.md` | `docs/address-find.md` |
| `skills/social-wallet/references/social-wallet.md` | `docs/social-wallet.md` |
| `skills/rwa-trading/references/rwa.md` | `docs/rwa.md` |
| `skills/x402-payments/references/x402-payments.md` | `docs/x402-payments.md` |
| `scripts/*.py` (7 files) | `scripts/*.py` (7 files) |

**Source fidelity: 17/17 files present**

### From `bitget-wallet-developer-skill` → 13 reference files

| Plugin Path | Source |
|-------------|--------|
| `skills/dapp-integration/references/evm.md` | chain guides |
| `skills/dapp-integration/references/solana.md` | chain guides |
| `skills/dapp-integration/references/bitcoin.md` | chain guides |
| `skills/dapp-integration/references/ton.md` | chain guides |
| `skills/dapp-integration/references/aptos.md` | chain guides |
| `skills/dapp-integration/references/cosmos.md` | chain guides |
| `skills/dapp-integration/references/tron.md` | chain guides |
| `skills/dapp-integration/references/sui.md` | chain guides |
| `skills/dapp-integration/references/detection-and-setup.md` | detection |
| `skills/dapp-integration/references/adapters.md` | adapters |
| `skills/dapp-integration/references/telegram-miniapp.md` | telegram |
| `skills/dapp-integration/references/deeplink.md` | deeplink |
| `skills/dapp-integration/references/bitget-exclusive.md` | exclusive features |

**Source fidelity: 13/13 files present**

### From `dapp-common-skill` → 10 reference files (prefixed `dapp-`)

| Plugin Path | Source |
|-------------|--------|
| `skills/dapp-integration/references/dapp-layout.md` | layout |
| `skills/dapp-integration/references/dapp-wallet-connection.md` | wallet-connection |
| `skills/dapp-integration/references/dapp-adapter-integration.md` | adapter-integration |
| `skills/dapp-integration/references/dapp-transfer.md` | transfer |
| `skills/dapp-integration/references/dapp-token-approval.md` | token-approval |
| `skills/dapp-integration/references/dapp-chain-switching.md` | chain-switching |
| `skills/dapp-integration/references/dapp-signing.md` | signing |
| `skills/dapp-integration/references/dapp-transaction-lifecycle.md` | transaction-lifecycle |
| `skills/dapp-integration/references/dapp-gas-and-fees.md` | gas-and-fees |
| `skills/dapp-integration/references/dapp-ux-patterns.md` | ux-patterns |

**Source fidelity: 10/10 files present**

### From `bitget-wallet-partner-skill` → 4 reference files

| Plugin Path | Source |
|-------------|--------|
| `skills/api-debugging/references/authentication.md` | authentication |
| `skills/api-debugging/references/swap-order.md` | swap-order |
| `skills/api-debugging/references/market-data.md` | market-data |
| `skills/api-debugging/references/token.md` | token |

**Source fidelity: 4/4 files present**

### Overall: 44/44 source files accounted for. Zero missing content.

---

## 6. Cross-Reference Consistency Matrix

| Item | Expected Value | Files Where Verified |
|------|---------------|---------------------|
| Chain codes | `eth, sol, bnb, base, arbitrum, matic, morph, trx` | defi-trading SKILL.md, swap.md, swap-safety.mdc, commands.md, CLAUDE.md |
| MCP tools (swap) | `swap_quote, swap_confirm, swap_make_order, swap_send, check_swap_token, balance` | defi-trading SKILL.md, README.md, CLAUDE.md, defi-operator.md, swap-safety.mdc |
| Token analysis tools | `bgw_token_find, bgw_token_check, bgw_token_analyze, bgw_address_find` | token-analysis SKILL.md, market-data.md, token-analyze.md, address-find.md |
| Script paths | `scripts/<name>.py` | SKILL.md files, commands.md, CLAUDE.md |
| Feature flags | `user_gas` (user pays), `no_gas` (gasless) | swap.md, swap-safety.mdc, defi-trading SKILL.md, bitget-wallet-agent-api.py |
| Provider namespace | `window.bitkeep.*` | provider-namespace.mdc, dapp-integration SKILL.md, dapp-developer.md |
| Version | `1.0.0` | Both plugin.json, CHANGELOG.md, all 7 SKILL.md frontmatter |
| License | `MIT` | Both plugin.json, LICENSE, all 7 SKILL.md frontmatter |
| Author | `Bitget Wallet` / `Bitget Wallet AI Lab` | Both plugin.json, CLAUDE.md, all 7 SKILL.md metadata |
| API domain (Bitget) | `copenapi.bgwapi.io` | bitget-wallet-agent-api.py, social-wallet.py |
| API domain (x402) | User-specified URLs (third-party) | x402_pay.py `pay` subcommand |
| Endpoint naming | `getOrderDetails` (CLI) / `getSwapOrder` (partner API) | swap.md (cross-referenced), swap-safety.mdc, swap-order.md |

---

## 7. Security Audit Summary

### SlowMist Agent Security Framework ([v0.1.2](https://github.com/slowmist/slowmist-agent-security))

Full report: `reviews/security-audit-slowmist-v1.0.md`

| Pattern Category | Check Points | Flags Found |
|-----------------|-------------|-------------|
| Code-Level Red Flags | 11 | 0 |
| Social Engineering & Prompt Injection | 8 | 0 |
| Supply Chain Attack | 7 | 0 |
| **Total** | **26** | **0** |

**Risk: 🟢 LOW | Verdict: ✅ SAFE**

Key security features:
- Private keys: `tempfile.mkstemp()` → `read_key_file()` reads + deletes → `variable = None` clears memory
- Network: Bitget API calls to `copenapi.bgwapi.io`; x402 payments call user-specified third-party URLs
- No persistence: No crontabs, no startup scripts, no auto-update
- No privilege escalation: Only `chmod 0600` (restrictive, not permissive)
- No binary files: All code is readable Python + Markdown
- Human-in-the-loop: agent-orchestrated confirmation at 3 layers (scripts are execution tools, not interactive)

### Informational Items (not security concerns)

1. Test API credentials in `authentication.md` — intentionally shared, rate-limited (2 QPS), upstream-identical
2. `importlib` usage — standard Python pattern for hyphenated module names
3. `X402_PRIVATE_KEY` env var fallback — key stays local, used only for signing

---

## 8. Comparison with Phantom Connect Plugin

| Dimension | Phantom Connect | Bitget Wallet | Delta |
|-----------|----------------|---------------|-------|
| Skills | 8 | 7 | -1 (but broader scope) |
| Rules | 3 (alwaysApply: true) | 3 (alwaysApply: true) | Equal |
| Agents | 2 | 3 | +1 |
| Reference files | 7 | 37 | +30 |
| Total content lines | ~2,000 | ~17,500 | +15,500 |
| Chains (swap) | 4 (EVM only) | 8 (EVM + Solana + Tron) | +4 |
| Chains (DApp) | 1 (Solana) | 8+ | +7 |
| MCP servers | 2 | 1 | -1 |
| CLI tools | 0 | 7 Python scripts | +7 |
| Gasless | No | Yes (EIP-7702) | +1 |
| Cross-chain | No | Yes | +1 |
| Token analysis | No | Yes | +1 |
| RWA trading | No | Yes | +1 |
| x402 payments | No | Yes | +1 |
| Logo file | Yes | Yes | Equal |
| CHANGELOG.md | Yes | Yes | Equal |
| `.claude-plugin/` | Yes | Yes | Equal |

---

## 9. SKILL.md Frontmatter Consistency

All 7 skills use identical frontmatter structure:

```yaml
---
name: <skill-name>
description: >
  <multi-line description with trigger keywords>
license: MIT
metadata:
  author: Bitget Wallet
  version: 1.0.0
  tags: [<relevant-tags>]
---
```

| Skill | name | license | metadata.version | metadata.author |
|-------|------|---------|-----------------|----------------|
| defi-trading | ✅ | ✅ MIT | ✅ 1.0.0 | ✅ Bitget Wallet |
| token-analysis | ✅ | ✅ MIT | ✅ 1.0.0 | ✅ Bitget Wallet |
| social-wallet | ✅ | ✅ MIT | ✅ 1.0.0 | ✅ Bitget Wallet |
| rwa-trading | ✅ | ✅ MIT | ✅ 1.0.0 | ✅ Bitget Wallet |
| x402-payments | ✅ | ✅ MIT | ✅ 1.0.0 | ✅ Bitget Wallet |
| dapp-integration | ✅ | ✅ MIT | ✅ 1.0.0 | ✅ Bitget Wallet |
| api-debugging | ✅ | ✅ MIT | ✅ 1.0.0 | ✅ Bitget Wallet |

---

## 10. Review Instructions for Independent Auditor

You are reviewing the Bitget Wallet Cursor Plugin at:

```
/Users/devin.yin/Documents/Work/009-AI/bgw-cursor-plugin/
```

### Recommended Review Approach

1. **Read `.cursor-plugin/plugin.json`** — verify all fields, paths resolve, JSON valid
2. **Read each `skills/*/SKILL.md`** — verify frontmatter, routing table, description quality
3. **Spot-check 3-5 `references/*.md`** — verify content is substantial, technical, and matches the skill's claimed scope
4. **Read all 3 `rules/*.mdc`** — verify `alwaysApply: true`, globs correct, rules make technical sense
5. **Read all 3 `agents/*.md`** — verify they reference correct tools, rules, and skills
6. **Read `CLAUDE.md`** — verify accuracy against actual repo structure
7. **Read `README.md`** — verify claims match reality (chain count, skill count, file count)
8. **Scan `scripts/*.py`** — verify no hardcoded credentials, correct API domain, secure key handling
9. **Run SlowMist patterns** — `patterns/red-flags.md` (11 categories) against all `.py` files
10. **Verify logo** — `assets/logo.svg` exists and is valid SVG

### Key Questions to Answer

- [ ] Does every file referenced in `plugin.json` exist on disk?
- [ ] Are all 44 source files from the 4 upstream repos present?
- [ ] Are chain codes consistent across all files (8 chains)?
- [ ] Are MCP tool names consistent across skills, agents, README, CLAUDE.md?
- [ ] Do Python scripts handle private keys securely (read-and-delete)?
- [ ] Is human confirmation required before trade execution?
- [ ] Are there any hardcoded secrets in any file?
- [ ] Does the plugin auto-update or phone home unexpectedly?
- [ ] Does the plugin request permissions beyond its stated scope?

### Known Accepted Items

These items have been evaluated and intentionally accepted:

1. **Test API credentials in `authentication.md`** — shared test keys (2 QPS limit), upstream-identical, clearly warned
2. **`getOrderDetails` vs `getSwapOrder` naming** — two different API paths for the same function (CLI vs partner API); cross-referenced in `swap.md`
3. **`requirements.txt` uses `>=` not `==`** — acceptable for a plugin (not a production service)

---

## 11. Audit Trail

| Date | Activity | Result |
|------|----------|--------|
| 2026-03-30 | Initial plugin creation | 68 files, 17,500 lines |
| 2026-03-30 | Independent audit (zero-context, file-by-file) | 8.5/10, 1 blocking (logo) + 6 quality |
| 2026-03-30 | Fix: logo downloaded from official repo | Blocking resolved |
| 2026-03-30 | Fix: swap.md 7→8 chains + Tron row | Quality resolved |
| 2026-03-30 | Fix: social-wallet.md table column alignment | Quality resolved |
| 2026-03-30 | Fix: getOrderDetails/getSwapOrder cross-reference | Quality resolved |
| 2026-03-30 | Fix: plugin.json description trimmed to 107 chars | Quality resolved |
| 2026-03-30 | SlowMist Agent Security audit (26 checkpoints) | 🟢 LOW / ✅ SAFE |
| 2026-03-30 | This submission review document created | Ready for independent review |

---

*This document is self-contained. An independent reviewer with no prior context should be able to fully audit the plugin using only this document and the repository files.*
