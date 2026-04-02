# Wallet Connection Reference

Standard patterns for connecting, disconnecting, and managing wallet state in DApps.

## Connection Hook

```typescript
import { useState, useEffect, useCallback } from 'react';

interface WalletState {
  account: string | null;
  chainId: number | null;
  isConnected: boolean;
  isConnecting: boolean;
  error: string | null;
}

function useWalletConnection(provider: any) {
  const [state, setState] = useState<WalletState>({
    account: null,
    chainId: null,
    isConnected: false,
    isConnecting: false,
    error: null,
  });

  const connect = useCallback(async () => {
    if (!provider) {
      setState(s => ({ ...s, error: 'Wallet not detected. Please install a wallet extension.' }));
      return;
    }
    setState(s => ({ ...s, isConnecting: true, error: null }));
    try {
      const accounts: string[] = await provider.request({ method: 'eth_requestAccounts' });
      const chainIdHex: string = await provider.request({ method: 'eth_chainId' });
      setState({
        account: accounts[0],
        chainId: parseInt(chainIdHex, 16),
        isConnected: true,
        isConnecting: false,
        error: null,
      });
    } catch (err: any) {
      setState(s => ({
        ...s,
        isConnecting: false,
        error: err.code === 4001 ? 'Connection rejected.' : err.message,
      }));
    }
  }, [provider]);

  const disconnect = useCallback(() => {
    setState({ account: null, chainId: null, isConnected: false, isConnecting: false, error: null });
  }, []);

  useEffect(() => {
    if (!provider) return;

    const handleAccountsChanged = (accounts: string[]) => {
      if (accounts.length === 0) {
        disconnect();
      } else {
        setState(s => ({ ...s, account: accounts[0] }));
      }
    };

    const handleChainChanged = (chainIdHex: string) => {
      setState(s => ({ ...s, chainId: parseInt(chainIdHex, 16) }));
    };

    provider.on('accountsChanged', handleAccountsChanged);
    provider.on('chainChanged', handleChainChanged);

    return () => {
      provider.removeListener('accountsChanged', handleAccountsChanged);
      provider.removeListener('chainChanged', handleChainChanged);
    };
  }, [provider, disconnect]);

  // Auto-reconnect on page load
  useEffect(() => {
    if (!provider) return;
    provider.request({ method: 'eth_accounts' }).then((accounts: string[]) => {
      if (accounts.length > 0) {
        connect();
      }
    }).catch(() => {});
  }, [provider, connect]);

  return { ...state, connect, disconnect };
}
```

## Wallet Status Component

Always display wallet status in the header. Never hide connection state.

```tsx
interface WalletStatusProps {
  account: string | null;
  chainId: number | null;
  isConnected: boolean;
  isConnecting: boolean;
  onConnect: () => void;
  onDisconnect: () => void;
}

function WalletStatus({ account, chainId, isConnected, isConnecting, onConnect, onDisconnect }: WalletStatusProps) {
  if (!isConnected) {
    return (
      <button onClick={onConnect} disabled={isConnecting}>
        {isConnecting ? 'Connecting...' : 'Connect Wallet'}
      </button>
    );
  }

  const chainName = chainId ? (CHAINS[chainId]?.name || `Chain ${chainId}`) : 'Unknown';

  return (
    <div className="wallet-status">
      <span className="chain-badge">{chainName}</span>
      <span className="address">{shortenAddress(account || '')}</span>
      <button onClick={onDisconnect}>Disconnect</button>
    </div>
  );
}
```

## Wallet Guard

Wrap pages that require a connected wallet:

```tsx
interface WalletGuardProps {
  isConnected: boolean;
  onConnect: () => void;
  children: React.ReactNode;
}

function WalletGuard({ isConnected, onConnect, children }: WalletGuardProps) {
  if (!isConnected) {
    return (
      <div className="wallet-guard">
        <h2>Wallet Required</h2>
        <p>Connect your wallet to use this feature.</p>
        <button onClick={onConnect}>Connect Wallet</button>
      </div>
    );
  }
  return <>{children}</>;
}
```

## Multi-Wallet Selection

When supporting multiple wallets, present a selection modal:

```tsx
interface WalletOption {
  name: string;
  icon: string;
  provider: any;
}

function WalletSelector({ wallets, onSelect }: { wallets: WalletOption[]; onSelect: (w: WalletOption) => void }) {
  return (
    <div className="wallet-selector">
      <h3>Select a Wallet</h3>
      {wallets.map(w => (
        <button key={w.name} onClick={() => onSelect(w)} className="wallet-option">
          <img src={w.icon} alt={w.name} width={32} height={32} />
          <span>{w.name}</span>
        </button>
      ))}
    </div>
  );
}
```

## Multi-Chain Connection

For DApps supporting multiple chain families, manage each connection independently:

```typescript
interface ChainConnection {
  family: ChainFamily;
  name: string;
  account: string | null;
  isConnected: boolean;
  connect: () => Promise<void>;
  disconnect: () => void;
}

function useMultiChainConnection(chains: ChainFamily[]): {
  connections: ChainConnection[];
  activeChain: ChainFamily | null;
  setActiveChain: (chain: ChainFamily) => void;
} {
  const [activeChain, setActiveChain] = useState<ChainFamily | null>(chains[0] || null);

  // Each chain family has its own connect/disconnect logic
  // EVM: provider.request({ method: 'eth_requestAccounts' })
  // Solana: provider.connect()
  // Bitcoin: provider.requestAccounts()
  // TON: provider.send('ton_requestAccounts')
  // Aptos: provider.connect()
  // ... etc (see wallet-specific skill for actual API calls)

  // The key pattern: connections are INDEPENDENT per chain family
  // User can be connected to Ethereum AND Solana at the same time
  // UI shows which chain is "active" for operations

  return { connections, activeChain, setActiveChain };
}
```

### Chain Family Tabs Component

```tsx
function ChainFamilyTabs({ families, active, onSelect, connections }: {
  families: ChainFamily[];
  active: ChainFamily;
  onSelect: (f: ChainFamily) => void;
  connections: Record<ChainFamily, { isConnected: boolean; account: string | null }>;
}) {
  const familyNames: Record<ChainFamily, string> = {
    evm: 'EVM', solana: 'Solana', bitcoin: 'Bitcoin',
    ton: 'TON', aptos: 'Aptos', cosmos: 'Cosmos', tron: 'Tron', sui: 'Sui',
  };

  return (
    <div className="chain-family-tabs" role="tablist">
      {families.map(f => (
        <button
          key={f}
          role="tab"
          aria-selected={f === active}
          className={`chain-tab ${f === active ? 'active' : ''}`}
          onClick={() => onSelect(f)}
        >
          {familyNames[f]}
          {connections[f]?.isConnected && <span className="connected-dot" />}
        </button>
      ))}
    </div>
  );
}
```

## Best Practices

1. **Auto-reconnect** — check accounts on load; reconnect silently if previously connected
2. **Listen to events** — always handle `accountsChanged` and `chainChanged` (EVM), `disconnect` (Solana), etc.
3. **Show connection state** — never leave users guessing if they're connected
4. **Handle rejection gracefully** — 4001 is not an error, it's a user choice
5. **Provide disconnect** — users must be able to disconnect at any time
6. **Independent chain connections** — in multi-chain DApps, each chain family connects independently
7. **Show active chain clearly** — use tabs or a prominent selector so users know which chain they're operating on
