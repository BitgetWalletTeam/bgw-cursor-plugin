# Bitget Wallet Cursor Plugin - Independent Final Audit Report v1.4

> Audit Date: 2026-03-31
> Auditor: Independent strict review
> Repository: `bgw-cursor-plugin`
> Scope: final zero-finding verification after the team reported all `v1.3` findings fixed
> Prior Reports: `AUDIT-REPORT-v1.0.md`, `AUDIT-REPORT-v1.1.md`, `AUDIT-REPORT-v1.2.md`, `AUDIT-REPORT-v1.3.md`

---

## Executive Summary

**Verdict:** `HOLD - zero-finding verification not yet passed`

This audit confirms that the repository has improved significantly and that the specific findings from `v1.3` were largely or fully addressed:

- stale `order-create` terminology has been cleaned up in the main script flows
- stale `--private-key-sol` / `--private-key-tron` user-facing flag issues are largely fixed
- `order_make_sign_send.py` help text now includes Tron
- top-level security wording is materially better than earlier versions

However, this final zero-finding pass still surfaced **newly visible documentation consistency issues** that remain reviewer-visible under a strict marketplace/security review standard.

Current release posture:

- **Blocking issues:** 0
- **High-risk issues:** 0
- **Medium-risk issues:** 1
- **Low-risk issues:** 3

These are no longer architecture or dependency failures. They are final documentation and wording consistency issues that should be cleaned before claiming zero findings.

---

## Audit Method

This final audit used:

- Static review of updated repository contents
- Targeted verification of the claimed `v1.3` remediations
- Cross-checking:
  - `README.md`
  - `CLAUDE.md`
  - `SUBMISSION-REVIEW.md`
  - `security-audit-slowmist-v1.0.md`
  - `agents/`
  - `skills/`
  - `scripts/`
- Repo-wide residue search for:
  - `order-create`
  - `order-submit`
  - `--private-key-sol`
  - `OpenAPI`
  - stale enforcement/network-boundary wording
- Minimal non-destructive CLI smoke checks:
  - `python3 scripts/order_sign.py --help`
  - `python3 scripts/order_make_sign_send.py --help`
  - `python3 scripts/x402_pay.py --help`

This audit did **not** use:

- Live Bitget API calls
- Live MCP execution
- Real wallet credentials
- On-chain transaction execution

---

## Status of v1.3 Findings

| v1.3 Finding | Current Status |
|--------------|----------------|
| `order_sign.py` stale submit-step wording / stale flag wording | ✅ Fixed |
| reference docs stale order-flow terminology | ✅ Fixed in the previously named locations |
| `order_make_sign_send.py` CLI description omitted Tron | ✅ Fixed |

The remaining findings below are **not** repeats of the main `v1.3` findings. They are newly surfaced consistency issues visible in the final validation pass.

---

## Remaining Findings

### 1. [Medium] `api-debugging` documentation still has no single authoritative auth model

**Files:**

- `README.md`
- `skills/api-debugging/SKILL.md`
- `agents/api-debugger.md`
- `skills/api-debugging/references/authentication.md`
- `skills/api-debugging/references/swap-order.md`

**Issue:**

The repository still contains conflicting descriptions of the partner/API-debugging auth model.

Current inconsistencies include:

- `README.md` describes the skill as: `Debug Bitget Wallet Agent API: HMAC auth, error diagnosis`
- `skills/api-debugging/SKILL.md` says `bopenapi.bgwapi.io` uses headers `x-api-key`, `x-api-timestamp`, `x-api-sign`
- `skills/api-debugging/references/authentication.md` says the HMAC header is `x-api-signature`
- the same `authentication.md` also states that **Swap Order endpoints use `Partner-Code` instead of HMAC**
- `skills/api-debugging/references/swap-order.md` uses `Partner-Code` throughout
- `agents/api-debugger.md` mirrors the simplified HMAC-only partner model and does not mention the `Partner-Code` split in its workflow summary

**Why this matters:**

- A strict reviewer will not see a single source of truth for partner debugging
- Integrators can be misled on which header name/path is authoritative
- This weakens the repo's credibility exactly in the "API debugging" area that is supposed to reduce confusion

**Recommendation:**

Refactor the `api-debugging` model into a clearly separated matrix, for example:

