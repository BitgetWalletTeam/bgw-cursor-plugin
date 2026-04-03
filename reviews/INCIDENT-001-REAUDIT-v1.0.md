# Bitget Wallet Cursor Plugin - Incident 001 Re-Audit Report v1.0

> Audit Date: 2026-04-02
> Auditor: Independent strict review
> Trigger: `reviews/INCIDENT-001-upstream-drift.md`
> Scope: post-incident re-audit of upstream-fidelity controls, current repository state, and sign-off artifact credibility

---

## Executive Summary

**Verdict:** `HOLD - engineering fixes are mostly present, but incident closure and final sign-off evidence are not yet audit-clean`

This re-audit confirms an important distinction:

- the **repository's current MCP-facing implementation and documentation are largely repaired**
- but the **sign-off artifacts and closure evidence are still stale/incomplete**

I manually re-verified the new upstream-fidelity controls:

- current `.mcp.json` has no `BGW_API_KEY` / `BGW_API_SECRET`
- current DeFi MCP tool names align with the live upstream `bitget-wallet-mcp` README
- `T4.6` / `T4.7` from `reviews/ACCEPTANCE-TEST.md` currently pass when executed manually

However, the repository still contains materially misleading review artifacts that overstate closure.

Findings in this pass:

- **High-risk issues:** 1
- **Medium-risk issues:** 1
- **Low-risk issues:** 1

---

## Audit Method

This re-audit used:

- Static review of:
  - `reviews/INCIDENT-001-upstream-drift.md`
  - `reviews/FINAL-REPORT.md`
  - `reviews/ACCEPTANCE-RESULT-v1.0.md`
  - `reviews/ACCEPTANCE-TEST.md`
  - `reviews/SUBMISSION-REVIEW.md`
  - `.mcp.json`
  - `README.md`
  - `CLAUDE.md`
  - `skills/defi-trading/SKILL.md`
  - `agents/defi-operator.md`
  - `rules/swap-safety.mdc`
- Live upstream verification against:
  - `bitget-wallet-mcp` upstream README
  - GitHub repository star counts
- Manual execution of the new upstream-sync acceptance controls:
  - `T4.6` MCP tool-name verification
  - `T4.7` no-key-auth verification

This pass specifically corrected the blind spot identified by the incident: I did **not** limit this review to internal consistency. I checked the current repository against live upstream data.

---

## Findings

### 1. [High] `FINAL-REPORT.md` still issues a zero-finding sign-off using superseded acceptance evidence

**Files:**

- `reviews/FINAL-REPORT.md`
- `reviews/ACCEPTANCE-RESULT-v1.0.md`
- `reviews/ACCEPTANCE-TEST.md`

**Issue:**

The final sign-off chain is no longer reliable after `INCIDENT-001`.

Current state:

- `reviews/FINAL-REPORT.md` says all workstreams reached zero-finding status and the plugin is ready for submission
- it cites acceptance testing as `35/35 PASS` on baseline `reviews/ACCEPTANCE-TEST.md` `v1.2`
- `reviews/ACCEPTANCE-RESULT-v1.0.md` also records baseline `v1.2` and stops at `T4.5`

But the current acceptance contract is now `reviews/ACCEPTANCE-TEST.md` `v1.3`, which added:

- `T4.6` — upstream MCP tool-name sync
- `T4.7` — upstream MCP auth-model sync

So the repository now has a **new required acceptance scope**, but the authoritative pass artifacts still reflect the **pre-incident baseline**.

There is also a concrete counting inconsistency in the sign-off evidence:

- `FINAL-REPORT.md` says acceptance testing was `35 tests`
- `ACCEPTANCE-RESULT-v1.0.md` also says `35/35`
- but its own per-level breakdown is `8 + 6 + 11 + 9 + 5 = 39`
- and the current `ACCEPTANCE-TEST.md` execution template now enumerates `T1.1` through `T4.7`, i.e. `41` actual test rows

I manually ran the new `T4.6` / `T4.7` checks and they **currently pass**, which reduces product risk. But that does **not** repair the audit-trace problem: there is still no authoritative acceptance result or final sign-off document that records those post-incident checks.

**Why this matters:**

- External reviewers can be misled into believing incident-driven controls were executed and signed off when the recorded result set predates them
- The current final sign-off is not supported by the current acceptance baseline
- This invalidates the repository's "ready for submission" claim as an audit artifact, even if the underlying repo is now close to correct

**Recommendation:**

1. Re-run acceptance testing against `reviews/ACCEPTANCE-TEST.md` `v1.3`
2. Publish an updated acceptance result artifact that explicitly includes `T4.6` and `T4.7`
3. Replace or supersede `reviews/FINAL-REPORT.md` with a post-incident final report based on the new acceptance baseline
4. Recompute and correct the total test counts instead of carrying forward `35/35`

---

### 2. [Medium] `SUBMISSION-REVIEW.md` still contains upstream-drifted facts in the exact area highlighted by the incident

**Files:**

- `reviews/SUBMISSION-REVIEW.md`

**Issue:**

The submission packet still contains stale upstream facts, despite `INCIDENT-001` identifying upstream drift as the core failure mode.

Confirmed examples:

- `bitget-wallet-skill` is still listed as `171` stars, while live GitHub currently reports `176`
- `bitget-wallet-mcp` is still listed as `13` stars and `17 tools`, while live GitHub currently reports `14` stars and the live upstream README documents `36` tools

