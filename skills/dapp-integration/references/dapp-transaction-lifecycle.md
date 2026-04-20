# Transaction Lifecycle Reference

Standard patterns for tracking, displaying, and managing transaction states in DApps. Works across all chain families — each chain has different confirmation mechanisms but the same UI state machine.

## Transaction States

Every on-chain action follows this state machine:

```
idle → signing → pending → confirmed
                        ↘ failed
```

```typescript
type TxStatus = 'idle' | 'signing' | 'pending' | 'confirmed' | 'failed';

interface TxState {
  status: TxStatus;
  hash: string | null;
  error: string | null;
  confirmations: number;
}
```

## Transaction Tracker Hook

```typescript
import { BrowserProvider } from 'ethers';

function useTransactionTracker(provider: any, chainId: number | null) {
  const [txState, setTxState] = useState<TxState>({
    status: 'idle',
    hash: null,
    error: null,
    confirmations: 0,
  });

  const trackTransaction = useCallback(async (hash: string) => {
    setTxState({ status: 'pending', hash, error: null, confirmations: 0 });

    try {
      const ethersProvider = new BrowserProvider(provider);
      const receipt = await ethersProvider.waitForTransaction(hash, 1);

      if (receipt && receipt.status === 1) {
        setTxState({ status: 'confirmed', hash, error: null, confirmations: 1 });
      } else {
        setTxState({ status: 'failed', hash, error: 'Transaction reverted.', confirmations: 0 });
      }
    } catch (err: any) {
      setTxState({ status: 'failed', hash, error: err.message, confirmations: 0 });
    }
  }, [provider]);

  const reset = useCallback(() => {
    setTxState({ status: 'idle', hash: null, error: null, confirmations: 0 });
  }, []);

  const setSigning = useCallback(() => {
    setTxState({ status: 'signing', hash: null, error: null, confirmations: 0 });
  }, []);

  const setFailed = useCallback((error: string) => {
    setTxState(s => ({ ...s, status: 'failed', error }));
  }, []);

  return { txState, trackTransaction, reset, setSigning, setFailed };
}
```

## Transaction Status Component

```tsx
function TxStatus({ txState, chainId }: { txState: TxState; chainId: number | null }) {
  const { status, hash, error } = txState;

  if (status === 'idle') return null;

  const explorerUrl = hash && chainId ? getExplorerTxUrl(chainId, hash) : null;

  return (
    <div className={`tx-status tx-status--${status}`}>
      {status === 'signing' && (
        <div className="tx-signing">
          <span className="spinner" />
          <p>Waiting for wallet confirmation...</p>
        </div>
      )}

      {status === 'pending' && (
        <div className="tx-pending">
          <span className="spinner" />
          <p>Transaction submitted. Waiting for confirmation...</p>
          {explorerUrl && (
            <a href={explorerUrl} target="_blank" rel="noopener noreferrer">
              View on Explorer →
            </a>
          )}
        </div>
      )}

      {status === 'confirmed' && (
        <div className="tx-confirmed">
          <span className="check-icon">✓</span>
          <p>Transaction confirmed!</p>
          {explorerUrl && (
            <a href={explorerUrl} target="_blank" rel="noopener noreferrer">
              View on Explorer →
            </a>
          )}
        </div>
      )}

      {status === 'failed' && (
        <div className="tx-failed">
          <span className="error-icon">✕</span>
          <p>{error || 'Transaction failed.'}</p>
          {explorerUrl && (
            <a href={explorerUrl} target="_blank" rel="noopener noreferrer">
              View on Explorer →
            </a>
          )}
        </div>
      )}
    </div>
  );
}
```

## Transaction History

For DApps that need to show recent transactions:

```typescript
interface TxRecord {
  hash: string;
  chainId: number;
  type: string;          // 'transfer', 'sign', 'approve', etc.
  description: string;   // "Sent 0.1 ETH to 0x1234...abcd"
  status: TxStatus;
  timestamp: number;
}

function useTxHistory() {
  const STORAGE_KEY = 'dapp_tx_history';

  const [history, setHistory] = useState<TxRecord[]>(() => {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
    } catch {
      return [];
    }
  });

  const addTx = useCallback((record: TxRecord) => {
    setHistory(prev => {
      const updated = [record, ...prev].slice(0, 50); // keep last 50
      localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
      return updated;
    });
  }, []);

  const updateTxStatus = useCallback((hash: string, status: TxStatus) => {
    setHistory(prev => {
      const updated = prev.map(tx => tx.hash === hash ? { ...tx, status } : tx);
      localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
      return updated;
    });
  }, []);

  return { history, addTx, updateTxStatus };
}
```

## Transaction History List Component

```tsx
function TxHistoryList({ history, className }: { history: TxRecord[]; className?: string }) {
  if (history.length === 0) {
    return <p className="no-history">No transactions yet.</p>;
  }

  return (
    <ul className={`tx-history ${className || ''}`}>
      {history.map(tx => (
        <li key={tx.hash} className={`tx-history-item tx-history--${tx.status}`}>
          <div className="tx-info">
            <span className="tx-type">{tx.type}</span>
            <span className="tx-description">{tx.description}</span>
            <span className="tx-time">{new Date(tx.timestamp).toLocaleString()}</span>
          </div>
          <div className="tx-actions">
            <span className={`status-badge status-badge--${tx.status}`}>{tx.status}</span>
            <a href={getExplorerTxUrl(tx.chainId, tx.hash)} target="_blank" rel="noopener noreferrer">
              Explorer →
            </a>
          </div>
        </li>
      ))}
    </ul>
  );
}
```

## Composing Transfer + Lifecycle

Standard pattern for combining transfer with transaction tracking:

```typescript
function useTrackedTransfer(provider: any, chainId: number | null) {
  const { sendNative } = useNativeTransfer(provider);
  const { txState, trackTransaction, setSigning, setFailed, reset } = useTransactionTracker(provider, chainId);

  const send = useCallback(async (to: string, amount: string) => {
    setSigning();
    try {
      const hash = await sendNative(to, amount);
      await trackTransaction(hash);
    } catch (err: any) {
      setFailed(getUserFriendlyError(err));
    }
  }, [sendNative, trackTransaction, setSigning, setFailed]);

  return { send, txState, reset };
}
```

## Multi-Chain Explorer Links

The `TxStatus` and `TxHistoryList` components use `getExplorerTxUrl(chainId, txHash)` which already supports all chains via the `CHAINS` config in `SKILL.md`. Each chain has different explorer URL patterns:

| Chain | Explorer | TX URL Pattern |
|-------|----------|---------------|
| EVM | Etherscan, BscScan, etc. | `/tx/{hash}` |
| Solana | Solscan | `/tx/{signature}` |
| Bitcoin | Mempool.space | `/tx/{txid}` |
| TON | TonViewer | `/transaction/{hash}` |
| Aptos | Aptos Explorer | `/txn/{hash}` |
| Cosmos | Mintscan | `/tx/{hash}` |
| Tron | TronScan | `/#/transaction/{hash}` |
| Sui | SuiScan | `/tx/{digest}` |

The `TxRecord` type uses `chainId: string` (e.g. `"solana"`, `"bitcoin"`) instead of `chainId: number` to support non-EVM chains.

## Best Practices

1. **Always show status** — never leave the user wondering what happened
2. **Link to explorer** — every transaction hash should link to the correct chain's block explorer
3. **Handle all states** — idle, signing, pending, confirmed, failed
4. **Persist history** — store in localStorage so users see past transactions
5. **Show signing step** — "Waiting for wallet confirmation" before the tx is even submitted
6. **Allow reset** — let users dismiss status and try again
7. **Limit history** — keep the last 50 transactions, not unlimited
8. **Tag chain in history** — each history entry should show which chain family it belongs to
