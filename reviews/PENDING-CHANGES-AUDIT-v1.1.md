# Bitget Wallet Cursor Plugin - Pending Changes Audit Report v1.1

> Audit Date: 2026-04-04
> Auditor: Independent strict review
> Scope: `README.md`, `CHANGELOG.md`, `upstream.json`, `scripts/check-upstream.sh`, `reviews/SUBMISSION-REVIEW.md`
> Supersedes: `reviews/PENDING-CHANGES-AUDIT-v1.0.md`

---

## Executive Summary

**Verdict:** `HOLD - two prior findings are closed, one low-risk documentation inconsistency remains`

Closed in this pass:

- Previous finding about missing `dapp-common-skill` coverage is resolved. Live upstream verification confirms `dapp-common-skill/` is a subdirectory inside the pinned `bitget-wallet-developer-skill` repository, so tracking that repo's pinned commit is the correct boundary.
- Previous finding about `scripts/check-upstream.sh --update` not refreshing `commitDate` is resolved. A temp-file simulation confirmed that when a pinned SHA changes, the script now refreshes `commitDate` as well.
- Previous `CHANGELOG.md` provenance issue is resolved. Current upstream pins are now separated from the historical `1.0.0` release entry.

Remaining in this pass:

- **Low-risk issues:** 1

---

## Audit Method

This audit used:

- Static review of the 5 in-scope files
- `bash scripts/check-upstream.sh`
- Live GitHub tree verification for `bitget-wallet-developer-skill @ 34a02aa`
- Temp-file simulation of `bash scripts/check-upstream.sh --update`

---

## Finding

### 1. [Low] `reviews/SUBMISSION-REVIEW.md` now contradicts itself about whether there are 5 separate repositories

**File:**

- `reviews/SUBMISSION-REVIEW.md`

**Issue:**

The updated table now correctly says that `dapp-common-skill` is a subdirectory of `bitget-wallet-developer-skill`, not a separate GitHub repository.

But the surrounding prose still says:

- "Bitget Wallet AI Lab has 5 separate open-source repositories on GitHub"
- "This plugin consolidates all 5 repositories"

Those statements are no longer consistent with the table immediately below them.

**Why this matters:**

- This is a provenance-facing document in the exact area touched by the upstream-drift incident
- Even though the impact is documentation-only, the wording is now factually imprecise
- It creates unnecessary ambiguity about the true upstream boundary

**Recommendation:**

Update the surrounding prose so it matches the corrected table. For example, describe the ecosystem as:

- 4 upstream repositories used by this plugin
- with `dapp-common-skill` included as a subdirectory inside `bitget-wallet-developer-skill`

---

## Confirmed Closures

These previously reported issues are now closed:

- `README.md` and `upstream.json` now describe `dapp-integration` provenance in a way that covers the `dapp-common-skill/` subtree under the pinned developer-skill repo
- `scripts/check-upstream.sh --update` now refreshes `commitDate` when a pin changes
- `CHANGELOG.md` now places current upstream pins in a separate top-level section instead of mixing them into the historical `1.0.0` release entry

---

## Final Assessment

The substantive upstream-tracking design issues are fixed.

One low-risk wording inconsistency remains in `reviews/SUBMISSION-REVIEW.md`. If your bar is zero findings before commit/push, this still needs one more tiny doc correction. After that, this change set should be ready for a short final verification pass.
