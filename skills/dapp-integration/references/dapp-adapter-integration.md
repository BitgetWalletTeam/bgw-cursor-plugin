# Adapter Integration Reference

Standard patterns for using wallet adapter libraries (Wagmi, RainbowKit, WalletConnect) in DApps. Adapter libraries replace manual provider detection and give you multi-wallet UI, auto-reconnect, and mobile QR support out of the box.

## When to Use Adapters vs Direct Provider

| Scenario | Recommendation |
|----------|---------------|
| React + EVM only | **Wagmi + RainbowKit** — best DX, built-in UI |
| React + EVM + need custom wallet list | **Wagmi + RainbowKit** with custom wallet config |
| React + EVM + minimal deps | **Wagmi** alone (no UI kit, use your own components) |
| Vue / Angular / Vanilla JS + EVM | **WalletConnect EthereumProvider** directly |
| Any framework + multi-wallet modal | **Web3-Onboard** (framework-agnostic) |
| Non-EVM chains (Solana, Bitcoin, TON, etc.) | **Direct provider** (adapters are mostly EVM-focused) |
| Telegram Mini App + TON | **TonConnect** (see wallet skill) |

> **Key rule:** When using adapters, you do NOT need manual provider detection (`window.bitkeep`, EIP-6963, etc.) — the adapter handles all of that. You still need the wallet-specific skill for knowing which connectors/wallet IDs to configure.

## Prerequisites: Reown (WalletConnect) Project ID

Most adapter setups require a **Reown Project ID** (formerly WalletConnect Project ID) for QR code and mobile wallet connections.

**What needs a Project ID:**
- WalletConnect QR code connections (mobile wallets)
- RainbowKit's `getDefaultConfig` (uses WalletConnect under the hood)
- Web3Modal / AppKit

**What does NOT need a Project ID:**
- EIP-6963 browser extension detection (e.g. Bitget Wallet Chrome extension auto-discovered)
- `injected()` connector alone

### How to Get a Project ID

