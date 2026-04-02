# Bitget Wallet Cursor Plugin — Independent Audit Report v1.0

> Audit Date: 2026-03-31
> Auditor: Independent strict review
> Repository: `bgw-cursor-plugin`
> Scope: manifests, docs, skills, rules, agents, scripts, dependency declarations

---

## Executive Summary

**Verdict:** `NO-GO`

This repository is **not** a fake or empty plugin. It contains substantial skill content, executable Python tooling, and a coherent progressive-disclosure structure. However, it does **not yet** meet a "highest standard / ready for strict marketplace review" bar.

Current release posture:

- **Blocking issues:** 1
- **High-risk issues:** 4
- **Medium-risk issues:** 2
- **Primary concerns:** component format compliance, x402 documentation/implementation drift, incomplete runtime dependencies, missing execution-layer safety enforcement, and lack of automated acceptance coverage

---

## Audit Method

This audit used:

- Static review of repository contents
- Cross-checking top-level claims against actual files
- Review of `skills/`, `rules/`, `agents/`, and `scripts/`
- Dependency declaration review via `requirements.txt`
- Minimal non-destructive CLI smoke checks:
  - `python3 scripts/x402_pay.py --help`
  - `python3 scripts/order_make_sign_send.py --help`
- Cursor plugin documentation cross-check for manifest/agent format expectations

This audit did **not** use:

- Live Bitget API calls
- Live MCP execution
- Real wallet keys
- On-chain transaction execution

---

## Severity Summary

| Severity | Count | Release Impact |
|----------|-------|----------------|
| Blocking | 1 | Must fix before submission |
| High | 4 | Must fix before security/reviewer confidence |
| Medium | 2 | Should fix before release |

---

## Detailed Findings

### 1. [Blocking] `agents/*.md` missing required YAML frontmatter

**Files:**

- `agents/api-debugger.md`
- `agents/defi-operator.md`
- `agents/dapp-developer.md`

**Issue:**

All three agent files begin directly with Markdown body content and do not include YAML frontmatter metadata such as `name` and `description`.

**Why this matters:**

- Cursor plugin docs define frontmatter metadata for agents.
- Missing metadata may prevent correct agent discovery/parsing.
- This is a submission-format issue, not just a quality issue.

**Recommendation:**

Add valid frontmatter to all agent files and verify they load correctly in a local plugin install.

---

### 2. [High] `x402` skill claims do not match the shipped implementation

**Files:**

- `skills/x402-payments/SKILL.md`
- `skills/x402-payments/references/x402-payments.md`
- `scripts/x402_pay.py`

**Issue:**

The x402 skill advertises and instructs a flow that does not match the actual CLI and implementation.

**Evidence:**

- `SKILL.md` shows `python3 scripts/x402_pay.py --chain ... --url ...`, but the real CLI is subcommand-based: `sign-eip3009`, `sign-solana`, `pay`
- `SKILL.md` says the retry header is `X-PAYMENT`, while the reference doc and code use `PAYMENT-SIGNATURE`
- `SKILL.md` advertises `Permit2` and Solana payment flow support, but `scripts/x402_pay.py` contains `NotImplementedError` for Permit2 and the Solana `pay` path is not fully implemented

**Why this matters:**

- Agents following the skill literally will fail
- Reviewers will classify this as overclaiming functionality
- Security and correctness claims become less credible when docs and execution diverge

**Recommendation:**

Choose one of two paths:

1. Reduce claims to the exact shipped behavior and update `SKILL.md`, `README.md`, and references
2. Implement the missing flows and keep the broader claim set

Until one path is completed, do not present x402 as production-ready multi-scheme support.

---

### 3. [High] `requirements.txt` does not declare all runtime dependencies

**Files:**

- `requirements.txt`
- `scripts/social-wallet.py`
- `scripts/x402_pay.py`

**Issue:**

The dependency file currently declares only:

- `requests`
- `eth-account`

But the shipped scripts import additional libraries, including:

- `cryptography`
- `eth_utils`
- `eth_abi`
- `base58`
- `solders`

**Why this matters:**

- Clean installs can fail immediately with `ModuleNotFoundError`
- Marketplace/security reviewers often test in fresh environments
- "Real functionality" is weakened if the packaged dependency story is incomplete

**Recommendation:**

- Add all required runtime dependencies explicitly
- Perform a fresh-venv install test
- Document optional vs required dependencies if some flows intentionally need extra packages

---

### 4. [High] Human confirmation exists in docs/rules, but is not enforced in execution code

**Files:**

- `rules/swap-safety.mdc`
- `skills/defi-trading/SKILL.md`
- `scripts/order_make_sign_send.py`
- `scripts/order_sign.py`

**Issue:**

The repository repeatedly claims that swaps require explicit user confirmation and transaction detail presentation before signing. However, the actual one-shot execution path performs:

`makeOrder -> sign -> send`

without a built-in step that decodes and presents transaction details to the user or requires a final confirmation gate inside the script itself.

`order_sign.py` also signs raw hashes/messages using `unsafe_sign_hash` when the API instructs it to do so.

**Why this matters:**

- Current safety is largely procedural and agent-dependent
- It is not a script-level security control
- A compromised upstream response could be signed without an execution-layer verification step

**Recommendation:**

- Add an execution-layer confirmation barrier for signing flows
- Display recipient, token, amount, route, gas, and destination chain before any final signature/send step
- Treat documentation-only confirmation promises as insufficient until enforced in code

---

### 5. [High] No automated tests or acceptance harness found

**Files/areas:**

- No `tests/`
- No `*test*`
- No `*spec*`

**Issue:**

No automated test suite or acceptance harness was found for the plugin.

**Why this matters:**

- This plugin spans swap execution, social wallet signing, x402 payment signing, and multi-chain tooling
- Without tests, regressions in CLI shape, imports, dependency coverage, or routing consistency can easily ship unnoticed
- "Production-ready" is difficult to support without repeatable verification

**Recommendation:**

At minimum, add:

- Import smoke tests for all scripts
- CLI parsing/help tests
- Doc-to-CLI consistency checks for critical commands
- Dependency installation verification in a clean environment

---

### 6. [Medium] `api-debugging` mixes multiple API models without clear separation

**Files:**

- `skills/api-debugging/SKILL.md`
- `skills/api-debugging/references/authentication.md`
- `skills/api-debugging/references/swap-order.md`
- `skills/api-debugging/references/market-data.md`
- `skills/api-debugging/references/token.md`
- `agents/api-debugger.md`
- `scripts/bitget-wallet-agent-api.py`

**Issue:**

The `api-debugging` area blends:

- partner API semantics (`bopenapi.bgwapi.io`, API Key/API Secret, HMAC, IP whitelist)
- agent/CLI semantics (`copenapi.bgwapi.io`, "new swap flow", no API key)

At the same time, `agents/api-debugger.md` tells the agent to validate requests against an "OpenAPI spec", but no OpenAPI artifact is present in the repository.

**Why this matters:**

- Users and reviewers may not understand which auth model applies to which flow
- "Compare against the OpenAPI spec" is not actionable from this repo alone
- This undermines trust in the debugging guidance

**Recommendation:**

- Split the docs into clearly named domains, or add an explicit matrix of host/auth/tooling differences
- If OpenAPI is claimed, include the spec or remove the claim

---

### 7. [Medium] Progressive-disclosure routing contains stale or broken links

**Files:**

- `skills/defi-trading/references/commands.md`
- `skills/token-analysis/references/market-data.md`

**Issue:**

Several references still point to old or misleading paths such as:

- `docs/market-data.md`
- `docs/token-analyze.md`
- `docs/address-find.md`

In the current repo layout, the real files live under `skills/token-analysis/references/`.

**Why this matters:**

- Agent routing is one of the plugin's core architecture claims
- Broken cross-links reduce usability and weaken the "load only what is needed" design

**Recommendation:**

Update all cross-skill links to the current repository structure and validate them systematically.

---

## Strengths

Despite the issues above, the repository shows clear substance:

- The plugin is **not** an empty wrapper; `skills/`, `rules/`, and `scripts/` contain meaningful material
- Progressive disclosure is a good architecture choice for large domain knowledge
- The repo covers real multi-chain scenarios including EVM, Solana, Tron, and social wallet flows
- `key_utils.py` uses a better pattern than passing secrets directly on the command line
- The safety rules around provider namespace, human-readable amounts, and explicit confirmation point in the right direction

---

## Release Recommendation

**Current decision:** Do **not** submit yet.

This plugin is promising, but it is not currently at a strict marketplace/security-review standard.

The minimum conditions to change the verdict to `GO` are:

1. Fix the blocking metadata issue in all agent files
2. Align x402 claims with real implementation or complete the missing implementation
3. Complete dependency declarations and pass a clean-environment install test
4. Add execution-layer confirmation and transaction detail presentation for signing flows
5. Add basic automated acceptance coverage

---

## Recommended Fix Order

1. Fix agent frontmatter
2. Reconcile x402 docs, headers, CLI, and implementation
3. Correct `requirements.txt` and verify a fresh install
4. Add execution-layer transaction confirmation safeguards
5. Add automated smoke/acceptance tests
6. Split or clarify `api-debugging` host/auth models
7. Repair broken cross-skill links

---

## Notes

- This report intentionally uses a strict standard suitable for marketplace review and security-sensitive plugin submission.
- A number of repository claims are directionally correct, but several are still stronger than the shipped implementation can currently support.
- No live API, MCP, or on-chain operations were executed during this audit.
