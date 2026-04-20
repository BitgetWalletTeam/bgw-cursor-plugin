# EVM Reference

Integrate Bitget Wallet with Ethereum, BSC, Polygon, Arbitrum, Optimism, Base, Avalanche, Fantom, zkSync, Linea, Scroll, and all EVM-compatible chains.

## Prerequisites

```bash
npm install ethers@6.13
```

Bitget Wallet injects an EIP-1193 provider at `window.bitkeep.ethereum`. Wrap it with `ethers.BrowserProvider` for a high-level API — avoid calling `provider.request()` directly when ethers alternatives exist.

## Provider

```typescript
import { BrowserProvider, JsonRpcSigner } from 'ethers';

const raw = window.bitkeep.ethereum;
raw.isBitKeep;   // true — identifies Bitget Wallet
raw.isMetaMask;  // true — MetaMask-compatible

const provider = new BrowserProvider(raw);
const signer: JsonRpcSigner = await provider.getSigner();
const address: string = await signer.getAddress();
const chainId: bigint = (await provider.getNetwork()).chainId;
```

## Connect

```typescript
async function connect(): Promise<string> {
  const provider = new BrowserProvider(window.bitkeep.ethereum);
  try {
    const signer = await provider.getSigner();
    return await signer.getAddress();
  } catch (error: any) {
    if (error.code === 4001) console.log('User rejected connection.');
    throw error;
  }
}
```

## Get Account

```typescript
const provider = new BrowserProvider(window.bitkeep.ethereum);
const signer = await provider.getSigner();
const address: string = await signer.getAddress();
const balance = await provider.getBalance(address);
const network = await provider.getNetwork(); // { chainId, name }
```

## Sign Message

### `personal_sign`

```typescript
async function signMessage(message: string): Promise<string> {
  const provider = new BrowserProvider(window.bitkeep.ethereum);
  const signer = await provider.getSigner();
  try {
    return await signer.signMessage(message);
  } catch (error: any) {
    if (error.code === 4001) console.log('User rejected signing.');
    throw error;
  }
}
```

### `eth_signTypedData_v4` (EIP-712)

> **⚠️ Always validate the JSON structure before calling the wallet.** Required fields: `types`, `domain`, `primaryType`, `message`. See `signing.md → validateEIP712TypedData()` for the validation helper.

```typescript
async function signTypedData(typedDataJson: string): Promise<string> {
  // 1. Validate JSON and required EIP-712 fields BEFORE touching the wallet
  let data: any;
  try {
    data = JSON.parse(typedDataJson);
  } catch (e: any) {
    throw new Error(`Invalid JSON: ${e.message}`);
  }
  if (!data.types || !data.domain || !data.primaryType || !data.message) {
    throw new Error('Invalid EIP-712 structure. Required: types, domain, primaryType, message');
  }

  // 2. Call wallet
  const raw = window.bitkeep.ethereum;
  const provider = new BrowserProvider(raw);
  const signer = await provider.getSigner();
  const address = await signer.getAddress();
  try {
    return await raw.request({
      method: 'eth_signTypedData_v4',
      params: [address, JSON.stringify(data)],
    });
  } catch (error: any) {
    if (error.code === 4001) console.log('User rejected typed data signing.');
    throw error;
  }
}
```

### Verify EIP-712 Signature

```typescript
import { verifyTypedData } from 'ethers';

function verifyEIP712Signature(
  domain: { name: string; version: string; chainId: number; verifyingContract: string },
  types: Record<string, { name: string; type: string }[]>,
  value: Record<string, any>,
  signature: string
): string {
  return verifyTypedData(domain, types, value, signature);
}
```

### SIWE (EIP-4361) — Sign-In with Ethereum

