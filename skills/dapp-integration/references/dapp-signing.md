# Signing Reference

Standard patterns for message signing in DApps — supports EVM, Solana, Bitcoin, TON, Aptos, Cosmos, Tron, and Sui.

## Signing Types by Chain

Each chain family supports different signing methods. The signing panel must adapt:

### EVM

| Type | Method | Use Case |
|------|--------|----------|
| Personal Sign | `personal_sign` | Simple messages, off-chain auth |
| Typed Data (EIP-712) | `eth_signTypedData_v4` | Permits, orders, structured data |
| Sign Transaction (no broadcast) | `eth_signTransaction` | Offline signing, multisig prep |

### Solana

| Type | Method | Use Case |
|------|--------|----------|
| Sign Message | `signMessage(Uint8Array)` | Off-chain verification |
| Sign Transaction (no broadcast) | `signTransaction(tx)` | Offline signing; **preferred for DApp-controlled send** |
| Sign + Send | `signAndSendTransaction(tx)` | Only when wallet RPC = DApp RPC |

> **⚠️ `signAndSendTransaction` pitfall:** The wallet submits the transaction to its own internal RPC, ignoring the DApp's `connection`. If you target devnet but the wallet points to mainnet, the tx lands on the wrong network and times out. **Use `signTransaction` + `connection.sendRawTransaction`** to control which network receives the transaction.
>
> **⚠️ Cross-realm return format:** `signTransaction` returns `[{ signedTransaction: {0:N, 1:N, ...} }]` — the full serialized transaction as a numeric-keyed plain object (no `.serialize()` method). Extract bytes manually. See `solana.md` reference for the extraction pattern.

### Bitcoin

| Type | Method | Use Case |
|------|--------|----------|
| Sign Message | `signMessage(msg, type?)` | BIP-322 / ECDSA message signing |
| Sign PSBT | `signPsbt(psbtHex)` | Partially Signed Bitcoin Transaction |

### TON

| Type | Method | Use Case |
|------|--------|----------|
| Sign (via TonConnect) | `sendTransaction(...)` | Always broadcasts |

### Aptos

| Type | Method | Use Case |
|------|--------|----------|
| Sign Message | `signMessage({ message, nonce })` | Off-chain verification |
| Sign Transaction | `signTransaction(payload)` | Sign without submit |
| Sign + Submit | `signAndSubmitTransaction(payload)` | Standard flow |

### Cosmos

| Type | Method | Use Case |
|------|--------|----------|
| Sign Arbitrary | `signArbitrary(chainId, signer, data)` | ADR-036 off-chain signing |
| Sign Amino | `signAmino(chainId, signer, signDoc)` | Legacy transaction signing |
| Sign Direct | `signDirect(chainId, signer, signDoc)` | Protobuf transaction signing |

### Tron

| Type | Method | Use Case |
|------|--------|----------|
| Sign Message | `tronWeb.trx.signMessageV2(msg)` | Off-chain verification |
| Sign Transaction | `tronWeb.trx.sign(tx)` | Sign without broadcast |

### Sui

| Type | Method | Use Case |
|------|--------|----------|
| Sign Personal Message | `signPersonalMessage({ message })` | Off-chain verification |
| Sign Transaction Block | `signTransactionBlock({ transactionBlock })` | Sign without execute |

## Signing Panel Component (Multi-Chain Aware)

The signing panel adapts its available sign types based on the active chain:

