# Bitget Wallet Cursor Plugin - Pending Changes Audit Report v1.0

> Audit Date: 2026-04-04
> Auditor: Independent strict review
> Scope: pending changes in `README.md`, `CHANGELOG.md`, `scripts/check-upstream.sh`, and `upstream.json`

---

## Executive Summary

**Verdict:** `HOLD - the new upstream-tracking additions are useful, but not yet audit-clean`

The newly added upstream-tracking material is directionally correct:

- pinned SHAs in `README.md` and `upstream.json` currently match live upstream HEADs
- pinned commit dates currently match live GitHub commit dates
- `bash scripts/check-upstream.sh` successfully reports the tracked sources as up to date

However, this change set still has material issues in the exact area it is trying to strengthen: upstream provenance and drift detection.

Findings in this pass:

- **Medium-risk issues:** 2
- **Low-risk issues:** 1

---

## Audit Method

This audit used:

- Static review of:
  - `README.md`
  - `CHANGELOG.md`
  - `scripts/check-upstream.sh`
  - `upstream.json`
  - `reviews/SUBMISSION-REVIEW.md`
- Live upstream verification:
  - GitHub API commit-date lookup for all pinned SHAs
  - `bash scripts/check-upstream.sh`
- Behavioral validation of the update path:
  - simulated `--update` behavior to verify whether `commitDate` is refreshed

---

## Findings

### 1. [Medium] The new upstream-tracking system omits `dapp-common-skill`, leaving a real source blind spot

**Files:**

- `README.md`
- `upstream.json`
- `CHANGELOG.md`
- `reviews/SUBMISSION-REVIEW.md`

**Issue:**

The new upstream-tracking additions cover only 4 upstream sources:

- `bitget-wallet-skill`
- `bitget-wallet-developer-skill`
- `bitget-wallet-partner-skill`
- `bitget-wallet-mcp`

But the repository's existing traceability material still shows that `dapp-integration` content comes from **both**:

- `bitget-wallet-developer-skill`
- `dapp-common-skill`

Specifically, `reviews/SUBMISSION-REVIEW.md` still documents:

- `dapp-integration` = `developer-skill + dapp-common-skill`
- 10 reference files sourced from `dapp-common-skill`

That means the new tracking system does **not** actually cover all real upstream sources used in the plugin. Drift in the `dapp-common-skill` portion of `dapp-integration` would still go undetected by the new mechanism.

**Why this matters:**

- This reintroduces the same class of blind spot that `INCIDENT-001` was meant to close
- The missing source is not cosmetic; it covers 10 shipped reference files
- The new upstream-tracking narrative is therefore incomplete

**Recommendation:**

Add `dapp-common-skill` to:

1. `upstream.json`
2. the upstream table in `README.md`
3. the upstream section in `CHANGELOG.md`

and describe exactly which `dapp-integration` files come from it.

---

### 2. [Medium] `scripts/check-upstream.sh --update` refreshes `pinnedCommit` but not `commitDate`

**Files:**

- `scripts/check-upstream.sh`
- `upstream.json`

**Issue:**

The new metadata model now relies on both:

- `pinnedCommit`
- `commitDate`

But the `--update` path only updates:

- `pinnedCommit`
- `lastVerified`

It does **not** update `commitDate`.

This was verified directly by simulating the update logic with an intentionally wrong `commitDate`; after the update logic ran, the SHA changed back to the correct current HEAD, but the wrong `commitDate` remained unchanged.

So after the first real pin bump, `upstream.json` can silently contain:

- a new SHA
- an old date

which makes the new provenance layer internally inaccurate.

**Why this matters:**

- The current change set explicitly elevates commit dates into user-visible provenance data
- A tracking script that mutates SHAs without mutating dates will quickly make that provenance untrustworthy
- This weakens both `upstream.json` and any docs copied from it later

**Recommendation:**

Update the `--update` path so that when `pinnedCommit` changes, `commitDate` is also refreshed from the actual commit's date.

---

### 3. [Low] `CHANGELOG.md` now mixes current upstream-sync metadata into the historical `1.0.0` release entry

**Files:**

- `CHANGELOG.md`

**Issue:**

The `1.0.0` changelog entry is dated:

- `2026-03-30`

But the new `Upstream Sources` block inside that same release entry includes:

- `bitget-wallet-skill` pinned commit `2a4b6c5`
- commit date `2026-04-03`

That is a chronology mismatch for a historical release note. It makes the `1.0.0` entry read partly like:

- original release history
- and partly like current source-tracking state

Those are different kinds of records and should not be conflated.

**Why this matters:**

- It weakens release provenance
- A reviewer cannot tell whether those upstream pins describe what shipped on `2026-03-30` or what is merely true now

**Recommendation:**

Either:

1. move current upstream pins out of the `1.0.0` release entry into a separate non-versioned metadata section
2. or clearly label the block as a later-added source-tracking annotation rather than original `1.0.0` release content

---

## Confirmed Strengths

These parts of the pending changes look good:

- README's MCP install guidance now correctly describes the shipped `uvx`-based `.mcp.json`
- README now warns about `--project` install collisions and skipped items
- README now states the platform boundary (`macOS` / `Linux`, Windows not validated)
- the currently pinned SHAs and dates are real and match live upstream data
- `bash scripts/check-upstream.sh` works for the currently tracked sources

---

## Severity Summary

| Severity | Count | Impact |
|----------|-------|--------|
| Blocking | 0 | None |
| High | 0 | None |
| Medium | 2 | Upstream-tracking blind spot and metadata refresh defect |
| Low | 1 | Historical release provenance becomes harder to trust |

---

## Final Assessment

The pending changes improve the repository, but they do **not** fully close the upstream-tracking problem yet.

The biggest issue is that the new tracking layer is incomplete: it omits `dapp-common-skill`, which means one of the actual source repos used in the plugin is still outside the new drift-detection boundary.

The second issue is that the update script currently cannot maintain its own new metadata model correctly, because it updates SHAs without updating the corresponding commit dates.

---

## Release Recommendation

**Current decision:** Hold these pending changes until the upstream-tracking mechanism is completed and made self-consistent.

Minimum actions to clear this report:

1. Add `dapp-common-skill` to the tracked upstream sources
2. Make `scripts/check-upstream.sh --update` refresh `commitDate`
3. Separate current upstream-sync metadata from the historical `1.0.0` changelog entry, or label it explicitly as post-release annotation

After those updates, another short audit pass should be sufficient.
