# Bitget Wallet Cursor Plugin - README Audit Report v1.0

> Audit Date: 2026-04-02
> Auditor: Independent strict review
> Target: `README.md`
> Scope: user-facing accuracy, installation reliability, consistency with repository behavior, and post-incident upstream-fidelity expectations

---

## Executive Summary

**Verdict:** `HOLD - README is directionally strong, but install guidance is not yet fully reliable`

The current `README.md` is substantially better than a typical plugin README:

- the product scope is clear
- the skill matrix matches the current repository
- the MCP naming and no-key auth model are current
- the repository structure section is broadly aligned with the tree
- Claude Code `--plugin-dir` usage is a real documented path

However, under the stricter post-incident audit standard, the README still has a few user-facing issues that can mislead installation or runtime expectations.

Findings in this pass:

- **Medium-risk issues:** 1
- **Low-risk issues:** 2

---

## Audit Method

This audit used:

- Static review of:
  - `README.md`
  - `install.sh`
  - `.mcp.json`
  - `.cursor-plugin/plugin.json`
  - `.claude-plugin/plugin.json`
  - `CLAUDE.md`
  - `reviews/SUBMISSION-REVIEW.md`
  - `reviews/ACCEPTANCE-TEST.md`
- Validation of installer usage via:
  - `bash install.sh --help`
- Live documentation checks:
  - Claude Code plugin docs (`--plugin-dir` support)
- Cross-checking current MCP runtime expectations:
  - README MCP instructions
  - `.mcp.json` server launcher
  - acceptance-plan note that MCP integration requires `uv`

---

## Findings

### 1. [Medium] README's MCP install path is internally inconsistent with the repository's actual `.mcp.json` launcher

**Files:**

- `README.md`
- `.mcp.json`
- `reviews/ACCEPTANCE-TEST.md`

**Issue:**

The README currently gives a user a misleading "pip-only" path for MCP enablement.

In `README.md`, the "Optional: Python CLI & MCP Tools" section says:

- `pip install bitget-wallet-mcp`
- then immediately says Cursor reads `.mcp.json` automatically and the agent can call MCP tools directly

But the repository's `.mcp.json` is hardcoded to launch MCP via:

- `uvx bitget-wallet-mcp`

So `pip install bitget-wallet-mcp` by itself does **not** satisfy the repository's default MCP startup path unless the user also has `uv` / `uvx` installed or manually changes `.mcp.json`.

This is also inconsistent with the acceptance plan, which explicitly notes:

- MCP integration requires `uv`

**Why this matters:**

- A user can follow the README literally, believe MCP is installed, and still fail to launch MCP tools at runtime
- This affects the plugin's execution capability, not just explanatory prose
- It is exactly the kind of "docs look right, runtime contract differs" issue that should be treated seriously after `INCIDENT-001`

**Recommendation:**

Make the README explicit about the actual runtime contract. For example:

1. State that the shipped `.mcp.json` requires `uv` / `uvx`
2. Separate the two valid paths:
   - `uvx bitget-wallet-mcp` with the current `.mcp.json`
   - `pip install bitget-wallet-mcp` only if the user also updates `.mcp.json` to invoke the installed binary directly
3. Remove or rewrite any wording that implies `pip install` alone is sufficient for automatic MCP startup

---

### 2. [Low] Single-project install guidance understates collision and partial-install risk

**Files:**

- `README.md`
- `install.sh`

**Issue:**

The README presents `--project` install as a straightforward per-project mode, but the installer actually tries to symlink a broad set of top-level paths:

- `.cursor-plugin`
- `.claude-plugin`
- `skills`
- `rules`
- `agents`
- `.mcp.json`
- `CLAUDE.md`
- `assets`
- `scripts`
- `requirements.txt`

If any of those targets already exist in the user's project, `install.sh` skips them rather than merging or failing hard.

That means a project-scoped install can become **partial** in exactly the kinds of repositories likely to already contain:

- `CLAUDE.md`
- `.mcp.json`
- `scripts/`
- `assets/`
- `requirements.txt`

The README does not clearly warn users to inspect the installer's skipped-items output or explain that collisions may leave the plugin only partially available.

**Why this matters:**

- Users can think the plugin is installed when core pieces were actually skipped
- The risk is highest in mature repos, which are also the most likely users of AI tooling

**Recommendation:**

Add one short warning in the `Option B: Single-Project Install` section:

- this mode works best in projects that do not already define conflicting top-level plugin files/directories
- users should review any `Skipped` entries printed by `install.sh`
- if core items like `.cursor-plugin`, `.claude-plugin`, `skills`, `rules`, `agents`, `.mcp.json`, or `CLAUDE.md` are skipped, they should prefer global install instead

---

### 3. [Low] README omits the OS support boundary that the repository already documents elsewhere

**Files:**

- `README.md`
- `reviews/ACCEPTANCE-TEST.md`

**Issue:**

The README gives shell, symlink, and home-directory-based install instructions, but does not state the platform boundary anywhere up front.

The acceptance plan already documents:

- `macOS / Linux`
- `Windows not tested`

That limitation is absent from the README.

**Why this matters:**

- Windows users can reasonably assume the install flow is supported, then hit avoidable failures around Bash, symlinks, and Unix-style paths

**Recommendation:**

Add a short note near Quick Start or Prerequisites:

- Tested on macOS and Linux
- Windows is not currently validated

---

## Confirmed Strengths

These areas look reasonable and do **not** need correction from this audit:

- Feature scope and skill descriptions are aligned with the current repository
- MCP naming (`swap_quote`, `swap_confirm`, `swap_make_order`, `swap_send`, `balance`) is current
- No-key MCP auth wording matches current repository state
- `install.sh --help` matches the major install/uninstall command shapes described in the README
- Claude Code `--plugin-dir` usage is a valid documented local-plugin workflow

---

## Severity Summary

| Severity | Count | Impact |
|----------|-------|--------|
| Blocking | 0 | None |
| High | 0 | None |
| Medium | 1 | MCP setup can fail for users who follow README literally |
| Low | 2 | Project-install usability risk and missing OS boundary |

---

## Final Assessment

`README.md` is **mostly reasonable**, but not yet strict-audit clean.

The biggest problem is not feature drift; it is install-path clarity. The README currently mixes a `pip install` MCP story with a `.mcp.json` that actually expects `uvx`, which can mislead users into believing execution is available when it is not.

After that, the remaining issues are lighter but still worth correcting because they affect first-run success and user trust.

---

## Release Recommendation

**Current decision:** Hold README sign-off until installation guidance is tightened.

Minimum actions to clear this report:

1. Fix the MCP install instructions so they match the actual `.mcp.json` launcher
2. Add a collision warning for `--project` install
3. Add an OS support note (`macOS/Linux`, Windows not tested)

After those updates, another short README verification pass should be sufficient.
