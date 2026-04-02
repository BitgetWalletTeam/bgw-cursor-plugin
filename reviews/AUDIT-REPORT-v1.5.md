# Bitget Wallet Cursor Plugin - Independent Final Audit Report v1.5

> Audit Date: 2026-03-31
> Auditor: Independent strict review
> Repository: `bgw-cursor-plugin`
> Scope: zero-finding verification after the team reported all `v1.4` findings fixed
> Prior Reports: `AUDIT-REPORT-v1.0.md`, `AUDIT-REPORT-v1.1.md`, `AUDIT-REPORT-v1.2.md`, `AUDIT-REPORT-v1.3.md`, `AUDIT-REPORT-v1.4.md`

---

## Executive Summary

**Verdict:** `HOLD - zero-finding verification still not passed`

This pass confirms that the specific items called out in `v1.4` were largely addressed:

- stale `order-create` / `order-submit` script wording is cleaned up in the main paths
- stale `--private-key-sol` issues in scripts are fixed
- `order_make_sign_send.py` CLI help now includes Tron
- top-level wording around x402 third-party URLs and agent-orchestrated confirmation is much stronger than in earlier versions

However, a strict final review still surfaced **newly visible consistency issues** in the documentation layer. These are no longer core implementation or dependency problems. They are now concentrated in:

- inconsistent naming and auth-model framing in `api-debugging`
- contradictory top-level chain-count claims
- remaining reviewer-visible understatement of Tron support in some DeFi reference docs
- one low-grade wording precision issue in x402

Current release posture:

- **Blocking issues:** 0
- **High-risk issues:** 0
- **Medium-risk issues:** 2
- **Low-risk issues:** 2

---

## Audit Method

This final audit used:

- Static review of updated repository contents
- Targeted verification of the claimed `v1.4` remediations
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
  - stale `OpenAPI`
  - stale auth-model wording
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

## Status of v1.4 Findings

| v1.4 Finding | Current Status |
|--------------|----------------|
| `api-debugging` lacks a single authoritative auth model | ⚠️ Improved, but not fully resolved |
| `README.md` chain coverage is ambiguous | ⚠️ Improved, but now numerically inconsistent with `CLAUDE.md` |
| `x402-payments/SKILL.md` "automatically sign" wording | ⚠️ Improved in some places, but still slightly over-strong in overview text |
| remaining Tron-understatement prose | ⚠️ Fixed in scripts, but still present in some DeFi reference docs |

The remaining findings below are not repeats of the original `v1.4` wording. They are what remains after the claimed remediation pass.

---

## Remaining Findings

### 1. [Medium] `api-debugging` still has no single authoritative auth-model story

**Files:**

- `README.md`
- `skills/api-debugging/SKILL.md`
- `agents/api-debugger.md`
- `skills/api-debugging/references/authentication.md`
- `skills/api-debugging/references/swap-order.md`
- `SUBMISSION-REVIEW.md`

**Issue:**

The repository still describes the `api-debugging` capability with overlapping and partially conflicting terminology.

Observed inconsistencies include:

- `README.md` now says `HMAC, Partner-Code, and Agent auth models`, which is directionally correct
- `skills/api-debugging/SKILL.md` correctly introduces a 3-row auth matrix
- but the same `SKILL.md` frontmatter and Role section still describe the whole skill as `Bitget Wallet Agent API` debugging
- `agents/api-debugger.md` YAML description and opening paragraph still name the whole domain `Bitget Wallet Agent API`, even though the agent also handles partner HMAC and `Partner-Code` flows
- `agents/api-debugger.md` workflow step 2 still describes the partner model as `x-api-key + x-api-sign + x-api-timestamp`, while `references/authentication.md` uses `x-api-signature`
- `references/authentication.md` explicitly distinguishes HMAC-based Market/Token endpoints from `Partner-Code`-based Swap Order endpoints
- `SUBMISSION-REVIEW.md` still frames the plugin capability as `Debug Bitget Wallet Agent API integrations`

**Why this matters:**