This same document is internally contradictory:

- the early upstream-repo table still says `bitget-wallet-mcp` has `17 tools`
- but later sections already describe MCP as `36 tools`

So the exact drift class described in the incident remains present inside a core external-facing audit artifact.

**Why this matters:**

- `SUBMISSION-REVIEW.md` is presented as the main submission document for external auditors
- It is supposed to support trust, provenance, and traceability
- Leaving known drift in this document means the incident is not truly closed at the submission-package level

**Recommendation:**

Update `reviews/SUBMISSION-REVIEW.md` so all upstream-derived facts reflect current verified values, or explicitly mark them as snapshot metadata with pinned dates and commit SHAs.

---

### 3. [Low] `INCIDENT-001-upstream-drift.md` has an ambiguous closure state

**File:**

- `reviews/INCIDENT-001-upstream-drift.md`

**Issue:**

The incident report header says:

- `Status: Remediated`

But the body still contains open-ended language:

- Finding 2: `Fix: Pending`
- Finding 3: `Fix: Pending`
- remediation items 2–4 are listed without completion markers
- structural prevention says future acceptance runs should include upstream sync checks, but the recorded acceptance result artifact still predates those checks

This creates ambiguity about what exactly is:

- fixed in the repository
- rerun in acceptance
- closed at the sign-off level

**Why this matters:**

- Incident reports are governance documents, not just engineering notes
- A closure state should match the actual evidence trail

**Recommendation:**

Either:

- change the incident status from `Remediated` to something like `Engineering fixes applied, sign-off refresh pending`
- or update the body so each remediation item is explicitly marked done and linked to the new acceptance/final-report artifacts

---

## Confirmed Current-State Improvements

These areas do appear fixed in the current repository and were re-verified in this pass:

- `.mcp.json` no longer contains `BGW_API_KEY` or `BGW_API_SECRET`
- `README.md`, `CLAUDE.md`, `skills/defi-trading/SKILL.md`, `agents/defi-operator.md`, and `rules/swap-safety.mdc` now use the current MCP naming model
- the live upstream `bitget-wallet-mcp` README confirms the documented tool names `swap_quote`, `swap_confirm`, `swap_make_order`, `swap_send`, `check_swap_token`, and `balance`
- the live upstream README confirms `No API key required — uses SHA256 hash signing (BKHmacAuth)`

This means the main remaining problem is **artifact truthfulness and sign-off integrity**, not the core MCP documentation layer itself.

---

## Auditor Reflection

I did miss this class of issue earlier, and the incident report is correct about the failure mode.

### Why I missed it

1. **I optimized for repository-internal consistency, not external truth.** My earlier audits were strong at checking whether manifests, docs, skills, scripts, and acceptance plans agreed with each other. That catches many classes of defects, but it cannot detect upstream drift if the whole local bundle drifts together.

2. **I treated traceability claims as evidence instead of hypotheses to verify.** Documents like `SUBMISSION-REVIEW.md` described upstream sources and tool names, and I cross-checked those claims against the repository itself. I should have sampled the live upstream repositories before granting a zero-finding pass.

3. **I did not require an explicit ground-truth gate before final sign-off.** A strict audit process for snapshot-based integrations needs one mandatory stage that checks live upstream contracts: MCP tool names, auth model, major chain support, and other machine-sensitive identifiers.

4. **I over-trusted aggregate summary artifacts.** I did not independently recompute some summary claims, like total acceptance-test counts and whether the final sign-off still matched the active acceptance baseline.

### What I should have done differently

1. Add a mandatory live-upstream verification step before any `PASS`
2. Recompute totals and baseline references independently instead of trusting report summaries
3. Treat MCP tool names and auth models as runtime contracts, not ordinary documentation claims
4. Require all final sign-off artifacts to be regenerated whenever acceptance scope changes

### Process improvement I will follow going forward

Before issuing any future zero-finding verdict on snapshot-based repositories, I should always verify:

- current upstream contract names
- current auth model
- current top-level support claims
- whether final sign-off artifacts are based on the current acceptance baseline

---

## Severity Summary

| Severity | Count | Impact |
|----------|-------|--------|
| Blocking | 0 | None |
| High | 1 | Current final sign-off is not evidence-clean after the incident |
| Medium | 1 | Submission packet still contains the same drift class that caused the incident |
| Low | 1 | Incident closure state is ambiguous |

---

## Final Assessment

`INCIDENT-001` correctly identified a real blind spot in the prior audit approach.

This re-audit shows that the repository has made real corrective progress, and the newly added upstream-sync controls appear to work. But the incident is **not fully audit-closed** yet, because the post-incident acceptance/sign-off artifacts have not been refreshed to match the new truth and new test scope.

---

## Release Recommendation

**Current decision:** Reopen final sign-off until the post-incident evidence chain is refreshed.

Minimum actions to clear this re-audit:

1. Update `reviews/SUBMISSION-REVIEW.md` to remove remaining stale upstream facts
2. Re-run acceptance against `reviews/ACCEPTANCE-TEST.md` `v1.3` and publish a new acceptance result artifact
3. Replace or supersede `reviews/FINAL-REPORT.md` with a post-incident final report that cites the updated acceptance result
4. Make `reviews/INCIDENT-001-upstream-drift.md` status/body consistent with the actual closure state

After those updates, another short post-incident verification pass would be appropriate.
