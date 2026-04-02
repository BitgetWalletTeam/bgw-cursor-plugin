# Bitget Wallet Cursor Plugin — Acceptance Test Plan

> Version: 1.3
> Date: 2026-03-31
> Repository: `bgw-cursor-plugin`
> Plugin Version: 1.0.0

---

## Purpose

This document defines the acceptance criteria and executable test cases for the Bitget Wallet Cursor / Claude Code plugin. It is designed to be:

1. **Auditable** — an independent auditor can verify the tests cover all plugin claims
2. **Executable** — an independent agent can run every test case and report pass/fail
3. **Self-contained** — all context needed to run tests is in this document

---

## Prerequisites

### Environment

| Requirement | Minimum | Notes |
|-------------|---------|-------|
| Python | 3.9+ | For CLI script tests |
| Cursor IDE or Claude Code | Latest | For plugin loading / behavioral tests |
| OS | macOS / Linux | Windows not tested |
| Network | Internet access | CLI scripts call Bitget Wallet public API |

### Setup

All commands in this document assume the working directory is the **repository root** (`bgw-cursor-plugin/`). The variable `$REPO_ROOT` refers to the absolute path of the repository on the local machine.

```bash
# 1. Set REPO_ROOT to wherever you cloned / checked out the plugin
export REPO_ROOT="$(pwd)"   # run this from the repository root

# 2. Create Python virtual environment and install deps
cd "$REPO_ROOT"
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 3. Verify setup
python3 scripts/bitget-wallet-agent-api.py --help
```

**Success criteria for setup:** The `--help` command prints a usage message listing subcommands (quote, confirm, make-order, send, etc.) with exit code 0.

**To test plugin loading**, symlink or clone the repo into any project:

- **Cursor IDE:** Symlink the plugin into your test project, then open it in Cursor.
- **Claude Code:** Place or symlink the repo so that `.claude-plugin/plugin.json` is visible to the Claude Code agent.

```bash
cd /path/to/your/test-project
ln -s "$REPO_ROOT" .bitget-wallet
```

### What Is NOT Tested

- Live swap execution (requires real funds)
- MCP server integration (requires `uv`)
- x402 real payment (requires funded wallet)
- Social Login Wallet TEE signing (requires Bitget account session)

These are excluded because they involve real on-chain transactions or external authentication that cannot be safely automated.

### Runtime Scope

This plugin targets both **Cursor IDE** and **Claude Code**. The acceptance plan covers:

- **Structural acceptance** for both targets (Level 1: T1.1 for Cursor, T1.2 for Claude Code)
- **Behavioral/knowledge acceptance** via either Cursor IDE or Claude Code (Level 3) — the acceptance agent should use whichever runtime is available and note which one in the Execution Log
- **CLI acceptance** is runtime-independent (Level 2) — scripts run directly in a terminal

---

## Test Matrix

### Level 1: Structural Integrity (no IDE, no network)

These tests verify the plugin's file structure against Cursor/Claude Code plugin standards.

#### T1.1 — Plugin manifest exists and is valid JSON

| Field | Check | Expected |
|-------|-------|----------|
| File | `.cursor-plugin/plugin.json` exists | Yes |
| Parse | Valid JSON | No parse errors |
| `name` | Non-empty string | `"bitget-wallet"` |
| `displayName` | Non-empty string | `"Bitget Wallet"` |
| `version` | Semver string | `"1.0.0"` |
| `description` | Non-empty, ≤ 120 chars | Present |
| `author.name` | Non-empty | `"Bitget Wallet AI Lab"` |
| `author.email` | Valid email format | `"AiAgent@bitget.com"` |
| `license` | Non-empty | `"MIT"` |
| `logo` | Points to existing file | `assets/logo.svg` exists and is non-empty |
| `skills` | Points to existing directory | `./skills/` exists |
| `rules` | Points to existing directory | `./rules/` exists |
| `agents` | Points to existing directory | `./agents/` exists |
| `mcpServers` | Points to existing file | `.mcp.json` exists |

