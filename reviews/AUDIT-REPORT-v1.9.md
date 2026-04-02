# Bitget Wallet Cursor Plugin - Independent Final Audit Report v1.9

> Audit Date: 2026-03-31
> Auditor: Independent strict review
> Repository: `bgw-cursor-plugin`
> Scope: zero-finding verification after the team reported remaining `v1.8` findings fixed
> Prior Reports: `AUDIT-REPORT-v1.0.md`, `AUDIT-REPORT-v1.1.md`, `AUDIT-REPORT-v1.2.md`, `AUDIT-REPORT-v1.3.md`, `AUDIT-REPORT-v1.4.md`, `AUDIT-REPORT-v1.5.md`, `AUDIT-REPORT-v1.6.md`, `AUDIT-REPORT-v1.7.md`, `AUDIT-REPORT-v1.8.md`

---

## Executive Summary

**Verdict:** `HOLD - zero-finding verification still not passed`

This pass confirms that the four low-severity issues from `v1.8` were addressed in the intended places:

- `commands.md` now documents both `data.signatures` and `data.txs` modes
- `swap.md` no longer uses the old generic "signature hex strings" wording
- `CLAUDE.md` now includes Tron in the `order_sign.py` script description
- `agents/defi-operator.md` now consistently uses `8 chains`
- `SUBMISSION-REVIEW.md` now lists all 7 Python dependencies in `requirements.txt`

Minimal non-destructive CLI smoke checks still pass:

- `python3 scripts/order_sign.py --help`
- `python3 scripts/order_make_sign_send.py --help`
- `python3 scripts/x402_pay.py --help`

No blocking, high, or medium findings were identified in this pass.

However, the repository still does **not** satisfy a literal zero-finding bar because several low-severity documentation inconsistencies remain around signing-flow precision and inventory freshness.

Current release posture:

- **Blocking issues:** 0
- **High-risk issues:** 0
- **Medium-risk issues:** 0
- **Low-risk issues:** 4

---

## Audit Method

This audit used:

- Static review of updated repository contents
- Targeted verification of the claimed `v1.8` remediations
- Cross-checking:
  - `CLAUDE.md`
  - `SUBMISSION-REVIEW.md`
  - `agents/`
  - `skills/`
  - `scripts/`
  - plugin manifests
- Residue scans for:
  - stale `order_sign.py` output wording
  - stale `txs[].sig`-only signing flow language
  - stale inventory counts
  - chain-count phrasing drift
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

## Confirmed Fixes Since v1.8

The following previously reported areas were verified as fixed in this pass:

- `skills/defi-trading/references/commands.md` now describes both `data.signatures` mode and `data.txs` mode
- `skills/defi-trading/references/swap.md` now uses broader signed-output wording instead of the old "signature hex strings" phrasing
- `CLAUDE.md` now describes `order_sign.py` as supporting `EVM raw tx, EIP-712, Solana Ed25519, Tron secp256k1`
- `agents/defi-operator.md` now uses `8 chains` in both frontmatter and body text
- `SUBMISSION-REVIEW.md` now lists 7 `requirements.txt` dependencies:
  - `requests`
  - `eth-account`
  - `cryptography`
  - `eth-utils`
  - `eth-abi`
  - `base58`
  - `solders`

---

## Remaining Findings

### 1. [Low] `swap.md` main swap flow still documents only the `data.txs -> txs[].sig -> send` path

**File:**

- `skills/defi-trading/references/swap.md`

**Issue:**

The primary flow table and separate-step flow still describe only the classic tx path:

- `make-order` returns unsigned `data.txs`
- `order_sign.py` fills `txs[].sig`
- `send` submits `{ orderId, txs }`

But the repository now explicitly documents and implements more than that:

- `order_sign.py` also supports `data.signatures` mode
- EVM gasless / `msgs[]` flows do not fit a simple `fill txs[].sig` summary

This means the newly corrected `order_sign.py` summary is more accurate than the higher-level flow section that precedes it.

**Why this matters:**

- `swap.md` is the main operational reference for the swap flow
- A strict reviewer can still flag the flow as internally inconsistent
- Integrators following only the top-level flow table may miss the non-`txs[].sig` path

**Recommendation:**

Update the `Flow Overview` rows `3′–5′` and the `3′–5′` narrative section so they mention both:

- `data.txs` signing / send flow
- `data.signatures` or gasless signing flow where applicable

---

