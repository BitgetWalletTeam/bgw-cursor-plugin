# Bitget Wallet Cursor Plugin - Acceptance Plan Audit Report v1.2

> Audit Date: 2026-03-31
> Auditor: Independent strict review
> Target: `reviews/ACCEPTANCE-TEST.md`
> Scope: acceptance-plan quality, executability, coverage, and consistency with the current repository

---

## Executive Summary

**Verdict:** `CONDITIONAL PASS - all material issues from v1.1 are closed, but one low-risk strictness gap remains`

The acceptance plan is now materially stronger and is close to independent sign-off quality:

- `T2.11` was replaced with a command that is actually executable without wallet credentials
- `T1.1`, `T1.2`, and `T1.3` were strengthened and pass against the current repository
- Cursor-only runtime wording was removed from Level 3
- `T3.8` now includes the Social Wallet confirmation gate

I re-verified the key repaired areas with live commands. No medium or high findings remain.

However, under the same strict zero-finding standard used in the project audit, there is still one residual low-risk issue.

---

## Audit Method

This audit used:

- Static review of `reviews/ACCEPTANCE-TEST.md`
- Cross-checking against:
  - `skills/social-wallet/SKILL.md`
  - `scripts/bitget-wallet-agent-api.py`
- Targeted execution in the project virtualenv:
  - `T1.1` manifest assertion
  - `T1.2` Claude manifest assertion
  - `T1.3` skill/reference assertion
  - `T2.11` via `python3 scripts/bitget-wallet-agent-api.py rwa-get-user-ticker-selector --chain bnb`
  - field-level validation for `ticker`, `name`, `chain`, `contract`, `latest_price`

This audit did **not** execute the full acceptance plan end to end. It evaluates whether the plan itself is accurate, portable, and suitable for an independent acceptance agent.

---

## Confirmed Fixes Since v1.1

### Closed

1. **`T2.11` false-fail fixed:** The RWA check now uses `rwa-get-user-ticker-selector --chain bnb`, which executes successfully without credentials and returns live data.
2. **Claude Code runtime contradiction removed:** Level 3 text and setup are now runtime-neutral across Cursor IDE and Claude Code.
3. **Social Wallet safety gate added:** `T3.8` now requires explicit user confirmation before signing, matching `skills/social-wallet/SKILL.md`.

### Substantially improved

1. **Level 1 automation coverage:** `T1.1`, `T1.2`, and `T1.3` are much stronger than before and pass on the current repository.

---

## Findings

### 1. [Low] `T1.3` still does not fully validate the exact reference counts stated in its own table

**File:**

- `reviews/ACCEPTANCE-TEST.md`

**Issue:**

The `T1.3` table presents exact current counts per skill, for example:

- `defi-trading` = 4
- `dapp-integration` = 23

But the executable check uses:

- `[ "$ref_count" -ge "$expected" ]`

That means the test only enforces a minimum count, not the exact count stated in the table.

So if a future repository drift added extra reference files while the table remained stale, the executable check could still pass.

**Why this matters:**

- This is the last remaining place where the automation does not fully match the table it claims to validate
- It is low risk for current execution, but it prevents a strict zero-finding sign-off

**Recommendation:**

Choose one of these and make them consistent:

1. Change `-ge` to exact equality (`-eq`) if the table is intended to assert exact counts
2. Or relax the table wording from `Yes (N files)` to `Yes (at least N files)` if minimum counts are intentional

---

## Severity Summary

| Severity | Count | Impact |
|----------|-------|--------|
| Blocking | 0 | None |
| High | 0 | None |
| Medium | 0 | None |
| Low | 1 | Residual strictness / table-to-automation alignment gap |

---

## Final Assessment

The acceptance plan is now independently usable and the previously material issues are closed.

The updated `T2.11` is real and executable, the dual-runtime framing is now coherent, and the Social Wallet acceptance criteria now reflect the critical confirmation requirement.

The remaining issue is narrow and low risk, but under a strict audit standard it is still a finding. So this is **very close**, but not yet a zero-finding verification pass.

---

## Release Recommendation

**Current decision:** Conditional pass for practical independent execution; not yet zero-finding sign-off.

Minimum action to clear this report:

1. Make `T1.3`'s reference-count assertion match the table exactly, either by using `-eq` or by relaxing the table wording

After that change, another short verification pass would be appropriate.