```bash
# Executable check — validates all table criteria
python3 -c "
import json, os
d = json.load(open('.cursor-plugin/plugin.json'))
assert d['name'] == 'bitget-wallet', 'name mismatch'
assert d['displayName'] == 'Bitget Wallet', 'displayName mismatch'
assert d['version'] == '1.0.0', 'version mismatch'
assert d['description'] and len(d['description']) <= 120, 'description empty or too long'
assert d['author']['name'], 'author.name missing'
assert '@' in d['author']['email'], 'author.email invalid'
assert d['license'] == 'MIT', 'license mismatch'
assert os.path.isfile(d['logo']), f'logo file missing: {d[\"logo\"]}'
assert os.path.getsize(d['logo']) > 0, 'logo file is empty'
assert os.path.isdir(d['skills'].rstrip('/')), 'skills dir missing'
assert os.path.isdir(d['rules'].rstrip('/')), 'rules dir missing'
assert os.path.isdir(d['agents'].rstrip('/')), 'agents dir missing'
assert os.path.isfile(d['mcpServers']), 'mcpServers file missing'
print('T1.1 PASS')
"
```

#### T1.2 — Claude Code manifest exists and is valid

| Field | Check | Expected |
|-------|-------|----------|
| File | `.claude-plugin/plugin.json` exists | Yes |
| Parse | Valid JSON | No parse errors |
| `name` | Matches Cursor manifest | `"bitget-wallet"` |
| `version` | Matches Cursor manifest | `"1.0.0"` |
| `skills` | Points to existing directory | `./skills/` |
| `agents` | Points to existing directory | `./agents/` |
| No `rules` field | Claude Code does not use `.mdc` rules | Field absent or null |

```bash
python3 -c "
import json, os
d = json.load(open('.claude-plugin/plugin.json'))
assert d['name'] == 'bitget-wallet', 'name mismatch'
assert d['version'] == '1.0.0', 'version mismatch'
assert 'rules' not in d or d.get('rules') is None, 'rules should be absent for Claude Code'
assert d.get('skills'), 'skills field missing'
assert os.path.isdir(d['skills'].rstrip('/')), f'skills dir not found: {d[\"skills\"]}'
assert d.get('agents'), 'agents field missing'
assert os.path.isdir(d['agents'].rstrip('/')), f'agents dir not found: {d[\"agents\"]}'
print('T1.2 PASS')
"
```

#### T1.3 — All 7 skills have valid SKILL.md with frontmatter

| Skill Directory | SKILL.md exists | Has `name:` | Has `description:` | Has `references/` |
|-----------------|-----------------|-------------|--------------------|--------------------|
| `skills/defi-trading/` | Yes | `defi-trading` | Yes | Yes (4 files) |
| `skills/token-analysis/` | Yes | `token-analysis` | Yes | Yes (3 files) |
| `skills/social-wallet/` | Yes | `social-wallet` | Yes | Yes (1 file) |
| `skills/rwa-trading/` | Yes | `rwa-trading` | Yes | Yes (1 file) |
| `skills/x402-payments/` | Yes | `x402-payments` | Yes | Yes (1 file) |
| `skills/dapp-integration/` | Yes | `dapp-integration` | Yes | Yes (23 files) |
| `skills/api-debugging/` | Yes | `api-debugging` | Yes | Yes (4 files) |

```bash
# Executable check — validates SKILL.md frontmatter, references/ exists, and expected file counts
declare -A expected_refs=(
  [defi-trading]=4 [token-analysis]=3 [social-wallet]=1 [rwa-trading]=1
  [x402-payments]=1 [dapp-integration]=23 [api-debugging]=4
)
for skill in defi-trading token-analysis social-wallet rwa-trading x402-payments dapp-integration api-debugging; do
  f="skills/$skill/SKILL.md"
  ref_count=$(find "skills/$skill/references/" -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  expected=${expected_refs[$skill]}
  if test -f "$f" && grep -q "^name: $skill" "$f" && grep -q "^description:" "$f" && [ "$ref_count" -eq "$expected" ]; then
    echo "T1.3 $skill PASS (refs: $ref_count/$expected)"
  else
    echo "T1.3 $skill FAIL (refs: $ref_count/$expected)"
  fi
done
```

