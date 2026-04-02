# Adapters Reference

Integrate Bitget Wallet via popular wallet adapter libraries. Use adapters when you want automatic wallet discovery, UI components, and multi-wallet support.

**When to use adapters vs direct JS Bridge:**

| Scenario | Recommended |
|---|---|
| React project, EVM only | Wagmi + RainbowKit |
| React project, multi-wallet UI | RainbowKit |
| Any framework, WalletConnect support | WalletConnect |
| TON DApp | TonConnect |
| Framework-agnostic, many wallets | Web3-Onboard |
| Direct control, custom UI | JS Bridge (`window.bitkeep.*`) |

---

## How to Put Bitget Wallet in the Recommended / Default Wallet List

This section covers how to make Bitget Wallet appear prominently in the wallet selection UI across all major adapter libraries. There are 3 discovery mechanisms:

### Discovery Mechanism Summary

| Mechanism | How It Works | DApp Config Needed? |
|-----------|-------------|---------------------|
| **EIP-6963** (auto-discovery) | Browser extension wallets announce themselves; adapter auto-detects | No — works out of the box |
| **RainbowKit `wallets` array** | Explicit wallet list in config | Yes — add `bitgetWallet` |
| **WalletConnect `featuredWalletIds`** | Control which wallets appear in WalletConnect/Web3Modal QR modal | Yes — add Bitget Wallet IDs |

### Bitget Wallet Identifiers (Cheat Sheet)

```
EIP-6963 RDNS:              com.bitget.web3
RainbowKit import:          bitgetWallet (from @rainbow-me/rainbowkit/wallets)
Web3-Onboard module:        @web3-onboard/bitget

WalletConnect Explorer IDs (for featuredWalletIds / includeWalletIds):
  Bitget Wallet:            38f5d18bd8522c244bdd70cb4a68e0e718865155811c043f052fb9f1c51de662
  Bitget Wallet Lite:       21c3a371f72f0057186082edb2ddd43566f7e908508ac3e85373c6d1966ed614
```

