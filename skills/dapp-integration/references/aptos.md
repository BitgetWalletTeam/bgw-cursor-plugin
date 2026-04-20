# Aptos Reference

Integrate Bitget Wallet with Aptos DApps. The provider is Petra-compatible — code written for Petra works with Bitget Wallet.

## Prerequisites

```bash
npm install aptos@1.21.0 tweetnacl@1
```

```bash
# For the Complete Example
npm create vite@latest my-aptos-dapp -- --template react-ts
cd my-aptos-dapp
npm install aptos@1.21.0
```

No SDK is required for basic provider interaction (connect, sign, events).

## Provider

```typescript
const provider = window.bitkeep.aptos;

// Petra-compatible aliases:
// window.bitkeep.petra
// window.petra
// window.aptos
```

Detect and redirect if not installed:

```typescript
function getAptosProvider() {
  if (window.bitkeep?.aptos) return window.bitkeep.aptos;
  window.open('https://web3.bitget.com/en/wallet-download', '_blank');
  throw new Error('Bitget Wallet not installed');
}
```

## Connect

```typescript
interface AptosConnectResult {
  publicKey: string;
  address: string;
}

async function connectAptos(): Promise<AptosConnectResult> {
  const provider = getAptosProvider();
  try {
    const result: AptosConnectResult = await provider.connect();
    return result;
  } catch (error: any) {
    throw error;
  }
}
```

Disconnect:

```typescript
async function disconnectAptos(): Promise<void> {
  await provider.disconnect();
}
```

## Get Account

```typescript
interface AptosAccount {
  publicKey: string;
  address: string;
}

async function getAccount(): Promise<AptosAccount> {
  return await provider.account();
}

async function checkConnection(): Promise<boolean> {
  return await provider.isConnected();
}

async function getNetwork(): Promise<string> {
  return await provider.network();
}
```

## Sign Message

```typescript
interface SignMessagePayload {
  address?: boolean;
  application?: boolean;
  chainId?: boolean;
  message: string;
  nonce: string;
}

interface SignMessageResult {
  address: string;
  application: string;
  chainId: number;
  fullMessage: string;
  message: string;
  nonce: number;
  prefix: string;
  publicKey: string;
  signature: string;
}

async function signMessage(
  message: string,
  nonce: string
): Promise<SignMessageResult> {
  const provider = getAptosProvider();
  const result: SignMessageResult = await provider.signMessage({
    message,
    nonce,
    address: true,
    application: true,
    chainId: true,
  });
  return result;
}
```

### Verify Signature

Aptos uses ed25519 — the `signMessage` response contains all data needed for verification:

```typescript
import nacl from 'tweetnacl';

function verifyAptosSignature(result: SignMessageResult): boolean {
  const messageBytes = new TextEncoder().encode(result.fullMessage);
  const signatureBytes = Uint8Array.from(
    Buffer.from(result.signature.slice(2), 'hex')
  );
  const publicKeyBytes = Uint8Array.from(
    Buffer.from(result.publicKey.slice(2), 'hex')
  );
  return nacl.sign.detached.verify(messageBytes, signatureBytes, publicKeyBytes);
}
```

## Sign Transaction

Sign a transaction without submitting it to the network.

```typescript
interface AptosTransactionPayload {
  type: 'entry_function_payload';
  function: string;
  type_arguments: string[];
  arguments: (string | number)[];
}

async function signTransaction(
  payload: AptosTransactionPayload,
  options?: Record<string, any>
): Promise<Uint8Array> {
  const provider = getAptosProvider();
  return await provider.signTransaction(payload, options);
}
```

## Send Transaction

Sign and submit a transaction to the Aptos blockchain.

```typescript
async function signAndSubmitTransaction(
  payload: AptosTransactionPayload
): Promise<{ hash: string }> {
  const provider = getAptosProvider();
  return await provider.signAndSubmitTransaction(payload);
}
```

Transfer APT example (1 APT = 10^8 Octas):