- `bopenapi` Market/Token API -> API Key + HMAC + `x-api-signature`
- `bopenapi` Swap Order API -> `Partner-Code`
- `copenapi` Agent/CLI API -> `X-SIGN`, `X-TIMESTAMP`, `token`, `channel`, `brand`

Also update `README.md` so the high-level skill description no longer conflates "Agent API" with "HMAC auth".

---

### 2. [Low] `README.md` still compresses chain support into one ambiguous aggregate line

**File:**

- `README.md`

**Issue:**

`README.md` still contains a single `Supported chains` line that mixes swap chains and other plugin-wide chains into one flat list:

- Ethereum
- BNB
- Arbitrum
- Base
- Polygon
- Solana
- Morph
- Tron
- Bitcoin
- Aptos
- Cosmos
- TON
- Sui

This is not strictly false at the plugin level, but it is less precise than `CLAUDE.md`, which separates:

- Swap
- Market Data
- DApp Integration

**Why this matters:**

- A strict reviewer may interpret the single line as uniform support across features
- This is a wording precision issue, not a functional defect

**Recommendation:**

Mirror the `CLAUDE.md` breakdown in `README.md` to avoid ambiguity.

---

### 3. [Low] `x402-payments/SKILL.md` still uses “automatically sign” wording without immediate qualification

**File:**

- `skills/x402-payments/SKILL.md`

**Issue:**

The overview still says:

- `the agent can automatically sign a USDC payment and retry the request`

Later in the same file, the Key Rules correctly require user confirmation and note the interactive prompt behavior. The file is directionally correct, but the opening sentence is still slightly stronger than the control model described below it.

**Why this matters:**

- This is a tone/precision issue under a strict audit lens
- It can be read as weaker human gating than the repo currently intends to claim

**Recommendation:**

Qualify the sentence inline, e.g. "can sign after explicit user approval" or equivalent.

---

### 4. [Low] A few Tron-support statements are still incomplete in prose

**Files:**

- `skills/defi-trading/references/commands.md`
- `scripts/order_sign.py`

**Issue:**

Some remaining prose still under-describes current Tron support:

- `skills/defi-trading/references/commands.md` says `order_make_sign_send.py` supports `EVM and Solana`, while the CLI and code support Tron too
- `scripts/order_sign.py` opens with `Signs makeOrder (make-order) response for both EVM and Solana chains`, but the same file also implements Tron signing
- `scripts/order_sign.py` says `eth_account (EVM only)`, while Tron signing also uses `eth_account`

**Why this matters:**

- This is not a functional bug
- It is final terminology polish in reviewer-visible text

**Recommendation:**

Update these descriptions to match the actual current chain/support scope.

---

## Severity Summary

| Severity | Count | Release Impact |
|----------|-------|----------------|
| Blocking | 0 | None |
| High | 0 | None |
| Medium | 1 | Recommended to fix before claiming zero findings |
| Low | 3 | Cleanup / wording precision |

---

## Final Assessment

This repository is materially stronger than it was in `v1.0`, `v1.1`, `v1.2`, and `v1.3`.

What is clearly true now:

- The earlier structural/plugin-format problems are gone
- The major x402 alignment work is in much better shape
- The dependency declaration story is adequate
- The agent/CLI distinction is much better documented
- The repo is no longer suffering from obvious acceptance-blocking defects

What is **not** yet true:

- The repository does **not** pass a strict zero-finding documentation review
- The `api-debugging` area still lacks a single internally consistent auth story

Under a normal internal engineering bar, this repository may already be acceptable.

Under the strict audit bar used for these reports, it is **close**, but still not a clean zero-finding submission.

---

## Release Recommendation

**Current decision:** Hold for one final documentation-consistency pass.

Minimum actions to clear this report:

1. Unify `api-debugging` auth/header terminology across `README.md`, `SKILL.md`, `agents/api-debugger.md`, `references/authentication.md`, and `references/swap-order.md`
2. Clarify `README.md` chain coverage by feature category
3. Tone down the `x402-payments/SKILL.md` overview sentence so it matches the repo's user-confirmation model
4. Clean the remaining Tron-understatement prose in `commands.md` and `order_sign.py`

After those changes, a zero-finding final verification pass should be realistic.