#### T1.4 — All 3 rules have valid frontmatter with alwaysApply

| Rule File | `alwaysApply` | Has `globs` | Has `description` |
|-----------|---------------|-------------|-------------------|
| `rules/provider-namespace.mdc` | `true` | Yes | Yes |
| `rules/security-practices.mdc` | `true` | Yes | Yes |
| `rules/swap-safety.mdc` | `true` | Yes | Yes |

```bash
# Validates alwaysApply, globs, and description are all present
for rule in provider-namespace security-practices swap-safety; do
  f="rules/$rule.mdc"
  if grep -q "alwaysApply: true" "$f" && grep -q "globs:" "$f" && grep -q "description:" "$f"; then
    echo "T1.4 $rule PASS"
  else
    echo "T1.4 $rule FAIL"
  fi
done
```

#### T1.5 — All 3 agents have YAML frontmatter

| Agent File | Has `name:` | Has `description:` |
|------------|-------------|-------------------|
| `agents/defi-operator.md` | `defi-operator` | Yes |
| `agents/dapp-developer.md` | `dapp-developer` | Yes |
| `agents/api-debugger.md` | `api-debugger` | Yes |

```bash
# Validates both name: and description: are present in YAML frontmatter
for agent in defi-operator dapp-developer api-debugger; do
  f="agents/$agent.md"
  if grep -q "^name: $agent" "$f" && grep -q "^description:" "$f"; then
    echo "T1.5 $agent PASS"
  else
    echo "T1.5 $agent FAIL"
  fi
done
```

#### T1.6 — No junk files in repository

```bash
# Check for common junk
find . -path ./.git -prune -o \( -name '.DS_Store' -o -name '*.pyc' -o -name '__pycache__' -o -name 'node_modules' -o -name '.env' \) -print | head -5
# Expected: no output
# Check for empty files
find . -path ./.git -prune -o -type f -empty -print | head -5
# Expected: no output
```

#### T1.7 — LICENSE file is MIT

```bash
head -1 LICENSE | grep -q "MIT License" && echo "T1.7 PASS" || echo "T1.7 FAIL"
```

#### T1.8 — .gitignore covers sensitive files

```bash
grep -q '.env' .gitignore && grep -q '.social-wallet-secret' .gitignore && grep -q '.venv' .gitignore && echo "T1.8 PASS" || echo "T1.8 FAIL"
```

---

### Level 2: CLI Smoke Tests (requires network, no API key)

These tests verify the Python CLI scripts function correctly against the public Bitget Wallet API. No API key, wallet, or private key is required.

**Setup:** Activate the Python venv before running (from repository root).

```bash
cd "$REPO_ROOT"
source .venv/bin/activate
```

#### T2.1 — All scripts print help without error

```bash
python3 scripts/bitget-wallet-agent-api.py --help > /dev/null 2>&1 && echo "T2.1a PASS" || echo "T2.1a FAIL"
python3 scripts/order_sign.py --help > /dev/null 2>&1 && echo "T2.1b PASS" || echo "T2.1b FAIL"
python3 scripts/order_make_sign_send.py --help > /dev/null 2>&1 && echo "T2.1c PASS" || echo "T2.1c FAIL"
python3 scripts/x402_pay.py --help > /dev/null 2>&1 && echo "T2.1d PASS" || echo "T2.1d FAIL"
python3 scripts/social-wallet.py --help > /dev/null 2>&1 && echo "T2.1e PASS" || echo "T2.1e FAIL"
python3 scripts/social_order_make_sign_send.py --help > /dev/null 2>&1 && echo "T2.1f PASS" || echo "T2.1f FAIL"
```

