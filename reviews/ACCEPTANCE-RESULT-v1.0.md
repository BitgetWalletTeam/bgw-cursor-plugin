# Bitget Wallet Cursor Plugin — Acceptance Test Result

> **Version:** 1.0
> **Date:** 2026-04-02
> **Baseline:** `reviews/ACCEPTANCE-TEST.md` v1.2
> **Runtime:** Cursor IDE (Agent mode)
> **Executor:** AI Acceptance Agent (Claude)
> **Repository:** `bgw-cursor-plugin` @ branch `feature/plugin-v1.0`

---

## Overall Verdict: PASS

35/35 tests pass. All levels at 100%.

> **History:** Initial run found 2 failures (T2.1e, T2.9). Fixed in commit `ec2593d`, re-tested and confirmed PASS.

---

## Summary by Level

| Level | Tests | Passed | Failed | Pass Rate | Required | Status |
|-------|-------|--------|--------|-----------|----------|--------|
| Level 1: Structural | T1.1–T1.8 | 8 | 0 | 100% | 100% | **PASS** |
| Level 2: CLI Help (T2.1) | T2.1a–f | 6 | 0 | 100% | 100% | **PASS** |
| Level 2: CLI API (T2.2–T2.12) | T2.2–T2.12 | 11 | 0 | 100% | 80% | **PASS** |
| Level 3: Knowledge | T3.1–T3.9 | 9 | 0 | 100% | 100% | **PASS** |
| Level 4: Consistency | T4.1–T4.5 | 5 | 0 | 100% | 100% | **PASS** |
| **Total** | **35** | **35** | **0** | **100%** | — | **PASS** |

---

## Execution Log

| Test ID | Result | Notes |
|---------|--------|-------|
| T1.1    | PASS   | Cursor manifest valid: name=`bitget-wallet`, version=`1.0.0`, displayName=`Bitget Wallet`, description ≤120 chars, author/email present, license=MIT, logo `assets/logo.svg` exists and non-empty, skills/rules/agents dirs exist, mcpServers `.mcp.json` exists |
| T1.2    | PASS   | Claude Code manifest valid: name/version match Cursor manifest, no `rules` field (correct for Claude Code), skills/agents dirs exist |
| T1.3    | PASS   | All 7 skills have valid SKILL.md with correct `name:` and `description:` frontmatter. Reference file counts verified: defi-trading=4/4, token-analysis=3/3, social-wallet=1/1, rwa-trading=1/1, x402-payments=1/1, dapp-integration=23/23, api-debugging=4/4 |
| T1.4    | PASS   | All 3 rules have `alwaysApply: true`, `globs:`, and `description:` in frontmatter: provider-namespace, security-practices, swap-safety |
| T1.5    | PASS   | All 3 agents have correct `name:` and `description:` frontmatter: defi-operator, dapp-developer, api-debugger |
| T1.6    | PASS   | No junk files in tracked repository. `__pycache__` found in `.venv/` and `scripts/` but both are gitignored (verified via `git check-ignore`). No empty files in tracked tree |
| T1.7    | PASS   | LICENSE file first line is "MIT License" |
| T1.8    | PASS   | `.gitignore` covers `.env`, `.social-wallet-secret`, and `.venv` |
| T2.1a   | PASS   | `bitget-wallet-agent-api.py --help` exits 0 |
| T2.1b   | PASS   | `order_sign.py --help` exits 0 |
| T2.1c   | PASS   | `order_make_sign_send.py --help` exits 0 |
| T2.1d   | PASS   | `x402_pay.py --help` exits 0 |
| T2.1e   | PASS   | `social-wallet.py --help` exits 0 — prints usage text. *(Re-test after fix commit `ec2593d`: argparse now runs before credential check)* |
| T2.1f   | PASS   | `social_order_make_sign_send.py --help` exits 0 |
| T2.2    | PASS   | Token search (`search-tokens --keyword USDT`) returns valid JSON, `data.list` has 100 tokens, each with `symbol`, `chain`, `contract` fields |
| T2.3    | PASS   | Token price (`token-price --chain eth --contract 0xdAC17...`) returns valid JSON with `price=1` for USDT |
| T2.4    | PASS   | Balance query (`batch-v2 --chain eth --address 0xd8dA6B...`) returns valid JSON for vitalik.eth |
| T2.5    | PASS   | K-line data (`kline --chain eth --contract 0xdAC17... --period 1h --size 5`) returns valid JSON |
| T2.6    | PASS   | Security audit (`security --chain eth --contract 0xdAC17...`) returns valid JSON with risk assessment data |
| T2.7    | PASS   | Swap quote (`quote --from-chain eth --from-symbol USDT ...`) returns valid JSON with `data.quoteResults` |
| T2.8    | PASS   | Token risk check (`check-swap-token ...`) returns valid JSON with `data.list` |
| T2.9    | PASS   | `echo '{}' \| python3 scripts/order_sign.py --private-key-file /dev/null` — exits 1 with clean error `ERROR: No signatures or txs in response`. No traceback. *(Re-test after fix commit `ec2593d`: `key_utils.py` now guards `unlink()` with `is_file()` and catches `PermissionError/OSError`)* |
| T2.10   | PASS   | Token rankings (`rankings --name topGainers`) returns valid JSON with ranking entries |
| T2.11   | PASS   | RWA stock discovery (`rwa-get-user-ticker-selector --chain bnb`) returns valid JSON |
| T2.12   | PASS   | `social-wallet.py profile` exits 1 with clean error "Missing credentials" (not a Python traceback). Confirms script loads and runs auth flow before failing |
| T3.1    | PASS   | **DApp Integration:** Agent references `dapp-integration` skill; response uses `window.bitkeep.ethereum` (not `window.ethereum`); SKILL.md includes code examples with provider detection (lines 196–201); mentions EIP-6963 and adapter integration (RainbowKit/Web3Modal, line 91) |
| T3.2    | PASS   | **Swap flow:** Agent references `defi-trading` skill; describes correct 6-step flow (quote→confirm→makeOrder→sign→send→getOrderDetails); user confirmation required before signing (SKILL.md line 50); ~60s makeOrder expiry documented (swap.md line 7); does NOT mention `data.signatures` (explicitly excluded in swap.md line 9) |
| T3.3    | PASS   | **API debugging:** Agent references `api-debugging` skill; distinguishes 3 auth models: HMAC (`x-api-signature`), Partner-Code, Agent CLI (`X-SIGN`+`X-TIMESTAMP`) per API Model Matrix (SKILL.md lines 42–48); asks which host (`bopenapi` vs `copenapi`); suggests checking timestamp drift, IP whitelist, signature |
| T3.4    | PASS   | **Chain support:** Lists exactly 8 chains: Ethereum, BNB, Arbitrum, Base, Polygon, Solana, Morph, Tron with correct codes (eth, bnb, arbitrum, base, matic, sol, morph, trx). Does NOT claim swap support for Bitcoin, Aptos, Cosmos, TON, or Sui |
| T3.5    | PASS   | **Security enforcement:** Generated code uses `window.bitkeep.ethereum` (per `provider-namespace.mdc`); includes user confirmation before sending (per `security-practices.mdc` line 12); no hardcoded private keys (line 7); follows provider namespace rule |
| T3.6    | PASS   | **x402 payments:** Agent references `x402-payments` skill; explains HTTP 402→sign→retry flow (SKILL.md lines 35–41); mentions EIP-3009 for EVM (line 30); Solana is sign-only (line 31); user approval required (line 64) |
| T3.7    | PASS   | **Token analysis:** Agent references `token-analysis` skill; suggests `security` subcommand for safety audit; suggests `trading-dynamics`/`tx-info` for activity; uses chain code `eth` and USDT contract `0xdAC17F958D2ee523a2206206994597C13D831ec7` |
| T3.8    | PASS   | **Social Wallet:** Agent references `social-wallet` skill; explains TEE-based signing (no local private key); mentions `social-wallet.py` and `social_order_make_sign_send.py`; `walletId` needed via `profile` command; explicit user confirmation required before every signing operation |
| T3.9    | PASS   | **RWA trading:** Agent references `rwa-trading` skill; explains RWA as tokenized real-world asset stocks; mentions discovery flow (rwa-get-user-ticker-selector, rwa-get-config, rwa-stock-info, rwa-stock-order-price); signing reuses swap scripts (`order_make_sign_send.py`/`social_order_make_sign_send.py`) |
| T4.1    | PASS   | README lists 8 swap chains ("Ethereum · BNB · Arbitrum · Base · Polygon · Solana · Morph · Tron") and "32+" market data. CLAUDE.md lists "Swap (8)" with same chains and "Market Data (32+)". Match confirmed |
| T4.2    | PASS   | Both plugin.json manifests match: name=`bitget-wallet`, version=`1.0.0`, description identical, author.name=`Bitget Wallet AI Lab`, author.email=`AiAgent@bitget.com` |
| T4.3    | PASS   | All 7 scripts in CLAUDE.md table exist in `scripts/` directory. No extra `.py` files found outside the documented list |
| T4.4    | PASS   | All 7 SKILL.md `name:` frontmatter values match their parent directory names exactly |
| T4.5    | PASS   | All 37 reference files across all 7 skills exist: defi-trading (swap.md, wallet-signing.md, commands.md, first-time-setup.md), token-analysis (market-data.md, token-analyze.md, address-find.md), social-wallet (social-wallet.md), rwa-trading (rwa.md), x402-payments (x402-payments.md), api-debugging (authentication.md, swap-order.md, market-data.md, token.md), dapp-integration (23 files — all verified) |

