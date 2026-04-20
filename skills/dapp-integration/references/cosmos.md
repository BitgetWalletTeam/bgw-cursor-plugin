# Cosmos Reference

Integrate Bitget Wallet with Cosmos ecosystem DApps. The provider follows the Keplr protocol — code written for Keplr works with Bitget Wallet.

## Prerequisites

```bash
npm install @cosmjs/stargate@0.32 @cosmjs/proto-signing@0.32 cosmjs-types
```

No SDK is required for basic provider interaction. CosmJS is needed for transaction construction and offline signing.

## Provider

```typescript
const provider = window.bitkeep.keplr;
```

If not installed, redirect to `https://web3.bitget.com/en/wallet-download`.

## Supported Chains

| Chain | Chain ID | Description |
|---|---|---|
| Cosmos Hub | `cosmoshub-4` | Core IBC hub, native token ATOM |
| Osmosis | `osmosis-1` | Leading Cosmos DEX |
| Celestia | `celestia-mainnet-1` | Modular data availability layer |
| MANTRA | `mantra-mainnet-1` | DeFi and staking protocol |
| Coreum | `coreum-mainnet-1` | Enterprise WASM smart contracts |
| Saga | `saga-mainnet-1` | App-specific chain protocol |
| Xion | `xion-mainnet-1` | Universal abstraction layer |
| Nillion | `nil-chain-mainnet-1` | Privacy-focused compute network |

## Connect

```typescript
async function connectCosmos(chainId: string): Promise<void> {
  const provider = window.bitkeep.keplr;
  if (!provider) {
    window.open('https://web3.bitget.com/en/wallet-download', '_blank');
    throw new Error('Bitget Wallet not installed');
  }
  await provider.enable(chainId);
}
```

## Get Account

```typescript
interface CosmosKey {
  name: string;
  algo: string;
  pubKey: Uint8Array;
  address: Uint8Array;
  bech32Address: string;
}

async function getAccount(chainId: string): Promise<CosmosKey> {
  const provider = window.bitkeep.keplr;
  return await provider.getKey(chainId);
}
```

## Sign Message

### signArbitrary

Sign arbitrary data for off-chain authentication or verification.

```typescript
interface StdSignature {
  signature: string;
  pub_key: { type: string; value: string };
}

async function signArbitrary(
  chainId: string,
  signer: string,
  data: string
): Promise<StdSignature> {
  const provider = window.bitkeep.keplr;
  return await provider.signArbitrary(chainId, signer, data);
}
```

### verifyArbitrary

```typescript
async function verifyArbitrary(
  chainId: string,
  signer: string,
  data: string,
  signature: string
): Promise<boolean> {
  const provider = window.bitkeep.keplr;
  return await provider.verifyArbitrary(chainId, signer, data, signature);
}
```

### signAmino

Sign using Amino JSON format (legacy Cosmos SDK).

```typescript
interface Coin { denom: string; amount: string }
interface StdFee { amount: readonly Coin[]; gas: string; granter?: string; payer?: string }
interface AminoMsg { type: string; value: any }

interface StdSignDoc {
  chain_id: string;
  account_number: string;
  sequence: string;
  fee: StdFee;
  msgs: readonly AminoMsg[];
  memo: string;
  timeout_height?: string;
}

interface SignAminoResponse {
  signed: StdSignDoc;
  signature: StdSignature;
}

async function signAmino(
  chainId: string,
  signer: string,
  signDoc: StdSignDoc
): Promise<SignAminoResponse> {
  const provider = window.bitkeep.keplr;
  return await provider.signAmino(chainId, signer, signDoc);
}
```

### signDirect

Sign using Protobuf direct format.

```typescript
interface SignDocDirect {
  bodyBytes: Uint8Array | null;
  authInfoBytes: Uint8Array | null;
  chainId: string | null;
  accountNumber: bigint | null;
}

async function signDirect(
  chainId: string,
  signer: string,
  signDoc: SignDocDirect
): Promise<any> {
  const provider = window.bitkeep.keplr;
  return await provider.signDirect(chainId, signer, signDoc);
}
```

## Sign Transaction

### Amino Transaction

```typescript
async function signAminoTransfer(
  chainId: string, sender: string, recipient: string, amount: string, denom: string
): Promise<SignAminoResponse> {
  const signDoc: StdSignDoc = {
    chain_id: chainId, account_number: '0', sequence: '0',
    fee: { amount: [{ denom, amount: '5000' }], gas: '200000' },
    msgs: [{
      type: 'cosmos-sdk/MsgSend',
      value: { from_address: sender, to_address: recipient, amount: [{ denom, amount }] },
    }],
    memo: '',
  };
  return await signAmino(chainId, sender, signDoc);
}
```

### Direct Transaction (Protobuf)