### 2. [Low] `commands.md` and `swap.md` still compress EVM signed output too narrowly

**Files:**

- `skills/defi-trading/references/commands.md`
- `skills/defi-trading/references/swap.md`

**Issue:**

The current one-line summary says `order_sign.py` outputs signed strings by chain and describes EVM output as `0x`-prefixed hex.

That is still incomplete for one implemented EVM path:

- EVM `data.signatures` mode returns `0x`-prefixed hex signatures
- EVM raw-tx / typed-data signing also returns hex signatures
- But EVM gasPayMaster `msgs[]` mode returns a JSON stringified msgs structure with embedded `sig` fields, not just a plain hex string

So the new wording is improved, but it still over-compresses EVM outputs into a single format.

**Why this matters:**

- This is the user-facing command reference
- It can mislead readers about the exact output contract of EVM gasless signing

**Recommendation:**

Split the wording by signing mode rather than only by chain, for example:

- `data.signatures`: EVM `0x`-prefixed signatures
- `data.txs` EVM raw-tx / typed-data: signed hex strings
- `data.txs` EVM gasPayMaster: JSON msgs payload with `sig`
- Solana: base58 signed tx
- Tron: JSON with `signature` / `txID` / `raw_data`

---

### 3. [Low] `scripts/order_sign.py` module docstring is still behind the current signing behavior

**File:**

- `scripts/order_sign.py`

**Issue:**

The module docstring still says:

- output is ready for the send step by filling `txs[].sig`

That description no longer fully covers the current implementation, because:

- `data.signatures` mode exists and is handled before the `txs` branch
- EVM gasPayMaster can emit a JSON msgs payload rather than a simple `txs[].sig`-fill mental model

**Why this matters:**

- This docstring is the closest in-file contract for script behavior
- A strict audit treats stale module-level behavior docs as reviewer-visible residue

**Recommendation:**

Refresh the docstring so it mirrors the actual supported outputs and distinguishes:

- `data.signatures` mode
- `data.txs` raw-tx mode
- EVM gasPayMaster `msgs[]` mode
- Solana and Tron output forms

---

### 4. [Low] `SUBMISSION-REVIEW.md` inventory snapshot is still not current enough to support a zero-finding claim

**File:**

- `SUBMISSION-REVIEW.md`

**Issue:**

The new snapshot note improves framing, but the inventory still contains stale exact-count data.

Examples confirmed in this pass:

- the document still says `68 files total`, while the repository currently contains `86` non-`.git` files
- agent line counts are still stale:
  - `defi-operator.md`: listed as `38`, current `42`
  - `dapp-developer.md`: listed as `28`, current `32`
  - `api-debugger.md`: listed as `33`, current `42`

Because this document positions itself as a current submission inventory, these exact-count rows remain reviewer-visible drift even after the new snapshot note.

**Why this matters:**

- This is the primary submission document for auditors
- Exact inventory tables create a higher accuracy burden than ordinary narrative docs

**Recommendation:**

Either:

- refresh the exact counts to match the current repository, or
- remove exact total/count claims and present the inventory as a structure overview only

---

## Severity Summary

| Severity | Count | Release Impact |
|----------|-------|----------------|
| Blocking | 0 | None |
| High | 0 | None |
| Medium | 0 | None |
| Low | 4 | Prevents a literal zero-finding claim under strict review |

---

## Final Assessment

The claimed `v1.8` fixes were real and materially improved the repository.

The remaining issues are all low-severity and concentrated in documentation precision rather than security or runtime behavior:

- no security regressions were identified in this pass
- no new high-risk functionality gaps surfaced
- CLI smoke checks remain healthy

At this point, the repository is **close** to a zero-finding state, but it still does not meet a strict zero-finding standard because the signing-flow story and submission inventory are not yet fully synchronized across all reviewer-facing documents.

---

## Release Recommendation

**Current decision:** Hold the zero-finding claim for one final low-level documentation cleanup pass.

Minimum actions to clear this report:

1. Update `swap.md` high-level flow sections so they cover both `data.txs` and `data.signatures` / gasless signing flows
2. Refine `commands.md` and `swap.md` output wording for EVM gasPayMaster `msgs[]` mode
3. Refresh the `order_sign.py` module docstring to match current behavior
4. Refresh or simplify the exact inventory counts in `SUBMISSION-REVIEW.md`

After those updates, a true zero-finding final verification pass should be realistic.
