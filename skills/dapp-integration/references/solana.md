# Solana Reference

Integrate Bitget Wallet with Solana DApps. The provider is Phantom-compatible (`isPhantom = true`) — code written for Phantom works with Bitget Wallet.

## Prerequisites

```bash
npm install @solana/web3.js@1 tweetnacl@1
```

## Provider

```typescript
const provider = window.bitkeep.solana;

provider.isPhantom;  // true — Phantom-compatible
provider.isBitKeep;  // true — identifies Bitget Wallet
```

If the provider is not available, redirect to install:

```typescript
if (!window.bitkeep?.solana) {
  window.open('https://web3.bitget.com/en/wallet-download', '_blank');
}
```

RPC connection (used for transaction construction and confirmation — the provider only handles signing):

> **⚠️ RPC Rate Limits:** The public endpoint `https://api.mainnet-beta.solana.com` is rate-limited by Solana Foundation and will return **403** under moderate load. For production, use a commercial RPC provider (Helius, QuickNode, Alchemy). For development/testing, use devnet.

```typescript
import { Connection } from '@solana/web3.js';

// Production — use a commercial RPC provider:
// const connection = new Connection('https://rpc.helius.xyz/?api-key=YOUR_KEY');

// Development / testing:
const connection = new Connection('https://api.devnet.solana.com');

// Public mainnet (rate-limited, NOT recommended for production):
// const connection = new Connection('https://api.mainnet-beta.solana.com');
```

## Connect

```typescript
async function connect(): Promise<string> {
  const provider = window.bitkeep.solana;
  try {
    await provider.connect();
    return provider.publicKey.toString();
  } catch (error: any) {
    throw error;
  }
}
```

## Get Account

```typescript
const provider = window.bitkeep.solana;

const address: string = await provider.getAccount();
const isConnected: boolean = provider.connected;
const publicKey: string = provider.publicKey?.toString() ?? '';
```

## Sign Message

> **⚠️ Return format varies by version:** Bitget Wallet's `signMessage` may return:
> 1. **Array format:** `[{ signedMessage: {0:t,1:e,...}, signature: {0:175,1:61,...} }]` — an array containing one object with numeric-keyed plain objects (most common in Chrome Extension)
> 2. **Object format:** `{ signature: Uint8Array, publicKey: PublicKey }` — Phantom-style
> 3. **Raw Uint8Array** — direct bytes
> 4. **Serialized:** `{ data: number[] }` — serialized typed array
>
> Additionally, for typed arrays from the wallet extension context (cross-realm):
> - `instanceof Uint8Array` → **false** (cross-realm)
> - `new Uint8Array(crossRealm)` → **all zeros** (silently broken)
> - `crossRealm[i]` → may return **undefined** (proxy interception)
>
> Use the multi-strategy extraction pattern below. Try each strategy in order; the first one that produces non-zero bytes wins.