```tsx
interface SignOption {
  id: string;
  label: string;
  placeholder: string;
}

function getSignOptions(family: ChainFamily): SignOption[] {
  const options: Record<ChainFamily, SignOption[]> = {
    evm: [
      { id: 'personal', label: 'Personal Sign', placeholder: 'Enter message to sign...' },
      { id: 'typedData', label: 'Typed Data (EIP-712)', placeholder: '{"types":...,"domain":...,"message":...}' },
    ],
    solana: [
      { id: 'message', label: 'Sign Message', placeholder: 'Enter message to sign...' },
    ],
    bitcoin: [
      { id: 'message', label: 'Sign Message (BIP-322)', placeholder: 'Enter message to sign...' },
    ],
    ton: [
      { id: 'proof', label: 'TON Proof', placeholder: 'Enter proof payload...' },
    ],
    aptos: [
      { id: 'message', label: 'Sign Message', placeholder: 'Enter message to sign...' },
    ],
    cosmos: [
      { id: 'arbitrary', label: 'Sign Arbitrary (ADR-036)', placeholder: 'Enter message to sign...' },
    ],
    tron: [
      { id: 'message', label: 'Sign Message V2', placeholder: 'Enter message to sign...' },
    ],
    sui: [
      { id: 'personal', label: 'Sign Personal Message', placeholder: 'Enter message to sign...' },
    ],
  };
  return options[family] || [];
}

interface SigningPanelProps {
  account: string;
  chainFamily: ChainFamily;
  chainId?: number;
  onSign: (type: string, message: string) => Promise<string>;
  onVerify?: (type: string, message: string, signature: string) => Promise<boolean>;
}

function SigningPanel({ account, chainFamily, chainId, onSign, onVerify }: SigningPanelProps) {
  const signOptions = getSignOptions(chainFamily);
  const [signType, setSignType] = useState(signOptions[0]?.id || '');
  const [message, setMessage] = useState('');
  const [signature, setSignature] = useState<string | null>(null);
  const [verified, setVerified] = useState<boolean | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [signing, setSigning] = useState(false);

  const activeOption = signOptions.find(o => o.id === signType);

  const handleSign = async () => {
    setSigning(true);
    setError(null);
    setSignature(null);
    setVerified(null);
    try {
      const sig = await onSign(signType, message);
      setSignature(sig);
    } catch (err: any) {
      setError(getUserFriendlyError(err));
    } finally {
      setSigning(false);
    }
  };

  const handleVerify = async () => {
    if (!signature || !onVerify) return;
    try {
      const isValid = await onVerify(signType, message, signature);
      setVerified(isValid);
    } catch {
      setVerified(false);
    }
  };

  return (
    <div className="signing-panel">
      <h3>Sign Message ({chainFamily.toUpperCase()})</h3>

      {signOptions.length > 1 && (
        <div className="sign-type-selector">
          {signOptions.map(opt => (
            <label key={opt.id}>
              <input type="radio" value={opt.id} checked={signType === opt.id}
                onChange={() => setSignType(opt.id)} />
              {opt.label}
            </label>
          ))}
        </div>
      )}

      <textarea
        value={message}
        onChange={e => setMessage(e.target.value)}
        placeholder={activeOption?.placeholder || 'Enter message...'}
        rows={signType === 'typedData' ? 6 : 4}
      />

      <button onClick={handleSign} disabled={!message || signing}>
        {signing ? 'Signing...' : 'Sign'}
      </button>

      {signature && (
        <div className="signature-result">
          <h4>Signature</h4>
          <code className="signature-display">{signature}</code>
          {onVerify && (
            <button onClick={handleVerify}>Verify Signature</button>
          )}
          {verified !== null && (
            <span className={verified ? 'verified' : 'invalid'}>
              {verified ? 'Valid ✓' : 'Invalid ✕'}
            </span>
          )}
        </div>
      )}

      {error && <div className="error-message">{error}</div>}
    </div>
  );
}
```

## Personal Sign

```typescript
async function signPersonalMessage(provider: any, account: string, message: string): Promise<string> {
  const hexMessage = '0x' + Array.from(new TextEncoder().encode(message))
    .map(b => b.toString(16).padStart(2, '0')).join('');

  return await provider.request({
    method: 'personal_sign',
    params: [hexMessage, account],
  });
}
```

## Signature Verification (All Chains)

Every signing operation **must** offer a Verify button. Here are the verification patterns per chain:

### EVM — Verify Personal Sign

```typescript
import { verifyMessage } from 'ethers';

function verifyPersonalSign(message: string, signature: string, expectedAddress: string): boolean {
  try {
    const recovered = verifyMessage(message, signature);
    return recovered.toLowerCase() === expectedAddress.toLowerCase();
  } catch {
    return false;
  }
}
```

### EVM — Verify EIP-712 Typed Data