```typescript
import { MsgSend } from 'cosmjs-types/cosmos/bank/v1beta1/tx';

async function signDirectTransfer(
  chainId: string, sender: string, recipient: string, amount: string, denom: string
): Promise<any> {
  const bodyBytes = MsgSend.encode({
    fromAddress: sender, toAddress: recipient, amount: [{ denom, amount }],
  }).finish();
  return await signDirect(chainId, sender, {
    bodyBytes, authInfoBytes: null, chainId, accountNumber: BigInt(0),
  });
}
```

## Send Transaction

```typescript
type BroadcastMode = 'block' | 'sync' | 'async';

async function sendTx(chainId: string, tx: Uint8Array, mode: BroadcastMode = 'sync'): Promise<Uint8Array> {
  return await window.bitkeep.keplr.sendTx(chainId, tx, mode);
}
```

## Get Offline Signer

`getOfflineSignerAuto` returns an Amino or Direct signer based on chain capabilities.

```typescript
async function getOfflineSigner(chainId: string) {
  return await window.bitkeep.keplr.getOfflineSignerAuto(chainId);
}
```

### Using with CosmJS

```typescript
import { SigningStargateClient } from '@cosmjs/stargate';

async function createSigningClient(chainId: string, rpcEndpoint: string) {
  const provider = window.bitkeep.keplr;
  await provider.enable(chainId);
  const signer = await provider.getOfflineSignerAuto(chainId);
  return await SigningStargateClient.connectWithSigner(rpcEndpoint, signer);
}
```

### IBC Transfer

```typescript
async function sendIbcTransfer(
  rpcEndpoint: string, sender: string, recipient: string,
  amount: string, denom: string, sourceChannel: string
): Promise<string> {
  const client = await createSigningClient('cosmoshub-4', rpcEndpoint);
  const timeout = BigInt(Date.now() + 600_000) * BigInt(1_000_000);
  const result = await client.sendIbcTokens(
    sender, recipient, { denom, amount }, 'transfer', sourceChannel,
    undefined, timeout, 'auto'
  );
  return result.transactionHash;
}
// Cosmos Hub IBC channels: Osmosis channel-141, Juno channel-207, Akash channel-184
```

## Events

```typescript
window.addEventListener('keplr_keystorechange', () => {
  // Re-fetch account info when user switches account or chain
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

Add Cosmos wallet connectivity to any existing project:

```typescript
const CHAIN_ID = 'cosmoshub-4';
const RPC = 'https://rpc.cosmos.network';

async function connectAndSend(recipient: string, amount: string) {
  const provider = window.bitkeep.keplr;
  if (!provider) throw new Error('Install Bitget Wallet');

  await provider.enable(CHAIN_ID);
  const key = await provider.getKey(CHAIN_ID);
  const signer = await provider.getOfflineSignerAuto(CHAIN_ID);

  const { SigningStargateClient } = await import('@cosmjs/stargate');
  const client = await SigningStargateClient.connectWithSigner(RPC, signer);

  const result = await client.sendTokens(
    key.bech32Address,
    recipient,
    [{ denom: 'uatom', amount }],
    { amount: [{ denom: 'uatom', amount: '5000' }], gas: '200000' }
  );
  return result.transactionHash;
}
```

## Complete Example

Project setup:

```bash
npm create vite@latest my-cosmos-dapp -- --template react-ts
cd my-cosmos-dapp
npm install @cosmjs/stargate@0.32 @cosmjs/proto-signing@0.32
```

### src/hooks/useCosmosWallet.ts

```typescript
import { useState, useCallback, useEffect } from 'react';
import { SigningStargateClient } from '@cosmjs/stargate';

interface CosmosKey {
  name: string;
  algo: string;
  pubKey: Uint8Array;
  address: Uint8Array;
  bech32Address: string;
}

interface WalletState {
  account: CosmosKey | null;
  client: SigningStargateClient | null;
  isConnecting: boolean;
  error: string | null;
}

interface TxResult {
  hash: string;
  status: 'pending' | 'confirmed' | 'error';
}

