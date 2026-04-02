# Incident Report: Upstream Drift

> **ID:** INCIDENT-001
> **Date Detected:** 2026-04-02
> **Severity:** Medium
> **Status:** Remediated

---

## Summary

The plugin contained stale information copied from upstream repositories at build time. As upstream repos evolved, the plugin's documentation drifted out of sync. This was not caught by 14 rounds of internal audits, 1 security audit, or acceptance testing because all verification was self-referential — checking internal consistency, not upstream fidelity.

---

## Root Cause Analysis

### Why it happened

The plugin was built by consolidating content from 5 upstream GitHub repositories:

| Upstream Repo | Content Taken | Snapshot Date |
|---------------|---------------|---------------|
| `bitget-wallet-skill` | Skills, scripts, docs | ~2026-03-30 |
| `bitget-wallet-developer-skill` | DApp integration skill | ~2026-03-30 |
| `bitget-wallet-partner-skill` | API debugging skill | ~2026-03-30 |
| `bitget-wallet-mcp` | MCP config, tool names | ~2026-03-30 |
| `bitget-wallet-cli` | Referenced in docs | ~2026-03-30 |

The build process was a **one-time snapshot**: clone upstream, extract relevant content, rewrite into plugin structure. No mechanism was established to detect when upstream sources change.

### Why it wasn't caught

The quality assurance lifecycle was designed for **internal consistency**, not **upstream fidelity**:

1. **Plugin audit (14 rounds)** — Checked: Do manifests match docs? Do skills reference correct paths? Do script docstrings match SKILL.md claims? → All internal cross-checks.
2. **SlowMist security audit** — Checked: Prompt injection, credential leakage, privilege escalation. → Security scope, not content accuracy.
3. **Acceptance plan audit (4 rounds)** — Checked: Are test cases executable? Do assertions match tables? → Test quality, not upstream truth.
4. **Acceptance testing (35 tests)** — Checked: Do scripts run? Does the agent give correct answers based on loaded skills? → Runtime validation against the plugin's own knowledge, not against upstream.

**No test or audit step verified claims against the live upstream source.**

### The specific gap

```
Upstream repo evolves
       │
       ▼
Plugin snapshot stays frozen ← No sync mechanism
       │
       ▼
Audit checks plugin vs plugin (self-referential)
       │
       ▼
All internal checks pass, but content is stale
```

---

## Findings

### Finding 1: MCP API Key Requirement Removed (already fixed)

- **Upstream change:** `bitget-wallet-mcp` switched from API key auth to SHA256 hash signing (BKHmacAuth). `BGW_API_KEY` and `BGW_API_SECRET` environment variables were removed.
- **Our state:** `.mcp.json` still had `BGW_API_KEY`/`BGW_API_SECRET` in env block. README told users to `export BGW_API_KEY=...`. CLAUDE.md said "Set `BGW_API_KEY` and `BGW_API_SECRET`".
- **Impact:** Users following our Quick Start would set unnecessary env vars. Not harmful (MCP ignores them), but misleading.
- **Fix commit:** `692311b`

### Finding 2: MCP Tool Names Stale

- **Upstream change:** `bitget-wallet-mcp` tool names changed from `bgw_swap`, `bgw_check_token`, `bgw_get_balance`, `bgw_get_supported_chains` (4 tools) to `swap_quote`, `swap_confirm`, `swap_make_order`, `swap_send`, `check_swap_token`, `balance`, etc. (36 tools).
- **Our state:** 5 files still reference old tool names:
  - `skills/defi-trading/SKILL.md` (MCP Tools table)
  - `agents/defi-operator.md` (Tools section + Workflow)
  - `rules/swap-safety.mdc` (inline reference)
  - `reviews/SUBMISSION-REVIEW.md` (consistency table)
  - `CLAUDE.md` (already fixed tool count, but old tool names may linger)
- **Impact:** Agent using MCP would fail to find tools by the documented names. The MCP server would expose `swap_quote` but the agent would look for `bgw_swap`.
- **Fix:** Pending

### Finding 3: Star Count Stale

- **Our README:** "Wallet Skill (171 stars)"
- **Actual (API check):** 176 stars
- **Impact:** Minor; cosmetic inaccuracy.
- **Fix:** Pending

---

## What We're NOT Fixing

The following `bgw_` prefixed names are **not** MCP tool names — they are **skill-level conceptual groupings** from the upstream `bitget-wallet-skill` architecture, used as section headers to organize CLI sub-commands:

- `bgw_token_find` → groups: `search-tokens`, `token-price`, `rankings`, `launchpad`, etc.
- `bgw_token_check` → groups: `security`, `coin-dev`, `coin-market-info`, etc.
- `bgw_token_analyze` → groups: `simple-kline`, `trading-dynamics`, `holders-info`, etc.
- `bgw_address_find` → groups: `recommend-address-list`

These appear in `token-analysis/SKILL.md`, `references/market-data.md`, `references/token-analyze.md`, `references/address-find.md`, and as code comments in `scripts/bitget-wallet-agent-api.py`. They correctly match the upstream skill's published architecture and are clearly labeled as skill groupings, not MCP tools.

---

## Remediation

### Immediate Fixes (this commit)

1. ~~Remove `BGW_API_KEY`/`BGW_API_SECRET` from `.mcp.json`, README, CLAUDE.md~~ (done, `692311b`)
2. Update MCP tool names in `defi-trading/SKILL.md`, `agents/defi-operator.md`, `rules/swap-safety.mdc`
3. Update star count in `README.md`
4. Update `SUBMISSION-REVIEW.md` MCP tool references

### Structural Prevention

5. Add **upstream sync check** to acceptance test plan (`ACCEPTANCE-TEST.md`) as a new Level 4 test:
   - Fetch latest upstream READMEs
   - Verify MCP tool names match live `bitget-wallet-mcp` documentation
   - Verify authentication model claims match upstream
   - Verify chain support claims match upstream
   - Verify star counts are within reasonable range

This ensures future acceptance runs catch upstream drift before submission.

---

## Lessons Learned

1. **Self-referential audits have a blind spot.** Internal consistency checks — no matter how many rounds — cannot detect drift from external sources. The audit harness must include at least one "ground truth" verification step against the upstream.

2. **Snapshot-based integrations need a sync mechanism.** When consolidating content from multiple repos, the build process should record upstream commit SHAs and provide a diff check.

3. **MCP tool names are a runtime contract.** Unlike documentation prose (where minor inaccuracies are cosmetic), MCP tool names are machine-parsed identifiers. A stale tool name means the agent literally cannot call the tool. This class of issue should be treated as higher severity than general doc drift.
