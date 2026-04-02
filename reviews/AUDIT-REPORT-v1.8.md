# Bitget Wallet Cursor Plugin - Independent Final Audit Report v1.8

> Audit Date: 2026-03-31
> Auditor: Independent strict review
> Repository: `bgw-cursor-plugin`
> Scope: zero-finding verification after the team reported remaining `v1.7` findings fixed
> Prior Reports: `AUDIT-REPORT-v1.0.md`, `AUDIT-REPORT-v1.1.md`, `AUDIT-REPORT-v1.2.md`, `AUDIT-REPORT-v1.3.md`, `AUDIT-REPORT-v1.4.md`, `AUDIT-REPORT-v1.5.md`, `AUDIT-REPORT-v1.6.md`, `AUDIT-REPORT-v1.7.md`

---

## Executive Summary

**Verdict:** `HOLD - zero-finding verification still not passed`

This pass confirms that the two remaining `v1.7` findings were fixed correctly:

- `skills/defi-trading/references/wallet-signing.md` now documents Tron detection in a way that matches `_is_tron_order()` in `scripts/order_sign.py`
- `skills/defi-trading/references/wallet-signing.md` and `skills/defi-trading/references/commands.md` now include explicit Tron usage examples alongside EVM and Solana
- Minimal non-destructive CLI smoke checks still pass:
  - `python3 scripts/order_sign.py --help`
  - `python3 scripts/order_make_sign_send.py --help`
  - `python3 scripts/x402_pay.py --help`

No blocking, high, or medium findings were identified in this pass.

However, the repository still does **not** meet a literal zero-finding bar because several low-severity documentation inconsistencies remain.

Current release posture:

- **Blocking issues:** 0
- **High-risk issues:** 0
- **Medium-risk issues:** 0
- **Low-risk issues:** 4

---

## Audit Method

This audit used:

- Static review of updated repository contents
- Targeted verification of the claimed `v1.7` remediations
- Cross-checking:
  - `CLAUDE.md`
  - `SUBMISSION-REVIEW.md`
  - `agents/`
  - `skills/`
  - `scripts/`
- Residue scans for:
  - stale Tron detection wording
  - missing Tron examples
  - stale script-output wording
  - top-level project-description drift
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

## Confirmed Fixes Since v1.7

The following previously reported areas were verified as fixed in this pass:

- `wallet-signing.md` Tron Auto-Detection row now matches code logic:
  - `chain=trx|tron`, or
  - `transaction.raw_data_hex` present
- `wallet-signing.md` Order Mode Signing examples now include a Tron example using `--private-key-file-tron`
- `commands.md` `order_make_sign_send.py` section now includes a Tron example using `--from-chain trx` and `--private-key-file-tron`
- `order_sign.py --help` still exposes the correct current flags for EVM, Solana, and Tron
- `order_make_sign_send.py --help` still exposes the correct current flags for EVM, Solana, and Tron

---

## Remaining Findings

### 1. [Low] DeFi references still overstate `order_sign.py` output format

**Files:**

- `skills/defi-trading/references/commands.md`
- `skills/defi-trading/references/swap.md`

**Issue:**

These references still describe `order_sign.py` as outputting a JSON array of "signature hex strings."

That wording is now too narrow for the actual implementation:

- EVM signatures mode returns `0x`-prefixed signature hex strings
- Solana tx mode returns base58-encoded signed transactions
- Tron tx mode returns JSON strings containing `{ signature, txID, raw_data }`

In addition, `commands.md` currently describes the script as taking makeOrder JSON and signing only `data.txs`, while the script also supports `data.signatures` mode.

**Why this matters:**

- This is a user-facing integration guide
- A strict reviewer can still classify this as inaccurate behavior documentation
- Integrators may build the wrong post-processing expectation for Solana or Tron outputs

**Recommendation:**

Update both references to use broader wording such as:

- "outputs a JSON array of signed strings appropriate to the detected mode/chain"

Also explicitly mention that `order_sign.py` supports both:

- `data.signatures` mode
- `data.txs` mode

---

### 2. [Low] `CLAUDE.md` script table still omits Tron for `order_sign.py`

**File:**

- `CLAUDE.md`

**Issue:**

The Scripts table still describes `order_sign.py` as:

- "Sign makeOrder data (raw tx, EIP-712, Solana Ed25519)"

But the implementation and DeFi references clearly document Tron support as well.

**Why this matters:**

- This is top-level project context for Claude Code
- It is a reviewer-visible capability mismatch, even though functionality is present

**Recommendation:**

Expand the `order_sign.py` description so it includes Tron explicitly.

---

### 3. [Low] `defi-operator.md` still uses inconsistent chain-count phrasing

**File:**

- `agents/defi-operator.md`

**Issue:**

The file currently mixes:

- frontmatter description: `8 chains`
- body text: `8+ blockchains`

This is a minor but visible inconsistency for the same supported scope.

**Why this matters:**

- It weakens top-level consistency under a strict review bar
- This issue has no functional impact, but it is easy to spot

**Recommendation:**

Standardize both lines to the same exact phrasing, preferably `8 chains` if that is the intended current scope.

---

### 4. [Low] `SUBMISSION-REVIEW.md` still contains stale exact inventory data

**File:**

- `SUBMISSION-REVIEW.md`

**Issue:**

The document still presents exact inventory and dependency details that no longer match the current repository state.

Concrete example:

- the `requirements.txt` row still says `2` dependencies: `requests, eth-account`

But the current file contains 7 packages:

- `requests`
- `eth-account`
- `cryptography`
- `eth-utils`
- `eth-abi`
- `base58`
- `solders`

Because this document also claims exact total file counts and line counts, the stale dependency row makes the inventory section no longer trustworthy as a literal manifest.

**Why this matters:**

- This is the main submission document for auditors
- Exact-count tables create a stronger obligation to stay current than normal narrative docs

**Recommendation:**

Refresh the inventory tables and exact counts, or explicitly relabel them as a dated snapshot rather than current ground truth.

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

The claimed `v1.7` fixes were real and correctly applied.

From a functionality and safety-documentation perspective, this repository is now in much better shape than earlier rounds:

- the previous Tron-detection mismatch is gone
- the missing Tron usage examples are now present
- current CLI help output is internally consistent
- no new medium or high issues surfaced in this pass

At this point, the repository is **very close** to a zero-finding state, but it still does not satisfy a strict zero-finding standard because several low-severity reviewer-visible documentation drifts remain.

---

## Release Recommendation

**Current decision:** Hold the zero-finding claim until one final low-level documentation cleanup pass is completed.

Minimum actions to clear this report:

1. Fix the `order_sign.py` output-format wording in `commands.md` and `swap.md`
2. Add Tron to the `order_sign.py` description in `CLAUDE.md`
3. Standardize `8 chains` vs `8+ blockchains` in `agents/defi-operator.md`
4. Refresh or reframe the exact inventory/dependency tables in `SUBMISSION-REVIEW.md`

After those updates, a true zero-finding verification pass should be realistic.