**Expected:** All 6 print exit code 0.

#### T2.2 — Token search returns valid JSON

```bash
python3 scripts/bitget-wallet-agent-api.py search-tokens --keyword USDT 2>/dev/null
```

**Expected:**
- Exit code 0
- Output is valid JSON
- `data.list` is a non-empty array
- Each item has `symbol`, `chain`, `contract` fields

```bash
python3 -c "
import subprocess, json
r = subprocess.run(['python3', 'scripts/bitget-wallet-agent-api.py', 'search-tokens', '--keyword', 'USDT'], capture_output=True, text=True)
d = json.loads(r.stdout)
assert d.get('error_code') == 0 or d.get('code') == '0' or 'data' in d, f'Bad response: {r.stdout[:200]}'
print('T2.2 PASS')
"
```

#### T2.3 — Token price returns data

```bash
python3 scripts/bitget-wallet-agent-api.py token-price --chain eth --contract 0xdAC17F958D2ee523a2206206994597C13D831ec7
```

**Expected:**
- Exit code 0
- Output is valid JSON
- Contains price data for USDT on Ethereum

#### T2.4 — Balance query returns data

```bash
python3 scripts/bitget-wallet-agent-api.py batch-v2 \
  --chain eth \
  --address 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045 \
  --contract ""
```

**Expected:**
- Exit code 0
- Output is valid JSON
- Returns ETH balance for the queried address (vitalik.eth)

#### T2.5 — K-line data returns array

```bash
python3 scripts/bitget-wallet-agent-api.py kline \
  --chain eth \
  --contract 0xdAC17F958D2ee523a2206206994597C13D831ec7 \
  --period 1h --size 5
```

**Expected:**
- Exit code 0
- Output is valid JSON
- `data.klineList` is an array with ≤ 5 items
- Each item has OHLC fields

#### T2.6 — Security audit returns risk data

```bash
python3 scripts/bitget-wallet-agent-api.py security \
  --chain eth \
  --contract 0xdAC17F958D2ee523a2206206994597C13D831ec7
```

**Expected:**
- Exit code 0
- Output is valid JSON
- Contains risk assessment fields (e.g. `highRisk`, `riskCount`)

#### T2.7 — Swap quote returns market results (read-only, no funds needed)

```bash
python3 scripts/bitget-wallet-agent-api.py quote \
  --from-address 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045 \
  --from-chain eth \
  --from-symbol USDT \
  --from-contract 0xdAC17F958D2ee523a2206206994597C13D831ec7 \
  --from-amount 10 \
  --to-chain eth \
  --to-symbol ETH \
  --to-contract ""
```

**Expected:**
- Exit code 0
- Output is valid JSON
- `data.quoteResults` is a non-empty array
- Each result has `market`, `outAmount`, `minAmount` fields

#### T2.8 — Token risk check returns safety data

```bash
python3 scripts/bitget-wallet-agent-api.py check-swap-token \
  --from-chain eth --from-contract 0xdAC17F958D2ee523a2206206994597C13D831ec7 --from-symbol USDT \
  --to-chain eth --to-contract "" --to-symbol ETH
```

**Expected:**
- Exit code 0
- Output is valid JSON
- `data.list` is an array

#### T2.9 — order_sign.py rejects empty input gracefully

```bash
echo '{}' | python3 scripts/order_sign.py --private-key-file /dev/null 2>&1
```

**Expected:**
- Exit code 1 (error)
- Stderr contains "No signatures or txs" or similar error message
- Does NOT crash with a Python traceback that leaks internal paths

#### T2.10 — Token rankings returns data

```bash
python3 scripts/bitget-wallet-agent-api.py rankings --name topGainers
```

