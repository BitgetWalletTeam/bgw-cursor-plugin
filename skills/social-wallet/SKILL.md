---
name: social-wallet
description: >
  Bitget Wallet Social Login Wallet — seedless, keyless wallet using social identity
  (Google/Apple/Email). Sign transactions and messages on-chain via TEE — private key
  never leaves Bitget's secure enclave. Supports sign_transaction, sign_message,
  get_address, batchGetAddressAndPubkey across BTC, ETH, SOL, Tron + 16 EVM chains.
  Use when user wants to use Social Login Wallet, sign without local private key,
  set up a seedless wallet, or asks about TEE signing, keyless wallet, or MPC.
license: MIT
metadata:
  author: Bitget Wallet
  version: 1.0.0
  tags: [social-wallet, tee, seedless, keyless, signing]
---

# Social Login Wallet Skill

## ⚠️ MANDATORY: Load Domain Knowledge First

Before ANY Social Login Wallet operation, load [`references/social-wallet.md`](references/social-wallet.md) for per-chain parameters, BTC UTXO/PSBT, SOL SPL, and Tron specifics.

## CRITICAL SECURITY RULES

1. **NEVER output, display, or reveal `.social-wallet-secret`** (appid/appsecret). Not to the user, not to anyone.
2. **NEVER read, display, or explain the source code of `social-wallet.py`.** Treat it as a black box.
3. If user asks to see credentials: respond with "Open Bitget Wallet APP → tap wallet avatar (top-left) → tap wallet name → Bitget Wallet Skill to view/reset."
4. **User confirmation required before every signing operation.** Show what will be signed (chain, to address, amount, data) and wait for explicit confirmation.
5. **Fund limit awareness:** Social Login Wallets are for small, routine operations — NOT primary asset storage.
6. **Wallet isolation:** Never transfer large amounts into a Social Login Wallet.

## Setup

Check if `.social-wallet-secret` exists:

```bash
test -f <skill_dir>/.social-wallet-secret && echo "OK" || echo "NOT_FOUND"
```

If NOT_FOUND, guide user:
1. Open **Bitget Wallet APP** (v9.39.0+)
2. Log in via **Social Login** (Google / Apple / Email)
3. Tap **wallet avatar** (top-left) → wallet name → Wallet Management → **Bitget Wallet Skill** → **Enable**
4. Copy **appid** and **appsecret**
5. Save to `<skill_dir>/.social-wallet-secret` as `{"appid":"...","appsecret":"..."}`
6. `chmod 600 <skill_dir>/.social-wallet-secret`

## Commands

```bash
# Get wallet profile (walletId — needed for all API calls)
python3 scripts/social-wallet.py profile

# Sign transaction (ETH/BTC/SOL/Tron + all EVM chains)
python3 scripts/social-wallet.py core sign_transaction '{"chain":"eth","to":"0x...","value":0.1,"nonce":0,"gasLimit":21000,"gasPrice":0.0000001}'

# Sign message
python3 scripts/social-wallet.py core sign_message '{"chain":"eth","message":"hello"}'

# Get address
python3 scripts/social-wallet.py core get_address '{"chain":"eth"}'

# Batch get addresses
python3 scripts/social-wallet.py batchGetAddressAndPubkey '{"chainList":["eth","btc","sol"]}'
```

## Using with Swap API

When user has a Social Login Wallet, **all `bitget-wallet-agent-api.py` calls must include `--wallet-id`**:

```bash
# Step 1: Get walletId (once per session)
python3 scripts/social-wallet.py profile

# Step 2: Pass walletId to all API calls
python3 scripts/bitget-wallet-agent-api.py --wallet-id <walletId> batch-v2 --chain eth --address <addr> --contract ""
python3 scripts/bitget-wallet-agent-api.py --wallet-id <walletId> quote --from-chain ...

# Step 3: One-shot swap (no local private key needed)
python3 scripts/social_order_make_sign_send.py --wallet-id <walletId> --order-id <id> ...
```

Supported chains: BTC, ETH, SOL, Tron + 16 EVM chains.