```typescript
async function signMessage(message: string): Promise<string> {
  const provider = window.bitkeep.solana;
  const encoded: Uint8Array = new TextEncoder().encode(message);
  const result = await provider.signMessage(encoded);

  // Step 0: Unwrap array — BGW may return [{ signedMessage, signature }]
  const unwrapped = Array.isArray(result) ? result[0] : result;

  // Step 1: Extract signature field
  const raw = unwrapped?.signature ?? unwrapped;
  const source = (raw as any)?.data ?? raw;
  const len = source?.length ?? source?.byteLength ?? 0;

  // For plain objects like {0:175, 1:61, ...}, count numeric keys
  const effectiveLen = len || Object.keys(source).filter((k: string) => !isNaN(Number(k))).length;

  // Strategy 1: direct indexed copy (same-realm typed arrays)
  const s1 = new Uint8Array(effectiveLen);
  for (let i = 0; i < effectiveLen; i++) s1[i] = source[i];
  if (s1.some((b: number) => b !== 0)) return toHex(s1);

  // Strategy 2: ArrayBuffer slice (cross-realm where .buffer is still accessible)
  if (source.buffer) {
    try {
      const off = source.byteOffset ?? 0;
      const s2 = new Uint8Array(source.buffer.slice(off, off + (source.byteLength ?? effectiveLen)));
      if (s2.some((b: number) => b !== 0)) return toHex(s2);
    } catch { /* fall through */ }
  }

  // Strategy 3: JSON round-trip (serializes typed arrays as {"0":v,"1":v,...})
  try {
    const json = JSON.parse(JSON.stringify(source));
    const s3 = new Uint8Array(effectiveLen);
    for (let i = 0; i < effectiveLen; i++) s3[i] = json[String(i)] ?? 0;
    if (s3.some((b: number) => b !== 0)) return toHex(s3);
  } catch { /* fall through */ }

  // Strategy 4: Object.values (plain objects like {0:175, 1:61, ...})
  try {
    const vals = Object.values(source).filter((v): v is number => typeof v === 'number');
    if (vals.length >= 32) return toHex(new Uint8Array(vals));
  } catch { /* fall through */ }

  throw new Error('Cannot extract signature bytes from wallet result');
}

function toHex(bytes: Uint8Array): string {
  return Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('');
}
```

## Verify Signature

Use `tweetnacl` (already listed in Prerequisites):

```typescript
import nacl from 'tweetnacl';
import { PublicKey } from '@solana/web3.js';

/**
 * Verify a Solana message signature.
 * @param message    - original plain-text message
 * @param signatureHex - hex string returned by signMessage above
 * @param pubkeyString - base58 public key of the signer
 */
function verifySolanaMessage(message: string, signatureHex: string, pubkeyString: string): boolean {
  try {
    const msgBytes = new TextEncoder().encode(message);
    const sigBytes = new Uint8Array(
      signatureHex.match(/.{1,2}/g)!.map((b: string) => parseInt(b, 16))
    );
    return nacl.sign.detached.verify(msgBytes, sigBytes, new PublicKey(pubkeyString).toBytes());
  } catch {
    return false;
  }
}
```

## Sign Transaction

> **⚠️ signTransaction return format:** BGW returns `[{ signedTransaction: {0:N, 1:N, ...} }]` — an array wrapping the **full serialized transaction** as a numeric-keyed plain object (cross-realm, no `.serialize()` method). Extract bytes manually.
>
> **⚠️ Do NOT use `signAndSendTransaction` when you need to control which network receives the transaction.** `signAndSendTransaction` submits to the wallet's own internal RPC endpoint, ignoring the `connection` you constructed. Use `signTransaction` + `connection.sendRawTransaction` instead.

```typescript
import {
  Connection, PublicKey, TransactionMessage,
  VersionedTransaction, SystemProgram,
} from '@solana/web3.js';

/**
 * Sign a versioned transaction and submit it via a specific connection.
 * Use this pattern (not signAndSendTransaction) when targeting devnet or
 * any RPC that differs from the wallet's internal endpoint.
 */
async function sendTransaction(
  connection: Connection, from: PublicKey, to: PublicKey, lamports: number
): Promise<string> {
  const { blockhash, lastValidBlockHeight } = await connection.getLatestBlockhash('confirmed');
  const msg = new TransactionMessage({
    payerKey: from,
    recentBlockhash: blockhash,
    instructions: [SystemProgram.transfer({ fromPubkey: from, toPubkey: to, lamports })],
  }).compileToV0Message();
  const tx = new VersionedTransaction(msg);

  // signTransaction returns [{ signedTransaction: {0:N,1:N,...} }]
  const result = await window.bitkeep.solana.signTransaction(tx);
  const unwrapped = Array.isArray(result) ? result[0] : result;
  const txSource = (unwrapped as any)?.signedTransaction ?? unwrapped;
  const txLen = txSource?.length ?? txSource?.byteLength ??
    Object.keys(txSource ?? {}).filter((k: string) => !isNaN(Number(k))).length;
  if (!txLen) throw new Error('signTransaction: could not determine serialized tx length');
  const rawTx = new Uint8Array(txLen);
  for (let i = 0; i < txLen; i++) rawTx[i] = (txSource as any)[i] ?? 0;

  // skipPreflight: devnet public nodes have blockhash sync delay between
  // the node that provided the blockhash and the simulation node, causing
  // "Blockhash not found" on preflight. Skip it; the chain will validate.
  const signature = await connection.sendRawTransaction(rawTx, {
    skipPreflight: true,
    preflightCommitment: 'confirmed',
  });

  // Resend every 2 s until confirmed — devnet nodes may drop packets,
  // and sendRawTransaction does NOT retry by default.
  const confirmPromise = connection.confirmTransaction(
    { signature, blockhash, lastValidBlockHeight }, 'confirmed'
  );
  const retryInterval = setInterval(async () => {
    try { await connection.sendRawTransaction(rawTx, { skipPreflight: true }); } catch { /* ignore */ }
  }, 2000);
  try {
    await confirmPromise;
  } finally {
    clearInterval(retryInterval);
  }

  return signature;
}
```