**Expected:**
- Exit code 0
- Output is valid JSON
- Contains ranking entries

#### T2.11 — RWA stock discovery returns data

```bash
python3 scripts/bitget-wallet-agent-api.py rwa-get-user-ticker-selector --chain bnb
```

**Expected:**
- Exit code 0 (or API-level exit code with valid JSON body)
- Output is valid JSON
- `data.list` is a non-empty array
- Each item has `ticker`, `name`, `chain`, `contract`, `latest_price` fields

#### T2.12 — Social wallet profile requires auth (expected failure)

```bash
python3 scripts/social-wallet.py profile 2>&1
```

**Expected:**
- Exit code 1 (no credentials configured)
- Stderr contains an auth error or missing-token error (NOT a Python import traceback)
- Confirms the script loads and runs its auth flow before failing

---

### Level 3: Knowledge Accuracy Tests (requires Cursor IDE or Claude Code)

> **Runtime scope:** Level 3 tests are written as interactive prompts for an AI agent. They can be executed in **Cursor IDE** (primary target) or **Claude Code** (if configured with `.claude-plugin/plugin.json`). If only one runtime is available, note which one was used in the Execution Log. Claude Code structural acceptance is covered by T1.2; behavioral acceptance via Claude Code is optional but recommended if available.

These tests verify that an AI agent using this plugin produces correct, grounded responses. They must be run interactively in an AI-agent runtime (Cursor IDE or Claude Code) with the plugin loaded.

**Setup:** Open a project that contains (or symlinks to) the plugin in your chosen runtime (Cursor IDE or Claude Code).

#### T3.1 — DApp Integration knowledge

**Prompt:** "How do I connect Bitget Wallet to a React DApp?"

**Pass criteria:**
- [ ] Agent references `dapp-integration` skill
- [ ] Response mentions `window.bitkeep.ethereum` (not generic `window.ethereum`)
- [ ] Response includes actual code example with provider detection
- [ ] Mentions EIP-6963 or adapter integration as options

#### T3.2 — Swap flow knowledge

**Prompt:** "Walk me through the Bitget Wallet swap flow step by step."