```typescript
import { verifyTypedData } from 'ethers';

function verifyEIP712Signature(
  typedDataJson: string, signature: string, expectedAddress: string,
): boolean {
  try {
    const data = JSON.parse(typedDataJson);
    // Remove EIP712Domain from types before calling ethers (it adds it automatically)
    const { EIP712Domain, ...typesWithoutDomain } = data.types;
    const recovered = verifyTypedData(data.domain, typesWithoutDomain, data.message, signature);
    return recovered.toLowerCase() === expectedAddress.toLowerCase();
  } catch {
    return false;
  }
}
```

### Solana — Verify Message

Requires `tweetnacl` and `@solana/web3.js`:

```typescript
import nacl from 'tweetnacl';
import { PublicKey } from '@solana/web3.js';

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

### Bitcoin — Verify ECDSA Message

Requires `@noble/curves` and `@noble/hashes`. See `bitcoin.md` reference for the full `verifyBitcoinSignature()` implementation using `secp256k1` + double SHA-256.

> **⚠️ P2TR (Taproot / `bc1p...`) address support:** Bitget Wallet defaults to P2TR addresses. The ECDSA-recovered pubkey cannot be compared via hash160 against a P2TR address (which encodes a _tweaked_ x-only key). **Always pass `getPublicKey()` result to the verify function** and compare the recovered compressed pubkey hex directly. This works for all address types. Fall back to hash160 comparison only for legacy/segwit addresses (P2PKH `1...`, P2SH `3...`, P2WPKH `bc1q...`).

> **Note:** BIP-322 signature verification is more complex (requires parsing a virtual PSBT). For DApp demos, ECDSA verification is sufficient. BIP-322 verify can show "Verification not supported for BIP-322" in the UI.

## EIP-712 Typed Data Validation

> **⚠️ Always validate the JSON structure BEFORE calling the wallet.** Missing required fields will cause the wallet to throw an opaque error. Validate first, then call `eth_signTypedData_v4`.

Required EIP-712 fields: `types`, `domain`, `primaryType`, `message`.

```typescript
function validateEIP712TypedData(json: string): { valid: boolean; error?: string; data?: any } {
  let data: any;
  try {
    data = JSON.parse(json);
  } catch (e: any) {
    return { valid: false, error: `Invalid JSON: ${e.message}` };
  }
  if (!data.types || typeof data.types !== 'object')
    return { valid: false, error: 'Missing required field: types' };
  if (!data.domain || typeof data.domain !== 'object')
    return { valid: false, error: 'Missing required field: domain' };
  if (!data.primaryType || typeof data.primaryType !== 'string')
    return { valid: false, error: 'Missing required field: primaryType' };
  if (!data.message || typeof data.message !== 'object')
    return { valid: false, error: 'Missing required field: message' };
  return { valid: true, data };
}
```

## EIP-712 Typed Data Sign

```typescript
async function signTypedData(
  provider: any,
  account: string,
  chainId: number,
  typedDataJson: string,
): Promise<string> {
  // Validate first — never pass raw user input to the wallet
  const { valid, error, data } = validateEIP712TypedData(typedDataJson);
  if (!valid) throw new Error(error);

  if (!data.domain.chainId) {
    data.domain.chainId = chainId;
  }

  return await provider.request({
    method: 'eth_signTypedData_v4',
    params: [account, JSON.stringify(data)],
  });
}
```

## Sign-In with Ethereum (SIWE)

```typescript
function createSIWEMessage(address: string, chainId: number, nonce: string, domain: string): string {
  const now = new Date().toISOString();
  const expiry = new Date(Date.now() + 10 * 60 * 1000).toISOString();

  return [
    `${domain} wants you to sign in with your Ethereum account:`,
    address,
    '',
    'Sign in to access the application.',
    '',
    `URI: https://${domain}`,
    `Version: 1`,
    `Chain ID: ${chainId}`,
    `Nonce: ${nonce}`,
    `Issued At: ${now}`,
    `Expiration Time: ${expiry}`,
  ].join('\n');
}