1. Go to [dashboard.reown.com](https://dashboard.reown.com/)
2. Sign up or sign in (email-based account)
3. Click **"+ Project"** → select **"AppKit"** → enter your project name → click **"Create"**
4. Your Project ID is shown on the project page — copy it

### Store in Environment Variables

```bash
# Vite
echo 'VITE_WALLETCONNECT_PROJECT_ID=your_project_id_here' >> .env

# Next.js
echo 'NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id_here' >> .env.local
```

Then reference in code:

```typescript
// Vite
const projectId = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID;

// Next.js
const projectId = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID;

if (!projectId) {
  console.warn('WalletConnect Project ID not configured. QR code connections will not work.');
}
```

> **Agent behavior:** When the user asks to set up Wagmi/RainbowKit, you MUST ask if they have a Project ID before writing config code. If they don't, walk them through the steps above. Do NOT leave `'YOUR_PROJECT_ID'` as a placeholder and move on.

---

## Wagmi Setup (React)

### Installation

```bash
npm install wagmi viem@2.x @tanstack/react-query
```

### Configuration

```typescript
import { http, createConfig } from 'wagmi';
import { mainnet, bsc, polygon, arbitrum, base, sepolia } from 'wagmi/chains';
import { injected, walletConnect } from 'wagmi/connectors';

const projectId = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID; // from dashboard.reown.com

const config = createConfig({
  chains: [mainnet, bsc, polygon, arbitrum, base, sepolia],
  connectors: [
    injected(),            // Auto-detects all injected wallets via EIP-6963
    walletConnect({ projectId }),  // QR code for mobile wallets
  ],
  transports: {
    [mainnet.id]: http(),
    [bsc.id]: http(),
    [polygon.id]: http(),
    [arbitrum.id]: http(),
    [base.id]: http(),
    [sepolia.id]: http(),
  },
});
```

### App Wrapper

```tsx
import { WagmiProvider } from 'wagmi';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient();

export default function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        {/* Your DApp components */}
      </QueryClientProvider>
    </WagmiProvider>
  );
}
```

### Using Wagmi Hooks (replaces useWalletConnection)

When using Wagmi, you do NOT create a custom `useWalletConnection` hook. Wagmi provides all the hooks:

```typescript
import { useAccount, useConnect, useDisconnect, useBalance, useChainId, useSwitchChain } from 'wagmi';
import { useSendTransaction, useSignMessage, useSignTypedData, useWaitForTransactionReceipt } from 'wagmi';
```

| Common Skill Hook | Wagmi Replacement |
|-------------------|-------------------|
| `useWalletConnection` | `useAccount` + `useConnect` + `useDisconnect` |
| `useBalance` | `useBalance` |
| `useChainSwitch` | `useSwitchChain` |
| `useTransfer` (sendNative) | `useSendTransaction` |
| `useSigning` | `useSignMessage` + `useSignTypedData` |
| `useTransactionTracker` | `useWaitForTransactionReceipt` |

### Connect / Disconnect

```tsx
import { useAccount, useConnect, useDisconnect } from 'wagmi';
import { injected } from 'wagmi/connectors';

function ConnectButton() {
  const { address, isConnected } = useAccount();
  const { connect, isPending } = useConnect();
  const { disconnect } = useDisconnect();

  if (isConnected) {
    return (
      <div>
        <span>{address}</span>
        <button onClick={() => disconnect()}>Disconnect</button>
      </div>
    );
  }

  return (
    <button onClick={() => connect({ connector: injected() })} disabled={isPending}>
      {isPending ? 'Connecting...' : 'Connect Wallet'}
    </button>
  );
}
```

### Send Transaction

```tsx
import { useSendTransaction, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther } from 'viem';

function SendForm() {
  const { sendTransaction, data: hash, isPending, error } = useSendTransaction();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const handleSend = (to: string, amount: string) => {
    sendTransaction({
      to: to as `0x${string}`,
      value: parseEther(amount),
    });
  };

  return (
    <div>
      {/* Use TransferForm from common skill, pass handleSend as onSend */}
      {isPending && <p>Confirm in wallet...</p>}
      {isConfirming && <p>Waiting for confirmation...</p>}
      {isSuccess && <p>Transaction confirmed!</p>}
      {error && <p>Error: {error.message}</p>}
    </div>
  );
}
```

## RainbowKit Setup (React + UI)

RainbowKit adds a polished wallet connection modal on top of Wagmi.

### Installation

```bash
npm install @rainbow-me/rainbowkit wagmi viem@2.x @tanstack/react-query
```

### Configuration

```typescript
import '@rainbow-me/rainbowkit/styles.css';
import { getDefaultConfig, RainbowKitProvider, ConnectButton } from '@rainbow-me/rainbowkit';
import { WagmiProvider } from 'wagmi';
import { mainnet, polygon, arbitrum, base, bsc } from 'wagmi/chains';
import { QueryClientProvider, QueryClient } from '@tanstack/react-query';

const projectId = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID;

const config = getDefaultConfig({
  appName: 'My DApp',
  projectId,
  chains: [mainnet, polygon, arbitrum, base, bsc],
});

const queryClient = new QueryClient();
```

### App with ConnectButton

```tsx
export default function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          <header>
            <ConnectButton />   {/* Replaces WalletStatus component */}
          </header>
          <main>
            {/* TransferForm, SigningPanel, etc. from common skill still work */}
          </main>
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
```

### Customizing the Wallet List

By default, RainbowKit shows a curated list. To control which wallets appear and in what order:

```typescript
import {
  getDefaultConfig,
} from '@rainbow-me/rainbowkit';
import {
  bitgetWallet,
  metaMaskWallet,
  coinbaseWallet,
  walletConnectWallet,
  rainbowWallet,
} from '@rainbow-me/rainbowkit/wallets';

const projectId = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID;

const config = getDefaultConfig({
  appName: 'My DApp',
  projectId,
  chains: [mainnet, polygon, arbitrum, base],
  wallets: [
    {
      groupName: 'Recommended',
      wallets: [
        bitgetWallet,         // First = most prominent
        metaMaskWallet,
        walletConnectWallet,
      ],
    },
    {
      groupName: 'Other',
      wallets: [
        coinbaseWallet,
        rainbowWallet,
      ],
    },
  ],
});
```

**Key points for wallet ordering:**
- The `wallets` array controls the order — first wallet in the first group is shown most prominently
- Installed wallets are auto-promoted to the top of their group via EIP-6963
- You can create multiple groups with custom names
- `walletConnectWallet` should always be included as a fallback for mobile users

### RainbowKit with Custom Theme

```typescript
import { darkTheme, lightTheme } from '@rainbow-me/rainbowkit';

<RainbowKitProvider
  theme={darkTheme({
    accentColor: '#00e6b8',
    accentColorForeground: '#0f172a',
    borderRadius: 'medium',
  })}
>
```

## WalletConnect Direct Setup (Non-React)

For Vue, Angular, or vanilla JS projects that need QR-based wallet connection:

### Installation

```bash
npm install @walletconnect/ethereum-provider @walletconnect/modal
```

### Configuration

```typescript
import { EthereumProvider } from '@walletconnect/ethereum-provider';

async function createProvider() {
  const projectId = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID;
  const provider = await EthereumProvider.init({
    projectId,
    chains: [1],
    optionalChains: [56, 137, 42161, 8453],
    showQrModal: true,

    // Control which wallets appear in the QR modal
    qrModalOptions: {
      // Show these wallets at the top of the list
      explorerRecommendedWalletIds: [
        'bitget',       // Bitget Wallet
      ],
    },
  });

  return provider;
}
```

### How to Get a Reown (WalletConnect) Project ID

See the **Prerequisites** section at the top of this file for step-by-step instructions.
Register at [dashboard.reown.com](https://dashboard.reown.com/).

### How to Control Which Wallets Appear in WalletConnect Modal

WalletConnect's modal shows wallets from their Explorer registry. You can control the list:

```typescript
const projectId = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID;
const provider = await EthereumProvider.init({
  projectId,
  chains: [1],
  showQrModal: true,
  qrModalOptions: {
    // Option 1: Recommend specific wallets (shown at top, others still visible)
    explorerRecommendedWalletIds: [
      'bitget',
      // Add other wallet IDs as needed
    ],

    // Option 2: Exclude specific wallets
    explorerExcludedWalletIds: ['some-wallet-id'],

    // Option 3: ONLY show specific wallets (exclusive mode)
    // explorerRecommendedWalletIds: ['bitget'],
    // explorerExcludedWalletIds: 'ALL',  // Hide all others
  },
});
```

## Integrating Adapters with Common Skill Components

When using Wagmi/RainbowKit, the common skill's UI components (TransferForm, SigningPanel, TxHistory) still work. You just wire them to Wagmi hooks instead of custom hooks:

```tsx
import { useAccount, useSendTransaction, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther } from 'viem';

function TransferPage() {
  const { address } = useAccount();
  const { sendTransactionAsync } = useSendTransaction();

  // This callback is passed to TransferForm's onSend prop
  const handleSend = async (to: string, amount: string): Promise<string> => {
    const hash = await sendTransactionAsync({
      to: to as `0x${string}`,
      value: parseEther(amount),
    });
    return hash;
  };

  return (
    <TransferForm
      balance={balance}
      symbol="ETH"
      decimals={18}
      onSend={handleSend}
    />
  );
}
```

## Architecture: Adapter-Based DApp

When using adapters, the architecture simplifies:

```
src/
├── components/
│   ├── TransferForm.tsx       # Same as common skill
│   ├── SigningPanel.tsx        # Same as common skill
│   ├── TxStatus.tsx            # Same as common skill
│   └── Layout.tsx              # Use <ConnectButton /> instead of WalletStatus
├── hooks/
│   └── (none needed — Wagmi provides all hooks)
├── config/
│   └── wagmi.ts               # Wagmi config + chains + connectors
├── App.tsx                     # WagmiProvider + RainbowKitProvider + QueryClientProvider
└── main.tsx
```

**What adapters replace:**
- `useWalletConnection` → `useAccount` + `useConnect` + `useDisconnect`
- `useBalance` → `useBalance` (from wagmi)
- `useChainSwitch` → `useSwitchChain`
- `useTransfer` → `useSendTransaction`
- Provider detection → handled by adapter (EIP-6963, injected, WalletConnect)
- WalletStatus component → `<ConnectButton />` (RainbowKit)

**What adapters do NOT replace (still use common skill):**
- TransferForm UI (amount input, validation, MAX button)
- SigningPanel UI (message input, type selector)
- TxStatus display (signing → pending → confirmed)
- Toast notifications
- Confirmation dialog
- Gas fee preview
- Transaction history

## Connection Modal UX — Let Users Choose

A production DApp should present a **connection method selection modal** when the user clicks "Connect Wallet". Do NOT hardcode a single connection method.

### What a Good Connection Modal Shows

```
┌─────────────────────────────────────┐
│  Connect Wallet                     │
├─────────────────────────────────────┤
│                                     │
│  Recommended                        │
│  ┌─────────────────────────────┐    │
│  │ 🟢 Bitget Wallet  [Installed]│   │  ← EIP-6963 detected (browser extension)
│  │    MetaMask                  │   │  ← EIP-6963 detected
│  │    WalletConnect        📱  │   │  ← QR code for mobile wallets
│  └─────────────────────────────┘    │
│                                     │
│  Other                              │
│  ┌─────────────────────────────┐    │
│  │    Coinbase Wallet           │   │
│  │    Rainbow                   │   │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

**RainbowKit provides this out of the box** with `<ConnectButton />`. Web3Modal provides a similar modal with `<w3m-button />`.

### Connection Methods That Should Be Available

| Method | Connector | Config |
|--------|-----------|--------|
| Browser extension (installed wallets) | `injected()` | Auto — EIP-6963 discovers all installed wallets |
| WalletConnect QR (mobile wallets) | `walletConnect({ projectId })` | Needs Reown Project ID |
| Coinbase Wallet | `coinbaseWallet()` | Auto (if Wagmi configured) |
| Email / Social login | Reown AppKit `authConnector` | Optional — needs extra config |

### Wagmi Config for All Connection Methods

```typescript
import { http, createConfig } from 'wagmi';
import { mainnet, polygon, arbitrum } from 'wagmi/chains';
import { injected, walletConnect } from 'wagmi/connectors';

const projectId = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID;

const config = createConfig({
  chains: [mainnet, polygon, arbitrum],
  connectors: [
    injected(),                        // All browser extension wallets (EIP-6963)
    walletConnect({ projectId }),       // QR code for mobile wallets
  ],
  transports: {
    [mainnet.id]: http(),
    [polygon.id]: http(),
    [arbitrum.id]: http(),
  },
});
```

With RainbowKit, you can additionally control which wallets appear and in what order — see the "Customizing the Wallet List" section above.

### Non-EVM: Custom Connection Selector

For non-EVM chains (Solana, Bitcoin, TON, etc.) where no adapter modal exists, build a simple connection method selector:

```tsx
function ConnectSelector() {
  const providers = [];

  if (window.bitkeep?.solana) {
    providers.push({ name: 'Bitget Wallet', icon: '🟢', connect: () => window.bitkeep.solana.connect() });
  }
  if (window.phantom?.solana) {
    providers.push({ name: 'Phantom', icon: '👻', connect: () => window.phantom.solana.connect() });
  }

  if (providers.length === 0) {
    return <p>No Solana wallet detected. <a href="https://web3.bitget.com">Install Bitget Wallet</a></p>;
  }

  return (
    <div className="wallet-selector">
      <h3>Select Wallet</h3>
      {providers.map(p => (
        <button key={p.name} onClick={p.connect}>{p.icon} {p.name}</button>
      ))}
    </div>
  );
}
```

## Best Practices

1. **Always include `walletConnect` connector** — it's the universal fallback for mobile users
2. **Always include `injected()` connector** — it auto-detects all browser extension wallets via EIP-6963
3. **Get a Reown Project ID** — required for QR code connections; free at [dashboard.reown.com](https://dashboard.reown.com/)
4. **Customize the wallet list** — put your preferred wallet first in the RainbowKit `wallets` array
5. **Don't mix adapters and direct provider** — choose one approach per chain; mixing creates state conflicts
6. **Adapters are EVM-focused** — for Solana, Bitcoin, TON, etc., use direct provider from the wallet skill
7. **Next.js SSR** — set `ssr: true` in `getDefaultConfig` and add `'use client'` to components using hooks