**Pass criteria:**
- [ ] Agent references `defi-trading` skill
- [ ] Describes the correct flow: quote → confirm → makeOrder → sign → send → getOrderDetails
- [ ] Mentions user confirmation is required before signing
- [ ] Mentions the ~60s expiry on makeOrder data
- [ ] Does NOT mention `data.signatures` (that's partner API only)

#### T3.3 — API debugging with three auth models

**Prompt:** "I'm getting a 403 error when calling the Bitget Wallet API. How do I debug it?"

**Pass criteria:**
- [ ] Agent references `api-debugging` skill
- [ ] Distinguishes between the three auth models: HMAC (`x-api-signature`), Partner-Code, and Agent CLI (`X-SIGN` + `X-TIMESTAMP`)
- [ ] Asks which API host the user is calling (`bopenapi` vs `copenapi`)
- [ ] Suggests checking timestamp drift, IP whitelist, or signature computation

#### T3.4 — Chain support accuracy

**Prompt:** "What chains does Bitget Wallet swap support?"

**Pass criteria:**
- [ ] Lists exactly 8 chains: Ethereum, BNB, Arbitrum, Base, Polygon, Solana, Morph, Tron
- [ ] Uses correct chain codes (eth, bnb, arbitrum, base, matic, sol, morph, trx)
- [ ] Does NOT claim swap support for Bitcoin, Aptos, Cosmos, TON, or Sui

#### T3.5 — Security rule enforcement

**Prompt:** "Write a TypeScript function that connects to Bitget Wallet and sends 1 ETH."

**Pass criteria:**
- [ ] Generated code uses `window.bitkeep.ethereum`, NOT `window.ethereum`
- [ ] Code includes user confirmation before sending transaction
- [ ] Does NOT hardcode private keys or mnemonics
- [ ] Mentions or follows the provider namespace rule

#### T3.6 — x402 payment knowledge with safety qualification

**Prompt:** "How does x402 payment work with Bitget Wallet?"

**Pass criteria:**
- [ ] Agent references `x402-payments` skill
- [ ] Explains HTTP 402 → sign → retry flow
- [ ] Mentions EIP-3009 for EVM
- [ ] Mentions Solana is sign-only (not full pay flow)
- [ ] States that user approval is required before signing

#### T3.7 — Token analysis knowledge

**Prompt:** "Analyze the safety and trading activity of USDT on Ethereum for me."

**Pass criteria:**
- [ ] Agent references `token-analysis` skill
- [ ] Suggests or runs `security` subcommand for safety audit
- [ ] Suggests or runs `trading-dynamics` or `tx-info` for activity
- [ ] Correctly uses chain code `eth` and USDT contract address

#### T3.8 — Social Wallet knowledge

**Prompt:** "How does Bitget Wallet's Social Login Wallet work? How would I sign a transaction with it?"

**Pass criteria:**
- [ ] Agent references `social-wallet` skill
- [ ] Explains TEE-based signing (no local private key)
- [ ] Mentions `social-wallet.py` or `social_order_make_sign_send.py` as tools
- [ ] Mentions that a `walletId` is needed (obtained via `profile` command)
- [ ] States that explicit user confirmation is required before signing (critical security gate — agent must not present a flow that signs without user approval)

#### T3.9 — RWA trading knowledge

**Prompt:** "Can I trade stocks through Bitget Wallet? How does RWA trading work?"

**Pass criteria:**
- [ ] Agent references `rwa-trading` skill
- [ ] Explains RWA as tokenized real-world asset stocks
- [ ] Mentions the discovery flow (rwa-get-config, rwa-stock-info, rwa-stock-order-price)
- [ ] Mentions that signing reuses the same swap signing scripts

---

### Level 4: Cross-Consistency Tests (document review)

These tests verify internal consistency across the plugin's documentation.

#### T4.1 — README ↔ CLAUDE.md chain counts match

| Claim | README.md | CLAUDE.md | Match? |
|-------|-----------|-----------|--------|
| Swap chains | 8 specific chains listed | "Swap (8)" | Must match |
| Market Data chains | "All major chains (32+)" | "Market Data (32+)" | Must match |

#### T4.2 — plugin.json manifests are consistent

| Field | `.cursor-plugin/plugin.json` | `.claude-plugin/plugin.json` | Match? |
|-------|------------------------------|------------------------------|--------|
| `name` | Same | Same | Required |
| `version` | Same | Same | Required |
| `description` | Same | Same | Required |
| `author` | Same | Same | Required |

#### T4.3 — Scripts table in CLAUDE.md matches actual scripts

Verify every file in `scripts/` has a row in CLAUDE.md's Scripts table, and every row references an existing file.

#### T4.4 — Skill names in SKILL.md frontmatter match directory names

Verify that each `skills/*/SKILL.md` has `name:` matching its parent directory name.

#### T4.5 — Internal documentation links are not broken

Check that all `references/*.md` files referenced in each `SKILL.md` routing table actually exist.

```bash
# Example check for defi-trading
for ref in swap.md wallet-signing.md commands.md first-time-setup.md; do
  test -f "skills/defi-trading/references/$ref" && echo "T4.5 defi-trading/$ref PASS" || echo "T4.5 defi-trading/$ref FAIL"
done
```

#### T4.6 — Upstream sync: MCP tool names match live documentation

Fetch the latest `bitget-wallet-mcp` README and verify that MCP tool names referenced in the plugin match the upstream source of truth.

```bash
curl -s https://raw.githubusercontent.com/bitget-wallet-ai-lab/bitget-wallet-mcp/main/README.md -o /tmp/mcp-readme.md
# Verify key swap tools exist in upstream
for tool in swap_quote swap_confirm swap_make_order swap_send check_swap_token balance; do
  if grep -q "$tool" /tmp/mcp-readme.md; then
    echo "T4.6 $tool PASS"
  else
    echo "T4.6 $tool FAIL — not found in upstream MCP README"
  fi
done
```

**Pass criteria:**
- All MCP tool names referenced in `defi-trading/SKILL.md`, `agents/defi-operator.md`, and `rules/swap-safety.mdc` appear in the upstream README
- No `BGW_API_KEY` or `BGW_API_SECRET` references in `.mcp.json`

#### T4.7 — Upstream sync: MCP authentication model

Verify the plugin's MCP auth description matches upstream.

```bash
# Check .mcp.json has no API key env vars
python3 -c "
import json
d = json.load(open('.mcp.json'))
env = d.get('mcpServers', {}).get('bitget-wallet-mcp', {}).get('env', {})
assert 'BGW_API_KEY' not in env, 'Stale BGW_API_KEY in .mcp.json'
assert 'BGW_API_SECRET' not in env, 'Stale BGW_API_SECRET in .mcp.json'
print('T4.7 .mcp.json PASS — no API key env vars')
"
# Check upstream confirms no-key auth
grep -q "No API key required" /tmp/mcp-readme.md && echo "T4.7 upstream PASS" || echo "T4.7 upstream FAIL"
```

---

## Verdict Criteria

| Level | Tests | Minimum Pass Rate | Blocking? |
|-------|-------|-------------------|-----------|
| Level 1: Structural | T1.1–T1.8 | 100% | Yes — any failure blocks submission |
| Level 2: CLI Smoke | T2.1–T2.12 | 100% for T2.1; 80% for T2.2–T2.12 (API may be rate-limited) | T2.1 blocks; others are advisory |
| Level 3: Knowledge | T3.1–T3.9 | 100% for pass criteria checkboxes | Yes — core plugin value |
| Level 4: Consistency | T4.1–T4.7 | 100% | Yes — documentation trust + upstream fidelity |

### Overall Verdict

- **PASS**: All Level 1 pass, all T2.1 pass, ≥80% Level 2 API tests pass, all Level 3 core checkboxes pass, all Level 4 pass
- **CONDITIONAL PASS**: Minor Level 3 checkbox misses that are AI behavior variance (not plugin defect)
- **FAIL**: Any Level 1 failure, T2.1 failure, or systematic Level 3/4 failure

---

## Execution Log Template

The acceptance agent should fill this table after running all tests:

```
| Test ID | Result | Notes |
|---------|--------|-------|
| T1.1    |        |       |
| T1.2    |        |       |
| T1.3    |        |       |
| T1.4    |        |       |
| T1.5    |        |       |
| T1.6    |        |       |
| T1.7    |        |       |
| T1.8    |        |       |
| T2.1a   |        |       |
| T2.1b   |        |       |
| T2.1c   |        |       |
| T2.1d   |        |       |
| T2.1e   |        |       |
| T2.1f   |        |       |
| T2.2    |        |       |
| T2.3    |        |       |
| T2.4    |        |       |
| T2.5    |        |       |
| T2.6    |        |       |
| T2.7    |        |       |
| T2.8    |        |       |
| T2.9    |        |       |
| T2.10   |        |       |
| T2.11   |        |       |
| T2.12   |        |       |
| T3.1    |        |       |
| T3.2    |        |       |
| T3.3    |        |       |
| T3.4    |        |       |
| T3.5    |        |       |
| T3.6    |        |       |
| T3.7    |        |       |
| T3.8    |        |       |
| T3.9    |        |       |
| T4.1    |        |       |
| T4.2    |        |       |
| T4.3    |        |       |
| T4.4    |        |       |
| T4.5    |        |       |
| T4.6    |        |       |
| T4.7    |        |       |
```

**Runtime used for Level 3:** [ ] Cursor IDE / [ ] Claude Code / [ ] Both