```typescript
async function signInWithEthereum(
  domain: string,
  uri: string,
  nonce: string
): Promise<{ message: string; signature: string }> {
  const provider = new BrowserProvider(window.bitkeep.ethereum);
  const signer = await provider.getSigner();
  const address = await signer.getAddress();
  const { chainId } = await provider.getNetwork();

  const message = [
    `${domain} wants you to sign in with your Ethereum account:`,
    address,
    '',
    `URI: ${uri}`,
    `Version: 1`,
    `Chain ID: ${chainId}`,
    `Nonce: ${nonce}`,
    `Issued At: ${new Date().toISOString()}`,
  ].join('\n');

  const signature = await signer.signMessage(message);
  return { message, signature };
}
```

**Backend verification (Node.js / Express):**

```typescript
import { verifyMessage } from 'ethers';

// Full SIWE auth flow:
// 1. Frontend: GET /api/nonce → receive nonce
// 2. Frontend: signInWithEthereum(domain, uri, nonce) → { message, signature }
// 3. Frontend: POST /api/verify { message, signature }
// 4. Backend:  verifyMessage(message, signature) → recoveredAddress
// 5. Backend:  compare recoveredAddress with claimed address → issue session

function verifySIWE(message: string, signature: string): string {
  const recoveredAddress = verifyMessage(message, signature);
  const claimedAddress = message.split('\n')[1]; // second line is the address
  if (recoveredAddress.toLowerCase() !== claimedAddress.toLowerCase()) {
    throw new Error('Signature verification failed');
  }
  return recoveredAddress;
}
```

## Sign Transaction

```typescript
async function signTransaction(tx: {
  to: string; value?: string; data?: string;
}): Promise<string> {
  const raw = window.bitkeep.ethereum;
  const [from] = await raw.request({ method: 'eth_accounts' });
  return await raw.request({
    method: 'eth_signTransaction',
    params: [{ ...tx, from }],
  });
}
```

## Send Transaction

```typescript
import { BrowserProvider, parseEther } from 'ethers';

async function sendTransaction(
  to: string,
  ethAmount: string
): Promise<string> {
  const provider = new BrowserProvider(window.bitkeep.ethereum);
  const signer = await provider.getSigner();

  try {
    const tx = await signer.sendTransaction({
      to,
      value: parseEther(ethAmount),
    });
    console.log('Pending:', tx.hash);
    const receipt = await tx.wait();
    console.log('Confirmed in block:', receipt?.blockNumber);
    return tx.hash;
  } catch (error: any) {
    if (error.code === 4001) console.log('User rejected transaction.');
    else if (error.code === -32603) console.log('RPC error. Check node status.');
    throw error;
  }
}
```

## Contract Interaction

Use `ethers.Contract` for read/write operations — never manually encode calldata.

```typescript
import { BrowserProvider, Contract, formatUnits, parseUnits } from 'ethers';

const ERC20_ABI = [
  'function name() view returns (string)',
  'function symbol() view returns (string)',
  'function decimals() view returns (uint8)',
  'function balanceOf(address) view returns (uint256)',
  'function transfer(address to, uint256 amount) returns (bool)',
] as const;

async function getTokenBalance(tokenAddress: string): Promise<string> {
  const provider = new BrowserProvider(window.bitkeep.ethereum);
  const contract = new Contract(tokenAddress, ERC20_ABI, provider);
  const signer = await provider.getSigner();
  const address = await signer.getAddress();

  try {
    const [balance, decimals, symbol] = await Promise.all([
      contract.balanceOf(address),
      contract.decimals(),
      contract.symbol(),
    ]);
    return `${formatUnits(balance, decimals)} ${symbol}`;
  } catch (error: any) {
    if (error.code === 'CALL_EXCEPTION') throw new Error('Invalid token contract or address');
    throw error;
  }
}

async function transferToken(
  tokenAddress: string,
  to: string,
  amount: string
): Promise<string> {
  const provider = new BrowserProvider(window.bitkeep.ethereum);
  const signer = await provider.getSigner();
  const contract = new Contract(tokenAddress, ERC20_ABI, signer);

  try {
    const decimals = await contract.decimals();
    const gasEstimate = await contract.transfer.estimateGas(to, parseUnits(amount, decimals));

    const tx = await contract.transfer(to, parseUnits(amount, decimals), {
      gasLimit: gasEstimate * 120n / 100n, // 20% buffer
    });
    console.log('Pending:', tx.hash);
    const receipt = await tx.wait();
    console.log('Confirmed in block:', receipt?.blockNumber);
    return tx.hash;
  } catch (error: any) {
    if (error.code === 4001) throw error; // user rejected
    if (error.code === 'UNPREDICTABLE_GAS_LIMIT') throw new Error('Transfer would fail — check balance and allowance');
    if (error.reason) throw new Error(`Contract reverted: ${error.reason}`);
    throw error;
  }
}
```

