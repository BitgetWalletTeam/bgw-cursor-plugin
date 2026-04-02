# Bitget Wallet Cursor Plugin - Independent Final Audit Report v1.10

> Audit Date: 2026-03-31
> Auditor: Independent strict review
> Repository: `bgw-cursor-plugin`
> Scope: zero-finding verification after the team reported remaining `v1.9` findings fixed
> Prior Reports: `AUDIT-REPORT-v1.0.md`, `AUDIT-REPORT-v1.1.md`, `AUDIT-REPORT-v1.2.md`, `AUDIT-REPORT-v1.3.md`, `AUDIT-REPORT-v1.4.md`, `AUDIT-REPORT-v1.5.md`, `AUDIT-REPORT-v1.6.md`, `AUDIT-REPORT-v1.7.md`, `AUDIT-REPORT-v1.8.md`, `AUDIT-REPORT-v1.9.md`

---

## Executive Summary

**Verdict:** `HOLD - zero-finding verification still not passed`

This pass confirms that the four low-severity items from `v1.9` were materially improved:

- `swap.md` now broadens the opening signing-flow explanation
- `commands.md` now expands `order_sign.py` output descriptions
- `scripts/order_sign.py` now distinguishes output/fill targets by mode in its module docstring
- `SUBMISSION-REVIEW.md` now updates the top-level file count to `87` and the total-size estimate to `~18,000`

Minimal non-destructive CLI smoke checks still pass:

- `python3 scripts/order_sign.py --help`
- `python3 scripts/order_make_sign_send.py --help`
- `python3 scripts/x402_pay.py --help`

However, this pass found one **newly surfaced medium-severity contract mismatch** and one remaining low-severity inventory-drift issue.

Current release posture:

- **Blocking issues:** 0
- **High-risk issues:** 0
- **Medium-risk issues:** 1
- **Low-risk issues:** 1

---

## Audit Method

This audit used:

- Static review of updated repository contents
- Targeted verification of the claimed `v1.9` remediations
- Cross-checking:
  - `skills/defi-trading/references/swap.md`
  - `skills/defi-trading/references/commands.md`
  - `skills/api-debugging/SKILL.md`
  - `skills/api-debugging/references/swap-order.md`
  - `scripts/order_sign.py`
  - `scripts/order_make_sign_send.py`
  - `scripts/social_order_make_sign_send.py`
  - `scripts/bitget-wallet-agent-api.py`
  - `SUBMISSION-REVIEW.md`
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

## Confirmed Fixes Since v1.9

The following previously reported areas were verified as fixed in this pass:

- `skills/defi-trading/references/swap.md` now broadens the signing-flow narrative beyond only `fill txs[].sig`
- `skills/defi-trading/references/commands.md` now distinguishes:
  - EVM regular signed tx output
  - EVM gasPayMaster `msgs[]` JSON output
  - EVM `data.signatures` output
  - Solana output
  - Tron output
- `scripts/order_sign.py` module docstring now documents:
  - `data.signatures` mode -> fill `signatures[].sig`
  - `data.txs` regular EVM mode -> fill `txs[].sig`
  - `data.txs` gasPayMaster `msgs[]` mode -> fill `txs[].sig`
  - Solana output form
  - Tron output form
- `SUBMISSION-REVIEW.md` now updates the top-level repository snapshot summary to `87 files total, ~18,000 lines`

---

## Remaining Findings

### 1. [Medium] `swap.md` now mixes partner `signatures` response semantics into the Agent/CLI swap flow, but the CLI implementation remains `txs`-only

**Files:**

- `skills/defi-trading/references/swap.md`
- `scripts/bitget-wallet-agent-api.py`
- `scripts/order_make_sign_send.py`
- `scripts/social_order_make_sign_send.py`
- `skills/api-debugging/SKILL.md`
- `skills/api-debugging/references/swap-order.md`

**Issue:**

The DeFi swap reference now states that the Agent/CLI `make-order -> sign -> send` flow can return or process:

- `data.txs`, or
- `data.signatures`

and suggests an "equivalent for signatures mode" submit path.

But the actual Agent/CLI implementation remains `txs`-only:

- `scripts/bitget-wallet-agent-api.py make_order()` still documents `Create order; returns unsigned data.txs`
- `scripts/bitget-wallet-agent-api.py send()` accepts only `txs` and submits `{ "orderId": ..., "txs": ... }`
- `_cmd_send` reads only `{ orderId, txs }`
- `scripts/order_make_sign_send.py` hard-fails if `txs` is absent and always mutates `txs[i]["sig"]`
- `scripts/social_order_make_sign_send.py` likewise indexes `data["txs"]` directly and sends only `txs`

At the same time, the repo's own API-debugging matrix clearly separates:

- partner Swap Order API at `bopenapi` using `references/swap-order.md`
- Agent/CLI API at `copenapi` using the CLI scripts

and `references/swap-order.md` is explicitly the **partner** API doc that defines the `txs` vs `signatures` response split and `signedTxs` submit model.

This means `swap.md` now appears to have imported partner swap-order response semantics into the Agent/CLI flow without matching implementation support in the CLI path.

**Why this matters:**

- This is no longer just wording polish; it is a real user-facing contract mismatch
- A reader following `swap.md` can reasonably expect `data.signatures` to work through the local CLI flow, but the combined scripts and `send` helper do not implement that path
- Under a strict audit, this is a medium-severity documentation/functionality mismatch

**Recommendation:**

Choose one of two directions and make the repository consistent:

1. **Documentation-only fix:** Keep the Agent/CLI `swap.md` flow `txs`-only, and clearly state that `data.signatures` / `signedTxs` is part of the **partner Swap Order API** model documented in `skills/api-debugging/references/swap-order.md`, not the current CLI fallback flow.
2. **Implementation fix:** Add full `data.signatures` handling to:
   - `scripts/bitget-wallet-agent-api.py send`
   - `_cmd_send`
   - `scripts/order_make_sign_send.py`
   - `scripts/social_order_make_sign_send.py`
   and then document the exact request body for the Agent/CLI signatures-mode path.

---

### 2. [Low] `SUBMISSION-REVIEW.md` still contains stale exact per-file line counts despite the refreshed top-level snapshot

**File:**

- `SUBMISSION-REVIEW.md`

**Issue:**

The top-level snapshot line is now updated, but the detailed inventory tables still use stale exact counts.

Examples confirmed in this pass:

- Agents table still says:
  - `defi-operator.md` = `38`
  - `dapp-developer.md` = `28`
  - `api-debugger.md` = `33`
- Current file counts are:
  - `defi-operator.md` = `42`
  - `dapp-developer.md` = `32`
  - `api-debugger.md` = `42`
- The scripts table still says:
  - `order_sign.py` = `814`
- Current file count is:
  - `order_sign.py` = `819`
- The skills table still says:
  - `swap.md` = `215`
- Current file count is:
  - `swap.md` = `221`

Because the document is positioned as a current submission inventory, these exact-count rows are still reviewer-visible drift even after the top summary was refreshed.

**Why this matters:**

- This is the primary submission document for auditors
- Exact per-file tables create a higher accuracy burden than narrative repository overviews

**Recommendation:**

Either:

- refresh the detailed tables to current values, or
- remove exact per-file line counts and present the section as a structure overview only

---

## Severity Summary

| Severity | Count | Release Impact |
|----------|-------|----------------|
| Blocking | 0 | None |
| High | 0 | None |
| Medium | 1 | Zero-finding claim not credible |
| Low | 1 | Submission-document polish / trustworthiness |

---

## Final Assessment

The claimed `v1.9` fixes were mostly real, but one of those documentation expansions surfaced a more important problem:

- the repo now describes `data.signatures` as part of the Agent/CLI swap flow
- the actual Agent/CLI send path and both one-shot swap scripts are still built around `txs`

This prevents a strict zero-finding conclusion.

The good news is that the repository remains materially cleaner than earlier rounds:

- no blocking or high issues were found
- CLI smoke checks remain healthy
- most remaining drift is now concentrated in one model-boundary mismatch plus one inventory table cleanup

---

## Release Recommendation

**Current decision:** Hold the zero-finding claim.

Minimum actions to clear this report:

1. Resolve the `data.signatures` vs `txs` contract mismatch between `swap.md` and the actual Agent/CLI implementation
2. Refresh or simplify the detailed per-file counts in `SUBMISSION-REVIEW.md`

After those updates, another final verification pass would be appropriate.