---

## Issues Found and Resolved

### Issue 1: T2.1e — `social-wallet.py --help` exits with error (RESOLVED)

- **Severity:** Low
- **Root cause:** `social-wallet.py` validated `.social-wallet-secret` credentials at module load time, before `argparse` could process `--help`
- **Fix:** Commit `ec2593d` — moved argparse (including `--help`/`-h`) before credential check
- **Re-test result:** PASS — `--help` now prints usage and exits 0

### Issue 2: T2.9 — `order_sign.py` leaks traceback on invalid key file (RESOLVED)

- **Severity:** Low
- **Root cause:** `key_utils.read_key_file()` called `pathlib.Path.unlink()` on `/dev/null` (a device file), throwing `PermissionError` with full traceback
- **Fix:** Commit `ec2593d` — added `is_file()` guard before `unlink()` and `try/except (PermissionError, OSError)` fallback
- **Re-test result:** PASS — outputs clean error `ERROR: No signatures or txs in response`, no traceback

---

## Verdict Analysis

Per the acceptance test verdict criteria:

| Criterion | Required | Actual | Met? |
|-----------|----------|--------|------|
| All Level 1 pass | 100% | 100% (8/8) | Yes |
| All T2.1 pass | 100% | 100% (6/6) | Yes |
| ≥80% Level 2 API tests pass | 80% | 100% (11/11) | Yes |
| All Level 3 core checkboxes pass | 100% | 100% (9/9, all criteria met) | Yes |
| All Level 4 pass | 100% | 100% (5/5) | Yes |

**Verdict: PASS**

All 35 tests pass across all 4 levels. The two issues found in the initial run were fixed in commit `ec2593d` and confirmed resolved via re-test.

**Runtime used for Level 3:** [x] Cursor IDE / [ ] Claude Code / [ ] Both
