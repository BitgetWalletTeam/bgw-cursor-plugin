# Bitget Wallet Cursor Plugin - Acceptance Plan Audit Report v1.1

> Audit Date: 2026-03-31
> Auditor: Independent strict review
> Target: `reviews/ACCEPTANCE-TEST.md`
> Scope: acceptance-plan quality, executability, coverage, and consistency with the current repository

---

## Executive Summary

**Verdict:** `HOLD - acceptance document improved materially, but is not yet ready for independent sign-off`

The acceptance plan is substantially better than `v1.0`:

- hardcoded workstation paths were removed in favor of portable `$REPO_ROOT`-based setup
- `social-wallet` and `rwa-trading` coverage were added to both Level 2 and Level 3
- `scripts/social_order_make_sign_send.py --help` is now covered in `T2.1`
- Level 1 executable checks were strengthened
- runtime scope is now explicitly discussed for Cursor IDE and Claude Code

However, under the same strict standard used for the project audit, the current acceptance document still has issues that would affect an independent acceptance agent:

- **Medium-risk issues:** 1
- **Low-risk issues:** 3

---

## Audit Method

This audit used:

- Static review of `reviews/ACCEPTANCE-TEST.md`
- Cross-checking against:
  - `README.md`
  - `CLAUDE.md`
  - `reviews/SUBMISSION-REVIEW.md`
  - `skills/rwa-trading/SKILL.md`
  - `skills/social-wallet/SKILL.md`
  - `scripts/bitget-wallet-agent-api.py`
  - `scripts/social-wallet.py`
- Targeted CLI verification in the project virtualenv:
  - `source .venv/bin/activate && python3 scripts/bitget-wallet-agent-api.py rwa-get-config`
  - `source .venv/bin/activate && python3 scripts/bitget-wallet-agent-api.py rwa-get-config --help`
  - `source .venv/bin/activate && python3 scripts/social-wallet.py profile`

This audit did **not** execute the full acceptance plan end to end. It evaluates whether the plan itself is accurate, portable, and suitable for an independent acceptance agent.

---

## Confirmed Improvements Since v1.0

### Closed

1. **Portable setup instructions:** The document now uses `$REPO_ROOT` instead of developer-local absolute paths.
2. **Feature coverage expansion:** `social-wallet`, `rwa-trading`, and `social_order_make_sign_send.py --help` are now explicitly covered.

### Improved but not fully closed

1. **Executable structural checks:** The Level 1 snippets are stronger than in `v1.0`, but some still do not validate their full tables.
2. **Claude Code runtime framing:** A runtime-scope note was added, but Cursor-only wording still remains later in the document.

---

## Findings

### 1. [Medium] `T2.11` is not executable as written and will false-fail a healthy repository

**Files:**

- `reviews/ACCEPTANCE-TEST.md`
- `scripts/bitget-wallet-agent-api.py`

**Issue:**

`T2.11` currently instructs the acceptance agent to run:

- `python3 scripts/bitget-wallet-agent-api.py rwa-get-config`

and expects:

- exit code 0
- valid JSON
- RWA config data

But the shipped CLI does **not** support that invocation. The parser and command implementation require either:

- `--address-list`
- or `--json-stdin`

Actual verification in the project venv returns:

- exit code `1`
- stderr: `Error: --address-list or --json-stdin with addressList required`

So the acceptance plan now contains a concrete executable false-fail.

**Why this matters:**

- An independent agent following the document literally will mark `T2.11` as failed even when the repository is correct
- This undermines confidence in the acceptance run
- It is not a flaky network issue; it is a deterministic command-shape mismatch

**Recommendation:**

Replace `T2.11` with a command that matches the actual CLI contract, for example by providing a portable sample `--address-list` payload or a `--json-stdin` example.

---

### 2. [Low] Some Level 1 "Executable check" snippets still do not validate the full criteria listed in their own tables

**File:**

- `reviews/ACCEPTANCE-TEST.md`

**Issue:**