## Send Transaction (signAndSendTransaction)

> **⚠️ Only use when wallet network = DApp network.** `signAndSendTransaction` submits to the wallet's own RPC. If your `connection` targets a different endpoint (e.g. devnet while the wallet is set to mainnet), the transaction will be broadcast to the wrong network and time out. Use the `signTransaction` pattern above instead.

```typescript
async function sendTransactionViaWallet(
  connection: Connection, from: PublicKey, to: PublicKey, lamports: number
): Promise<string> {
  const { blockhash } = await connection.getLatestBlockhash('confirmed');
  const msg = new TransactionMessage({
    payerKey: from,
    recentBlockhash: blockhash,
    instructions: [SystemProgram.transfer({ fromPubkey: from, toPubkey: to, lamports })],
  }).compileToV0Message();
  const tx = new VersionedTransaction(msg);
  const { signature } = await window.bitkeep.solana.signAndSendTransaction(tx);
  return signature;
}
```

## Batch Sign

```typescript
import { Transaction, VersionedTransaction } from '@solana/web3.js';

async function signAll(
  txs: (Transaction | VersionedTransaction)[]
): Promise<(Transaction | VersionedTransaction)[]> {
  return await window.bitkeep.solana.signAllTransactions(txs);
}
```

## Events

```typescript
const provider = window.bitkeep.solana;

provider.on('connect', () => {
  console.log('Connected:', provider.publicKey.toString());
});

provider.on('disconnect', () => {
  console.log('Disconnected');
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

Drop-in Solana connectivity for any project — no framework required:

```typescript
import { Connection, VersionedTransaction, TransactionMessage, SystemProgram, PublicKey } from '@solana/web3.js';

const provider = window.bitkeep?.solana;
if (!provider) throw new Error('Install Bitget Wallet: https://web3.bitget.com/en/wallet-download');

// Use devnet for testing; swap to a commercial RPC for production
const connection = new Connection('https://api.devnet.solana.com');

await provider.connect();
const pubkey = provider.publicKey!;
console.log('Address:', pubkey.toString());

const msg = new TextEncoder().encode('Hello Solana');
const sig = await provider.signMessage(msg);
console.log('Signature:', Buffer.from(sig).toString('hex'));

// signTransaction + sendRawTransaction (DApp controls the target network)
const { blockhash, lastValidBlockHeight } = await connection.getLatestBlockhash('confirmed');
const txMsg = new TransactionMessage({
  payerKey: pubkey,
  recentBlockhash: blockhash,
  instructions: [SystemProgram.transfer({ fromPubkey: pubkey, toPubkey: pubkey, lamports: 0 })],
}).compileToV0Message();
const tx = new VersionedTransaction(txMsg);
const result = await provider.signTransaction(tx);