## Network Management

### Common Chain IDs

```typescript
const CHAIN_IDS = {
  ETHEREUM: '0x1',     BSC: '0x38',       POLYGON: '0x89',
  ARBITRUM: '0xa4b1',  OPTIMISM: '0xa',   BASE: '0x2105',
  AVALANCHE: '0xa86a', FANTOM: '0xfa',    ZKSYNC: '0x144',
  LINEA: '0xe708',     SCROLL: '0x82750',
} as const;
```

### Switch or Add Chain

Switches to the target chain; if the chain hasn't been added yet (error 4902), auto-adds it.

```typescript
async function switchOrAddChain(chainId: string, chainParams?: {
  chainName: string;
  nativeCurrency: { name: string; symbol: string; decimals: number };
  rpcUrls: string[]; blockExplorerUrls?: string[];
}): Promise<void> {
  try {
    await window.bitkeep.ethereum.request({
      method: 'wallet_switchEthereumChain',
      params: [{ chainId }],
    });
  } catch (error: any) {
    if (error.code === 4902 && chainParams) {
      await window.bitkeep.ethereum.request({
        method: 'wallet_addEthereumChain',
        params: [{ chainId, ...chainParams }],
      });
    } else {
      throw error;
    }
  }
}
```

## Events

```typescript
const raw = window.bitkeep.ethereum;

raw.on('accountsChanged', (accounts: string[]) => {
  if (accounts.length === 0) console.log('Wallet locked / disconnected');
  else console.log('Active account:', accounts[0]);
});

raw.on('chainChanged', (chainId: string) => {
  console.log('Chain switched to:', chainId);
  window.location.reload();
});

raw.on('connect', (info: { chainId: string }) => {
  console.log('Connected to chain:', info.chainId);
});

raw.on('disconnect', (error: { code: number; message: string }) => {
  console.log('Disconnected:', error.message);
});
```

## Error Handling

```typescript
interface WalletError { code: number; message: string; data?: unknown; }

function handleError(error: WalletError): { userMessage: string; recovery: string } {
  switch (error.code) {
    case 4001:
      return { userMessage: 'You rejected the request.', recovery: 'Please try again when ready.' };
    case 4100:
      return { userMessage: 'Not authorized.', recovery: 'Connect your wallet first, then retry.' };
    case 4200:
      return { userMessage: 'Method not supported.', recovery: 'Check the method name and target chain.' };
    case 4900:
      return { userMessage: 'Wallet disconnected.', recovery: 'Reconnect your wallet.' };
    case 4901:
      return { userMessage: 'Chain disconnected.', recovery: 'Switch to a connected chain.' };
    case -32000:
      return { userMessage: 'Invalid input.', recovery: 'Check parameter format and try again.' };
    case -32602:
      return { userMessage: 'Invalid parameters.', recovery: 'Verify parameter types and values.' };
    case -32603:
      return { userMessage: 'Internal RPC error.', recovery: 'Check node status; retry with exponential backoff.' };
    default:
      return { userMessage: `Error ${error.code}: ${error.message}`, recovery: 'Try again or contact support.' };
  }
}
```

## Integration Snippet

Drop this into any existing project to add Bitget Wallet EVM connectivity:

```typescript
import { BrowserProvider, formatEther } from 'ethers';

export async function connectBitgetWallet() {
  const raw = window.bitkeep?.ethereum;
  if (!raw) {
    window.open('https://web3.bitget.com/en/wallet-download');
    throw new Error('Bitget Wallet not installed');
  }
  const provider = new BrowserProvider(raw);
  const signer = await provider.getSigner();
  const address = await signer.getAddress();
  const balance = formatEther(await provider.getBalance(address));
  return { provider, signer, address, balance };
}
```