- A strict reviewer still does not get one clean source of truth for the debugging/auth model
- The repo is much closer than before, but the naming still oscillates between:
  - `Agent API`
  - partner API
  - HMAC auth
  - `Partner-Code`
  - `copenapi` CLI auth
- This weakens the exact area that is supposed to reduce integration confusion

**Recommendation:**

Unify the `api-debugging` capability into a single vocabulary, for example:

- rename the skill/agent from `Agent API` debugging to `Bitget Wallet API debugging`
- keep the 3-row auth matrix
- make `agents/api-debugger.md` use `x-api-signature` consistently when referring to HMAC
- reserve `Agent API` wording only for the `copenapi` / CLI path

---

### 2. [Medium] Top-level chain support claims are still inconsistent

**Files:**

- `README.md`
- `CLAUDE.md`

**Issue:**

`README.md` now uses a feature-by-chain table, which is an improvement. But the Market Data / Token Analysis row says:

- `All chains supported by Bitget Wallet (13+)`

while `CLAUDE.md` says:

- `Market Data (32+)`

These are both top-level reviewer-facing docs and they contradict each other directly.

**Why this matters:**

- This is the kind of contradiction reviewers notice immediately
- It creates doubt about whether the chain support inventory has been rigorously validated

**Recommendation:**

Make `README.md` and `CLAUDE.md` use the same chain-count statement and the same support taxonomy.

---

### 3. [Low] `x402-payments/SKILL.md` still overstates autonomy slightly in the overview sentence

**File:**

- `skills/x402-payments/SKILL.md`

**Issue:**

The overview still says:

- `the agent can automatically sign a USDC payment and retry the request`

Even though the same file later says:

- user must confirm payment amount before signing
- `pay` includes an interactive confirmation prompt by default

**Why this matters:**

- This is not a behavior contradiction
- It is a wording precision issue under a strict security review

**Recommendation:**

Rewrite the overview sentence to qualify signing immediately, e.g. "can sign after explicit user approval" or similar.

---

### 4. [Low] Some DeFi reference docs still under-document current Tron support

**Files:**

- `skills/defi-trading/references/commands.md`
- `skills/defi-trading/references/wallet-signing.md`
- `skills/defi-trading/references/swap.md`

**Issue:**

Several DeFi reference docs still do not fully reflect the current Tron-capable implementation:

- `commands.md` says `order_make_sign_send.py` supports `EVM and Solana`
- `wallet-signing.md` examples and auto-detection table only cover EVM and Solana
- `swap.md` combined-script behavior still says it auto-detects `EVM vs Solana`, and the separate-sign step only mentions `--private-key-file` without clarifying Solana/Tron split flags

**Why this matters:**

- The scripts and CLI help are now better than the refs
- Reviewers who go deep into references can still see incomplete support descriptions

**Recommendation:**

Sweep the three files above so Tron support is documented as consistently as it is implemented.

---

## Severity Summary

| Severity | Count | Release Impact |
|----------|-------|----------------|
| Blocking | 0 | None |
| High | 0 | None |
| Medium | 2 | Recommended to fix before claiming zero findings |
| Low | 2 | Cleanup / wording precision |

---

## Final Assessment

This repository is materially stronger than in every prior audit round:

- plugin-format issues are gone
- dependency coverage is in much better shape
- x402 documentation is much more bounded
- zero-finding failure is now due to documentation consistency, not core engineering defects

What is true now:

- the repository is likely acceptable under a normal internal engineering bar
- it is much closer to submission quality than in `v1.0` or `v1.1`

What is not yet true:

- it still does **not** pass a strict zero-finding documentation review
- the `api-debugging` area still does not present one completely unified auth story

---

## Release Recommendation

**Current decision:** Hold for one final documentation-consistency sweep.

Minimum actions to clear this report:

1. Fully unify the `api-debugging` naming/auth story across README, SKILL, agent, and references
2. Reconcile `README.md` and `CLAUDE.md` on Market Data / Token Analysis chain counts
3. Tone down the x402 overview sentence so it matches the repo's approval model
4. Update the three remaining DeFi reference docs so Tron support is documented as completely as in the scripts

After those changes, a true zero-finding verification pass should be realistic.