// Extract raw bytes from cross-realm result: [{ signedTransaction: {0:N,...} }]
const unwrapped = Array.isArray(result) ? result[0] : result;
const txSource = (unwrapped as any)?.signedTransaction ?? unwrapped;
const txLen = Object.keys(txSource ?? {}).filter((k: string) => !isNaN(Number(k))).length;
const rawTx = new Uint8Array(txLen);
for (let i = 0; i < txLen; i++) rawTx[i] = (txSource as any)[i] ?? 0;

const signature = await connection.sendRawTransaction(rawTx, { skipPreflight: true });
await connection.confirmTransaction({ signature, blockhash, lastValidBlockHeight }, 'confirmed');
console.log('TX:', signature);
```

## Complete Example

React + TypeScript Hook pattern using Vite.

### Setup

```bash
npm create vite@latest my-solana-dapp -- --template react-ts
cd my-solana-dapp
npm install @solana/web3.js@1
npm install -D @types/node
```

### `src/hooks/useSolanaWallet.ts`

```typescript
import { useState, useEffect, useCallback } from 'react';
import {
  Connection, PublicKey, TransactionMessage,
  VersionedTransaction, SystemProgram,
} from '@solana/web3.js';

interface WalletState {
  publicKey: string | null;
  isConnected: boolean;
  loading: boolean;
  connect: () => Promise<void>;
  disconnect: () => Promise<void>;
  signMessage: (msg: string) => Promise<Uint8Array>;
  sendSol: (to: string, lamports: number) => Promise<string>;
}

// Use devnet for testing; swap to a commercial RPC for production
const connection = new Connection('https://api.devnet.solana.com');

function getProvider() {
  const p = (window as any).bitkeep?.solana;
  if (!p) throw new Error('Install Bitget Wallet');
  return p;
}

/** Extract raw bytes from BGW cross-realm signTransaction result */
function extractSignedTx(result: any): Uint8Array {
  const unwrapped = Array.isArray(result) ? result[0] : result;
  const txSource = (unwrapped as any)?.signedTransaction ?? unwrapped;
  const txLen = txSource?.length ?? txSource?.byteLength ??
    Object.keys(txSource ?? {}).filter((k: string) => !isNaN(Number(k))).length;
  if (!txLen) throw new Error('signTransaction: could not determine serialized tx length');
  const rawTx = new Uint8Array(txLen);
  for (let i = 0; i < txLen; i++) rawTx[i] = (txSource as any)[i] ?? 0;
  return rawTx;
}

export function useSolanaWallet(): WalletState {
  const [publicKey, setPublicKey] = useState<string | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const provider = (window as any).bitkeep?.solana;
    if (!provider) return;

    const onConnect = () => {
      setPublicKey(provider.publicKey.toString());
      setIsConnected(true);
    };
    const onDisconnect = () => {
      setPublicKey(null);
      setIsConnected(false);
    };

    provider.on('connect', onConnect);
    provider.on('disconnect', onDisconnect);

    if (provider.connected && provider.publicKey) {
      onConnect();
    }

    return () => {
      provider.removeListener('connect', onConnect);
      provider.removeListener('disconnect', onDisconnect);
    };
  }, []);

  const connect = useCallback(async () => {
    setLoading(true);
    try {
      const provider = getProvider();
      await provider.connect();
      setPublicKey(provider.publicKey.toString());
      setIsConnected(true);
    } finally {
      setLoading(false);
    }
  }, []);

  const disconnect = useCallback(async () => {
    setLoading(true);
    try {
      await getProvider().disconnect();
      setPublicKey(null);
      setIsConnected(false);
    } finally {
      setLoading(false);
    }
  }, []);

  const signMessage = useCallback(async (msg: string): Promise<Uint8Array> => {
    return await getProvider().signMessage(new TextEncoder().encode(msg));
  }, []);

  // Use signTransaction + sendRawTransaction (DApp controls the target network).
  // signAndSendTransaction submits to the wallet's own RPC, which may differ.
  const sendSol = useCallback(async (to: string, lamports: number): Promise<string> => {
    const provider = getProvider();
    const from = provider.publicKey as PublicKey;
    const { blockhash, lastValidBlockHeight } = await connection.getLatestBlockhash('confirmed');
    const msg = new TransactionMessage({
      payerKey: from,
      recentBlockhash: blockhash,
      instructions: [SystemProgram.transfer({ fromPubkey: from, toPubkey: new PublicKey(to), lamports })],
    }).compileToV0Message();
    const tx = new VersionedTransaction(msg);

    const result = await provider.signTransaction(tx);
    const rawTx = extractSignedTx(result);

    const signature = await connection.sendRawTransaction(rawTx, {
      skipPreflight: true,
      preflightCommitment: 'confirmed',
    });

    // Resend every 2 s — devnet nodes may drop packets
    const confirmPromise = connection.confirmTransaction(
      { signature, blockhash, lastValidBlockHeight }, 'confirmed'
    );
    const retryInterval = setInterval(async () => {
      try { await connection.sendRawTransaction(rawTx, { skipPreflight: true }); } catch { /* ignore */ }
    }, 2000);
    try { await confirmPromise; } finally { clearInterval(retryInterval); }

    return signature;
  }, []);

  return { publicKey, isConnected, loading, connect, disconnect, signMessage, sendSol };
}
```

### `src/App.tsx`

```tsx
import { useState } from 'react';
import { useSolanaWallet } from './hooks/useSolanaWallet';

