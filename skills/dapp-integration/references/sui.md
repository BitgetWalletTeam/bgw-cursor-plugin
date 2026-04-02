# Sui Reference

Integrate Bitget Wallet with Sui DApps. The provider implements the [Wallet Standard](https://docs.sui.io/standards/wallet-standard).

## Prerequisites

```bash
npm install @mysten/sui@1
```

If targeting legacy `@mysten/sui.js` projects, install that instead:

```bash
npm install @mysten/sui.js
```

Bitget Wallet extension: [https://web3.bitget.com/en/wallet-download](https://web3.bitget.com/en/wallet-download)

## Provider

```typescript
const provider = window.bitkeep.suiWallet;
```

Detection with installation prompt:

```typescript
function getSuiProvider() {
  if (window.bitkeep?.suiWallet) {
    return window.bitkeep.suiWallet;
  }
  window.open('https://web3.bitget.com/en/wallet-download', '_blank');
  throw new Error('Bitget Wallet not installed');
}
```

### Wallet Standard Discovery

```typescript
function discoverSuiWallet(): any {
  let wallet: any = null;
  const handler = {
    register: (w: any) => { wallet = w; }
  };
  const event = new CustomEvent('wallet-standard:app-ready', { detail: handler });
  window.dispatchEvent(event);
  return wallet;
}
```

## Connect

```typescript
interface SuiAccount {
  address: string;
  publicKey: Uint8Array;
}

async function connect(): Promise<SuiAccount> {
  const provider = window.bitkeep.suiWallet;
  await provider.requestPermissions();
  const accounts: SuiAccount[] = await provider.getAccounts();
  if (!accounts.length) throw new Error('No accounts returned');
  return accounts[0];
}
```

Legacy connect (also supported):

```typescript
async function connectLegacy(): Promise<SuiAccount> {
  const provider = window.bitkeep.suiWallet;
  const result = await provider.connect();
  return result.accounts[0];
}
```

## Sign Message

### signPersonalMessage (Recommended)

For `@mysten/sui` >= 1.0:

```typescript
interface SignPersonalMessageResult {
  message: string;
  signature: string;
  publicKey: string;
}

async function signPersonalMessage(message: string): Promise<SignPersonalMessageResult> {
  const provider = window.bitkeep.suiWallet;
  return await provider.signPersonalMessage({ message });
}
```

### signMessage (Legacy)

For `@mysten/sui.js` < 1.0:

```typescript
async function signMessage(message: string | Uint8Array): Promise<any> {
  const provider = window.bitkeep.suiWallet;
  return await provider.signMessage({ message });
}
```

### Verify Signature

```typescript
import { verifyPersonalMessageSignature } from '@mysten/sui/verify';

async function verifySuiSignature(
  message: string, signature: string
): Promise<string> {
  const publicKey = await verifyPersonalMessageSignature(
    new TextEncoder().encode(message),
    signature
  );
  return publicKey.toSuiAddress();
}
```

## Sign Transaction

### signTransaction (Recommended)

For `@mysten/sui` >= 1.0:

```typescript
import { Transaction } from '@mysten/sui/transactions';

interface SignTransactionResult {
  bytes: string;
  signature: string;
}

async function signTransaction(tx: Transaction): Promise<SignTransactionResult> {
  const provider = window.bitkeep.suiWallet;
  return await provider.signTransaction({ transaction: tx });
}
```

### signTransactionBlock (Legacy)

For `@mysten/sui.js`:

```typescript
import { TransactionBlock } from '@mysten/sui.js/transactions';

async function signTransactionBlock(txBlock: TransactionBlock): Promise<any> {
  const provider = window.bitkeep.suiWallet;
  return await provider.signTransactionBlock({ transactionBlock: txBlock });
}
```

## Send Transaction

### signAndExecuteTransaction (Recommended)

```typescript
import { Transaction } from '@mysten/sui/transactions';

interface ExecuteResult {
  digest: string;
  effects: any;
}

async function signAndExecuteTransaction(tx: Transaction): Promise<ExecuteResult> {
  const provider = window.bitkeep.suiWallet;
  return await provider.signAndExecuteTransaction({ transaction: tx });
}
```

### signAndExecuteTransactionBlock (Legacy)

```typescript
import { TransactionBlock } from '@mysten/sui.js/transactions';

async function signAndExecuteTransactionBlock(txBlock: TransactionBlock): Promise<any> {
  const provider = window.bitkeep.suiWallet;
  return await provider.signAndExecuteTransactionBlock({ transactionBlock: txBlock });
}
```

## Disconnect

```typescript
async function disconnect(): Promise<void> {
  const provider = window.bitkeep.suiWallet;
  await provider.disconnect();
}
```

## Error Handling

```typescript
interface WalletError {
  code: number;
  message: string;
}

function handleError(error: WalletError): { userMessage: string; recovery: string } {
  switch (error.code) {
    case 4001:
      return { userMessage: 'You rejected the request.', recovery: 'Please try again when ready.' };
    case 4100:
      return { userMessage: 'Not authorized.', recovery: 'Connect your wallet first, then retry.' };
    case 4200:
      return { userMessage: 'Method not supported.', recovery: 'Check the method name.' };
    case 4900:
      return { userMessage: 'Wallet disconnected.', recovery: 'Reconnect your wallet.' };
    case 4901:
      return { userMessage: 'Chain disconnected.', recovery: 'Switch to a connected chain.' };
    case -32000:
      return { userMessage: 'Invalid input.', recovery: 'Check parameter format.' };
    case -32602:
      return { userMessage: 'Invalid parameters.', recovery: 'Verify parameter types and values.' };
    case -32603:
      return { userMessage: 'Internal RPC error.', recovery: 'Check node status; retry with backoff.' };
    default:
      return { userMessage: `Error ${error.code}: ${error.message}`, recovery: 'Try again or contact support.' };
  }
}
```

## Integration Snippet

Drop-in Sui connectivity for any existing project:

```typescript
const SUI_PROVIDER = () => {
  if (!window.bitkeep?.suiWallet) throw new Error('Install Bitget Wallet');
  return window.bitkeep.suiWallet;
};

async function initSuiWallet() {
  const provider = SUI_PROVIDER();
  await provider.requestPermissions();
  const accounts = await provider.getAccounts();
  return { provider, address: accounts[0]?.address ?? null };
}

async function suiSignAndSend(tx: any) {
  const provider = SUI_PROVIDER();
  const result = await provider.signAndExecuteTransaction({ transaction: tx });
  return result.digest;
}

async function suiDisconnect() {
  await SUI_PROVIDER().disconnect();
}
```

## Complete Example

React/TypeScript hook-based DApp with loading states and pending→confirmed feedback.

### Project Setup

```bash
npm create vite@latest my-sui-dapp -- --template react-ts
cd my-sui-dapp
npm install @mysten/sui@1
```

### `src/hooks/useSuiWallet.ts`

```typescript
import { useState, useCallback } from 'react';
import { Transaction } from '@mysten/sui/transactions';

interface WalletError { code: number; message: string; }

function handleError(err: WalletError): { userMessage: string; recovery: string } {
  switch (err.code) {
    case 4001: return { userMessage: 'You rejected the request.', recovery: 'Please try again when ready.' };
    case 4100: return { userMessage: 'Not authorized.', recovery: 'Connect your wallet first, then retry.' };
    case 4200: return { userMessage: 'Method not supported.', recovery: 'Check the method name.' };
    case 4900: return { userMessage: 'Wallet disconnected.', recovery: 'Reconnect your wallet.' };
    case 4901: return { userMessage: 'Chain disconnected.', recovery: 'Switch to a connected chain.' };
    case -32000: return { userMessage: 'Invalid input.', recovery: 'Check parameter format.' };
    case -32602: return { userMessage: 'Invalid parameters.', recovery: 'Verify parameter types and values.' };
    case -32603: return { userMessage: 'Internal RPC error.', recovery: 'Check node status; retry with backoff.' };
    default: return { userMessage: `Error ${err.code}: ${err.message}`, recovery: 'Try again or contact support.' };
  }
}

type Status = 'idle' | 'connecting' | 'connected' | 'signing' | 'pending' | 'confirmed' | 'error';

interface WalletState {
  address: string | null;
  status: Status;
  error: { userMessage: string; recovery: string } | null;
  txDigest: string | null;
}

export function useSuiWallet() {
  const [state, setState] = useState<WalletState>({
    address: null, status: 'idle', error: null, txDigest: null,
  });

  const getProvider = useCallback(() => {
    if (!window.bitkeep?.suiWallet) {
      window.open('https://web3.bitget.com/en/wallet-download', '_blank');
      throw { code: 4900, message: 'Bitget Wallet not installed' } as WalletError;
    }
    return window.bitkeep.suiWallet;
  }, []);

  const connect = useCallback(async () => {
    setState(s => ({ ...s, status: 'connecting', error: null }));
    try {
      const provider = getProvider();
      await provider.requestPermissions();
      const accounts = await provider.getAccounts();
      const address = accounts[0]?.address ?? null;
      setState({ address, status: 'connected', error: null, txDigest: null });
    } catch (err: any) {
      const parsed = handleError(err);
      setState(s => ({ ...s, status: 'error', error: parsed }));
    }
  }, [getProvider]);

  const signMessage = useCallback(async (message: string) => {
    setState(s => ({ ...s, status: 'signing', error: null }));
    try {
      const provider = getProvider();
      const result = await provider.signPersonalMessage({ message });
      setState(s => ({ ...s, status: 'connected' }));
      return result;
    } catch (err: any) {
      const parsed = handleError(err);
      setState(s => ({ ...s, status: 'error', error: parsed }));
      return null;
    }
  }, [getProvider]);

  const sendTransaction = useCallback(async (tx: Transaction) => {
    setState(s => ({ ...s, status: 'pending', error: null, txDigest: null }));
    try {
      const provider = getProvider();
      const result = await provider.signAndExecuteTransaction({ transaction: tx });
      setState(s => ({ ...s, status: 'confirmed', txDigest: result.digest }));
      return result;
    } catch (err: any) {
      const parsed = handleError(err);
      setState(s => ({ ...s, status: 'error', error: parsed }));
      return null;
    }
  }, [getProvider]);

  const disconnect = useCallback(async () => {
    try {
      const provider = getProvider();
      await provider.disconnect();
    } catch { /* already disconnected */ }
    setState({ address: null, status: 'idle', error: null, txDigest: null });
  }, [getProvider]);

  return { ...state, connect, signMessage, sendTransaction, disconnect };
}
```

### `src/App.tsx`

```tsx
import { useSuiWallet } from './hooks/useSuiWallet';

function App() {
  const wallet = useSuiWallet();

  const handleSign = async () => {
    const result = await wallet.signMessage('Hello from Bitget Wallet!');
    if (result) console.log('Signature:', result.signature);
  };

  return (
    <div style={{ maxWidth: 520, margin: '40px auto', fontFamily: 'sans-serif' }}>
      <h1>Sui DApp</h1>

      {wallet.status === 'idle' && (
        <button onClick={wallet.connect}>Connect Bitget Wallet</button>
      )}

      {wallet.status === 'connecting' && <p>Connecting…</p>}

      {wallet.status === 'connected' && (
        <div>
          <p>Connected: <code>{wallet.address}</code></p>
          <button onClick={handleSign}>Sign Message</button>
          <button onClick={wallet.disconnect} style={{ marginLeft: 8 }}>Disconnect</button>
        </div>
      )}

      {wallet.status === 'signing' && <p>Waiting for signature…</p>}
      {wallet.status === 'pending' && <p>Transaction pending…</p>}

      {wallet.status === 'confirmed' && (
        <div>
          <p>Confirmed! Digest: <code>{wallet.txDigest}</code></p>
          <button onClick={wallet.disconnect}>Disconnect</button>
        </div>
      )}

      {wallet.status === 'error' && wallet.error && (
        <div style={{ color: '#c00' }}>
          <p>{wallet.error.userMessage}</p>
          <p><em>{wallet.error.recovery}</em></p>
          <button onClick={wallet.address ? wallet.disconnect : wallet.connect}>
            {wallet.address ? 'Disconnect' : 'Try Again'}
          </button>
        </div>
      )}
    </div>
  );
}

export default App;
```