```typescript
const tx = await signAndSubmitTransaction({
  type: 'entry_function_payload',
  function: '0x1::coin::transfer',
  type_arguments: ['0x1::aptos_coin::AptosCoin'],
  arguments: ['0xRecipientAddress...', '100000000'],
});
```

Wait for confirmation using the Aptos SDK:

```typescript
import { AptosClient } from 'aptos';

const client = new AptosClient('https://fullnode.mainnet.aptoslabs.com');

async function sendAndWait(payload: AptosTransactionPayload): Promise<string> {
  const pendingTx = await window.bitkeep.aptos.signAndSubmitTransaction(payload);
  await client.waitForTransaction(pendingTx.hash);
  return pendingTx.hash;
}
```

## Events

```typescript
const provider = window.bitkeep.aptos;

provider.onAccountChange((newAccount: { publicKey: string; address: string }) => {
  console.log('Account changed:', newAccount.address);
});

provider.onNetworkChange((newNetwork: { networkName: string }) => {
  console.log('Network changed:', newNetwork.networkName);
});

provider.onDisconnect(() => {
  console.log('Wallet disconnected');
});
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

Usage with any provider call:

```typescript
try {
  await provider.connect();
} catch (err: any) {
  const { userMessage, recovery } = handleError(err);
  alert(`${userMessage}\n${recovery}`);
}
```

## Integration Snippet

Drop-in Aptos connectivity for any existing project (~20 lines):

```typescript
const DOWNLOAD_URL = 'https://web3.bitget.com/en/wallet-download';

async function aptosConnect(): Promise<{ address: string; publicKey: string }> {
  const p = window.bitkeep?.aptos;
  if (!p) { window.open(DOWNLOAD_URL, '_blank'); throw new Error('Wallet not found'); }
  return p.connect();
}

async function aptosSend(fn: string, typeArgs: string[], args: any[]): Promise<string> {
  const p = window.bitkeep!.aptos;
  const tx = await p.signAndSubmitTransaction({
    type: 'entry_function_payload' as const,
    function: fn,
    type_arguments: typeArgs,
    arguments: args,
  });
  return tx.hash;
}

async function aptosSign(message: string): Promise<string> {
  const p = window.bitkeep!.aptos;
  const r = await p.signMessage({ message, nonce: Date.now().toString() });
  return r.signature;
}
```

## Complete Example

React/TypeScript Hook pattern. Scaffold with:

```bash
npm create vite@latest my-aptos-dapp -- --template react-ts
cd my-aptos-dapp
npm install aptos@1.21.0
npm run dev
```

### `src/hooks/useAptosWallet.ts`

```typescript
import { useCallback, useEffect, useRef, useState } from 'react';
import { AptosClient } from 'aptos';

interface WalletState {
  address: string | null;
  publicKey: string | null;
  network: string | null;
  connected: boolean;
  loading: boolean;
  error: string | null;
}

interface TxStatus {
  hash: string | null;
  status: 'idle' | 'pending' | 'confirmed' | 'failed';
}

const INITIAL_STATE: WalletState = {
  address: null, publicKey: null, network: null,
  connected: false, loading: false, error: null,
};

const CLIENT = new AptosClient('https://fullnode.mainnet.aptoslabs.com');

function getProvider() {
  return window.bitkeep?.aptos ?? null;
}

