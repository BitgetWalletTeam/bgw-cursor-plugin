# TON Reference

Integrate Bitget Wallet with TON (The Open Network) DApps. The provider is OpenMask/TonKeeper-compatible. For adapter-based integration, see `adapters.md` (TonConnect section).

## Prerequisites

```bash
# For TonConnect integration (optional)
npm install @tonconnect/ui-react
# or
npm install @tonconnect/ui
```

No SDK is required for JS Bridge (`window.bitkeep.ton`) usage.

```bash
# For signature verification
npm install tweetnacl@1
```

## Provider

```typescript
const provider = window.bitkeep.ton;

provider.isBitgetWallet;  // true
provider.isTonWallet;     // true
provider.isOpenMask;      // true — OpenMask-compatible
provider.isTonkeeper;     // true — TonKeeper-compatible
```

## Supported Versions

| Platform | Version |
|---|---|
| Chrome Extension | >= v2.4.1 |
| App (iOS) | >= 8.10.0 |
| App (Android) | >= 8.10.0 |

## Connect

```typescript
async function connectTon(): Promise<string[]> {
  const provider = window.bitkeep.ton;

  try {
    const accounts: string[] = await provider.send('ton_requestAccounts');
    return accounts;
  } catch (error: any) {
    if (error.code === 4001) {
      throw new Error('User rejected the connection request.');
    }
    if (error.code === 4100) {
      throw new Error('Wallet not authorized. Please connect first.');
    }
    throw error;
  }
}
```

## Get Account

```typescript
async function getAccounts(): Promise<string[]> {
  return await provider.send('ton_requestAccounts');
}

async function getBalance(address?: string): Promise<string> {
  const result = await provider.send('ton_getBalance', address);
  return Array.isArray(result) ? result[0] : result; // returns TON units (not nanotons)
}
```

> **Warning:** `ton_requestAccounts` returns **lowercase** addresses. Some TON REST APIs (e.g. toncenter) may reject lowercase addresses with 422 — convert to raw address format if needed.
> **Units:** `ton_getBalance` returns **TON** (not nanotons). Do NOT divide by 1e9. All `send()` methods return `result[]` arrays — extract with `result[0]`.

## Sign Message

### Raw Sign

```typescript
async function rawSign(data: string): Promise<string> {
  const provider = window.bitkeep.ton;

  try {
    const signature: string = await provider.send('ton_rawSign', [data]);
    return signature;
  } catch (error: any) {
    if (error.code === 4001) {
      throw new Error('User rejected signing.');
    }
    throw error;
  }
}
```

### Personal Sign

```typescript
interface PersonalSignParams {
  data: string;
}

async function personalSign(data: string): Promise<string> {
  const provider = window.bitkeep.ton;

  try {
    const signature: string = await provider.send('ton_personalSign', { data });
    return signature;
  } catch (error: any) {
    if (error.code === 4001) {
      throw new Error('User rejected personal signing.');
    }
    throw error;
  }
}
```

### Verify Signature

TON uses ed25519 signatures. Verify with `tweetnacl`:

```typescript
import nacl from 'tweetnacl';

function verifyTonSignature(
  message: string, signature: string, publicKey: string
): boolean {
  const messageBytes = new TextEncoder().encode(message);
  const signatureBytes = Buffer.from(signature, 'hex');
  const publicKeyBytes = Buffer.from(publicKey, 'hex');
  return nacl.sign.detached.verify(messageBytes, signatureBytes, publicKeyBytes);
}
```

> The `publicKey` can be obtained from `ton_getAccount` response.

## Send Transaction

```typescript
interface TonTransactionParams {
  to: string;
  value: string;       // in nanotons (1 TON = 1,000,000,000 nanotons)
  data?: string;
  dataType?: 'text' | 'hex' | 'base64' | 'boc';
}

async function sendTransaction(params: TonTransactionParams): Promise<string> {
  const provider = window.bitkeep.ton;

  try {
    const seqNo: string = await provider.send('ton_sendTransaction', [params]);
    return seqNo;
  } catch (error: any) {
    if (error.code === 4001) {
      throw new Error('User rejected the transaction.');
    }
    if (error.code === -32603) {
      throw new Error('Internal error. Check RPC node status.');
    }
    throw error;
  }
}

const seqNo = await sendTransaction({
  to: 'UQDxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
  value: '10000000',  // 0.01 TON
  data: 'Hello from DApp',
  dataType: 'text',
});
```

## Network Management

```typescript
async function getChain(): Promise<string> {
  const result = await provider.send('ton_getChain');
  return Array.isArray(result) ? result[0] : result;
}

async function switchChain(network: 'mainnet' | 'testnet'): Promise<void> {
  try {
    await provider.send('wallet_switchChain', network);
  } catch (error: any) {
    if (error.code === 4001) throw new Error('User rejected chain switch');
    if (error.code === 4200) throw new Error(`Chain "${network}" not supported`);
    throw error;
  }
}
```

