# UX Patterns Reference

Essential DApp UX infrastructure — loading states, notifications, empty states, input helpers, ENS resolution, mobile detection, and security safeguards.

> **Why this matters:** 65% of new Web3 users abandon after their first interaction. The patterns below address the most common causes of abandonment.

## Loading & Skeleton States

Never show a blank screen while data loads. Use skeleton placeholders:

```tsx
function Skeleton({ width, height }: { width?: string; height?: string }) {
  return (
    <div
      className="skeleton"
      style={{ width: width || '100%', height: height || '20px' }}
    />
  );
}

function BalanceSkeleton() {
  return (
    <div className="balance-display">
      <Skeleton width="80px" height="24px" />
      <Skeleton width="40px" height="16px" />
    </div>
  );
}
```

```css
.skeleton {
  background: linear-gradient(90deg, var(--border-color) 25%, var(--card-bg) 50%, var(--border-color) 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border-radius: 4px;
}

@keyframes shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
```

## Toast Notification System

DApps need a persistent notification system for transaction status — users may navigate away from the page:

```tsx
type ToastType = 'info' | 'success' | 'error' | 'warning' | 'pending';

interface Toast {
  id: string;
  type: ToastType;
  title: string;
  message?: string;
  txHash?: string;
  chainId?: string;
  autoClose?: number;  // ms, 0 = manual close
}

function useToasts() {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const addToast = useCallback((toast: Omit<Toast, 'id'>) => {
    const id = Date.now().toString(36) + Math.random().toString(36).slice(2);
    setToasts(prev => [...prev, { ...toast, id }]);

    if (toast.autoClose !== 0) {
      setTimeout(() => {
        setToasts(prev => prev.filter(t => t.id !== id));
      }, toast.autoClose || 5000);
    }

    return id;
  }, []);

  const removeToast = useCallback((id: string) => {
    setToasts(prev => prev.filter(t => t.id !== id));
  }, []);

  const updateToast = useCallback((id: string, updates: Partial<Toast>) => {
    setToasts(prev => prev.map(t => t.id === id ? { ...t, ...updates } : t));
  }, []);

  return { toasts, addToast, removeToast, updateToast };
}

function ToastContainer({ toasts, onClose }: { toasts: Toast[]; onClose: (id: string) => void }) {
  return (
    <div className="toast-container" aria-live="polite">
      {toasts.map(toast => (
        <div key={toast.id} className={`toast toast--${toast.type}`} role="alert">
          <div className="toast-content">
            <strong>{toast.title}</strong>
            {toast.message && <p>{toast.message}</p>}
            {toast.txHash && toast.chainId && (
              <a href={getExplorerTxUrl(toast.chainId, toast.txHash)}
                 target="_blank" rel="noopener noreferrer">
                View on Explorer →
              </a>
            )}
          </div>
          <button onClick={() => onClose(toast.id)} className="toast-close" aria-label="Close">×</button>
        </div>
      ))}
    </div>
  );
}
```

```css
.toast-container {
  position: fixed;
  top: 16px;
  right: 16px;
  z-index: 9999;
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-width: 400px;
}

.toast {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 12px 16px;
  border-radius: 12px;
  background: var(--card-bg);
  border: 1px solid var(--border-color);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  animation: slideIn 0.3s ease;
}

.toast--success { border-left: 4px solid var(--success); }
.toast--error   { border-left: 4px solid var(--error); }
.toast--pending { border-left: 4px solid var(--primary); }
.toast--warning { border-left: 4px solid #f59e0b; }

@keyframes slideIn {
  from { transform: translateX(100%); opacity: 0; }
  to   { transform: translateX(0); opacity: 1; }
}
```

### Toast Usage with Transaction Lifecycle

```typescript
// Combine toasts with transaction tracking
async function sendWithToast(
  send: () => Promise<string>,
  track: (hash: string) => Promise<void>,
  toast: ReturnType<typeof useToasts>,
  chainId: string,
) {
  const toastId = toast.addToast({
    type: 'pending',
    title: 'Waiting for wallet...',
    autoClose: 0,
  });

  try {
    const hash = await send();
    toast.updateToast(toastId, {
      type: 'pending',
      title: 'Transaction submitted',
      message: 'Waiting for confirmation...',
      txHash: hash,
      chainId,
    });

    await track(hash);
    toast.updateToast(toastId, {
      type: 'success',
      title: 'Transaction confirmed!',
      txHash: hash,
      chainId,
      autoClose: 8000,
    });
  } catch (err: any) {
    toast.updateToast(toastId, {
      type: 'error',
      title: 'Transaction failed',
      message: getUserFriendlyError(err),
      autoClose: 10000,
    });
  }
}
```

