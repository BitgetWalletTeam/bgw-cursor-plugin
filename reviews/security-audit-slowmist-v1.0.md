# SlowMist Agent Security Assessment Report

> Framework: [slowmist-agent-security v0.1.2](https://github.com/slowmist/slowmist-agent-security)
> Audit Date: 2026-03-30
> Auditor: AI Agent (independent, no development context)

```
════════════════════════════════════════════════════════════
  SKILL / MCP SECURITY ASSESSMENT
────────────────────────────────────────────────────────────
  Name:         bitget-wallet (Cursor Plugin)
  Version:      1.0.0
  Source:       GitHub (internal GitLab → github.com/bitget-wallet-ai-lab)
  Author:       Bitget Wallet AI Lab
  Trust Tier:   1 — Official project organization
  Published:    2026-03-30
  Last Updated: 2026-03-30
────────────────────────────────────────────────────────────
  FILES SCANNED
  Total: 68  |  Executable: 7 (.py)  |  Docs: 51 (.md)
  Config: 3 (.json) + 3 (.mdc) + 1 (.svg) + 3 (other)
  High-risk files: scripts/*.py (7 files, 3,606 lines)
  Binary files: None
────────────────────────────────────────────────────────────
  RED FLAGS
  None critical. Details below.
────────────────────────────────────────────────────────────
  PERMISSIONS REQUIRED
  Read:     .social-wallet-secret (local credential file)
            --private-key-file (temp file, read-and-delete)
  Write:    None (no file creation by plugin code)
  Network:  https://copenapi.bgwapi.io (Bitget Wallet API)
            User-specified URLs (x402_pay.py --url, third-party)
  System:   chmod 0o600 (temp key file permission, order_make_sign_send.py)
  Env Vars: BGW_API_KEY, BGW_API_SECRET (MCP server config)
            X402_PRIVATE_KEY (x402_pay.py fallback)
────────────────────────────────────────────────────────────
  ARCHITECTURE
  Credential handling:  Read-and-delete pattern via key_utils.py;
                        keys written to tempfile.mkstemp(), read once,
                        file deleted, variable nulled after use
  Human-in-the-loop:    Yes — swap requires explicit user confirmation
                        before sign+send (agent-orchestrated; enforced
                        via SKILL.md workflow + rules, not in scripts)
  Auto-update:          No — no VERSION check, no MANIFEST, no auto-download
  Data boundary:        Bitget API traffic to copenapi.bgwapi.io only;
                        x402_pay.py also calls user-specified URLs
                        (third-party, user-directed)
  Degradation:          Graceful — scripts exit with error messages on failure
────────────────────────────────────────────────────────────
  RISK:     🟢 LOW
  VERDICT:  ✅ SAFE
────────────────────────────────────────────────────────────
  NOTES
  See detailed findings below.
════════════════════════════════════════════════════════════
```

---

## 1. Red Flag Pattern Scan (11 Categories)

### 1.1 Outbound Data Exfiltration

| File | Network Calls | Destination | Purpose Match |
|------|--------------|-------------|---------------|
| `bitget-wallet-agent-api.py` | `requests.post`, `requests.get` | `copenapi.bgwapi.io` | Yes — Bitget Wallet API |
| `social-wallet.py` | `requests.post` | `copenapi.bgwapi.io` | Yes — Social Wallet TEE signing |
| `x402_pay.py` | `requests.get` (via `urllib` pattern) | User-specified `--url` | Yes — x402 payment protocol |
| `order_sign.py` | None | N/A | Pure offline signing |
| `order_make_sign_send.py` | Via imported modules | `copenapi.bgwapi.io` | Yes — combined flow |
| `social_order_make_sign_send.py` | Via imported modules | `copenapi.bgwapi.io` | Yes — combined flow |
| `key_utils.py` | None | N/A | Pure file I/O |

**Verdict:** All network destinations are consistent with the plugin's stated purpose (Bitget Wallet DEX aggregator API). No calls to unexpected or unknown domains. No local data sent to third-party servers.

**Rating: 🟢 No flag**

### 1.2 Credential / Environment Variable Access

| File | Access | Purpose | Boundary Match |
|------|--------|---------|----------------|
| `x402_pay.py` L366 | `os.environ["X402_PRIVATE_KEY"]` | Fallback when no `--private-key-file` | Yes — key stays local, used for on-chain signing |
| `social-wallet.py` L41 | `open(SECRET_FILE)` reads `.social-wallet-secret` | Load appid/appsecret for TEE API | Yes — credentials used only with `copenapi.bgwapi.io` |
| `.mcp.json` | `${BGW_API_KEY}`, `${BGW_API_SECRET}` | MCP server auth | Yes — template variables, not read by plugin code |

**Verdict:** All credential access matches the service boundary. `X402_PRIVATE_KEY` is used exclusively for local signing (never sent over network). `.social-wallet-secret` credentials are sent only to `copenapi.bgwapi.io` (Bitget's own API). No credential harvesting or cross-boundary leakage.

**Rating: 🟢 No flag**

### 1.3 File System Access Beyond Scope

| File | Access | Path |
|------|--------|------|
| `key_utils.py` | Read + Delete | User-specified `--private-key-file` path |
| `social-wallet.py` | Read | `.social-wallet-secret` (relative to script dir) |
| `order_make_sign_send.py` | chmod | `tempfile.mkstemp()` output (0o600) |

**Verdict:** No access to `~/.ssh`, `~/.aws`, `~/.config`, `~/.gnupg`, `/etc/`, `/proc/`, or any sensitive system directories. File access is strictly scoped to user-specified paths and the plugin's own directory.

**Rating: 🟢 No flag**

### 1.4 Agent Identity / Memory File Access

**Scan result:** Zero matches for `MEMORY.md`, `USER.md`, `SOUL.md`, `IDENTITY.md`, `paired.json`, `openclaw.json`, `sessions.json`, `.claude/settings`, or any agent identity files.

**Rating: 🟢 No flag**

### 1.5 Dynamic Code Execution

| File | Pattern | Context | Risk |
|------|---------|---------|------|
| `social_order_make_sign_send.py` L22-23 | `importlib.import_module()`, `importlib.util.spec_from_file_location()` | Loads sibling scripts (`bitget-wallet-agent-api`, `social-wallet`) by known, hardcoded relative paths | 🟢 Safe |
| `order_make_sign_send.py` L127-128 | `importlib.import_module()` | Loads `bitget-wallet-agent-api` by known module name | 🟢 Safe |

**Verdict:** `importlib` usage is strictly for loading known, local, co-located scripts — not for executing external or user-supplied code. The module names are hardcoded strings, not dynamic inputs. No `eval()`, `exec()`, `Function()`, `os.system()`, or `subprocess` calls found.

**Rating: 🟢 No flag** (false positive — standard Python inter-module loading)

### 1.6 Privilege Escalation

| File | Pattern | Context |
|------|---------|---------|
| `order_make_sign_send.py` L18 | `os.chmod(pk_file, 0o600)` | Restricts temp key file permissions — this is a security *improvement*, not escalation |
| `skills/social-wallet/SKILL.md` L46 | `chmod 600 .social-wallet-secret` | Documentation instructing user to secure credential file |

**Verdict:** No `sudo`, `su`, `setuid`, `setgid`, `chown root`, or any actual privilege escalation. The only `chmod` usage *reduces* permissions (0o600 = owner-only read/write), which is best practice for key files.

**Rating: 🟢 No flag**

### 1.7 Persistence Mechanisms

**Scan result:** Zero matches for `crontab`, `systemctl`, `.bashrc`, `.zshrc`, `.profile`, `launchd`, `plist`, `autostart`, or any persistence mechanism.

**Rating: 🟢 No flag**

### 1.8 Runtime Package Installation (Secondary Download)

**Scan result:** No `pip install`, `npm install`, `cargo install`, `curl | sh`, or any runtime download in Python scripts. The `npm install` references in documentation files (`dapp-integration/references/*.md`) are instructional examples for users building DApps — they are never executed by the plugin.

No `postinstall`, `preinstall`, `setup.py`, or `pyproject.toml` found in the repository.

**Rating: 🟢 No flag**

### 1.9 Code Obfuscation

**Scan result:** `base64` usage in 3 scripts:
- `x402_pay.py`: Base64 encoding/decoding of Solana serialized transactions and x402 payment payloads — standard protocol requirement
- `social-wallet.py`: Base64 for AES-GCM encrypted API communication — standard crypto pattern
- `order_sign.py`: Base58 encoding/decoding for Solana key format — standard blockchain format

All code is well-commented, uses descriptive variable names, and follows standard Python conventions. No minification, no hex-encoded payloads, no string concatenation to build commands, no ROT13 or custom encoding.

**Rating: 🟢 No flag** (false positive — standard crypto/blockchain encoding)

### 1.10 Process / System Reconnaissance

**Scan result:** Zero matches for `ps aux`, `pgrep`, `/proc/PID`, `netstat`, `lsof`, `nmap`, `uname`, `hostnamectl`, or any reconnaissance commands.

**Rating: 🟢 No flag**

### 1.11 Browser Session / Cookie Access

**Scan result:** `localStorage` referenced in 2 files:
- `rules/security-practices.mdc` L8: "Never store wallet credentials in localStorage or sessionStorage" — this is a **security rule prohibiting** localStorage abuse
- `skills/dapp-integration/references/dapp-transaction-lifecycle.md` L149-166: Example code showing `localStorage` for transaction history UI — standard DApp pattern, no credential storage

**Rating: 🟢 No flag** (false positive — security rule + instructional code example)

---

## 2. Social Engineering & Prompt Injection Scan (8 Categories)

### 2.1 Pseudo-Authority Claims

**Scan result:** No claims of endorsement by external organizations. Author correctly identified as "Bitget Wallet AI Lab" throughout. No fabricated certifications.

### 2.2 Safety False Assurance

**Scan result:** No misleading safety claims. Documentation accurately describes what operations are dangerous (private key handling, signing, fund transfers). Human confirmation is orchestrated at the agent layer (SKILL.md workflow and rules define the confirmation gate; scripts are execution tools called after confirmation).

### 2.3 Urgency and Pressure

**Scan result:** No urgency language. No "install immediately" or "critical update" patterns.

### 2.4 Trust Grafting

**Scan result:** Plugin name `bitget-wallet` matches the official organization `bitget-wallet-ai-lab` on GitHub. No typosquatting. Repository URL `https://github.com/bitget-wallet-ai-lab/bitget-wallet` is consistent with the official organization.

### 2.5 Progressive Escalation

**Scan result:** No escalation pattern. Plugin instructions follow a clear, documented workflow with explicit user confirmation gates at each step.

### 2.6 Mixed Payload (Trojan Lines)

**Scan result:** All code blocks in documentation files are instructional and consistent with their stated purpose. No hidden commands between legitimate ones.

### 2.7 Comment/Documentation Disguise

**Scan result:** Code comments accurately describe the code's behavior. No cases where comments claim "read-only" while code writes/sends data.

### 2.8 Confirmation Bypass

**Scan result:** No `-y`, `--force`, `--yes`, or pipe-to-shell patterns in the plugin's own installation or execution flow. The plugin requires user confirmation before executing trades (defined in `swap-safety.mdc` rule 5 and `defi-trading/SKILL.md` workflow; confirmation is agent-orchestrated, not script-enforced). The `x402_pay.py pay` subcommand includes its own interactive `Pay? [y/N]` prompt as an additional safeguard.

**Overall Social Engineering Rating: 🟢 No flags**

---

## 3. Supply Chain Attack Scan (7 Categories)

### 3.1 Runtime Secondary Download

**Result:** Not applicable — no runtime package installation.

### 3.2 Pipe-to-Shell Execution

**Result:** Not applicable — no `curl | sh` or `wget | bash` patterns in executable code.

### 3.3 One-Shot Execution (npx/pipx)

**Result:** MCP server uses `uvx bitget-wallet-mcp` (via `.mcp.json`). This is a standard MCP server invocation pattern — the package `bitget-wallet-mcp` is published by the same organization (`bitget-wallet-ai-lab`) and is a known, auditable PyPI package. Trust Tier 1.

### 3.4 Auto-Update Channels

**Result:** No VERSION file, no MANIFEST, no remote update check, no auto-download. Plugin is fully static.

### 3.5 Dependency Hijacking

**Result:** `requirements.txt` pins minimum versions (`requests>=2.28.0`, `eth-account>=0.9.0`) — both are well-known, high-download packages with no typosquatting risk. `bitget-wallet-mcp` in `.mcp.json` is published by the official organization.

### 3.6 Build-Time Injection

**Result:** No `package.json`, `setup.py`, `pyproject.toml`, `Makefile`, or `Dockerfile` present. No build-time hooks.

### 3.7 Trusted Source Compromise

**Result:** Trust Tier 1 — official organization. Source repository is maintained by `bitget-wallet-ai-lab` with active commit history. Risk is inherent to any Tier 1 source but mitigated by code auditability (all source is readable Python + Markdown).

**Overall Supply Chain Rating: 🟢 No flags**

---

## 4. Architecture Assessment

| Aspect | Assessment | Rating |
|--------|-----------|--------|
| **Private key management** | User holds keys. Agent constructs unsigned transactions. Keys passed via temp files (read-and-delete). Social Wallet uses TEE signing (no local key). | ✅ Secure |
| **Human-in-the-loop** | Swap flow requires explicit user confirmation before sign+send. Agent-orchestrated via SKILL.md workflow, rules, and agent personas (scripts are execution tools, not interactive). | ✅ Secure |
| **Credential storage** | `.social-wallet-secret` file (chmod 600). Private keys via `tempfile.mkstemp()` (deleted after read). Env vars for MCP config. | ✅ Secure (scoped, ephemeral) |
| **Auto-update** | None. Static plugin. | ✅ Secure |
| **Data boundary** | Bitget API traffic to `copenapi.bgwapi.io` only. `x402_pay.py` also calls user-specified third-party URLs (user-directed, not automatic). | ✅ Secure |
| **Degradation** | Scripts exit with descriptive error messages. No silent failures. | ✅ Secure |

---

## 5. Informational Findings (Non-Blocking)

### INFO-1: Test API Credentials in Documentation

**File:** `skills/api-debugging/references/authentication.md` L22-23

```
API Key:    6AE25C9BFEEC4D815097ECD54DDE36B9A1F2B069
API Secret: C2638D162310C10D5DAFC8013871F2868E065040
```

**Analysis:** These are intentionally shared, rate-limited (2 QPS) test credentials published by the upstream `bitget-wallet-partner-skill` repository. The file contains a clear warning: "Do not use test credentials in production." The credentials are not used by any executable code in the plugin.

**Risk:** 🟢 LOW — informational. Automated secret scanners (GitHub secret scanning, TruffleHog) may flag these. Consider adding a `.gitleaks.toml` allowlist if publishing to a public repository with scanning enabled.

### INFO-2: `importlib` Dynamic Import

**Files:** `social_order_make_sign_send.py` L22, `order_make_sign_send.py` L127

**Analysis:** Uses `importlib.import_module()` to load co-located sibling scripts by hardcoded name. This is a standard Python pattern when module names contain hyphens (e.g., `bitget-wallet-agent-api` cannot be imported with `import` statement due to the hyphens). The module paths are fixed strings, not user-controlled.

**Risk:** 🟢 LOW — no security concern. Standard Python workaround.

### INFO-3: `os.environ` for Private Key Fallback

**File:** `x402_pay.py` L366-367

**Analysis:** Falls back to `X402_PRIVATE_KEY` environment variable when `--private-key-file` is not provided. The key is used exclusively for local EIP-3009 or Solana signing — it never leaves the process. This is a standard pattern for CI/CD and testing scenarios. The `--private-key-file` (read-and-delete) method is preferred and documented as the primary approach.

**Risk:** 🟢 LOW — environment variables are process-scoped. No cross-boundary leakage.

---

## 6. Quick Decision Matrix

| Condition | Result |
|-----------|--------|
| Pure Markdown, no scripts, no network | ❌ Has scripts + network |
| Scripts exist but scope is clear, known author | ✅ **Applies** — Trust Tier 1, scope is clear |
| Touches credentials, funds, or system config | Credentials: scoped + ephemeral. Funds: requires human confirmation. System: no modification. |
| Matches red-flag patterns or contains obfuscated code | ❌ No matches |
| Binary files that cannot be audited | ❌ None |
| Installation source is a third-party domain | ❌ Official organization |
| Uses `-y`/`--force` flags to skip confirmation | ❌ Never |

**Matrix Result:** Scripts exist, scope is clear, known author → 🟡 MEDIUM baseline, **downgraded to 🟢 LOW** because:
1. Trust Tier 1 (official organization)
2. Zero red flag pattern matches across all 11 categories
3. Zero social engineering pattern matches across all 8 categories
4. Zero supply chain attack pattern matches across all 7 categories
5. Strong security architecture (read-and-delete keys, human-in-the-loop, no auto-update)
6. All network destinations match stated purpose
7. No binary files

---

## 7. Final Assessment

```
════════════════════════════════════════════════════════════
  RISK:     🟢 LOW
  VERDICT:  ✅ SAFE
════════════════════════════════════════════════════════════
```

### Summary

The Bitget Wallet Cursor Plugin (v1.0.0) passes all 26 security checks across the SlowMist Agent Security framework's three pattern libraries (11 red-flag, 8 social-engineering, 7 supply-chain). The plugin demonstrates strong security practices:

- **Private key lifecycle:** Read-and-delete pattern with `tempfile.mkstemp()`, 0600 permissions, explicit memory clearing after use
- **Human-in-the-loop:** Trade execution requires explicit user confirmation, orchestrated at the agent layer via SKILL.md workflow, rules, and agent personas (scripts are execution tools called after agent obtains confirmation)
- **Network boundary:** Bitget API calls to `copenapi.bgwapi.io`; x402 payments call user-specified third-party URLs
- **No persistence:** No crontabs, no startup scripts, no auto-update mechanisms
- **No escalation:** No sudo, no setuid, no system modification
- **Full auditability:** All code is readable Python + Markdown, no binaries or obfuscation

### Recommendations

1. If publishing to a GitHub repository with secret scanning, add a `.gitleaks.toml` to allowlist the intentional test credentials in `authentication.md`
2. Consider pinning exact dependency versions in `requirements.txt` (e.g., `requests==2.32.3` instead of `>=2.28.0`) for maximum supply chain protection

---

*Report generated using [SlowMist Agent Security Framework v0.1.2](https://github.com/slowmist/slowmist-agent-security)*
