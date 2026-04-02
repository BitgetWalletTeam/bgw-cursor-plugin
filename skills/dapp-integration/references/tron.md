# Tron Reference

Integrate Bitget Wallet with Tron DApps. The provider follows the TronLink protocol — code written for TronLink works with Bitget Wallet.

Wallet download: <https://web3.bitget.com/en/wallet-download>

## Prerequisites

Install tronweb for type utilities and contract interactions:

```bash
npm install tronweb@6
```

No additional SDK is required. Bitget Wallet injects a fully configured `tronWeb` instance at runtime.

## Provider

```typescript
const tronLink = window.bitkeep.tronLink;
const tronWeb = window.bitkeep.tronWeb;
```

Both objects are injected by the Bitget Wallet extension. `tronLink` handles connection lifecycle; `tronWeb` provides chain interaction methods.

## Connect

```typescript
interface TronConnectResult {
  code: number;
  message: string;
}

async function connectTron(): Promise<TronConnectResult> {
  const tronLink = window.bitkeep.tronLink;
  const result: TronConnectResult = await tronLink.request({
    method: 'tron_requestAccounts',
  });
  return result;
}
```

## Get Account

```typescript
function getDefaultAddress(): string {
  const tronWeb = window.bitkeep.tronWeb;
  return tronWeb.defaultAddress.base58;
}

// 1 TRX = 1,000,000 Sun
async function getBalance(address?: string): Promise<number> {
  const tronWeb = window.bitkeep.tronWeb;
  const addr = address ?? tronWeb.defaultAddress.base58;
  const balanceSun: number = await tronWeb.trx.getBalance(addr);
  return balanceSun;
}
```

## Disconnect

```typescript
async function disconnectTron(): Promise<void> {
  const tronLink = window.bitkeep.tronLink;
  await tronLink.disconnect();
}
```

## Configure Node

```typescript
function setNode(fullNodeUrl: string, solidityNodeUrl?: string): void {
  const tronWeb = window.bitkeep.tronWeb;
  tronWeb.setNode('fullNode', fullNodeUrl);
  if (solidityNodeUrl) {
    tronWeb.setNode('solidityNode', solidityNodeUrl);
  }
}
```

## Sign Message

```typescript
async function signMessage(message: string): Promise<string> {
  const tronWeb = window.bitkeep.tronWeb;
  const signature: string = await tronWeb.trx.signMessageV2(message);
  return signature;
}
```

### Verify Signature

```typescript
async function verifyMessage(message: string, signature: string): Promise<string> {
  const tronWeb = window.bitkeep.tronWeb;
  const recoveredAddress: string = await tronWeb.trx.verifyMessageV2(message, signature);
  return recoveredAddress;
}
```

## Sign and Send Transaction

### Send TRX (Simple)

Use `tronWeb.trx.sendTransaction` for straightforward native TRX transfers:

```typescript
async function sendTRXSimple(to: string, amountInSun: number): Promise<any> {
  const tronWeb = window.bitkeep.tronWeb;
  return await tronWeb.trx.sendTransaction(to, amountInSun);
}

// 1 TRX = 1,000,000 SUN
const result = await sendTRXSimple('TW8u1VSwbXY7o7H9kC8HmCNTiSXvD69Uiw', 1_000_000);
```

### Send TRX (TransactionBuilder)

For more control (custom memo, fee limits, multi-step workflows), use the transactionBuilder pattern:

```typescript
async function sendTRX(toAddress: string, amountInSun: number): Promise<any> {
  const tronWeb = window.bitkeep.tronWeb;
  const fromAddress = tronWeb.defaultAddress.base58;

  const tx = await tronWeb.transactionBuilder.sendTrx(toAddress, amountInSun, fromAddress);
  const signedTx = await tronWeb.trx.sign(tx);
  const broadcastTx = await tronWeb.trx.sendRawTransaction(signedTx);
  return broadcastTx;
}
```

### Send TRC-20 Token

```typescript
async function sendTRC20(
  contractAddress: string,
  toAddress: string,
  amount: number
): Promise<string> {
  const tronWeb = window.bitkeep.tronWeb;

  const contract = await tronWeb.contract().at(contractAddress);

  let decimal = 18;
  const decimalCall = contract.decimals || contract.DECIMALS;
  if (decimalCall) {
    decimal = await decimalCall().call();
  }

  const txId = await contract.transfer(
    toAddress,
    tronWeb.toHex(amount * Math.pow(10, decimal))
  ).send({ feeLimit: 10_000_000 });

  return txId;
}
```

## Events

```typescript
window.addEventListener('message', (event) => {
  const msg = event.data?.message;
  if (!msg) return;

  switch (msg.action) {
    case 'accountsChanged':
      console.log('Account changed:', msg.data);
      break;
    case 'chainChanged':
      console.log('Chain changed:', msg.data);
      break;
  }
});
```

## Error Handling

All 8 standard error codes with user-facing messages and recovery actions:

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

Drop-in module to add Tron connectivity to any existing project:

```typescript
async function initTron() {
  if (!window.bitkeep?.tronLink) {
    window.open('https://web3.bitget.com/en/wallet-download', '_blank');
    throw new Error('Bitget Wallet not installed');
  }
  const tronLink = window.bitkeep.tronLink;
  const tronWeb = window.bitkeep.tronWeb;
  await tronLink.request({ method: 'tron_requestAccounts' });
  const address = tronWeb.defaultAddress.base58;
  return { tronLink, tronWeb, address };
}

async function getBalance(tronWeb: any): Promise<string> {
  const sun = await tronWeb.trx.getBalance(tronWeb.defaultAddress.base58);
  return (sun / 1_000_000).toFixed(6) + ' TRX';
}

async function sendTRX(tronWeb: any, to: string, sun: number) {
  return await tronWeb.trx.sendTransaction(to, sun);
}
```

