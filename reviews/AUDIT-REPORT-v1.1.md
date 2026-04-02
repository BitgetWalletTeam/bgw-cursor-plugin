# Bitget Wallet Cursor Plugin — Independent Re-Audit Report v1.1

> Audit Date: 2026-03-31
> Auditor: Independent strict review
> Repository: `bgw-cursor-plugin`
> Scope: follow-up audit after the team reported 6 remediation items completed
> Prior Report: `AUDIT-REPORT-v1.0.md`

---

## Executive Summary

**Verdict:** `NO-GO`

This re-audit confirms that the repository has improved materially since `v1.0`.

- The prior **blocking** issue is resolved
- Several high-risk consistency issues are fully or mostly fixed
- The repository is now closer to submission quality

However, it still does **not** meet a strict "highest standard / ready for marketplace-style security review" bar. The remaining issues are no longer primarily about missing structure; they are now about:

- execution-layer safety vs documentation-layer safety
- residual API model confusion
- residual x402 overstatement / drift
- incomplete CLI onboarding for clean environments

Current release posture:

- **Blocking issues:** 0
- **High-risk issues:** 2
- **Medium-risk issues:** 3
- **Low-risk issues:** 1

---

## Re-Audit Method

This re-audit used:

- Static review of updated repository contents
- Targeted validation of the 6 claimed fixes
- Cross-checking `skills/`, `agents/`, `CLAUDE.md`, `README.md`, `requirements.txt`, and `scripts/`
- Minimal non-destructive CLI smoke checks:
  - `python3 scripts/x402_pay.py --help`
  - `python3 scripts/order_make_sign_send.py --help`
  - `python3 scripts/social-wallet.py --help`
- Repo-wide residue search for:
  - `OpenAPI`
  - `Partner-Code`
  - stale `docs/...` paths
  - `Permit2`
  - old x402 CLI/header strings

This re-audit did **not** use:

- Live Bitget API calls
- Live MCP execution
- Real wallet credentials
- On-chain transaction execution

---

## Status of Claimed Fixes

| # | Claimed Fix | Re-Audit Result | Notes |
|---|-------------|-----------------|-------|
| 1 | Agent YAML frontmatter added | ✅ Confirmed fixed | All 3 agent files now contain `name` + `description` frontmatter |
| 2 | x402 SKILL aligned with implementation | ⚠️ Mostly fixed | Core `SKILL.md` is much better; residual drift remains in reference doc and script header comments |
| 3 | `requirements.txt` completed | ✅ Confirmed fixed | Dependency list now matches current script imports |
| 4 | Script-layer confirmation addressed | ⚠️ Not fully fixed | The repo now documents the architecture honestly, but execution scripts still do not enforce confirmation |
| 5 | API model separation clarified | ⚠️ Partially fixed | Matrix added, but agent-side auth model is still mislabeled in current docs |
| 6 | Old `docs/` path references fixed | ⚠️ Mostly fixed | Main markdown references improved; one residual stale path remains in script docstring |

---

## Detailed Findings

### 1. [High] Swap confirmation is still policy-only, not execution-enforced

**Files:**

- `skills/defi-trading/SKILL.md`
- `CLAUDE.md`
- `scripts/order_make_sign_send.py`
- `scripts/social_order_make_sign_send.py`
- `scripts/order_sign.py`

**Issue:**

The repository now clearly states that human confirmation is enforced at the **agent layer**, not inside the scripts. This improves honesty, but it does **not** create an execution-layer safeguard.

The shipped one-shot execution paths still perform signing/sending directly once called:

- `makeOrder -> sign -> send`

There is still no in-script:

- final confirmation prompt
- decoded transaction preview
- binding check against a previously user-approved payload

**Why this matters:**

- This is not a "highest safety standard" execution model
- Safety remains dependent on the calling agent behaving correctly
- The current architecture is defensible, but it should not be described as a strong script-level security control

**Assessment vs v1.0:**

- **Improved honesty:** yes
- **Actual execution hardening:** no

**Recommendation:**

Either:

1. Add an execution-layer confirmation/preview mechanism for signing flows, or
2. Downgrade all security claims so they describe this as an **agent-orchestrated** safeguard rather than an enforced execution control

---

### 2. [High] `api-debugger` still retains unsupported OpenAPI language

**Files:**

- `agents/api-debugger.md`

**Issue:**

The file now has valid frontmatter, but the body still says:

- Bitget Wallet Agent API `(OpenAPI)`
- validate parameters against the `OpenAPI spec`

No OpenAPI artifact exists in the repository.

**Why this matters:**

- Reviewers will still see a claim that cannot be substantiated from repo contents
- This weakens the credibility of the debugging persona
- It creates confusion about what source of truth the agent should use

**Assessment vs v1.0:**

- Frontmatter issue fixed
- OpenAPI claim **not** fixed

**Recommendation:**

Remove `OpenAPI` / `OpenAPI spec` references entirely unless the spec is added to the repository.

---

### 3. [Medium] `api-debugging` still mislabels the `copenapi` auth model

**Files:**

- `skills/api-debugging/SKILL.md`
- `agents/api-debugger.md`
- `scripts/bitget-wallet-agent-api.py`

**Issue:**

The repo now includes an API Model Matrix, which is good. However, it currently describes the agent/CLI model at `copenapi.bgwapi.io` as:

- `Partner-Code header (no API key)`

That does **not** match the shipped CLI implementation, which sends:

- `X-SIGN`
- `X-TIMESTAMP`
- `token`
- `channel`
- `brand`

**Why this matters:**

- Developers using the debugging skill can still be pointed to the wrong auth model
- The new matrix introduces clarity at a high level but is still technically inaccurate in a critical detail

**Assessment vs v1.0:**

- Better than before, but still not correct

**Recommendation:**

Revise the `copenapi` row to describe the actual auth/header pattern used by `scripts/bitget-wallet-agent-api.py`.

---

### 4. [Medium] `x402` residual documentation drift still remains

**Files:**

- `skills/x402-payments/references/x402-payments.md`
- `scripts/x402_pay.py`
- `README.md`

**Issue:**

The main `skills/x402-payments/SKILL.md` is now much closer to the real implementation. However, some residual drift remains:

- `references/x402-payments.md` still shows a non-existent `--private-key` flag in the testing example
- `references/x402-payments.md` still documents Permit2 as a fallback path
- `scripts/x402_pay.py` header comments still say it handles Permit2
- `README.md` still describes x402 as `(EIP-3009 / Solana)` in a way that can over-imply parity, even though Solana is still sign-only / partial-flow oriented

**Why this matters:**

- Reviewers often scan references and script headers, not just the main router `SKILL.md`
- Residual inconsistencies make the repo look only partially cleaned up

**Assessment vs v1.0:**

- Major improvement
- Not fully reconciled

**Recommendation:**

Perform one final x402 wording sweep across:

- `README.md`
- `skills/x402-payments/references/x402-payments.md`
- `scripts/x402_pay.py`

and ensure all three describe the same actual support matrix.

---

### 5. [Medium] Python CLI onboarding is still incomplete in top-level docs

**Files:**

- `README.md`
- `requirements.txt`

**Issue:**

The dependency declaration problem is fixed in `requirements.txt`, but the top-level setup/docs still do not clearly instruct users to install Python dependencies before running the shipped CLI tools.

During smoke checking in the current environment, `python3 scripts/social-wallet.py --help` failed before dependency installation due to missing modules.

**Why this matters:**

- A clean reviewer environment can still perceive the CLI as broken
- This is now an onboarding/documentation gap rather than a dependency-declaration gap

**Assessment vs v1.0:**

- Runtime dependency listing fixed
- Clean-environment usability still underspecified

**Recommendation:**

Add an explicit CLI prerequisite step in `README.md`, for example:

- create virtualenv
- `pip install -r requirements.txt`
- then run CLI examples

---

### 6. [Low] Small residue remains in internal wording and stale references

**Files:**

- `scripts/bitget-wallet-agent-api.py`
- `security-audit-slowmist-v1.0.md`

**Issue:**

Two low-severity cleanup items remain:

- `scripts/bitget-wallet-agent-api.py` still contains a stale `See docs/market-data.md` docstring reference
- `security-audit-slowmist-v1.0.md` still reads as if human confirmation is an enforced execution property, while the repo now more accurately describes it as an agent-layer architecture

**Why this matters:**

- These are not major blockers
- But they reduce polish and weaken submission consistency

**Recommendation:**

Clean both files so they match the repository's updated, more accurate model.

---

## Confirmed Improvements

The following improvements were verified in this re-audit:

- All three agent files now have valid frontmatter
- `requirements.txt` now covers the current runtime imports
- `skills/x402-payments/SKILL.md` now correctly uses:
  - subcommand CLI structure
  - `PAYMENT-SIGNATURE`
  - explicit support boundaries for Solana
- `skills/api-debugging/SKILL.md` now has a useful API model matrix
- The repo is more honest than before about where confirmation is enforced

---

## Delta vs v1.0

Compared with `AUDIT-REPORT-v1.0.md`:

- **Resolved:** 1 blocking issue
- **Resolved:** dependency declaration gap
- **Resolved:** agent metadata compliance issue
- **Improved but not fully closed:** x402 consistency
- **Improved but not fully closed:** API model separation
- **Reframed, not truly fixed:** confirmation architecture

Overall trend: **substantial improvement**, but **not yet submission-ready under a strict audit standard**.

---

## Release Recommendation

**Current decision:** Do **not** submit yet.

The repository is now much closer to acceptable quality, but one final cleanup/hardening pass is still warranted before external review.

Minimum actions required to move this report to `GO`:

1. Remove all remaining unsupported `OpenAPI` references
2. Correct the `copenapi` auth model description to match the actual CLI headers/signing
3. Finish the x402 wording sweep across router, reference, script header, and README
4. Add explicit Python CLI setup instructions in `README.md`
5. Either:
   - implement execution-layer confirmation safeguards, or
   - consistently document the current model as agent-orchestrated rather than script-enforced

---

## Final Assessment

This is now a **real, substantial plugin repository** with meaningful remediation completed. It is no longer failing on obvious submission-shape issues.

But under a strict review lens, the remaining problems are exactly the kind of "last 10%" issues that determine whether a plugin feels truly production-ready:

- are the docs exact
- are the claims bounded
- is the execution safety model accurately represented
- can a fresh reviewer reproduce success cleanly

Until those are closed, this report remains `NO-GO`.
