# Bitget Wallet Cursor Plugin - Acceptance Plan Audit Report v1.0

> Audit Date: 2026-03-31
> Auditor: Independent strict review
> Target: `reviews/ACCEPTANCE-TEST.md`
> Scope: acceptance-plan quality, executability, coverage, and consistency with the current repository

---

## Executive Summary

**Verdict:** `HOLD - acceptance document not yet ready for independent sign-off`

The acceptance plan is directionally strong and much closer to usable than an average project test plan:

- it has a clear level structure
- many checks are executable
- it distinguishes structural, smoke, knowledge, and consistency checks
- it avoids unsafe live-funds testing

However, under the same strict standard used for the project audit, the current acceptance document still has material issues that would affect an independent acceptance agent:

- **Medium-risk issues:** 2
- **Low-risk issues:** 2

---

## Audit Method

This audit used:

- Static review of `reviews/ACCEPTANCE-TEST.md`
- Cross-checking against:
  - `README.md`
  - `CLAUDE.md`
  - `SUBMISSION-REVIEW.md`
  - `skills/`
  - `scripts/`
  - plugin manifests
- Targeted CLI verification:
  - `python3 scripts/social_order_make_sign_send.py --help`

This audit did **not** execute the full acceptance plan end to end. It evaluates whether the plan itself is accurate, portable, and suitable for an independent acceptance agent.

---

## Findings

### 1. [Medium] Hardcoded local filesystem paths break the document's "independent" and "self-contained" claims

**File:**

- `reviews/ACCEPTANCE-TEST.md`

**Issue:**

The Setup sections hardcode one developer's workstation path:

- `ln -s /Users/devin.yin/Documents/Work/009-AI/bgw-cursor-plugin .bitget-wallet`
- `cd /Users/devin.yin/Documents/Work/009-AI/bgw-cursor-plugin`

This directly conflicts with the document's stated goals that it be:

- executable by an independent agent
- self-contained

An external acceptance agent running on another machine cannot execute the plan literally without manually rewriting those paths.

**Why this matters:**

- It reduces portability
- It creates avoidable operator ambiguity
- It undermines the strongest claim in the document: that the plan is ready for independent execution

**Recommendation:**

Replace user-specific absolute paths with a portable variable or placeholder, for example:

- `<repo_root>`
- `$REPO_ROOT`
- or instructions that assume the agent starts in the repository root

---

### 2. [Medium] The plan does not actually cover all shipped feature claims

**Files:**

- `reviews/ACCEPTANCE-TEST.md`
- `README.md`

**Issue:**

The document says an independent auditor can verify the tests cover all plugin claims, but the acceptance matrix does not fully do that.

Concrete gaps:

- Level 3 knowledge tests cover:
  - DApp Integration
  - DeFi Trading
  - API Debugging
  - x402
  - Token Analysis
- But there is no corresponding knowledge/acceptance test for:
  - `social-wallet`
  - `rwa-trading`

There is also a concrete executable omission:

- `T2.1` says "All scripts print help without error"
- but it does **not** include `scripts/social_order_make_sign_send.py`
- that script exists, is a real CLI entrypoint, and prints help successfully

So the current plan mainly verifies existence of those domains, not their acceptance-level behavior.

**Why this matters:**

- The repository claims 7 user-facing skill domains
- An independent acceptance agent cannot sign off on omitted features
- This is a real coverage gap, not just editorial polish

**Recommendation:**

Add at least:

1. One Level 2 or Level 3 acceptance case for `social-wallet`
2. One Level 2 or Level 3 acceptance case for `rwa-trading`
3. `scripts/social_order_make_sign_send.py --help` to `T2.1`

---

### 3. [Low] Several "Executable check" snippets do not actually validate the full criteria listed in their own tables

**File:**

- `reviews/ACCEPTANCE-TEST.md`

**Issue:**

Several tests present a rich criteria table, but the executable snippet only checks a subset:

- `T1.1` table checks many manifest fields, but the command only asserts `name` and `version`
- `T1.3` table checks `name:` and `description:`, but the command only checks file existence and `references/`
- `T1.4` table checks `alwaysApply`, `globs`, and `description`, but the command only greps `alwaysApply: true`
- `T1.5` table checks `name:` and `description:`, but the command only greps `name:`

This means an acceptance agent that follows only the executable snippets can false-pass structural issues that the table says should be validated.

**Why this matters:**

- The document explicitly markets itself as executable
- Partial assertions weaken trust in PASS outcomes

**Recommendation:**

Either:

- strengthen each executable snippet so it checks the full table criteria, or
- relabel the current shell snippets as "quick smoke checks" and add explicit manual verification steps

---

### 4. [Low] Runtime acceptance is effectively Cursor-only, even though the document frames the product as a Cursor / Claude Code plugin

**File:**

- `reviews/ACCEPTANCE-TEST.md`

**Issue:**

The title and purpose frame the product as a Cursor / Claude Code plugin, but all behavior-level acceptance is defined only for Cursor IDE:

- Level 3 explicitly requires Cursor IDE
- there is no Claude Code runtime/behavior acceptance path
- Claude Code is only structurally checked via `T1.2`

This does not make the plan wrong, but it does mean the document is not yet a full acceptance plan for both declared plugin targets.

**Why this matters:**

- A reader can reasonably assume both integration targets are covered
- Current coverage only proves Claude Code structurally, not behaviorally

**Recommendation:**

Add either:

- one Claude Code behavior acceptance section, or
- an explicit note that runtime acceptance is Cursor-scoped and Claude Code is currently validated structurally only

---

## Severity Summary

| Severity | Count | Impact |
|----------|-------|--------|
| Blocking | 0 | None |
| High | 0 | None |
| Medium | 2 | Acceptance plan not yet reliable for independent sign-off |
| Low | 2 | Trust / coverage / portability gaps |

---

## Final Assessment

`reviews/ACCEPTANCE-TEST.md` is a solid base and is already useful internally.

But under a strict project-audit standard, it is not yet ready to serve as the authoritative plan for an independent acceptance agent because:

- execution still depends on developer-local paths
- coverage still misses two shipped feature domains
- several structural checks are weaker than their own stated criteria
- runtime acceptance is Cursor-only even though the product is framed as dual-target

---

## Release Recommendation

**Current decision:** Hold acceptance-plan sign-off.

Minimum actions to clear this report:

1. Replace hardcoded local paths with portable repo-root-based instructions
2. Add acceptance coverage for `social-wallet` and `rwa-trading`
3. Add `social_order_make_sign_send.py --help` to `T2.1`
4. Tighten Level 1 executable assertions or relabel them as partial smoke checks
5. Clarify Claude Code runtime scope, or add a Claude behavior acceptance section

After those updates, another acceptance-plan audit would be appropriate.