## Complete Example

### Project Setup

```bash
npm create vite@latest my-evm-dapp -- --template react-ts
cd my-evm-dapp
npm install ethers@6.13
```

### src/hooks/useWallet.ts

```typescript
import { useState, useCallback, useEffect } from 'react';
import { BrowserProvider, JsonRpcSigner, formatEther } from 'ethers';

export function useWallet() {
  const [account, setAccount] = useState<string>('');
  const [chainId, setChainId] = useState<string>('');
  const [balance, setBalance] = useState<string>('');
  const [provider, setProvider] = useState<BrowserProvider | null>(null);
  const [signer, setSigner] = useState<JsonRpcSigner | null>(null);
  const [loading, setLoading] = useState(false);
  const isConnected = !!account;

  const connect = useCallback(async () => {
    const raw = window.bitkeep?.ethereum;
    if (!raw) { window.open('https://web3.bitget.com/en/wallet-download'); return; }
    setLoading(true);
    try {
      const bp = new BrowserProvider(raw);
      const s = await bp.getSigner();
      const addr = await s.getAddress();
      const bal = formatEther(await bp.getBalance(addr));
      const net = await bp.getNetwork();
      setProvider(bp); setSigner(s); setAccount(addr);
      setBalance(bal); setChainId('0x' + net.chainId.toString(16));
    } catch (e: any) {
      if (e.code !== 4001) console.error(e);
    } finally { setLoading(false); }
  }, []);

  const disconnect = useCallback(() => {
    setAccount(''); setChainId(''); setBalance('');
    setProvider(null); setSigner(null);
  }, []);

  useEffect(() => {
    const raw = window.bitkeep?.ethereum;
    if (!raw) return;
    const onAccountsChanged = (accs: string[]) => { if (!accs.length) disconnect(); else setAccount(accs[0]); };
    const onChainChanged = (id: string) => { setChainId(id); connect(); };
    raw.on('accountsChanged', onAccountsChanged);
    raw.on('chainChanged', onChainChanged);
    return () => { raw.removeListener('accountsChanged', onAccountsChanged); raw.removeListener('chainChanged', onChainChanged); };
  }, [connect, disconnect]);

  return { account, chainId, balance, isConnected, loading, connect, disconnect, provider, signer };
}
```

### src/App.tsx

```tsx
import { useState } from 'react';
import { useWallet } from './hooks/useWallet';

export default function App() {
  const { account, chainId, balance, isConnected, loading, connect, disconnect, signer } = useWallet();
  const [status, setStatus] = useState('');

  const signMessage = async () => {
    if (!signer) return;
    setStatus('Signing...');
    try {
      const sig = await signer.signMessage('Hello from Bitget Wallet!');
      setStatus(`Signature: ${sig.slice(0, 20)}...`);
    } catch (e: any) {
      setStatus(e.code === 4001 ? 'Rejected by user' : e.message);
    }
  };

  const sendTx = async () => {
    if (!signer) return;
    setStatus('Sending...');
    try {
      const tx = await signer.sendTransaction({ to: account, value: 0n });
      setStatus(`Pending: ${tx.hash}`);
      await tx.wait();
      setStatus(`Confirmed: ${tx.hash}`);
    } catch (e: any) {
      setStatus(e.code === 4001 ? 'Rejected by user' : e.message);
    }
  };

  if (!isConnected) return <button onClick={connect} disabled={loading}>{loading ? 'Connecting...' : 'Connect Bitget Wallet'}</button>;

  return (
    <div>
      <p>Address: {account}</p>
      <p>Chain: {chainId} | Balance: {balance} ETH</p>
      <button onClick={signMessage}>Sign Message</button>
      <button onClick={sendTx}>Send 0 ETH (Test)</button>
      <button onClick={disconnect}>Disconnect</button>
      <pre>{status}</pre>
    </div>
  );
}
```