## TonConnect Integration

For a more standardized approach, use TonConnect v2. Bitget Wallet supports TonConnect via `window.bitgetTonWallet.tonconnect`.

See `adapters.md` → TonConnect section for full setup.

## Events

```typescript
const provider = window.bitkeep.ton;

provider.on('accountsChanged', (accounts: string[]) => {
  console.log('Account changed:', accounts);
});

provider.on('chainChanged', (chainId: string) => {
  console.log('Chain changed:', chainId);
});

provider.on('disconnect', () => {
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

## Integration Snippet

Drop-in snippet to add TON connectivity to any existing project:

```typescript
const DOWNLOAD_URL = 'https://web3.bitget.com/en/wallet-download';

async function getTonProvider() {
  if (!window.bitkeep?.ton) {
    window.open(DOWNLOAD_URL, '_blank');
    throw new Error('Bitget Wallet not installed');
  }
  return window.bitkeep.ton;
}

async function connectAndSend(to: string, valueNanotons: string): Promise<string> {
  const provider = await getTonProvider();
  const accounts = await provider.send('ton_requestAccounts');
  if (!accounts.length) throw new Error('No accounts available');
  return await provider.send('ton_sendTransaction', [{ to, value: valueNanotons }]);
}

async function signData(data: string): Promise<string> {
  const provider = await getTonProvider();
  await provider.send('ton_requestAccounts');
  return await provider.send('ton_personalSign', { data });
}
```

## Complete Example

Project setup:

```bash
npm create vite@latest my-ton-dapp -- --template react-ts
cd my-ton-dapp
npm install
```

### `src/hooks/useTonWallet.ts`

```typescript
import { useState, useEffect, useCallback, useRef } from 'react';

interface WalletError { code: number; message: string; }

interface TxResult {
  seqNo: string;
  status: 'pending' | 'confirmed';
}

function handleError(error: WalletError): { userMessage: string; recovery: string } {
  switch (error.code) {
    case 4001:  return { userMessage: 'You rejected the request.', recovery: 'Please try again when ready.' };
    case 4100:  return { userMessage: 'Not authorized.', recovery: 'Connect your wallet first, then retry.' };
    case 4200:  return { userMessage: 'Method not supported.', recovery: 'Check the method name.' };
    case 4900:  return { userMessage: 'Wallet disconnected.', recovery: 'Reconnect your wallet.' };
    case 4901:  return { userMessage: 'Chain disconnected.', recovery: 'Switch to a connected chain.' };
    case -32000: return { userMessage: 'Invalid input.', recovery: 'Check parameter format.' };
    case -32602: return { userMessage: 'Invalid parameters.', recovery: 'Verify parameter types and values.' };
    case -32603: return { userMessage: 'Internal RPC error.', recovery: 'Check node status; retry with backoff.' };
    default:     return { userMessage: `Error ${error.code}: ${error.message}`, recovery: 'Try again or contact support.' };
  }
}

