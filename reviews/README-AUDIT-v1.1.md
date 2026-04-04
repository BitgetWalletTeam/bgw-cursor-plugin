# Bitget Wallet Cursor Plugin - README Audit Report v1.1

> Audit Date: 2026-04-02
> Auditor: Independent strict review
> Target: `README.md`
> Scope: user-facing accuracy, installation reliability, consistency with repository behavior, and post-incident upstream-fidelity expectations

---

## Executive Summary

**Verdict:** `PASS - zero findings in README audit scope`

The issues raised in `reviews/README-AUDIT-v1.0.md` are now closed.

The current `README.md` is reasonable and materially aligned with:

- the repository's actual install flows
- the shipped `.mcp.json` launcher
- the current MCP naming/auth model
- the repository's documented platform boundary

No reviewer-grade defects were identified in this verification pass.

---

## Audit Method

This verification used:

- Static review of:
  - `README.md`
  - `install.sh`
  - `.mcp.json`
  - `.cursor-plugin/plugin.json`
  - `.claude-plugin/plugin.json`
  - `CLAUDE.md`
  - `reviews/SUBMISSION-REVIEW.md`
  - `reviews/ACCEPTANCE-TEST.md`
- Validation of installer surface via:
  - `bash install.sh --help`
- Documentation cross-checks:
  - Claude Code plugin docs for `--plugin-dir`
- Comparison against the prior findings from `reviews/README-AUDIT-v1.0.md`

This pass focused on README correctness and installer/documentation alignment. It did **not** perform a fresh end-to-end install in a clean Cursor runtime.

---

## Closed Findings from v1.0

### 1. MCP install-path mismatch

This is now closed.

`README.md` now correctly states that the shipped `.mcp.json` launches MCP via `uvx`, requires `uv`, and that a `pip install bitget-wallet-mcp` path requires the user to change `.mcp.json` accordingly.

### 2. Project-install collision / partial-install risk

This is now closed.

`README.md` now warns that `--project` install may skip existing paths and tells users to inspect `Skipped` entries and prefer global install if core items are skipped.

### 3. Missing OS support boundary

This is now closed.

`README.md` now explicitly states:

- tested on macOS and Linux
- Windows is not currently validated

---

## Confirmed Strengths

The current README is strong in the areas that matter most for user trust:

- product scope and skill descriptions match the current repository
- MCP tool naming is current (`swap_quote`, `swap_confirm`, `swap_make_order`, `swap_send`, `balance`, etc.)
- no-key MCP auth wording matches the repository's current state
- global and project installer commands match `install.sh`
- Claude Code `--plugin-dir` guidance is a valid local-plugin workflow
- the repository structure section matches the shipped tree closely enough for user orientation

---

## Findings

No findings.

---

## Severity Summary

| Severity | Count | Impact |
|----------|-------|--------|
| Blocking | 0 | None |
| High | 0 | None |
| Medium | 0 | None |
| Low | 0 | None |

---

## Residual Limits

This `PASS` applies to README quality and documentation-to-repository alignment.

The following were not part of this README-only verification:

- a clean-machine Cursor install test
- a clean-machine Claude Code install test
- Windows runtime validation

Those are runtime verification gaps, not README defects identified in this pass.

---

## Final Assessment

`README.md` is now audit-clean within this review scope.

The previous install-path ambiguity has been removed, the project-install caveat is now visible to users, and the platform support boundary is explicit. The README is suitable for user-facing distribution in its current form.

---

## Release Recommendation

**Current decision:** README sign-off approved.
