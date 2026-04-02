# Telegram Mini App Reference

Integrate Bitget Wallet with Telegram Mini Apps via TonConnect.

## Overview

Telegram Mini Apps run inside the Telegram App, so they cannot use JS Bridge (`window.bitkeep.*`) directly. Instead, use HTTP Bridge solutions:

| Chain | Solution | Package |
|---|---|---|
| TON | TonConnect | `@tonconnect/ui-react` or `@tonconnect/ui` |

## Scenario 1: TON via TonConnect

### Installation

```bash
npm install @tonconnect/ui-react
# or for vanilla JS:
npm install @tonconnect/ui
```

### Manifest

Create `tonconnect-manifest.json` at your app's public root:

```json
{
  "url": "https://your-miniapp.com",
  "name": "My TON Mini App",
  "iconUrl": "https://your-miniapp.com/icon.png"
}
```

### React Integration

```typescript
import { TonConnectUIProvider, TonConnectButton, useTonConnectUI } from '@tonconnect/ui-react';

function App() {
  return (
    <TonConnectUIProvider manifestUrl="https://your-miniapp.com/tonconnect-manifest.json">
      <TonConnectButton />
      <MainContent />
    </TonConnectUIProvider>
  );
}

function MainContent() {
  const [tonConnectUI] = useTonConnectUI();

  async function sendTransaction(): Promise<void> {
    try {
      await tonConnectUI.sendTransaction({
        validUntil: Math.floor(Date.now() / 1000) + 600,
        messages: [
          {
            address: 'UQDxxxxxxxxxxxxxxxxx',
            amount: '10000000',
          },
        ],
      });
    } catch (error: any) {
      console.error('Transaction failed:', error);
    }
  }

  return <button onClick={sendTransaction}>Send TON</button>;
}
```

### Open Bitget Wallet Directly

To specifically connect to Bitget Wallet (skip wallet selection modal):

```typescript
await tonConnectUI.openSingleWalletModal('bitgetTonWallet');
```

### Vanilla JS Integration

```typescript
import TonConnectUI from '@tonconnect/ui';

const tonConnectUI = new TonConnectUI({
  manifestUrl: 'https://your-miniapp.com/tonconnect-manifest.json',
});

// Connect
const wallet = await tonConnectUI.connectWallet();

// Or connect to Bitget Wallet specifically
await tonConnectUI.openSingleWalletModal('bitgetTonWallet');
```

## Scenario 2: Bitget Wallet Event Page Integration

For webapps displayed on the Bitget Wallet event page that redirect to a TG Mini App:

1. Provide your Mini App link to Bitget Wallet team: `https://t.me/your_bot_name/your_app?startapp=xxx`
2. Bitget Wallet adds `utm_source=BitgetWallet` parameter
3. In your Mini App, detect this parameter and auto-connect to Bitget Wallet:

```typescript
const urlParams = new URLSearchParams(window.location.search);
const isBitgetSource = urlParams.get('utm_source') === 'BitgetWallet';

if (isBitgetSource) {
  await tonConnectUI.openSingleWalletModal('bitgetTonWallet');
}
```

## Resources

- [TonConnect Documentation](https://docs.ton.org/develop/dapps/ton-connect/overview)
- [Bitget Wallet Developer Docs](https://web3.bitget.com/en/docs/)