export function useTonWallet() {
  const [account, setAccount] = useState<string | null>(null);
  const [balance, setBalance] = useState<string | null>(null);
  const [chain, setChain] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<{ userMessage: string; recovery: string } | null>(null);
  const [txResult, setTxResult] = useState<TxResult | null>(null);
  const providerRef = useRef(window.bitkeep?.ton ?? null);

  const isInstalled = !!providerRef.current;

  const resetState = useCallback(() => {
    setAccount(null);
    setBalance(null);
    setChain(null);
    setTxResult(null);
    setError(null);
  }, []);

  useEffect(() => {
    const provider = providerRef.current;
    if (!provider) return;

    const onAccountsChanged = (accounts: string[]) => {
      if (accounts.length === 0) {
        resetState();
      } else {
        setAccount(accounts[0]);
      }
    };
    const onChainChanged = (chainId: string) => setChain(chainId);
    const onDisconnect = () => resetState();

    provider.on('accountsChanged', onAccountsChanged);
    provider.on('chainChanged', onChainChanged);
    provider.on('disconnect', onDisconnect);

    return () => {
      provider.removeListener?.('accountsChanged', onAccountsChanged);
      provider.removeListener?.('chainChanged', onChainChanged);
      provider.removeListener?.('disconnect', onDisconnect);
    };
  }, [resetState]);

  const withLoading = useCallback(async <T>(fn: () => Promise<T>): Promise<T | undefined> => {
    setLoading(true);
    setError(null);
    try {
      return await fn();
    } catch (e: any) {
      setError(handleError(e));
      return undefined;
    } finally {
      setLoading(false);
    }
  }, []);

  const connect = useCallback(() => withLoading(async () => {
    const provider = providerRef.current!;
    const accounts: string[] = await provider.send('ton_requestAccounts');
    setAccount(accounts[0]);
    const chainResult = await provider.send('ton_getChain');
    setChain(Array.isArray(chainResult) ? chainResult[0] : chainResult);
    return accounts[0];
  }), [withLoading]);

  const refreshBalance = useCallback(() => withLoading(async () => {
    const provider = providerRef.current!;
    const result = await provider.send('ton_getBalance');
    const bal = Array.isArray(result) ? result[0] : result;
    setBalance(bal);
    return bal;
  }), [withLoading]);

  const signMessage = useCallback((data: string) => withLoading(async () => {
    const provider = providerRef.current!;
    return await provider.send('ton_personalSign', { data });
  }), [withLoading]);

  const sendTransaction = useCallback((to: string, value: string, data?: string) => withLoading(async () => {
    const provider = providerRef.current!;
    setTxResult(null);
    const seqNo: string = await provider.send('ton_sendTransaction', [{
      to, value, ...(data ? { data, dataType: 'text' as const } : {}),
    }]);
    setTxResult({ seqNo, status: 'pending' });
    setTimeout(() => setTxResult(prev => prev ? { ...prev, status: 'confirmed' } : null), 5000);
    return seqNo;
  }), [withLoading]);

  const switchChain = useCallback((network: 'mainnet' | 'testnet') => withLoading(async () => {
    const provider = providerRef.current!;
    await provider.send('wallet_switchChain', network);
    setChain(network);
  }), [withLoading]);

  const disconnect = useCallback(() => {
    resetState();
  }, [resetState]);

  return {
    isInstalled, account, balance, chain, loading, error, txResult,
    connect, refreshBalance, signMessage, sendTransaction, switchChain, disconnect,
  };
}
```

### `src/App.tsx`

```typescript
import { useTonWallet } from './hooks/useTonWallet';
import { useState } from 'react';

const DOWNLOAD_URL = 'https://web3.bitget.com/en/wallet-download';

export default function App() {
  const {
    isInstalled, account, balance, chain, loading, error, txResult,
    connect, refreshBalance, signMessage, sendTransaction, switchChain, disconnect,
  } = useTonWallet();

  const [recipient, setRecipient] = useState('');
  const [amount, setAmount] = useState('');

  if (!isInstalled) {
    return (
      <div style={{ maxWidth: 480, margin: '40px auto', fontFamily: 'sans-serif' }}>
        <h1>TON DApp</h1>
        <p>Bitget Wallet not detected.</p>
        <a href={DOWNLOAD_URL} target="_blank" rel="noreferrer">Install Bitget Wallet</a>
      </div>
    );
  }

  return (
    <div style={{ maxWidth: 480, margin: '40px auto', fontFamily: 'sans-serif' }}>
      <h1>TON DApp</h1>

      {!account ? (
        <button onClick={connect} disabled={loading}>
          {loading ? 'Connecting…' : 'Connect Wallet'}
        </button>
      ) : (
        <>
          <p><strong>Account:</strong> {account}</p>
          <p><strong>Chain:</strong> {chain ?? '—'}</p>
          <p><strong>Balance:</strong> {balance ? `${balance} TON` : '—'}</p>

          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', margin: '12px 0' }}>
            <button onClick={refreshBalance} disabled={loading}>Refresh Balance</button>
            <button onClick={() => signMessage('Hello TON')} disabled={loading}>Sign Message</button>
            <button onClick={() => switchChain(chain === 'mainnet' ? 'testnet' : 'mainnet')} disabled={loading}>
              Switch to {chain === 'mainnet' ? 'Testnet' : 'Mainnet'}
            </button>
            <button onClick={disconnect}>Disconnect</button>
          </div>

          <div style={{ margin: '12px 0' }}>
            <input placeholder="Recipient address" value={recipient} onChange={e => setRecipient(e.target.value)} style={{ width: '100%', padding: 6, marginBottom: 4 }} />
            <input placeholder="Amount in nanotons (1 TON = 1e9)" value={amount} onChange={e => setAmount(e.target.value)} type="number" style={{ width: '100%', padding: 6, marginBottom: 4 }} />
            <button onClick={() => sendTransaction(recipient, amount)} disabled={loading || !recipient || !amount}>
              {loading ? 'Sending…' : 'Send TON'}
            </button>
          </div>

          {txResult && (
            <p style={{ color: txResult.status === 'confirmed' ? 'green' : 'orange' }}>
              TX {txResult.seqNo}: {txResult.status}
            </p>
          )}
        </>
      )}

      {error && (
        <div style={{ color: 'red', marginTop: 12 }}>
          <p>{error.userMessage}</p>
          <p><em>{error.recovery}</em></p>
        </div>
      )}
    </div>
  );
}
```