## Empty States

Show helpful empty states, not blank screens:

```tsx
function EmptyState({ icon, title, description, action }: {
  icon?: string;
  title: string;
  description: string;
  action?: { label: string; onClick: () => void };
}) {
  return (
    <div className="empty-state">
      {icon && <span className="empty-icon">{icon}</span>}
      <h3>{title}</h3>
      <p>{description}</p>
      {action && <button onClick={action.onClick}>{action.label}</button>}
    </div>
  );
}

// Usage examples:
// No wallet: <EmptyState icon="🔗" title="No Wallet Connected" description="Connect your wallet to view balances and send transactions." action={{ label: 'Connect Wallet', onClick: connect }} />
// No history: <EmptyState icon="📋" title="No Transactions Yet" description="Your transaction history will appear here after your first transaction." />
// No balance: <EmptyState icon="💰" title="No Balance" description="Deposit tokens to get started." />
```

## ENS / Domain Name Resolution (EVM)

Accept human-readable names in address fields:

```typescript
import { BrowserProvider } from 'ethers';

function useENSResolution(provider: any, input: string) {
  const [resolved, setResolved] = useState<{
    address: string | null;
    name: string | null;
    isResolving: boolean;
  }>({ address: null, name: null, isResolving: false });

  useEffect(() => {
    if (!provider || !input) {
      setResolved({ address: null, name: null, isResolving: false });
      return;
    }

    // If it's already a valid address, no need to resolve
    if (/^0x[a-fA-F0-9]{40}$/.test(input)) {
      setResolved({ address: input, name: null, isResolving: false });
      return;
    }

    // If it contains a dot, try ENS resolution
    if (!input.includes('.')) return;

    let cancelled = false;
    setResolved(s => ({ ...s, isResolving: true }));

    const resolve = async () => {
      try {
        const ethersProvider = new BrowserProvider(provider);
        const address = await ethersProvider.resolveName(input);
        if (!cancelled) {
          setResolved({
            address,
            name: address ? input : null,
            isResolving: false,
          });
        }
      } catch {
        if (!cancelled) {
          setResolved({ address: null, name: null, isResolving: false });
        }
      }
    };

    const debounce = setTimeout(resolve, 600);
    return () => { cancelled = true; clearTimeout(debounce); };
  }, [provider, input]);

  return resolved;
}
```

### ENS-Aware Address Input

```tsx
function AddressInput({ value, onChange, provider, chainFamily }: {
  value: string;
  onChange: (value: string) => void;
  provider: any;
  chainFamily: ChainFamily;
}) {
  const isEVM = chainFamily === 'evm';
  const ens = isEVM ? useENSResolution(provider, value) : { address: null, name: null, isResolving: false };
  const validator = getAddressValidator(chainFamily);

  const resolvedAddress = ens.address || value;
  const isValid = resolvedAddress ? validator(resolvedAddress) : false;

  return (
    <div className="address-input-group">
      <input
        type="text"
        value={value}
        onChange={e => onChange(e.target.value)}
        placeholder={isEVM ? '0x... or ENS name' : '0x... or address'}
        spellCheck={false}
        autoComplete="off"
      />

      {ens.isResolving && <span className="resolving">Resolving...</span>}

      {ens.name && ens.address && (
        <div className="ens-resolved">
          <span className="ens-name">{ens.name}</span>
          <span className="ens-address">{shortenAddress(ens.address)}</span>
        </div>
      )}

      {value && !ens.isResolving && !isValid && (
        <span className="field-error">Invalid address</span>
      )}
    </div>
  );
}
```

## Mobile & In-App Browser Detection

Detect if the DApp is running inside a wallet's in-app browser:

```typescript
function detectEnvironment(): {
  isMobile: boolean;
  isInAppBrowser: boolean;
  walletName: string | null;
} {
  const ua = navigator.userAgent.toLowerCase();
  const isMobile = /android|iphone|ipad|ipod|mobile/i.test(ua);

  // Common wallet in-app browser signatures
  const walletSignatures: Record<string, string> = {
    'bitkeep': 'Bitget Wallet',
    'metamask': 'MetaMask',
    'trust': 'Trust Wallet',
    'coinbase': 'Coinbase Wallet',
    'tokenpocket': 'TokenPocket',
    'imtoken': 'imToken',
  };

  let walletName: string | null = null;
  for (const [key, name] of Object.entries(walletSignatures)) {
    if (ua.includes(key)) {
      walletName = name;
      break;
    }
  }

  return {
    isMobile,
    isInAppBrowser: isMobile && walletName !== null,
    walletName,
  };
}
```

### Responsive Adjustments for Mobile

```typescript
function useMobileLayout() {
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const check = () => setIsMobile(window.innerWidth < 768);
    check();
    window.addEventListener('resize', check);
    return () => window.removeEventListener('resize', check);
  }, []);

  return isMobile;
}
```

## Confirmation Dialog

For high-value or irreversible actions, show a confirmation before triggering the wallet:

```tsx
function ConfirmationDialog({ open, title, details, onConfirm, onCancel }: {
  open: boolean;
  title: string;
  details: { label: string; value: string }[];
  onConfirm: () => void;
  onCancel: () => void;
}) {
  if (!open) return null;

  return (
    <div className="dialog-overlay" onClick={onCancel}>
      <div className="dialog" onClick={e => e.stopPropagation()}>
        <h3>{title}</h3>
        <div className="dialog-details">
          {details.map(d => (
            <div key={d.label} className="detail-row">
              <span className="detail-label">{d.label}</span>
              <span className="detail-value">{d.value}</span>
            </div>
          ))}
        </div>
        <div className="dialog-actions">
          <button onClick={onCancel} className="btn-secondary">Cancel</button>
          <button onClick={onConfirm} className="btn-primary">Confirm</button>
        </div>
      </div>
    </div>
  );
}
```

### Usage: Pre-Wallet Confirmation

```typescript
// Before triggering the wallet popup, show an in-app preview:
const handleTransfer = async () => {
  setShowConfirm(true);  // Show ConfirmationDialog first
};

const handleConfirmed = async () => {
  setShowConfirm(false);
  // NOW trigger the wallet popup
  await sendTransaction(to, amount);
};
```

## Copy to Clipboard

Essential for addresses, signatures, and transaction hashes:

```tsx
function CopyButton({ text, label }: { text: string; label?: string }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    await navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <button onClick={handleCopy} className="copy-btn" title="Copy">
      {copied ? 'Copied!' : (label || 'Copy')}
    </button>
  );
}
```

## RPC Fallback & Retry

For read operations that don't go through the wallet provider:

```typescript
async function fetchWithRetry<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  baseDelay: number = 1000,
): Promise<T> {
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (err) {
      if (attempt === maxRetries) throw err;
      const delay = baseDelay * Math.pow(2, attempt);
      await new Promise(r => setTimeout(r, delay));
    }
  }
  throw new Error('Unreachable');
}

// Usage:
const balance = await fetchWithRetry(() => provider.getBalance(address));
```

## Best Practices Summary

1. **Skeleton loading** — show shimmering placeholders while data loads, never blank screens
2. **Toast notifications** — persistent toasts for transaction lifecycle, even across page navigation
3. **Empty states** — helpful messages with actionable CTAs (connect wallet, deposit tokens)
4. **ENS resolution** — accept `.eth` names in address fields (EVM), show resolved address below
5. **Pre-wallet confirmation** — show an in-app preview dialog BEFORE triggering the wallet popup
6. **Mobile detection** — detect in-app browsers, adjust layout for mobile viewports
7. **Copy buttons** — on addresses, signatures, tx hashes — always
8. **Retry with backoff** — RPC calls can fail; use exponential backoff for reads
9. **Progressive disclosure** — show essential info first, technical details on expand
10. **Debounce inputs** — don't call ENS resolution or gas estimation on every keystroke
