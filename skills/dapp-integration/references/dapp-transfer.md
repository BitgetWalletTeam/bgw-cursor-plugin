# Transfer Reference

Standard patterns for token transfers in DApps — supports EVM (native + ERC-20), Solana, Bitcoin, TON, Aptos, Cosmos, Tron, and Sui.

## Transfer Form Component

A proper transfer form has: recipient input, amount input with max button, balance display, gas estimate, and a send button.

```tsx
interface TransferFormProps {
  balance: string;
  symbol: string;
  decimals: number;
  onSend: (to: string, amount: string) => Promise<string>;
}

function TransferForm({ balance, symbol, decimals, onSend }: TransferFormProps) {
  const [to, setTo] = useState('');
  const [amount, setAmount] = useState('');
  const [txHash, setTxHash] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [sending, setSending] = useState(false);

  const isValidAddress = /^0x[a-fA-F0-9]{40}$/.test(to);
  const parsedAmount = parseFloat(amount);
  const hasEnough = !isNaN(parsedAmount) && parsedAmount > 0 && parsedAmount <= parseFloat(balance);
  const canSend = isValidAddress && hasEnough && !sending;

  const handleMax = () => setAmount(balance);

  const handleSend = async () => {
    setSending(true);
    setError(null);
    setTxHash(null);
    try {
      const hash = await onSend(to, amount);
      setTxHash(hash);
      setTo('');
      setAmount('');
    } catch (err: any) {
      setError(getUserFriendlyError(err));
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="transfer-form">
      <h3>Send {symbol}</h3>

      <label>
        Recipient Address
        <input
          type="text"
          value={to}
          onChange={e => setTo(e.target.value)}
          placeholder="0x..."
          spellCheck={false}
        />
        {to && !isValidAddress && <span className="field-error">Invalid address</span>}
      </label>

      <label>
        Amount
        <div className="amount-input-group">
          <input
            type="number"
            value={amount}
            onChange={e => setAmount(e.target.value)}
            placeholder="0.0"
            min="0"
            step="any"
          />
          <button type="button" onClick={handleMax} className="max-btn">MAX</button>
        </div>
        <span className="balance-hint">Balance: {balance} {symbol}</span>
        {amount && !hasEnough && <span className="field-error">Insufficient balance</span>}
      </label>

      <button onClick={handleSend} disabled={!canSend}>
        {sending ? 'Sending...' : `Send ${symbol}`}
      </button>

      {error && <div className="error-message">{error}</div>}
      {txHash && <TxLink txHash={txHash} />}
    </div>
  );
}
```

## Transfer Hook — Native Token

```typescript
import { BrowserProvider, parseEther, formatEther } from 'ethers';

function useNativeTransfer(provider: any) {
  const sendNative = useCallback(async (to: string, amountInEther: string): Promise<string> => {
    if (!provider) throw new Error('Wallet not connected');

    const ethersProvider = new BrowserProvider(provider);
    const signer = await ethersProvider.getSigner();

    const tx = await signer.sendTransaction({
      to,
      value: parseEther(amountInEther),
    });

    return tx.hash;
  }, [provider]);

  return { sendNative };
}
```

## Transfer Hook — ERC-20 Token

> **Important:** ERC-20 transfers require an approval step first. See `token-approval.md` for the full approve-before-transfer pattern. Always check `allowance` before calling `transfer`.

```typescript
import { BrowserProvider, Contract, parseUnits } from 'ethers';

const ERC20_ABI = [
  'function transfer(address to, uint256 amount) returns (bool)',
  'function balanceOf(address) view returns (uint256)',
  'function decimals() view returns (uint8)',
  'function symbol() view returns (string)',
];

function useERC20Transfer(provider: any) {
  const sendERC20 = useCallback(async (
    tokenAddress: string,
    to: string,
    amount: string,
  ): Promise<string> => {
    if (!provider) throw new Error('Wallet not connected');

    const ethersProvider = new BrowserProvider(provider);
    const signer = await ethersProvider.getSigner();
    const contract = new Contract(tokenAddress, ERC20_ABI, signer);

    const decimals = await contract.decimals();
    const tx = await contract.transfer(to, parseUnits(amount, decimals));

    return tx.hash;
  }, [provider]);

  return { sendERC20 };
}
```

## Balance Display Hook

```typescript
import { BrowserProvider, formatEther, Contract, formatUnits } from 'ethers';

function useBalance(provider: any, account: string | null) {
  const [balance, setBalance] = useState<string>('0');
  const [loading, setLoading] = useState(false);

  const fetchBalance = useCallback(async () => {
    if (!provider || !account) return;
    setLoading(true);
    try {
      const ethersProvider = new BrowserProvider(provider);
      const raw = await ethersProvider.getBalance(account);
      setBalance(formatEther(raw));
    } catch {
      setBalance('0');
    } finally {
      setLoading(false);
    }
  }, [provider, account]);

  useEffect(() => { fetchBalance(); }, [fetchBalance]);

  return { balance, loading, refresh: fetchBalance };
}
```

## Token Selector

For DApps supporting multiple tokens:

```tsx
interface TokenOption {
  address: string | null;  // null = native token
  symbol: string;
  decimals: number;
  icon?: string;
}

function TokenSelector({ tokens, selected, onSelect }: {
  tokens: TokenOption[];
  selected: TokenOption;
  onSelect: (t: TokenOption) => void;
}) {
  return (
    <select
      value={selected.address || 'native'}
      onChange={e => {
        const token = tokens.find(t => (t.address || 'native') === e.target.value);
        if (token) onSelect(token);
      }}
    >
      {tokens.map(t => (
        <option key={t.address || 'native'} value={t.address || 'native'}>
          {t.symbol}
        </option>
      ))}
    </select>
  );
}
```

## Non-EVM Transfer Patterns

The TransferForm component above is chain-agnostic. The `onSend` callback is provided by a chain-specific adapter. Here's how each chain family maps to the pattern:

| Chain | Native Transfer API | Amount Unit | Address Format | Address Validation |
|-------|-------------------|-------------|----------------|-------------------|
| EVM | `signer.sendTransaction({ to, value })` | wei (18 decimals) | `0x` + 40 hex chars | `/^0x[a-fA-F0-9]{40}$/` |
| Solana | `SystemProgram.transfer({ toPubkey, lamports })` | lamports (9 decimals) | Base58, 32-44 chars | `/^[1-9A-HJ-NP-Za-km-z]{32,44}$/` |
| Bitcoin | `provider.sendBitcoin(to, satoshis)` | satoshis (8 decimals) | bc1/1/3 prefix | starts with `bc1`/`1`/`3` |
| TON | `provider.send('ton_sendTransaction', ...)` | nanotons (9 decimals) | EQ/UQ prefix, base64 | starts with `EQ`/`UQ` |
| Aptos | `provider.signAndSubmitTransaction(payload)` | octas (8 decimals) | `0x` + 64 hex chars | `/^0x[a-fA-F0-9]{64}$/` |
| Cosmos | `client.sendTokens(from, to, coins, fee)` | uatom (6 decimals) | `cosmos1` prefix, bech32 | starts with `cosmos1` |
| Tron | `tronWeb.trx.sendTransaction(to, sunAmount)` | sun (6 decimals) | `T` prefix, base58 | starts with `T`, 34 chars |
| Sui | `client.signAndExecuteTransactionBlock(...)` | MIST (9 decimals) | `0x` + 64 hex chars | `/^0x[a-fA-F0-9]{64}$/` |

### Adapting the Transfer Form per Chain

The TransferForm component stays the same. Only the validation regex and the `onSend` callback change:

```typescript
function getAddressValidator(family: ChainFamily): (addr: string) => boolean {
  const validators: Record<ChainFamily, (addr: string) => boolean> = {
    evm:     addr => /^0x[a-fA-F0-9]{40}$/.test(addr),
    solana:  addr => /^[1-9A-HJ-NP-Za-km-z]{32,44}$/.test(addr),
    bitcoin: addr => /^(bc1|[13])[a-zA-HJ-NP-Z0-9]{25,62}$/.test(addr),
    ton:     addr => /^(EQ|UQ)[A-Za-z0-9_-]{46}$/.test(addr) || /^0:[a-fA-F0-9]{64}$/.test(addr),
    aptos:   addr => /^0x[a-fA-F0-9]{1,64}$/.test(addr),
    cosmos:  addr => /^cosmos1[a-z0-9]{38}$/.test(addr),
    tron:    addr => /^T[a-zA-Z0-9]{33}$/.test(addr),
    sui:     addr => /^0x[a-fA-F0-9]{64}$/.test(addr),
  };
  return validators[family] || (() => true);
}
```

### Amount Display per Chain

```typescript
function getDisplayDecimals(family: ChainFamily): { decimals: number; symbol: string } {
  const config: Record<ChainFamily, { decimals: number; symbol: string }> = {
    evm:     { decimals: 18, symbol: 'ETH' },
    solana:  { decimals: 9,  symbol: 'SOL' },
    bitcoin: { decimals: 8,  symbol: 'BTC' },
    ton:     { decimals: 9,  symbol: 'TON' },
    aptos:   { decimals: 8,  symbol: 'APT' },
    cosmos:  { decimals: 6,  symbol: 'ATOM' },
    tron:    { decimals: 6,  symbol: 'TRX' },
    sui:     { decimals: 9,  symbol: 'SUI' },
  };
  return config[family] || { decimals: 18, symbol: '?' };
}
```

## Best Practices

1. **Always show balance** — display the user's balance for the selected token next to the amount input
2. **Provide MAX button** — let users send their full balance with one click
3. **Validate address per chain** — different chains have different address formats
4. **Validate amount** — check > 0 and <= balance
5. **Show gas estimate** — if possible, estimate gas before sending (EVM/Solana)
6. **Return tx hash immediately** — don't wait for confirmation to show the hash
7. **Clear form on success** — reset inputs after successful send
8. **Format amounts per chain** — use the correct decimals: wei for EVM, lamports for Solana, satoshis for Bitcoin, etc.
9. **Show correct symbol** — ETH, SOL, BTC, TON, APT, ATOM, TRX, SUI — never generic "tokens"