## Complete Example

React/TypeScript hook-based DApp using Vite.

### Project Setup

```bash
npm create vite@latest my-tron-dapp -- --template react-ts
cd my-tron-dapp
npm install tronweb@6
```

### `src/hooks/useTronWallet.ts`

```typescript
import { useState, useEffect, useCallback } from 'react';

interface TronWalletState {
  address: string | null;
  balance: string | null;
  connected: boolean;
  loading: boolean;
  error: string | null;
  txStatus: 'idle' | 'pending' | 'confirmed' | 'failed';
}

export function useTronWallet() {
  const [state, setState] = useState<TronWalletState>({
    address: null,
    balance: null,
    connected: false,
    loading: false,
    error: null,
    txStatus: 'idle',
  });

  const getTronLink = () => window.bitkeep?.tronLink;
  const getTronWeb = () => window.bitkeep?.tronWeb;

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const msg = event.data?.message;
      if (!msg) return;
      if (msg.action === 'accountsChanged') {
        const addr = msg.data?.address ?? null;
        setState((s) => ({
          ...s,
          address: addr,
          connected: !!addr,
        }));
      }
      if (msg.action === 'chainChanged') {
        window.location.reload();
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  const connect = useCallback(async () => {
    const tronLink = getTronLink();
    if (!tronLink) {
      window.open('https://web3.bitget.com/en/wallet-download', '_blank');
      setState((s) => ({ ...s, error: 'Bitget Wallet not installed' }));
      return;
    }
    setState((s) => ({ ...s, loading: true, error: null }));
    try {
      await tronLink.request({ method: 'tron_requestAccounts' });
      const tw = getTronWeb()!;
      const address = tw.defaultAddress.base58;
      const balanceSun = await tw.trx.getBalance(address);
      const balance = (balanceSun / 1_000_000).toFixed(6);
      setState((s) => ({ ...s, address, balance, connected: true, loading: false }));
    } catch (err: any) {
      setState((s) => ({ ...s, loading: false, error: err.message ?? 'Connection failed' }));
    }
  }, []);

  const disconnect = useCallback(async () => {
    try {
      await getTronLink()?.disconnect();
    } finally {
      setState({ address: null, balance: null, connected: false, loading: false, error: null, txStatus: 'idle' });
    }
  }, []);

  const signMessage = useCallback(async (message: string): Promise<string> => {
    const tronWeb = getTronWeb();
    if (!tronWeb) throw new Error('Not connected');
    return tronWeb.trx.signMessageV2(message);
  }, []);

  const sendTRX = useCallback(async (to: string, sun: number): Promise<string> => {
    const tronWeb = getTronWeb();
    if (!tronWeb) throw new Error('Not connected');
    setState((s) => ({ ...s, txStatus: 'pending', error: null }));
    try {
      const from = tronWeb.defaultAddress.base58;
      const tx = await tronWeb.transactionBuilder.sendTrx(to, sun, from);
      const signed = await tronWeb.trx.sign(tx);
      const result = await tronWeb.trx.sendRawTransaction(signed);
      setState((s) => ({ ...s, txStatus: 'confirmed' }));
      return result.txid;
    } catch (err: any) {
      setState((s) => ({ ...s, txStatus: 'failed', error: err.message ?? 'Transaction failed' }));
      throw err;
    }
  }, []);

  return { ...state, connect, disconnect, signMessage, sendTRX };
}
```

### `src/App.tsx`

```tsx
import { useState } from 'react';
import { useTronWallet } from './hooks/useTronWallet';

export default function App() {
  const { address, balance, connected, loading, error, txStatus, connect, disconnect, signMessage, sendTRX } = useTronWallet();
  const [to, setTo] = useState('');
  const [amount, setAmount] = useState('');
  const [signature, setSignature] = useState('');
  const [txId, setTxId] = useState('');

  const handleSign = async () => {
    try {
      const sig = await signMessage('Hello from Bitget Wallet Tron DApp!');
      setSignature(sig);
    } catch {}
  };

  const handleSend = async () => {
    if (!to || !amount) return;
    try {
      const id = await sendTRX(to, Number(amount));
      setTxId(id);
    } catch {}
  };

  const handleDisconnect = async () => {
    await disconnect();
    setSignature('');
    setTxId('');
    setTo('');
    setAmount('');
  };

  return (
    <div style={{ maxWidth: 640, margin: '40px auto', fontFamily: 'sans-serif' }}>
      <h1>Bitget Wallet — Tron Demo</h1>

      {!connected ? (
        <button onClick={connect} disabled={loading}>
          {loading ? 'Connecting…' : 'Connect Wallet'}
        </button>
      ) : (
        <>
          <p>Connected: {address}</p>
          {balance && <p>Balance: {balance} TRX</p>}
          <button onClick={handleDisconnect}>Disconnect</button>
          <hr />
          <button onClick={handleSign}>Sign Message</button>
          {signature && <pre>Signature: {signature}</pre>}
          <hr />
          <input placeholder="Recipient address" value={to} onChange={(e) => setTo(e.target.value)} />
          <input placeholder="Amount (SUN)" type="number" value={amount} onChange={(e) => setAmount(e.target.value)} />
          <button onClick={handleSend} disabled={txStatus === 'pending'}>
            {txStatus === 'pending' ? 'Sending…' : 'Send TRX'}
          </button>
          {txStatus === 'confirmed' && <p>Confirmed — TX: {txId}</p>}
          {txStatus === 'failed' && <p style={{ color: 'red' }}>Failed</p>}
        </>
      )}

      {error && <p style={{ color: 'red' }}>{error}</p>}
    </div>
  );
}
```