export function useCosmosWallet(chainId: string, rpcEndpoint: string) {
  const [state, setState] = useState<WalletState>({
    account: null, client: null, isConnecting: false, error: null,
  });
  const [txResult, setTxResult] = useState<TxResult | null>(null);

  const getProvider = useCallback(() => {
    const provider = window.bitkeep?.keplr;
    if (!provider) {
      window.open('https://web3.bitget.com/en/wallet-download', '_blank');
      throw new Error('Bitget Wallet not installed');
    }
    return provider;
  }, []);

  const connect = useCallback(async () => {
    setState(s => ({ ...s, isConnecting: true, error: null }));
    try {
      const provider = getProvider();
      await provider.enable(chainId);
      const account = await provider.getKey(chainId);
      const signer = await provider.getOfflineSignerAuto(chainId);
      const client = await SigningStargateClient.connectWithSigner(rpcEndpoint, signer);
      setState({ account, client, isConnecting: false, error: null });
    } catch (err: any) {
      const { userMessage } = handleWalletError(err);
      setState(s => ({ ...s, isConnecting: false, error: userMessage }));
    }
  }, [chainId, rpcEndpoint, getProvider]);

  const disconnect = useCallback(() => {
    state.client?.disconnect();
    setState({ account: null, client: null, isConnecting: false, error: null });
    setTxResult(null);
  }, [state.client]);

  const sendTokens = useCallback(async (
    recipient: string, amount: string, denom: string
  ) => {
    if (!state.account || !state.client) throw new Error('Not connected');
    setTxResult({ hash: '', status: 'pending' });
    try {
      const result = await state.client.sendTokens(
        state.account.bech32Address,
        recipient,
        [{ denom, amount }],
        { amount: [{ denom, amount: '5000' }], gas: '200000' }
      );
      setTxResult({ hash: result.transactionHash, status: 'confirmed' });
      return result.transactionHash;
    } catch (err: any) {
      const { userMessage } = handleWalletError(err);
      setTxResult({ hash: '', status: 'error' });
      throw new Error(userMessage);
    }
  }, [state.account, state.client]);

  const signMessage = useCallback(async (message: string) => {
    if (!state.account) throw new Error('Not connected');
    const provider = getProvider();
    return await provider.signArbitrary(chainId, state.account.bech32Address, message);
  }, [chainId, state.account, getProvider]);

  useEffect(() => {
    const handler = () => { disconnect(); };
    window.addEventListener('keplr_keystorechange', handler);
    return () => window.removeEventListener('keplr_keystorechange', handler);
  }, [disconnect]);

  return { ...state, txResult, connect, disconnect, sendTokens, signMessage };
}

function handleWalletError(error: any): { userMessage: string; recovery: string } {
  const code = error?.code;
  switch (code) {
    case 4001: return { userMessage: 'You rejected the request.', recovery: 'Please try again when ready.' };
    case 4100: return { userMessage: 'Not authorized.', recovery: 'Connect your wallet first, then retry.' };
    case 4200: return { userMessage: 'Method not supported.', recovery: 'Check the method name.' };
    case 4900: return { userMessage: 'Wallet disconnected.', recovery: 'Reconnect your wallet.' };
    case 4901: return { userMessage: 'Chain disconnected.', recovery: 'Switch to a connected chain.' };
    case -32000: return { userMessage: 'Invalid input.', recovery: 'Check parameter format.' };
    case -32602: return { userMessage: 'Invalid parameters.', recovery: 'Verify parameter types and values.' };
    case -32603: return { userMessage: 'Internal RPC error.', recovery: 'Check node status; retry with backoff.' };
    default: return { userMessage: error?.message || 'Unknown error', recovery: 'Try again or contact support.' };
  }
}
```

### src/App.tsx

```typescript
import { useState } from 'react';
import { useCosmosWallet } from './hooks/useCosmosWallet';

const CHAIN_ID = 'cosmoshub-4';
const RPC = 'https://rpc.cosmos.network';

export default function App() {
  const { account, isConnecting, error, txResult, connect, disconnect, sendTokens, signMessage } = useCosmosWallet(CHAIN_ID, RPC);
  const [recipient, setRecipient] = useState('');
  const [amount, setAmount] = useState('');
  const [signature, setSignature] = useState('');

  const handleSend = async () => {
    try { await sendTokens(recipient, amount, 'uatom'); }
    catch (err: any) { console.error(err.message); }
  };

  const handleSign = async () => {
    try {
      const sig = await signMessage('Hello from Bitget Wallet!');
      setSignature(sig.signature);
    } catch (err: any) { console.error(err.message); }
  };

  return (
    <div style={{ maxWidth: 480, margin: '40px auto', fontFamily: 'system-ui' }}>
      <h1>Cosmos DApp</h1>

      {!account ? (
        <button onClick={connect} disabled={isConnecting}>
          {isConnecting ? 'Connecting…' : 'Connect Wallet'}
        </button>
      ) : (
        <div>
          <p><strong>{account.name}</strong>: {account.bech32Address}</p>
          <button onClick={disconnect}>Disconnect</button>

          <h3>Send Tokens</h3>
          <input placeholder="Recipient" value={recipient} onChange={e => setRecipient(e.target.value)} />
          <input placeholder="Amount (uatom)" value={amount} onChange={e => setAmount(e.target.value)} />
          <button onClick={handleSend} disabled={txResult?.status === 'pending'}>
            {txResult?.status === 'pending' ? 'Sending…' : 'Send'}
          </button>

          {txResult?.status === 'confirmed' && <p>TX: {txResult.hash}</p>}
          {txResult?.status === 'error' && <p style={{ color: 'red' }}>Transaction failed</p>}

          <h3>Sign Message</h3>
          <button onClick={handleSign}>Sign</button>
          {signature && <pre style={{ wordBreak: 'break-all' }}>{signature}</pre>}
        </div>
      )}

      {error && <p style={{ color: 'red' }}>{error}</p>}
    </div>
  );
}
```
