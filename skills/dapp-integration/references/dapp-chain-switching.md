# Chain Switching Reference

Standard patterns for chain selection, switching, and multi-chain support in DApps.

## Two Levels of Chain Switching

In multi-chain DApps, there are two distinct levels:

1. **Chain Family switching** — switching between EVM, Solana, Bitcoin, TON, etc.
   - Each family has a different provider, different API, different address format
   - Switching family = switching everything (connection, balance, transfer, signing logic)

2. **Sub-chain switching** (EVM only) — switching between Ethereum, BSC, Polygon, Arbitrum, etc.
   - Same provider (`window.ethereum`), same API (`eth_requestAccounts`)
   - Uses `wallet_switchEthereumChain` / `wallet_addEthereumChain`

```
┌────────────────────────────────────────────────────────────┐
│ Chain Family:  [ EVM ]  [ Solana ]  [ Bitcoin ]  [ TON ]   │  ← Level 1
├────────────────────────────────────────────────────────────┤
│ Sub-chain:     Ethereum ▼  (Polygon, Arbitrum, Base...)    │  ← Level 2 (EVM only)
└────────────────────────────────────────────────────────────┘
```

## Chain Family Selector

For DApps supporting multiple chain families:

```tsx
function ChainFamilySelector({ families, active, onSelect }: {
  families: ChainFamily[];
  active: ChainFamily;
  onSelect: (f: ChainFamily) => void;
}) {
  const labels: Record<ChainFamily, string> = {
    evm: 'EVM', solana: 'Solana', bitcoin: 'Bitcoin',
    ton: 'TON', aptos: 'Aptos', cosmos: 'Cosmos', tron: 'Tron', sui: 'Sui',
  };

  return (
    <div className="chain-family-selector" role="tablist">
      {families.map(f => (
        <button key={f} role="tab" aria-selected={f === active}
          className={f === active ? 'active' : ''} onClick={() => onSelect(f)}>
          {labels[f]}
        </button>
      ))}
    </div>
  );
}
```

## EVM Sub-Chain Selector

Only shown when the active chain family is EVM:

## Chain Selector Component

Every multi-chain DApp needs a visible chain selector. Never assume a single chain.

```tsx
interface ChainSelectorProps {
  currentChainId: number | null;
  supportedChains: ChainConfig[];
  onSwitch: (chainId: number) => Promise<void>;
}

function ChainSelector({ currentChainId, supportedChains, onSwitch }: ChainSelectorProps) {
  const [switching, setSwitching] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSwitch = async (chainId: number) => {
    if (chainId === currentChainId) return;
    setSwitching(true);
    setError(null);
    try {
      await onSwitch(chainId);
    } catch (err: any) {
      setError(getUserFriendlyError(err));
    } finally {
      setSwitching(false);
    }
  };

  const current = currentChainId ? CHAINS[currentChainId] : null;

  return (
    <div className="chain-selector">
      <select
        value={currentChainId || ''}
        onChange={e => handleSwitch(Number(e.target.value))}
        disabled={switching}
      >
        {!current && <option value="">Select Network</option>}
        {supportedChains.map(chain => (
          <option key={chain.chainId} value={chain.chainId}>
            {chain.name} {chain.isTestnet ? '(Testnet)' : ''}
          </option>
        ))}
      </select>
      {switching && <span className="switching-indicator">Switching...</span>}
      {error && <span className="chain-error">{error}</span>}
    </div>
  );
}
```

## Chain Switching Hook

```typescript
function useChainSwitch(provider: any) {
  const switchChain = useCallback(async (chainId: number) => {
    if (!provider) throw new Error('No wallet connected');

    const hexChainId = '0x' + chainId.toString(16);

    try {
      await provider.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: hexChainId }],
      });
    } catch (error: any) {
      // Chain not added to wallet — try adding it
      if (error.code === 4902) {
        const chain = CHAINS[chainId];
        if (!chain) throw new Error(`Unknown chain: ${chainId}`);

        await provider.request({
          method: 'wallet_addEthereumChain',
          params: [{
            chainId: hexChainId,
            chainName: chain.name,
            nativeCurrency: { name: chain.symbol, symbol: chain.symbol, decimals: chain.decimals },
            rpcUrls: [chain.rpcUrl],
            blockExplorerUrls: [chain.explorerUrl],
          }],
        });
      } else {
        throw error;
      }
    }
  }, [provider]);

  return { switchChain };
}
```

## Unsupported Chain Warning

When the user is on a chain your DApp doesn't support:

```tsx
function UnsupportedChainBanner({ currentChainId, supportedChains, onSwitch }: {
  currentChainId: number;
  supportedChains: ChainConfig[];
  onSwitch: (chainId: number) => Promise<void>;
}) {
  const currentName = CHAINS[currentChainId]?.name || `Chain ${currentChainId}`;
  const defaultChain = supportedChains[0];

  return (
    <div className="unsupported-chain-banner" role="alert">
      <p>
        <strong>Unsupported network:</strong> {currentName} is not supported by this DApp.
      </p>
      <button onClick={() => onSwitch(defaultChain.chainId)}>
        Switch to {defaultChain.name}
      </button>
    </div>
  );
}
```

## Network Indicator

Show mainnet vs testnet clearly — users must never accidentally transact on mainnet when they expect testnet:

```tsx
function NetworkIndicator({ chainId }: { chainId: number }) {
  const chain = CHAINS[chainId];
  if (!chain) return null;

  return (
    <span className={`network-badge ${chain.isTestnet ? 'testnet' : 'mainnet'}`}>
      {chain.name}
      {chain.isTestnet && <span className="testnet-label"> (Testnet)</span>}
    </span>
  );
}
```

## Non-EVM Chain Notes

For non-EVM chains, there is no `wallet_switchEthereumChain` equivalent. Each chain family typically has a single network (mainnet/testnet). The switching UX differs:

| Chain Family | Sub-chain Switching | Network Toggle |
|---|---|---|
| EVM | `wallet_switchEthereumChain` between Ethereum/BSC/Polygon/etc. | Mainnet ↔ Testnet via chain ID |
| Solana | N/A (single chain) | Mainnet ↔ Devnet via RPC endpoint change |
| Bitcoin | N/A (single chain) | Mainnet ↔ Testnet via wallet config |
| TON | N/A (single chain) | Mainnet ↔ Testnet via wallet config |
| Aptos | N/A (single chain) | Mainnet ↔ Testnet/Devnet via wallet config |
| Cosmos | Different chains (Cosmos Hub, Osmosis, etc.) via `experimentalSuggestChain` | Per chain |
| Tron | N/A (single chain) | Mainnet ↔ Shasta/Nile |
| Sui | N/A (single chain) | Mainnet ↔ Testnet/Devnet |

For non-EVM chains, the DApp should provide a **mainnet/testnet toggle** rather than a sub-chain dropdown.

## Best Practices

1. **Show current chain family + sub-chain** — "Solana (Mainnet)" or "EVM > Polygon"
2. **Support `wallet_addEthereumChain`** — handle 4902 errors by adding the chain (EVM)
3. **Warn on unsupported chains** — don't silently fail, show a banner with a switch button
4. **Distinguish testnet** — use visual indicators (color, label) for test networks
5. **Update all state on chain change** — balance, tokens, and RPC must refresh
6. **Define supported chains in config** — don't scatter chain IDs across components
7. **Two-level selector for multi-chain DApps** — chain family tabs on top, sub-chain dropdown (if EVM) below
8. **Handle wallet limitations** — some wallets may not support testnet for non-EVM chains; show a graceful message
