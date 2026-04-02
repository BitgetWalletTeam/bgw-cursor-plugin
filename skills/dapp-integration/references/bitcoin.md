# Bitcoin Reference

Integrate Bitget Wallet with Bitcoin DApps. The provider follows the UniSat protocol — code written for UniSat works with Bitget Wallet.

## Prerequisites

No SDK required for basic provider interaction. Install Bitget Wallet from [web3.bitget.com/en/wallet-download](https://web3.bitget.com/en/wallet-download).

```bash
# For signature verification (browser-native, no Node.js polyfills needed)
npm install @noble/curves @noble/hashes
```

## Provider

```typescript
const provider = window.bitkeep.unisat;

provider.isBitKeep; // true — identifies Bitget Wallet
```

## Connect

```typescript
async function connectBitcoin(): Promise<string[]> {
  const provider = window.bitkeep.unisat;
  if (!provider) {
    window.open('https://web3.bitget.com/en/wallet-download', '_blank');
    throw new Error('Bitget Wallet not installed');
  }
  try {
    const accounts = await provider.requestAccounts();
    return accounts;
  } catch (error: any) {
    if (isUserRejection(error)) throw new Error('Connection rejected by user');
    throw error;
  }
}
```

## Get Account

```typescript
interface BTCBalance {
  confirmed: number;
  unconfirmed: number;
  total: number;
}

async function getAccounts(): Promise<string[]> {
  return await provider.getAccounts();
}

async function getPublicKey(): Promise<string> {
  return await provider.getPublicKey();
}

async function getBalance(retries = 3): Promise<BTCBalance> {
  for (let i = 0; i < retries; i++) {
    try {
      return await provider.getBalance();
    } catch (e: any) {
      if (i < retries - 1) { await new Promise(r => setTimeout(r, 1500)); continue; }
      throw new Error('Balance unavailable. Wallet RPC may not be ready — try again shortly.');
    }
  }
  throw new Error('Unreachable');
}
```

## Sign Message

```typescript
async function signMessage(
  message: string,
  type: 'ecdsa' | 'bip322-simple' = 'ecdsa'
): Promise<string> {
  const provider = window.bitkeep.unisat;
  try {
    return await provider.signMessage(message, type);
  } catch (error: any) {
    if (isUserRejection(error)) throw new Error('Signing rejected by user');
    throw error;
  }
}

// ECDSA (default)
const ecdsaSig = await signMessage('Hello Bitcoin');

// BIP-322 Simple
const bip322Sig = await signMessage('Hello Bitcoin', 'bip322-simple');
```

### Verify Signature

> **Do NOT use `bitcoinjs-message`** — it depends on Node.js globals (`process`, `Buffer`) and requires heavy polyfills in Vite/browser environments. Use `@noble/curves` + `@noble/hashes` instead.
>
> **⚠️ P2TR (Taproot) addresses (`bc1p...`):** Bitget Wallet defaults to P2TR. The address encodes a _tweaked_ x-only pubkey, which cannot be compared via hash160 against the ECDSA-recovered pubkey. **Always pass `knownPublicKeyHex` (from `getPublicKey()`) when available** — this is the most reliable verification path for all address types.

```typescript
import { secp256k1 } from '@noble/curves/secp256k1';
import { sha256 } from '@noble/hashes/sha256';
import { ripemd160 } from '@noble/hashes/ripemd160';

/**
 * Verify a Bitcoin ECDSA signed message.
 *
 * @param message          - the original plain-text message that was signed
 * @param address          - the signer's Bitcoin address (any type: P2PKH/P2SH/P2WPKH/P2TR)
 * @param signatureBase64  - the base64 signature returned by signMessage('ecdsa')
 * @param knownPublicKeyHex - optional: hex pubkey from getPublicKey(). Required for P2TR (bc1p) addresses.
 */
function verifyBitcoinSignature(
  message: string,
  address: string,
  signatureBase64: string,
  knownPublicKeyHex?: string,
): boolean {
  try {
    // Build Bitcoin Signed Message hash
    const prefix = '\x18Bitcoin Signed Message:\n';
    const msgBytes = new TextEncoder().encode(message);
    const full = new Uint8Array([
      ...new TextEncoder().encode(prefix),
      msgBytes.length, ...msgBytes,
    ]);
    const msgHash = sha256(sha256(full));

    // Recover signer pubkey from signature
    const sigBytes = Uint8Array.from(atob(signatureBase64), c => c.charCodeAt(0));
    const recoveryFlag = sigBytes[0] - 27;
    const compressed = recoveryFlag >= 4;
    const recoveryBit = recoveryFlag & 3;
    const sig = secp256k1.Signature.fromCompact(sigBytes.slice(1)).addRecoveryBit(recoveryBit);
    const pubkey = sig.recoverPublicKey(msgHash);
    const pubBytes = pubkey.toRawBytes(compressed);
    const recoveredHex = Array.from(pubBytes).map(b => b.toString(16).padStart(2, '0')).join('');

    // Strategy 1: compare with known pubkey directly (works for ALL address types, including P2TR)
    if (knownPublicKeyHex && recoveredHex === knownPublicKeyHex) return true;

    // Strategy 2: hash160 comparison (works for P2PKH 1..., P2SH 3..., P2WPKH bc1q...)
    // Does NOT work for P2TR (bc1p) — use knownPublicKeyHex for those.
    const recoveredHash160 = ripemd160(sha256(pubBytes));
    const addressHash160 = decodeAddressToHash160(address);
    if (addressHash160) {
      return recoveredHash160.length === addressHash160.length &&
        recoveredHash160.every((b, i) => b === addressHash160[i]);
    }

    return false;
  } catch {
    return false;
  }
}
```

Helper — decode any legacy/segwit address to hash160 (returns `null` for P2TR):

```typescript
const BASE58_ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
const BECH32_CHARSET  = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';

function decodeAddressToHash160(addr: string): Uint8Array | null {
  if (addr.startsWith('bc1q') || addr.startsWith('tb1q')) return decodeBech32P2WPKH(addr);
  if (!addr.startsWith('bc1') && !addr.startsWith('tb1'))  return decodeBase58Check(addr);
  return null; // bc1p = P2TR: not supported via hash160
}

function decodeBase58Check(addr: string): Uint8Array | null {
  try {
    let num = 0n;
    for (const ch of addr) {
      const idx = BASE58_ALPHABET.indexOf(ch);
      if (idx < 0) return null;
      num = num * 58n + BigInt(idx);
    }
    const bytes = new Uint8Array(25);
    for (let i = 24; i >= 0; i--) { bytes[i] = Number(num & 0xffn); num >>= 8n; }
    const checksum = sha256(sha256(bytes.slice(0, 21))).slice(0, 4);
    for (let i = 0; i < 4; i++) if (bytes[21 + i] !== checksum[i]) return null;
    return bytes.slice(1, 21);
  } catch { return null; }
}

function decodeBech32P2WPKH(addr: string): Uint8Array | null {
  try {
    const lower = addr.toLowerCase();
    const sep = lower.lastIndexOf('1');
    if (sep < 1) return null;
    const hrp = lower.slice(0, sep);
    const values: number[] = [];
    for (const ch of lower.slice(sep + 1)) {
      const v = BECH32_CHARSET.indexOf(ch); if (v < 0) return null; values.push(v);
    }
    // verify checksum & witness version
    if (values[0] !== 0) return null; // must be witness v0 for P2WPKH
    const payload = values.slice(1, -6);
    let acc = 0, bits = 0;
    const prog: number[] = [];
    for (const v of payload) {
      acc = (acc << 5) | v; bits += 5;
      while (bits >= 8) { bits -= 8; prog.push((acc >> bits) & 0xff); acc &= (1 << bits) - 1; }
    }
    if (prog.length !== 20) return null;
    return new Uint8Array(prog);
  } catch { return null; }
}
```

## Sign Transaction

```typescript
interface SignPsbtOptions {
  autoFinalized?: boolean;
  toSignInputs?: {
    index: number;
    address?: string;
    publicKey?: string;
    sighashTypes?: number[];
    disableTweakSigner?: boolean;
  }[];
}

async function signPsbt(
  psbtHex: string,
  options?: SignPsbtOptions
): Promise<string> {
  const provider = window.bitkeep.unisat;
  try {
    return await provider.signPsbt(psbtHex, options);
  } catch (error: any) {
    if (isUserRejection(error)) throw new Error('PSBT signing rejected');
    throw error;
  }
}

async function signPsbts(
  psbtHexs: string[],
  options?: SignPsbtOptions[]
): Promise<string[]> {
  return await window.bitkeep.unisat.signPsbts(psbtHexs, options);
}
```

## Send Transaction

```typescript
interface SendBitcoinOptions {
  feeRate?: number;
}

async function sendBitcoin(
  toAddress: string,
  satoshis: number,
  options?: SendBitcoinOptions
): Promise<string> {
  const provider = window.bitkeep.unisat;
  try {
    return await provider.sendBitcoin(toAddress, satoshis, options);
  } catch (error: any) {
    if (isUserRejection(error)) throw new Error('Transaction rejected');
    throw error;
  }
}

async function pushTx(rawtx: string): Promise<string> {
  return await window.bitkeep.unisat.pushTx({ rawtx });
}

async function pushPsbt(psbtHex: string): Promise<string> {
  return await window.bitkeep.unisat.pushPsbt(psbtHex);
}

const txid = await sendBitcoin('bc1q...', 10000, { feeRate: 15 });
```

## Inscriptions

```typescript
interface Inscription {
  inscriptionId: string; inscriptionNumber: number; address: string;
  outputValue: number; content: string; contentType: string;
  preview: string; timestamp: number; offset: number;
  genesisTransaction: string; location: string;
}

async function getInscriptions(cursor = 0, size = 20): Promise<{ total: number; list: Inscription[] }> {
  return await window.bitkeep.unisat.getInscriptions(cursor, size);
}

async function sendInscription(
  address: string, inscriptionId: string, options?: { feeRate?: number }
): Promise<{ txid: string }> {
  const provider = window.bitkeep.unisat;
  try {
    return await provider.sendInscription(address, inscriptionId, options);
  } catch (error: any) {
    if (isUserRejection(error)) throw new Error('Inscription transfer rejected');
    throw error;
  }
}
```

## Network Management

```typescript
type BTCNetwork = 'livenet' | 'testnet' | 'signet';

async function getNetwork(): Promise<BTCNetwork> {
  return await window.bitkeep.unisat.getNetwork();
}

async function switchNetwork(network: BTCNetwork): Promise<void> {
  try {
    await window.bitkeep.unisat.switchNetwork(network);
  } catch (error: any) {
    if (isUserRejection(error)) throw new Error('User rejected network switch');
    if ((error?.message || '').toLowerCase().includes('not support')) {
      throw new Error(`Network "${network}" not supported`);
    }
    throw error;
  }
}
```

## Events

```typescript
const provider = window.bitkeep.unisat;

provider.on('accountsChanged', (accounts: string[]) => {
  if (accounts.length === 0) {
    // Wallet disconnected
  } else {
    // Active account changed
  }
});

provider.on('networkChanged', (network: string) => {
  // Network switched
});
```

## Error Handling

> **Important:** The BTC provider maps all error codes to `-32603` internally,
> including user rejections. Use `isUserRejection()` below instead of checking `error.code === 4001`.

```typescript
function isUserRejection(error: any): boolean {
  const msg = (error?.message || '').toLowerCase();
  return /reject|cancel|denied|user/.test(msg);
}

function handleBtcError(error: any): { userMessage: string; recovery: string } {
  if (isUserRejection(error)) {
    return { userMessage: 'You rejected the request.', recovery: 'Please try again when ready.' };
  }
  const msg = (error?.message || '').toLowerCase();
  if (msg.includes('not authorized')) {
    return { userMessage: 'Not authorized.', recovery: 'Connect your wallet first, then retry.' };
  }
  if (msg.includes('not support')) {
    return { userMessage: 'Method or network not supported.', recovery: 'Check the method or network.' };
  }
  return { userMessage: error?.message || 'Unknown error', recovery: 'Try again or contact support.' };
}
```

## Integration Snippet

Add Bitcoin wallet connectivity to any existing project:

```typescript
const DOWNLOAD_URL = 'https://web3.bitget.com/en/wallet-download';

async function connectBTCWallet() {
  const provider = window.bitkeep?.unisat;
  if (!provider) {
    window.open(DOWNLOAD_URL, '_blank');
    return null;
  }
  const [address] = await provider.requestAccounts();
  const publicKey = await provider.getPublicKey();
  const network = await provider.getNetwork();
  const balance = await provider.getBalance();

  provider.on('accountsChanged', (accts: string[]) => {
    if (accts.length === 0) disconnectHandler();
    else updateAccount(accts[0]);
  });
  provider.on('networkChanged', (net: string) => updateNetwork(net));

  return { address, publicKey, network, balance };
}

function disconnectHandler() { /* reset app state */ }
function updateAccount(addr: string) { /* refresh with new address */ }
function updateNetwork(net: string) { /* refresh with new network */ }
```

## Complete Example

### Project Setup

```bash
npm create vite@latest my-btc-dapp -- --template react-ts
cd my-btc-dapp
npm install
```

### `src/hooks/useBitcoinWallet.ts`

```typescript
import { useState, useCallback, useEffect } from 'react';

interface BTCBalance {
  confirmed: number;
  unconfirmed: number;
  total: number;
}

interface WalletState {
  address: string | null;
  publicKey: string | null;
  network: string | null;
  balance: BTCBalance | null;
  isConnecting: boolean;
  isSending: boolean;
  txid: string | null;
  error: string | null;
}

const INITIAL_STATE: WalletState = {
  address: null,
  publicKey: null,
  network: null,
  balance: null,
  isConnecting: false,
  isSending: false,
  txid: null,
  error: null,
};

function getProvider() {
  return window.bitkeep?.unisat ?? null;
}

export function useBitcoinWallet() {
  const [state, setState] = useState<WalletState>(INITIAL_STATE);

  const setPartial = (patch: Partial<WalletState>) =>
    setState((prev) => ({ ...prev, ...patch }));

  const connect = useCallback(async () => {
    const provider = getProvider();
    if (!provider) {
      window.open('https://web3.bitget.com/en/wallet-download', '_blank');
      return;
    }
    setPartial({ isConnecting: true, error: null });
    try {
      const [address] = await provider.requestAccounts();
      const publicKey = await provider.getPublicKey();
      const network = await provider.getNetwork();
      const balance = await provider.getBalance();
      setPartial({ address, publicKey, network, balance, isConnecting: false });
    } catch (e: any) {
      setPartial({ isConnecting: false, error: isUserRejection(e) ? 'Connection rejected' : e.message });
    }
  }, []);

  const disconnect = useCallback(() => {
    setState(INITIAL_STATE);
  }, []);

  const refreshBalance = useCallback(async () => {
    const provider = getProvider();
    if (!provider || !state.address) return;
    const balance = await provider.getBalance();
    setPartial({ balance });
  }, [state.address]);

  const sendBitcoin = useCallback(async (toAddress: string, satoshis: number, feeRate?: number) => {
    const provider = getProvider();
    if (!provider) return;
    setPartial({ isSending: true, txid: null, error: null });
    try {
      const txid = await provider.sendBitcoin(toAddress, satoshis, feeRate ? { feeRate } : undefined);
      setPartial({ isSending: false, txid });
      await refreshBalance();
    } catch (e: any) {
      setPartial({ isSending: false, error: isUserRejection(e) ? 'Transaction rejected' : e.message });
    }
  }, [refreshBalance]);

  const signMessage = useCallback(async (message: string, type: 'ecdsa' | 'bip322-simple' = 'ecdsa') => {
    const provider = getProvider();
    if (!provider) throw new Error('Wallet not available');
    return await provider.signMessage(message, type);
  }, []);

  useEffect(() => {
    const provider = getProvider();
    if (!provider) return;

    const onAccountsChanged = (accounts: string[]) => {
      if (accounts.length === 0) setState(INITIAL_STATE);
      else setPartial({ address: accounts[0] });
    };
    const onNetworkChanged = (network: string) => setPartial({ network });

    provider.on('accountsChanged', onAccountsChanged);
    provider.on('networkChanged', onNetworkChanged);
    return () => {
      provider.removeListener('accountsChanged', onAccountsChanged);
      provider.removeListener('networkChanged', onNetworkChanged);
    };
  }, []);

  return { ...state, connect, disconnect, sendBitcoin, signMessage, refreshBalance };
}
```

### `src/App.tsx`

```tsx
import { useState } from 'react';
import { useBitcoinWallet } from './hooks/useBitcoinWallet';

export default function App() {
  const wallet = useBitcoinWallet();
  const [toAddress, setToAddress] = useState('');
  const [amount, setAmount] = useState('');

  const handleSend = () => {
    const sats = parseInt(amount, 10);
    if (toAddress && sats > 0) wallet.sendBitcoin(toAddress, sats);
  };

  if (!wallet.address) {
    return (
      <div style={{ maxWidth: 480, margin: '80px auto', textAlign: 'center' }}>
        <h1>Bitcoin DApp</h1>
        <button onClick={wallet.connect} disabled={wallet.isConnecting}>
          {wallet.isConnecting ? 'Connecting…' : 'Connect Bitget Wallet'}
        </button>
        {wallet.error && <p style={{ color: 'red' }}>{wallet.error}</p>}
      </div>
    );
  }

  return (
    <div style={{ maxWidth: 480, margin: '40px auto' }}>
      <h1>Bitcoin DApp</h1>
      <p>Address: <code>{wallet.address}</code></p>
      <p>Network: {wallet.network}</p>
      {wallet.balance && (
        <p>Balance: {wallet.balance.confirmed} sats (confirmed) / {wallet.balance.total} sats (total)</p>
      )}
      <button onClick={wallet.refreshBalance}>Refresh Balance</button>
      <button onClick={wallet.disconnect} style={{ marginLeft: 8 }}>Disconnect</button>
      <hr />
      <h2>Send BTC</h2>
      <div>
        <input placeholder="Recipient address" value={toAddress} onChange={(e) => setToAddress(e.target.value)} style={{ width: '100%', padding: 6, marginBottom: 8 }} />
        <input placeholder="Amount (satoshis)" type="number" value={amount} onChange={(e) => setAmount(e.target.value)} style={{ width: '100%', padding: 6, marginBottom: 8 }} />
        <button onClick={handleSend} disabled={wallet.isSending}>
          {wallet.isSending ? 'Sending…' : 'Send'}
        </button>
      </div>
      {wallet.txid && <p style={{ color: 'green' }}>Sent! TX: <code>{wallet.txid}</code></p>}
      {wallet.error && <p style={{ color: 'red' }}>{wallet.error}</p>}
    </div>
  );
}
```
