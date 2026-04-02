---
name: dapp-integration
description: >
  Unified skill for production DApp frontends and Bitget Wallet multi-chain
  integration. Use when the user builds wallet-connected web apps, DApp layout,
  transfers, chain switching, signing, transaction lifecycle, gas UX, or
  mentions Bitget Wallet, window.bitkeep, Wagmi, RainbowKit, WalletConnect,
  TonConnect, Telegram Mini Apps, or DeepLinks. Covers DApp architecture
  patterns (layout, transfer forms, chain selector, signing panels) and
  chain-specific APIs for EVM, Solana, Bitcoin, TON, Aptos, Cosmos, Tron, and
  Sui. Do NOT use for pure smart-contract/backend work without wallet UI, or
  wallet-internal development.
license: MIT
metadata:
  author: Bitget Wallet
  version: 1.0.0
  tags:
    - dapp
    - developer
    - multichain
    - wallet
    - bitget
    - evm
    - solana
    - bitcoin
    - ton
    - aptos
    - cosmos
    - tron
    - sui
    - frontend
    - ux
---

# DApp integration (Bitget Wallet + common patterns)

This skill merges **Bitget Wallet provider integration** with **standard DApp UI/UX patterns**. Load only the references you need (progressive disclosure).

## Step 1: Route by intent

**Bitget Wallet / chain APIs**

| User intent | Load references |
|-------------|-----------------|
| Connect EVM / MetaMask-compatible | `references/detection-and-setup.md` + `references/evm.md` |
| Solana DApp | `references/detection-and-setup.md` + `references/solana.md` |
| Bitcoin / Ordinals / BRC-20 | `references/detection-and-setup.md` + `references/bitcoin.md` |
| TON | `references/detection-and-setup.md` + `references/ton.md` |
| Aptos | `references/detection-and-setup.md` + `references/aptos.md` |
| Cosmos / IBC | `references/detection-and-setup.md` + `references/cosmos.md` |
| Tron | `references/detection-and-setup.md` + `references/tron.md` |
| Sui | `references/detection-and-setup.md` + `references/sui.md` |
| Wagmi / RainbowKit | `references/adapters.md` (adapter handles detection) |
| Bitget in recommended wallet list | `references/adapters.md` → recommended/default list section |
| Multi-chain (Bitget APIs) | `references/detection-and-setup.md` + each chain file |
| Telegram Mini App | `references/telegram-miniapp.md` |
| Open Bitget Swap | `references/bitget-exclusive.md` |
| DeepLink / open in app | `references/deeplink.md` |

> **Wildcard:** Unlisted chain name → `references/detection-and-setup.md` + `references/{chain}.md` if present.

**DApp architecture & UX**

| User intent | Load references |
|-------------|-----------------|
| Generic DApp (EVM) | `references/dapp-layout.md` + `references/dapp-adapter-integration.md` + `references/dapp-ux-patterns.md` + clarify features |
| Generic DApp (non-EVM or multi-chain) | `references/dapp-layout.md` + `references/dapp-wallet-connection.md` + `references/dapp-ux-patterns.md` + clarify features |
| Wagmi / RainbowKit / WalletConnect (UI + config) | `references/dapp-adapter-integration.md` |
| Transfer / send tokens | `references/dapp-transfer.md` + `references/dapp-transaction-lifecycle.md` + `references/dapp-gas-and-fees.md` |
| ERC-20 transfer | `references/dapp-transfer.md` + `references/dapp-token-approval.md` + `references/dapp-gas-and-fees.md` |
| Chain switching / multi-chain UI | `references/dapp-chain-switching.md` |
| Message signing / SIWE | `references/dapp-signing.md` |
| Transaction status / history | `references/dapp-transaction-lifecycle.md` + `references/dapp-ux-patterns.md` |
| Gas / fee estimate UX | `references/dapp-gas-and-fees.md` |
| Full-featured DApp | All `references/dapp-*.md` files + wallet chain refs above |

> For almost any DApp screen, also load `references/dapp-ux-patterns.md` (loading states, toasts, empty states, confirmations).

**Decision shortcuts**

```
React + EVM only          → adapters.md + dapp-adapter-integration.md
React + multi-chain       → detection-and-setup.md + chain refs + dapp-wallet-connection.md
Vue / Angular / vanilla   → detection-and-setup.md + chain refs
Telegram Mini App         → telegram-miniapp.md (+ ton.md if TON)
Existing ethers / web3    → evm.md (provider directly)
```

