# Bitget Wallet Cursor Plugin — Independent Re-Audit Report v1.2

> Audit Date: 2026-03-31
> Auditor: Independent strict review
> Repository: `bgw-cursor-plugin`
> Scope: follow-up re-audit after the team reported all `v1.1` findings fixed
> Prior Reports: `AUDIT-REPORT-v1.0.md`, `AUDIT-REPORT-v1.1.md`

---

## Executive Summary

**Verdict:** `HOLD — close to submission-ready`

This repository has improved substantially across the last two remediation rounds.

- No blocking issues remain
- No high-severity issues remain in this audit pass
- Most of the previously reported structural and consistency problems are fixed
- The repository now looks materially closer to a credible submission candidate

However, under a **strict marketplace/security review standard**, a small number of cleanup items still remain. These are no longer architecture-level failures; they are primarily:

- security wording consistency in top-level review materials
- stale command names in script examples
- stale flag names in script error messages
- one remaining low-grade agent/docs inconsistency

Current release posture:

- **Blocking issues:** 0
- **High-risk issues:** 0
- **Medium-risk issues:** 3
- **Low-risk issues:** 1

---

## Audit Method

This re-audit used:

- Static review of updated repository contents
- Targeted verification of the 6 claimed `v1.1` remediations
- Cross-checking `README.md`, `CLAUDE.md`, `SUBMISSION-REVIEW.md`, `security-audit-slowmist-v1.0.md`, `skills/`, `agents/`, `requirements.txt`, and `scripts/`
- Repo-wide residue search for:
  - `OpenAPI`
  - `Partner-Code`
  - stale `docs/...` paths
  - `order-create`
  - old flag names such as `--private-key-sol`
- Minimal non-destructive CLI smoke checks:
  - `python3 scripts/x402_pay.py --help`
  - `python3 scripts/order_sign.py --help`
  - `python3 scripts/order_make_sign_send.py --help`

This re-audit did **not** use:

- Live Bitget API calls
- Live MCP execution
- Real wallet credentials
- On-chain transaction execution

---

## Status vs v1.1

| Area | v1.1 Status | v1.2 Result |
|------|-------------|-------------|
| Agent frontmatter | Fixed | ✅ Still correct |
| Unsupported `OpenAPI` references | Remaining | ✅ Fixed |
| `copenapi` auth model documentation | Partially fixed | ✅ Core issue fixed |
| x402 router/docs alignment | Mostly fixed | ✅ Core issue fixed |
| Python CLI setup instructions | Missing in top-level docs | ✅ Added in `README.md` |
| Stale `docs/...` path in script docstring | Remaining | ✅ Fixed |
| Security wording consistency across review docs | Remaining | ⚠️ Still partially inconsistent |
| Script example / error message polish | Not a primary focus in `v1.1` | ⚠️ Residual cleanup still needed |

---

## Confirmed Improvements

The following improvements were verified in this pass:

- `agents/api-debugger.md` no longer claims `(OpenAPI)` or references an `OpenAPI spec`
- `skills/api-debugging/SKILL.md` now documents `copenapi.bgwapi.io` with the actual CLI header family: `X-SIGN`, `X-TIMESTAMP`, `token`, `channel`, `brand`
- `README.md` now includes Python CLI setup instructions with virtualenv creation and `pip install -r requirements.txt`
- `skills/x402-payments/SKILL.md`, `README.md`, and `scripts/x402_pay.py` are materially better aligned on:
  - EIP-3009 support
  - Solana sign-only limitations
  - `PAYMENT-SIGNATURE`
  - `--private-key-file`
- `scripts/bitget-wallet-agent-api.py` no longer contains the old `docs/market-data.md` reference
- `requirements.txt` remains consistent with current script imports

---

## Remaining Findings

### 1. [Medium] Security boundary wording is still not fully reconciled across review materials

**Files:**

- `security-audit-slowmist-v1.0.md`
- `SUBMISSION-REVIEW.md`

**Issue:**

The repository now correctly documents many agent-layer vs script-layer distinctions. However, top-level audit/review materials still contain a few statements that are stronger than the actual network model.

Examples:

- `security-audit-slowmist-v1.0.md` correctly lists `x402_pay.py --url` as user-specified network traffic, but still says `Data boundary: Network calls only to copenapi.bgwapi.io`
- `SUBMISSION-REVIEW.md` still says `Network: All API calls only to copenapi.bgwapi.io`
- `SUBMISSION-REVIEW.md` still headlines `Human-in-the-Loop (3-layer enforcement)` even though the updated repo now more precisely frames this as agent-orchestrated rather than script-enforced

**Why this matters:**

- These files are likely to be read directly by reviewers
- Reviewers often judge trustworthiness by whether the highest-level materials are perfectly consistent
- This is now a wording/consistency issue, not a core implementation issue

**Recommendation:**

- Narrow these claims to the actual scope of Bitget API traffic
- Explicitly carve out x402 as user-directed third-party network traffic
- Replace `enforcement` wording with `agent-orchestrated confirmation architecture` or equivalent phrasing

---

### 2. [Medium] `order_sign.py` still uses the old public command name `order-create`

**Files:**

- `scripts/order_sign.py`
- `scripts/bitget-wallet-agent-api.py`

**Issue:**

The public CLI in `bitget-wallet-agent-api.py` now exposes `make-order`, but `order_sign.py` usage examples still tell users to pipe from `order-create`.

**Why this matters:**

- Copy-paste users will hit an argparse failure
- This is exactly the kind of small but credibility-damaging mismatch that strict reviewers notice

**Recommendation:**

- Replace `order-create` with `make-order` in all user-facing examples and descriptions
- Update `description="Sign order-create response"` and related wording if the public terminology has fully moved to `make-order`

---

### 3. [Medium] Script error messages still reference non-existent flag names

**Files:**

- `scripts/order_make_sign_send.py`
- `scripts/order_sign.py`

**Issue:**

The actual argparse flags are:

- `--private-key-file`
- `--private-key-file-sol`
- `--private-key-file-tron`

But several runtime error messages still say:

- `--private-key`
- `--private-key-sol`
- `--private-key-tron`

**Why this matters:**

- These messages appear exactly when users are already in a failure state
- Wrong remediation text slows debugging and makes the scripts feel less polished than they are

**Recommendation:**

Update all user-facing error/help strings to the real flag names.

---

### 4. [Low] `api-debugger` agent still uses a slightly simplified header description

**Files:**

- `agents/api-debugger.md`
- `skills/api-debugging/SKILL.md`

**Issue:**

`agents/api-debugger.md` now correctly identifies the agent API as `X-SIGN + X-TIMESTAMP` based, but it is still slightly less complete than the API matrix in `skills/api-debugging/SKILL.md`, which also lists:

- `token`
- `channel`
- `brand`

**Why this matters:**

- This is not a functional error
- It is a low-grade consistency issue between the agent persona and the skill reference

**Recommendation:**

Mirror the fuller header description from the skill matrix into the agent workflow text.

---

## Severity Summary

| Severity | Count | Release Impact |
|----------|-------|----------------|
| Blocking | 0 | None |
| High | 0 | None |
| Medium | 3 | Recommended to fix before submission |
| Low | 1 | Cleanup / consistency |

---

## Release Recommendation

**Current decision:** Hold for one final cleanup pass.

This repository is now **close** to submission-ready. The remaining items are not deep architectural failures, but I still recommend fixing them before external review because they are exactly the kind of issues that can cause a reviewer to doubt rigor.

Minimum cleanup before submission:

1. Reconcile `security-audit-slowmist-v1.0.md` and `SUBMISSION-REVIEW.md` wording around:
   - network boundary
   - x402 external URLs
   - agent-orchestrated confirmation vs enforcement
2. Replace `order-create` with `make-order` in `scripts/order_sign.py`
3. Replace all stale `--private-key*` error strings with the actual `--private-key-file*` flag names
4. Optionally make `agents/api-debugger.md` header wording fully match the skill matrix

---

## Final Assessment

Compared with `v1.1`, this repository has clearly moved into a stronger state:

- the core doc/model inconsistencies are largely resolved
- the dependency story is in much better shape
- the x402 narrative is much more honest and bounded
- the submission is now mostly suffering from polish and consistency residue rather than substantive design problems

Under a normal internal engineering bar, this might already be acceptable.

Under the **strict audit standard used for these reports**, it is **very close**, but still worth one final cleanup before declaring a full `GO`.