export function useAptosWallet() {
  const [wallet, setWallet] = useState<WalletState>(INITIAL_STATE);
  const [tx, setTx] = useState<TxStatus>({ hash: null, status: 'idle' });
  const providerRef = useRef(getProvider());

  const reset = useCallback(() => {
    setWallet(INITIAL_STATE);
    setTx({ hash: null, status: 'idle' });
  }, []);

  const connect = useCallback(async () => {
    const p = providerRef.current;
    if (!p) {
      window.open('https://web3.bitget.com/en/wallet-download', '_blank');
      return;
    }
    setWallet(s => ({ ...s, loading: true, error: null }));
    try {
      const { address, publicKey } = await p.connect();
      const network = await p.network();
      setWallet({ address, publicKey, network, connected: true, loading: false, error: null });
    } catch (err: any) {
      setWallet(s => ({ ...s, loading: false, error: err.message ?? 'Connection failed' }));
    }
  }, []);

  const disconnect = useCallback(async () => {
    await providerRef.current?.disconnect();
    reset();
  }, [reset]);

  const signMessage = useCallback(async (message: string, nonce?: string) => {
    const p = providerRef.current;
    if (!p) throw new Error('Not connected');
    return p.signMessage({ message, nonce: nonce ?? Date.now().toString() });
  }, []);

  const sendTransaction = useCallback(async (
    fn: string, typeArgs: string[], args: (string | number)[]
  ) => {
    const p = providerRef.current;
    if (!p) throw new Error('Not connected');
    setTx({ hash: null, status: 'pending' });
    try {
      const pending = await p.signAndSubmitTransaction({
        type: 'entry_function_payload' as const,
        function: fn, type_arguments: typeArgs, arguments: args,
      });
      setTx({ hash: pending.hash, status: 'pending' });
      await CLIENT.waitForTransaction(pending.hash);
      setTx({ hash: pending.hash, status: 'confirmed' });
      return pending.hash;
    } catch (err: any) {
      setTx(s => ({ ...s, status: 'failed' }));
      throw err;
    }
  }, []);

  useEffect(() => {
    const p = providerRef.current;
    if (!p) return;
    p.onAccountChange((acct: any) => {
      if (!acct?.address) { reset(); return; }
      setWallet(s => ({ ...s, address: acct.address, publicKey: acct.publicKey }));
    });
    p.onNetworkChange((net: any) => {
      setWallet(s => ({ ...s, network: net.networkName }));
    });
    p.onDisconnect(() => reset());
  }, [reset]);

  return { ...wallet, tx, connect, disconnect, signMessage, sendTransaction };
}
```

### `src/App.tsx`

```tsx
import { useAptosWallet } from './hooks/useAptosWallet';

export default function App() {
  const {
    address, network, connected, loading, error, tx,
    connect, disconnect, signMessage, sendTransaction,
  } = useAptosWallet();

  const handleSign = async () => {
    try {
      const result = await signMessage('Hello Aptos!');
      alert(`Signature: ${result.signature}`);
    } catch { /* handled by hook */ }
  };

  const handleSend = async () => {
    try {
      await sendTransaction(
        '0x1::coin::transfer',
        ['0x1::aptos_coin::AptosCoin'],
        [address!, '0'],
      );
    } catch { /* handled by hook */ }
  };

  if (!connected) {
    return (
      <div style={{ maxWidth: 480, margin: '80px auto', textAlign: 'center' }}>
        <h1>Aptos DApp</h1>
        <button onClick={connect} disabled={loading}>
          {loading ? 'Connecting…' : 'Connect Bitget Wallet'}
        </button>
        {error && <p style={{ color: 'red' }}>{error}</p>}
      </div>
    );
  }

  return (
    <div style={{ maxWidth: 480, margin: '80px auto' }}>
      <h1>Aptos DApp</h1>
      <p><strong>Address:</strong> {address}</p>
      <p><strong>Network:</strong> {network}</p>
      <div style={{ display: 'flex', gap: 8 }}>
        <button onClick={handleSign}>Sign Message</button>
        <button onClick={handleSend} disabled={tx.status === 'pending'}>
          {tx.status === 'pending' ? 'Sending…' : 'Send 0 APT'}
        </button>
        <button onClick={disconnect}>Disconnect</button>
      </div>
      {tx.hash && (
        <p>
          TX: {tx.status === 'confirmed' ? 'Confirmed' : tx.status === 'pending' ? 'Pending…' : 'Failed'}
          {' — '}<code>{tx.hash.slice(0, 16)}…</code>
        </p>
      )}
    </div>
  );
}
```