The structural snippets are stronger than before, but they are still not fully aligned with their tables.

Concrete examples:

- `T1.2` table says `skills` and `agents` must point to existing directories, but the executable check only asserts the fields are present
- `T1.3` table includes exact `references/` counts per skill, but the executable check only verifies the directory exists
- `T1.1` table lists non-empty description, specific author/email values, and non-empty logo expectations, but the executable check only partially validates those criteria

This means a strict acceptance agent that trusts the executable snippets can still false-pass some structural drift that the tables say should be checked.

**Why this matters:**

- The document explicitly positions itself as executable
- Table/script drift weakens trust in PASS outcomes
- This is a residual form of the `v1.0` "partial assertions" finding, not a brand-new category

**Recommendation:**

Either:

- strengthen the snippets so they fully validate the table criteria
- or reduce the tables so they describe only what is actually automated

---

### 3. [Low] Claude Code runtime scope is still internally contradictory

**File:**

- `reviews/ACCEPTANCE-TEST.md`

**Issue:**

The document now correctly adds a runtime-scope note saying Level 3 can be run in either:

- Cursor IDE
- Claude Code

But the very next lines still say:

- "They must be run interactively in Cursor IDE with the plugin loaded."
- "Setup: Open a project that contains (or symlinks to) the plugin in Cursor IDE."

So the document both allows Claude Code and instructs Cursor-only execution.

**Why this matters:**

- An independent Claude-based acceptance agent receives conflicting instructions
- This weakens the document's claim that runtime acceptance is dual-target aware

**Recommendation:**

Make the Level 3 body and setup runtime-neutral, or split them into explicit `Cursor IDE` and `Claude Code` setup variants.

---

### 4. [Low] The new Social Wallet knowledge test still omits a security-critical signing requirement

**Files:**

- `reviews/ACCEPTANCE-TEST.md`
- `skills/social-wallet/SKILL.md`

**Issue:**

`T3.8` now covers Social Wallet knowledge, which is an improvement. However, its pass criteria check only for:

- TEE-based signing
- script/tool awareness
- `walletId` / `profile` knowledge

The Social Wallet skill's critical security rules also require:

- explicit user confirmation before every signing operation

Because `T3.8` does not check for that, an agent could give unsafe signing guidance and still pass the acceptance test.

**Why this matters:**

- This plugin has been audited heavily around confirmation architecture
- Social Wallet signing is a high-sensitivity path
- A behavior acceptance case should not allow omission of the safety gate most specific to that skill

**Recommendation:**

Add a `T3.8` checkbox requiring the agent to state that explicit user confirmation is required before any signing or swap-signing step. If desired, also add a check that the agent does not reveal or request `.social-wallet-secret`.

---

## Severity Summary

| Severity | Count | Impact |
|----------|-------|--------|
| Blocking | 0 | None |
| High | 0 | None |
| Medium | 1 | Independent acceptance run can deterministically false-fail |
| Low | 3 | Residual trust, coverage, and dual-runtime clarity gaps |

---

## Final Assessment

`reviews/ACCEPTANCE-TEST.md` is now much closer to a real independent acceptance plan than `v1.0`.

The document's original portability and coverage gaps were materially improved. In particular, the plan now includes the previously missing domains and uses repo-root-based setup.

But this is **not** a zero-finding verification pass yet, because:

- `T2.11` is currently wrong as an executable command
- some structural automation still overstates what it checks
- Claude Code behavior acceptance is still described inconsistently
- Social Wallet behavior acceptance still misses a security-critical confirmation rule

---

## Release Recommendation

**Current decision:** Hold acceptance-plan sign-off.

Minimum actions to clear this report:

1. Fix `T2.11` so it matches the actual `rwa-get-config` CLI contract
2. Fully align Level 1 executable snippets with their tables, or narrow the tables
3. Remove the remaining Cursor-only wording from Level 3 if Claude Code is truly supported there
4. Add explicit confirmation-gate criteria to `T3.8`

After those updates, another acceptance-plan audit would be appropriate.