> **Where to find wallet IDs:** Browse [explorer.walletconnect.com](https://explorer.walletconnect.com/?type=wallet) and search "Bitget Wallet".

### Method 1: EIP-6963 Auto-Discovery (Zero Config)

If the user has Bitget Wallet browser extension installed, it automatically appears in:
- Wagmi's `injected()` connector
- RainbowKit's wallet list
- Web3Modal / AppKit's wallet list
- Web3-Onboard's wallet list

No DApp code changes needed. Bitget Wallet announces itself with `rdns: "com.bitget.web3"`.

```typescript
// Wagmi — injected() auto-detects all EIP-6963 wallets including Bitget Wallet
import { injected } from 'wagmi/connectors';

const config = createConfig({
  connectors: [
    injected(),  // Bitget Wallet auto-discovered here
  ],
  // ...
});
```

### Method 2: RainbowKit — Add to Recommended Wallets

```typescript
import {
  bitgetWallet,       // Bitget Wallet official connector
  metaMaskWallet,
  walletConnectWallet,
  rainbowWallet,
} from '@rainbow-me/rainbowkit/wallets';
import { getDefaultConfig } from '@rainbow-me/rainbowkit';

const config = getDefaultConfig({
  appName: 'My DApp',
  projectId: import.meta.env.VITE_WALLETCONNECT_PROJECT_ID, // Get from dashboard.reown.com
  chains: [mainnet, polygon, arbitrum, base],
  wallets: [
    {
      groupName: 'Recommended',
      wallets: [
        bitgetWallet,         // Put first = most prominent position
        metaMaskWallet,
        walletConnectWallet,  // Always include as mobile fallback
      ],
    },
    {
      groupName: 'Other',
      wallets: [rainbowWallet],
    },
  ],
});
```

**Key points:**
- First wallet in the first group gets the most prominent position
- Installed wallets are auto-promoted to the top via EIP-6963
- `bitgetWallet` is a built-in RainbowKit connector — no extra package needed
- Always include `walletConnectWallet` as a mobile fallback

### Method 3: WalletConnect Web3Modal / AppKit — Featured Wallets

Use `featuredWalletIds` to show Bitget Wallet at the top of the WalletConnect QR modal:

```typescript
import { createWeb3Modal } from '@web3modal/wagmi/react';

createWeb3Modal({
  wagmiConfig,
  projectId: import.meta.env.VITE_WALLETCONNECT_PROJECT_ID, // Get from dashboard.reown.com

  // Show Bitget Wallet prominently in the modal
  featuredWalletIds: [
    '38f5d18bd8522c244bdd70cb4a68e0e718865155811c043f052fb9f1c51de662', // Bitget Wallet
    '21c3a371f72f0057186082edb2ddd43566f7e908508ac3e85373c6d1966ed614', // Bitget Wallet Lite
  ],
});
```

**Advanced: Only show specific wallets (exclusive mode)**

```typescript
createWeb3Modal({
  wagmiConfig,
  projectId,

  // Only show these wallets — hide everything else
  includeWalletIds: [
    '38f5d18bd8522c244bdd70cb4a68e0e718865155811c043f052fb9f1c51de662', // Bitget Wallet
    'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96', // MetaMask
  ],

  // Or exclude specific wallets
  // excludeWalletIds: ['some-wallet-id'],
});
```

> **Known issue:** `featuredWalletIds` has a bug starting from Web3Modal v4.2.2 ([GitHub issue #2383](https://github.com/WalletConnect/web3modal/issues/2383)). If featured wallets don't appear, try `includeWalletIds` instead.

### Method 4: WalletConnect EthereumProvider — QR Modal Recommended

For direct WalletConnect usage without Web3Modal:

```typescript
import { EthereumProvider } from '@walletconnect/ethereum-provider';

const provider = await EthereumProvider.init({
  projectId: import.meta.env.VITE_WALLETCONNECT_PROJECT_ID, // Get from dashboard.reown.com
  chains: [1],
  optionalChains: [56, 137, 42161, 8453],
  showQrModal: true,
  qrModalOptions: {
    explorerRecommendedWalletIds: [
      '38f5d18bd8522c244bdd70cb4a68e0e718865155811c043f052fb9f1c51de662', // Bitget Wallet
    ],
  },
});
```

### Method 5: Web3-Onboard — Explicit Module

```typescript
import Onboard from '@web3-onboard/core';
import bitgetWalletModule from '@web3-onboard/bitget';

const bitgetWallet = bitgetWalletModule();

const onboard = Onboard({
  wallets: [bitgetWallet],  // Bitget Wallet appears first
  // ...
});
```

### Prerequisites: Reown (WalletConnect) Project ID

Methods 2-5 require a **Reown Project ID** (formerly WalletConnect Project ID) for WalletConnect QR/mobile. Method 1 (EIP-6963) does NOT require one.

**How to get one:**
1. Go to [dashboard.reown.com](https://dashboard.reown.com/)
2. Sign up → click **"+ Project"** → select **"AppKit"** → **"Create"**
3. Copy the Project ID → store in `.env` as `VITE_WALLETCONNECT_PROJECT_ID`

> **Agent rule:** When implementing adapter integration, ask the developer for their Project ID before writing config. If they don't have one, walk them through the steps above. Never leave a placeholder string.

### Quick Integration Checklist

When a DApp developer asks "how to add Bitget Wallet":

1. **Already using RainbowKit?** → Add `bitgetWallet` to the `wallets` array (Method 2)
2. **Already using Web3Modal/AppKit?** → Add wallet ID to `featuredWalletIds` (Method 3)
3. **Using WalletConnect directly?** → Add ID to `explorerRecommendedWalletIds` (Method 4)
4. **Using Web3-Onboard?** → `npm install @web3-onboard/bitget` (Method 5)
5. **None of the above?** → Bitget Wallet extension is auto-discovered via EIP-6963 (Method 1)

## Wagmi

Bitget Wallet works with Wagmi's `injected()` connector out of the box, and is auto-detected via EIP-6963 (`rdns: com.bitget.web3`).

### Installation

```bash
npm install wagmi viem@2.x @tanstack/react-query
```

### Configuration

```typescript
import { http, createConfig } from 'wagmi';
import { mainnet, bsc, polygon, arbitrum, base } from 'wagmi/chains';

const config = createConfig({
  chains: [mainnet, bsc, polygon, arbitrum, base],
  transports: {
    [mainnet.id]: http(),
    [bsc.id]: http(),
    [polygon.id]: http(),
    [arbitrum.id]: http(),
    [base.id]: http(),
  },
});
```

### Connect (React Hooks)

```typescript
import { useConnect, useDisconnect, useAccount } from 'wagmi';
import { injected } from 'wagmi/connectors';

function WalletConnect() {
  const { connect, isPending } = useConnect();
  const { disconnect } = useDisconnect();
  const { isConnected, address } = useAccount();

  const handleClick = () => {
    if (isConnected) {
      disconnect();
    } else {
      connect({ connector: injected() });
    }
  };

  return (
    <div>
      <p>{isConnected ? `Connected: ${address}` : 'Not connected'}</p>
      <button onClick={handleClick} disabled={isPending}>
        {isConnected ? 'Disconnect' : 'Connect Wallet'}
      </button>
    </div>
  );
}
```

### Connect (Vanilla JS / Actions)

```typescript
import { connect, disconnect, getAccount } from 'wagmi/actions';
import { injected } from 'wagmi/connectors';

async function connectWallet(config: any): Promise<string> {
  try {
    const result = await connect(config, { connector: injected() });
    return result.accounts[0];
  } catch (error: any) {
    if (error.message?.includes('rejected')) {
      console.log('User rejected connection.');
    }
    throw error;
  }
}
```

### Sign Message

```typescript
import { useSignMessage, useAccount } from 'wagmi';

function SignDemo() {
  const { signMessage, data: signature, error, isPending } = useSignMessage();
  const { isConnected } = useAccount();

  if (!isConnected) return <p>Please connect first.</p>;

  return (
    <div>
      <button
        onClick={() => signMessage({ message: 'Hello Bitget Wallet!' })}
        disabled={isPending}
      >
        Sign Message
      </button>
      {signature && <p>Signature: {signature}</p>}
      {error && <p style={{ color: 'red' }}>{error.message}</p>}
    </div>
  );
}
```

### Sign Typed Data (EIP-712)

```typescript
import { useSignTypedData } from 'wagmi';

function SignTypedDemo() {
  const { signTypedData, data, error, isPending } = useSignTypedData();

  const domain = {
    name: 'MyDApp',
    version: '1',
    chainId: 1,
    verifyingContract: '0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC' as const,
  };

  const types = {
    Mail: [
      { name: 'from', type: 'string' },
      { name: 'to', type: 'string' },
      { name: 'contents', type: 'string' },
    ],
  } as const;

  const message = {
    from: 'Alice',
    to: 'Bob',
    contents: 'Hello!',
  };

  return (
    <button
      onClick={() => signTypedData({ domain, types, primaryType: 'Mail', message })}
      disabled={isPending}
    >
      Sign Typed Data
    </button>
  );
}
```

### Send Transaction

```typescript
import { useSendTransaction } from 'wagmi';
import { parseEther } from 'viem';

function SendTxDemo() {
  const { sendTransaction, data, error, isPending } = useSendTransaction();

  return (
    <button
      onClick={() =>
        sendTransaction({
          to: '0xRecipientAddress...',
          value: parseEther('0.01'),
        })
      }
      disabled={isPending}
    >
      Send 0.01 ETH
    </button>
  );
}
```

### Full App Setup

```typescript
import { WagmiProvider } from 'wagmi';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient();

export default function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        {/* Your components here */}
        <WalletConnect />
      </QueryClientProvider>
    </WagmiProvider>
  );
}
```

### API Reference

- [Wagmi Documentation](https://wagmi.sh/)

---

## RainbowKit

RainbowKit provides a beautiful wallet connection UI with built-in Bitget Wallet support.

### Installation

```bash
npm install @rainbow-me/rainbowkit wagmi viem@2.x @tanstack/react-query
```

### Configuration

```typescript
import '@rainbow-me/rainbowkit/styles.css';
import { getDefaultConfig, RainbowKitProvider, ConnectButton } from '@rainbow-me/rainbowkit';
import { WagmiProvider } from 'wagmi';
import { mainnet, polygon, optimism, arbitrum, base } from 'wagmi/chains';
import { QueryClientProvider, QueryClient } from '@tanstack/react-query';
import {
  bitgetWallet,
  rainbowWallet,
  walletConnectWallet,
} from '@rainbow-me/rainbowkit/wallets';

const projectId = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID; // Get from dashboard.reown.com

const config = getDefaultConfig({
  appName: 'My DApp',
  projectId,
  chains: [mainnet, polygon, optimism, arbitrum, base],
  wallets: [{
    groupName: 'Recommended',
    wallets: [bitgetWallet, rainbowWallet, walletConnectWallet],
  }],
  ssr: false, // set true for Next.js
});

const queryClient = new QueryClient();
```

> **Next.js SSR note:** When using Next.js, set `ssr: true` above and add `'use client'` at the top of components that use RainbowKit/Wagmi hooks.

> **Note:** Bitget Wallet is also auto-discovered via EIP-6963 (rdns: `com.bitget.web3`), so it appears in the wallet list even without explicit `bitgetWallet` configuration.

### Usage

```typescript
export default function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          <ConnectButton />
          {/* Your DApp content */}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
```

### Prioritizing Bitget Wallet

To show Bitget Wallet first in the wallet list when it's not installed:

```typescript
let wallets = [rainbowWallet, walletConnectWallet];
if (!window.bitkeep) {
  wallets.unshift(bitgetWallet);
}
```

### API Reference

- [RainbowKit Documentation](https://www.rainbowkit.com)
- [Demo](https://github.com/bitgetwallet/dapp-integration-demos/blob/main/wallet-adapter-demo/src/rainbow.js)

---

## WalletConnect

Use WalletConnect for QR-code based wallet connection, supporting Bitget Wallet mobile app.

### Installation

```bash
npm install @walletconnect/ethereum-provider
```

### Configuration

```typescript
import { EthereumProvider } from '@walletconnect/ethereum-provider';

async function createWalletConnectProvider(): Promise<any> {
  const wcProvider = await EthereumProvider.init({
    projectId: import.meta.env.VITE_WALLETCONNECT_PROJECT_ID, // Get from dashboard.reown.com
    chains: [1],
    optionalChains: [56, 137, 42161, 10, 8453],
    showQrModal: true,
    qrModalOptions: {
      explorerRecommendedWalletIds: [
        '38f5d18bd8522c244bdd70cb4a68e0e718865155811c043f052fb9f1c51de662', // Bitget Wallet
      ],
    },
  });

  return wcProvider;
}
```

### Connect

```typescript
async function connectViaWalletConnect(): Promise<string[]> {
  const provider = await createWalletConnectProvider();

  try {
    const accounts: string[] = await provider.enable();
    console.log('Connected via WalletConnect:', accounts);
    return accounts;
  } catch (error: any) {
    console.error('WalletConnect error:', error);
    throw error;
  }
}
```

### API Reference

- [WalletConnect Documentation](https://docs.walletconnect.com/)

---

## TonConnect

For TON DApps, use TonConnect v2 to integrate with Bitget Wallet.

### Installation

```bash
npm install @tonconnect/ui-react
# or for vanilla JS:
npm install @tonconnect/ui
```

### Configuration

Create a `tonconnect-manifest.json` at your app's root:

```json
{
  "url": "https://your-dapp.com",
  "name": "My TON DApp",
  "iconUrl": "https://your-dapp.com/icon.png"
}
```

### React Integration

```typescript
import { TonConnectUIProvider, TonConnectButton, useTonConnectUI } from '@tonconnect/ui-react';

function App() {
  return (
    <TonConnectUIProvider manifestUrl="https://your-dapp.com/tonconnect-manifest.json">
      <TonConnectButton />
      <SendTx />
    </TonConnectUIProvider>
  );
}

function SendTx() {
  const [tonConnectUI] = useTonConnectUI();

  async function sendTransaction(): Promise<void> {
    try {
      await tonConnectUI.sendTransaction({
        validUntil: Math.floor(Date.now() / 1000) + 600,
        messages: [
          {
            address: 'UQDxxxxxxxxxxxxxxxxx',
            amount: '10000000', // 0.01 TON in nanotons
          },
        ],
      });
    } catch (error: any) {
      console.error('Transaction failed:', error);
    }
  }

  return <button onClick={sendTransaction}>Send 0.01 TON</button>;
}
```

### Vanilla JS Integration

```typescript
import TonConnectUI from '@tonconnect/ui';

const tonConnectUI = new TonConnectUI({
  manifestUrl: 'https://your-dapp.com/tonconnect-manifest.json',
});

async function connect(): Promise<void> {
  const connectedWallet = await tonConnectUI.connectWallet();
  console.log('Connected:', connectedWallet);
}
```

### Bitget Wallet TonConnect Provider

Bitget Wallet supports TonConnect v2 via `window.bitgetTonWallet.tonconnect`. When Bitget Wallet is installed, TonConnect auto-discovers it.

### API Reference

- [TonConnect Documentation](https://docs.ton.org/develop/dapps/ton-connect/overview)

---

## Web3-Onboard

Framework-agnostic wallet connection library.

### Installation

```bash
npm install @web3-onboard/core @web3-onboard/bitget
```

### Configuration

```typescript
import Onboard from '@web3-onboard/core';
import bitgetWalletModule from '@web3-onboard/bitget';

const bitgetWallet = bitgetWalletModule();

const onboard = Onboard({
  wallets: [bitgetWallet],
  chains: [
    {
      id: '0x1',
      token: 'ETH',
      label: 'Ethereum Mainnet',
      rpcUrl: 'https://eth.llamarpc.com',
    },
    {
      id: '0x38',
      token: 'BNB',
      label: 'BSC',
      rpcUrl: 'https://bsc-dataseed.binance.org/',
    },
  ],
  appMetadata: {
    name: 'My DApp',
    description: 'My DApp Description',
  },
});
```

### Connect

```typescript
async function connectOnboard(): Promise<string> {
  const wallets = await onboard.connectWallet();

  if (wallets[0]) {
    const address = wallets[0].accounts[0].address;
    console.log('Connected:', address);
    return address;
  }

  throw new Error('No wallet connected');
}
```

### Send Transaction

```typescript
import { ethers } from 'ethers';

async function sendViaOnboard(): Promise<void> {
  const wallets = await onboard.connectWallet();
  const ethersProvider = new ethers.BrowserProvider(wallets[0].provider);
  const signer = await ethersProvider.getSigner();

  const tx = await signer.sendTransaction({
    to: '0xRecipientAddress...',
    value: ethers.parseEther('0.01'),
  });

  console.log('TX hash:', tx.hash);
}
```

### API Reference

- [Web3-Onboard Documentation](https://onboard.blocknative.com/)

---

## Error Handling (All Adapters)

All adapters surface the same underlying wallet errors:

```typescript
function handleAdapterError(error: any): void {
  const code = error?.code ?? error?.cause?.code;

  switch (code) {
    case 4001:
      console.log('User rejected the request.');
      break;
    case 4100:
      console.log('Unauthorized. Connect wallet first.');
      break;
    case -32603:
      console.log('Internal error. Check RPC connection.');
      break;
    default:
      console.error('Unexpected error:', error?.message ?? error);
  }
}
```