type TxStatus = 'idle' | 'pending' | 'confirmed' | 'error';

export default function App() {
  const { publicKey, isConnected, loading, connect, disconnect, signMessage, sendSol } = useSolanaWallet();
  const [signature, setSignature] = useState('');
  const [txStatus, setTxStatus] = useState<TxStatus>('idle');
  const [txSig, setTxSig] = useState('');
  const [error, setError] = useState('');

  const handleSign = async () => {
    try {
      setError('');
      const sig = await signMessage('Hello from Bitget Wallet!');
      setSignature(Buffer.from(sig).toString('hex'));
    } catch (e: any) {
      setError(e.message ?? String(e));
    }
  };

  const handleSend = async () => {
    if (!publicKey) return;
    try {
      setError('');
      setTxStatus('pending');
      const sig = await sendSol(publicKey, 0);
      setTxSig(sig);
      setTxStatus('confirmed');
    } catch (e: any) {
      setTxStatus('error');
      setError(e.message ?? String(e));
    }
  };

  if (!isConnected) {
    return (
      <div style={{ maxWidth: 480, margin: '80px auto', textAlign: 'center' }}>
        <h1>Solana DApp</h1>
        <button onClick={connect} disabled={loading}>
          {loading ? 'Connecting…' : 'Connect Bitget Wallet'}
        </button>
        {error && <p style={{ color: 'red' }}>{error}</p>}
      </div>
    );
  }

  return (
    <div style={{ maxWidth: 480, margin: '80px auto' }}>
      <h1>Solana DApp</h1>
      <p><strong>Address:</strong> {publicKey}</p>
      <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        <button onClick={handleSign}>Sign Message</button>
        <button onClick={handleSend} disabled={txStatus === 'pending'}>
          {txStatus === 'pending' ? 'Sending…' : 'Send 0 SOL (Test)'}
        </button>
        <button onClick={disconnect} disabled={loading}>Disconnect</button>
      </div>
      {signature && <p><strong>Signature:</strong> <code style={{ wordBreak: 'break-all' }}>{signature}</code></p>}
      {txStatus === 'pending' && <p>⏳ Transaction pending…</p>}
      {txStatus === 'confirmed' && <p style={{ color: 'green' }}>✅ Confirmed: <code>{txSig}</code></p>}
      {txStatus === 'error' && <p style={{ color: 'red' }}>❌ Failed</p>}
      {error && <p style={{ color: 'red' }}>{error}</p>}
    </div>
  );
}
```