async function signInWithEthereum(provider: any, account: string, chainId: number): Promise<{
  message: string;
  signature: string;
}> {
  const nonce = Math.random().toString(36).substring(2, 15);
  const domain = window.location.host;
  const message = createSIWEMessage(account, chainId, nonce, domain);
  const signature = await signPersonalMessage(provider, account, message);
  return { message, signature };
}
```

## Signature Preview Dialog

Always show the user what they're about to sign BEFORE triggering the wallet popup. This is a critical security UX pattern:

```tsx
function SignaturePreview({ signType, message, chainFamily, onConfirm, onCancel }: {
  signType: string;
  message: string;
  chainFamily: ChainFamily;
  onConfirm: () => void;
  onCancel: () => void;
}) {
  const isTypedData = signType === 'typedData';
  let preview: React.ReactNode;

  if (isTypedData) {
    try {
      const parsed = JSON.parse(message);
      preview = (
        <div className="typed-data-preview">
          {parsed.domain && <div><strong>Domain:</strong> {parsed.domain.name} (Chain {parsed.domain.chainId})</div>}
          {parsed.primaryType && <div><strong>Type:</strong> {parsed.primaryType}</div>}
          <div><strong>Data:</strong><pre>{JSON.stringify(parsed.message, null, 2)}</pre></div>
        </div>
      );
    } catch {
      preview = <pre className="raw-preview">{message}</pre>;
    }
  } else {
    preview = <pre className="raw-preview">{message}</pre>;
  }

  return (
    <div className="dialog-overlay" onClick={onCancel}>
      <div className="dialog signature-preview-dialog" onClick={e => e.stopPropagation()}>
        <h3>Review Signature Request</h3>
        <div className="preview-chain">Signing on: {chainFamily.toUpperCase()}</div>
        <div className="preview-content">{preview}</div>
        <div className="security-notice">
          Only sign messages you understand. Malicious signatures can authorize token transfers.
        </div>
        <div className="dialog-actions">
          <button onClick={onCancel} className="btn-secondary">Cancel</button>
          <button onClick={onConfirm} className="btn-primary">Sign</button>
        </div>
      </div>
    </div>
  );
}
```

## Phishing Protection

DApps should implement safeguards against signature phishing:

```typescript
function validateSignatureRequest(signType: string, message: string, currentDomain: string): {
  safe: boolean;
  warning?: string;
} {
  if (signType === 'typedData') {
    try {
      const data = JSON.parse(message);
      // Warn if the domain doesn't match current site
      if (data.domain?.name && !data.domain.name.toLowerCase().includes(currentDomain.toLowerCase())) {
        return {
          safe: false,
          warning: `This signature request is for "${data.domain.name}" but you're on "${currentDomain}". This may be a phishing attempt.`,
        };
      }
      // Warn about Permit/approval signatures
      if (data.primaryType === 'Permit' || data.primaryType === 'Permit2') {
        return {
          safe: true,
          warning: 'This signature authorizes token spending. Review the spender address and amount carefully.',
        };
      }
    } catch {}
  }
  return { safe: true };
}
```

## Sign Transaction (No Broadcast)

For cases where the user wants to sign but not broadcast:

```typescript
import { BrowserProvider, parseEther } from 'ethers';

async function signTransactionOnly(
  provider: any,
  to: string,
  value: string,
): Promise<string> {
  const ethersProvider = new BrowserProvider(provider);
  const signer = await ethersProvider.getSigner();

  const tx = {
    to,
    value: parseEther(value),
    gasLimit: 21000n,
  };

  const populatedTx = await signer.populateTransaction(tx);
  const signedTx = await signer.signTransaction(populatedTx);
  return signedTx;
}
```

## Best Practices

1. **Adapt sign types per chain** — EVM has personal_sign + EIP-712; Solana has signMessage; Bitcoin has BIP-322; show only what the chain supports
2. **Show what they're signing** — never sign opaque data without user preview
3. **Provide editable input** — let users type or paste the message to sign
4. **Show signature result** — display the full signature with copy button
5. **Offer verification** — let users verify the signature locally when possible
6. **Support sign-only** — not every signing operation needs to broadcast
7. **Use structured signing when available** — EIP-712 (EVM), signMessage with nonce (Aptos), ADR-036 (Cosmos)
8. **Include chain context** — always bind signatures to a specific chain ID or network
9. **Show chain label in panel** — "Sign Message (EVM)" or "Sign Message (Solana)" so users know which chain is active