**Connection architecture (summary)**

- Prefer **RainbowKit / Web3Modal** for EVM: EIP-6963 + WalletConnect QR + mobile paths. Do not ship a single hardcoded “one wallet” button for production EVM.
- **Non-EVM:** `references/dapp-wallet-connection.md` (direct provider); combine with `references/dapp-adapter-integration.md` when the app is EVM + non-EVM.
- **WalletConnect Project ID:** Required for QR / mobile via Reown; optional for extension-only. Guide: [dashboard.reown.com](https://dashboard.reown.com/) → env `VITE_WALLETCONNECT_PROJECT_ID` or `NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID`.

## Step 2: Clarify before coding

| Topic | Ask |
|-------|-----|
| DApp purpose | Swap, transfer, mint, dashboard, etc. — do not assume “connect only” |
| Chains | Which families (EVM, Solana, …)? Single vs multi-chain? **Do not default to EVM-only.** |
| Framework | React+Vite, Next, Vue — default React+Vite if unspecified |
| Transfers | Native only vs tokens; never hardcode amounts |
| Signing | Login / typed data / which sign types |
| Bridge vs adapter | `window.bitkeep` vs Wagmi etc. |
| EVM tooling | Target chain, chain switching, ethers vs viem |
| Solana | Legacy vs versioned transactions |
| Bitcoin | Ordinals / PSBT? |
| TON | JS bridge vs TonConnect |
| Aptos | Mainnet vs testnet |
| WalletConnect | Project ID for QR/mobile |

## Step 3: Read references (progressive disclosure)

**Wallet / Bitget (`references/` except `dapp-*`):**

- `references/detection-and-setup.md` — detection, install prompts, EIP-6963
- Chains: `references/evm.md`, `solana.md`, `bitcoin.md`, `ton.md`, `aptos.md`, `cosmos.md`, `tron.md`, `sui.md`
- `references/adapters.md` — Wagmi, RainbowKit, WalletConnect, TonConnect, Web3-Onboard
- `references/telegram-miniapp.md`, `deeplink.md`, `bitget-exclusive.md`

**DApp patterns (`references/dapp-*.md`):**

- `references/dapp-layout.md`, `dapp-wallet-connection.md`, `dapp-adapter-integration.md`
- `references/dapp-transfer.md`, `dapp-token-approval.md`, `dapp-chain-switching.md`
- `references/dapp-signing.md`, `dapp-transaction-lifecycle.md`, `dapp-gas-and-fees.md`, `dapp-ux-patterns.md`

## Step 4: Architecture expectations

- **Adapter EVM app:** `config/wagmi.ts`, RainbowKit `<ConnectButton />`, shared components (`TransferForm`, `SigningPanel`, `TxStatus`, `Layout`), `utils/format|chains|errors`.
- **Direct provider:** `WalletStatus`, hooks (`useWalletConnection`, `useTransfer`, `useSigning`, `useBalance`), same utils/components pattern.
- **Multi-chain:** `chains/` adapters + `ChainFamilySelector` + hooks delegating to active adapter — see `references/dapp-chain-switching.md` and chain files for Bitget APIs.

UI components stay **adapter-agnostic** where possible; Bitget-specific calls live in chain references or thin adapter modules.

## Step 5: DApp UX essentials

1. Never hardcode tx parameters — inputs for amount, recipient, token.
2. Always show chain context and a way to switch.
3. Human-readable amounts (ETH not wei, SOL not lamports).
4. EVM: accept ENS, validate addresses per chain.
5. Tx lifecycle: idle → signing → pending → confirmed/failed + explorer link.
6. Show gas/fee estimate before confirm (EVM tiers where relevant).
7. Pre-wallet confirmation preview in the DApp.
8. Toasts for tx lifecycle; skeletons while loading; empty states with CTAs.
9. ERC-20: explicit approve step, prefer exact allowance, check existing allowance.
10. Map wallet errors to plain language; show what is being signed; cancel/back paths.
11. Persist connection across reload; indicate mainnet vs testnet.
12. Copy buttons for addresses, sigs, hashes; respect dark mode.

## Step 6: Implement & handle errors

- Detect provider first (`detection-and-setup.md` or adapter detection).
- Handle all wallet throws; use TypeScript types from references.
- Test extension and Bitget app where relevant.

| Code | Meaning | Action |
|------|---------|--------|
| 4001 | User rejected | Retry prompt; do not auto-retry |
| 4100 | Unauthorized | Connect first |
| 4200 | Unsupported method | Check method / chain |
| 4900 | Disconnected | Reconnect |
| 4901 | Chain disconnected | Switch chain |
| -32000 | Invalid input | Fix params |
| -32602 | Invalid params | Fix types/values |
| -32603 | Internal | RPC / retry with backoff |

```typescript
interface WalletError { code: number; message: string; }
function handleWalletError(error: WalletError): void {
  switch (error.code) {
    case 4001: console.log('User rejected. Try again when ready.'); break;
    case 4100: console.log('Connect your wallet first.'); break;
    case -32603: console.log('Network/wallet error. Retry later.'); break;
    default: console.error(`Wallet error ${error.code}: ${error.message}`);
  }
}
```

## Core knowledge (inline)

**Provider quick reference**

| Chain | Bitget provider | Common compat |
|-------|-----------------|---------------|
| EVM | `window.bitkeep.ethereum` | MetaMask |
| Solana | `window.bitkeep.solana` | Phantom |
| Bitcoin | `window.bitkeep.unisat` | UniSat |
| TON | `window.bitkeep.ton` | OpenMask |
| Aptos | `window.bitkeep.aptos` | Petra |
| Cosmos | `window.bitkeep.keplr` | Keplr |
| Tron | `window.bitkeep.tronWeb` / `.tronLink` | TronLink |
| Sui | `window.bitkeep.suiWallet` | Wallet Standard |

**Quick connect**

```typescript
const accounts: string[] = await window.bitkeep.ethereum.request({ method: 'eth_requestAccounts' });
await window.bitkeep.solana.connect();
const pubkey = window.bitkeep.solana.publicKey.toString();
const btc = await window.bitkeep.unisat.requestAccounts();
```

**Wallet constants**

```
Bitget Wallet | window.bitkeep | https://web3.bitget.com
Extension: jiidiaalihmmhddjgbnbgdfflelocpak | EIP-6963 rdns: com.bitget.web3
Docs: https://web3.bitget.com/en/docs/ | Demos: https://github.com/bitgetwallet/dapp-integration-demos
```

**Formatting helpers** (full chain table: `references/dapp-gas-and-fees.md` / `dapp-chain-switching.md`)

```typescript
function formatAmount(raw: string | bigint, decimals = 18): string {
  const value = typeof raw === 'string' ? BigInt(raw) : raw;
  const divisor = BigInt(10 ** decimals);
  const whole = value / divisor;
  const fraction = (value % divisor).toString().padStart(decimals, '0').slice(0, 6);
  return `${whole}.${fraction}`.replace(/\.?0+$/, '') || '0';
}
function shortenAddress(address: string, chars = 4): string {
  return address ? `${address.slice(0, chars + 2)}...${address.slice(-chars)}` : '';
}
```

**Multi-chain React:** compose per-chain hooks from `references/evm.md`, `solana.md`, etc., inside a single provider; see those files for `useWallet` / `useSolanaWallet` patterns.

## Examples (abbreviated)

1. **EVM connect (Next.js):** `detection-and-setup.md` + `evm.md` → detect, `eth_requestAccounts`, show address, handle 4001.
2. **Multi-chain ETH+SOL+BTC:** detection + `evm.md` + `solana.md` + `bitcoin.md` + `dapp-layout.md` + `dapp-wallet-connection.md` + `dapp-chain-switching.md`.
3. **Wagmi:** `adapters.md` + `dapp-adapter-integration.md` — injected connector, EIP-6963 `com.bitget.web3`.
4. **Token-gated ERC-20:** `evm.md` + `dapp-transfer.md` / balance reads.
5. **Switch EVM chains:** `evm.md` — `wallet_switchEthereumChain`, `wallet_addEthereumChain`, `chainChanged`.
6. **Full DApp + Bitget:** Ask chains → load matching `dapp-*.md` + chain `references/*.md` → adapters + tx lifecycle + signing as needed.

## Resources

- Bitget: https://web3.bitget.com — Docs: https://web3.bitget.com/en/docs/
- Wagmi / Viem / ethers — official docs; EIP-712, EIP-4361 (SIWE)
- Demos: https://github.com/bitgetwallet/dapp-integration-demos
