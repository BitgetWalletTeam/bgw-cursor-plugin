# Changelog

## Current Upstream Pins

> This section tracks the latest verified upstream commits used in this plugin.
> For machine-readable data, see [`upstream.json`](upstream.json).
> To check for drift: `bash scripts/check-upstream.sh`

| Upstream Repo | Pinned Commit | Commit Date |
|---------------|---------------|-------------|
| bitget-wallet-skill | `2a4b6c5` | 2026-04-03 |
| bitget-wallet-developer-skill | `34a02aa` | 2026-03-24 |
| bitget-wallet-partner-skill | `05814bd` | 2026-03-31 |
| bitget-wallet-mcp | `7d961f7` | 2026-03-31 |

---

## [1.0.0] — 2026-03-30

### Added
- Initial plugin structure with `.cursor-plugin/` and `.claude-plugin/` manifests
- **7 Skills** from Bitget Wallet AI Lab ecosystem:
  - `defi-trading` — Token swap, cross-chain bridge, gasless transactions (from bitget-wallet-skill)
  - `token-analysis` — Market data, security audits, smart money tracking (from bitget-wallet-skill)
  - `social-wallet` — Social Login Wallet with TEE signing (from bitget-wallet-skill)
  - `rwa-trading` — Real-World Asset stock trading (from bitget-wallet-skill)
  - `x402-payments` — HTTP 402 USDC payment protocol (from bitget-wallet-skill)
  - `dapp-integration` — Multi-chain DApp code generation (from developer-skill + dapp-common-skill)
  - `api-debugging` — Bitget Wallet API debugging: HMAC, Partner-Code, Agent auth (from partner-skill)
- **3 Rules** (auto-applied):
  - `provider-namespace.mdc` — Enforces `window.bitkeep.*` namespace
  - `security-practices.mdc` — Prevents key leaks, unsafe approvals
  - `swap-safety.mdc` — Swap amount format, token safety checks
- **3 Agents**:
  - `defi-operator.md` — DeFi operations persona
  - `dapp-developer.md` — DApp code generation persona
  - `api-debugger.md` — API debugging persona
- **MCP configuration** for `bitget-wallet-mcp` server
- **7 Python scripts** from bitget-wallet-skill for CLI-based operations
- `CLAUDE.md` for Claude Code project context
- `reviews/REVIEW-v1.0.md` with initial review and fix log
