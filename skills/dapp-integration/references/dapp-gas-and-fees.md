# Gas & Fees Reference

Standard patterns for gas estimation, fee preview, and cost transparency in DApps.

> **Why this matters:** Gas fee ambiguity is the #2 reason users abandon DApps (after wallet friction). Users need to know what they'll pay BEFORE confirming.

## Fee Preview Component

Show gas estimates before the user confirms any transaction:

```tsx
interface FeePreviewProps {
  gasLimit: bigint;
  gasPrice: bigint;            // wei
  maxFeePerGas?: bigint;       // EIP-1559
  maxPriorityFeePerGas?: bigint;
  chainSymbol: string;
  chainDecimals: number;
}

function FeePreview({ gasLimit, gasPrice, maxFeePerGas, maxPriorityFeePerGas, chainSymbol, chainDecimals }: FeePreviewProps) {
  const estimatedCost = gasLimit * (maxFeePerGas || gasPrice);
  const formatted = formatAmount(estimatedCost.toString(), chainDecimals);

  return (
    <div className="fee-preview">
      <div className="fee-row">
        <span>Estimated Gas Fee</span>
        <span className="fee-amount">~{formatted} {chainSymbol}</span>
      </div>
      <details className="fee-details">
        <summary>Details</summary>
        <div className="fee-breakdown">
          <div><span>Gas Limit</span><span>{gasLimit.toString()}</span></div>
          {maxFeePerGas ? (
            <>
              <div><span>Max Fee</span><span>{formatGwei(maxFeePerGas)} Gwei</span></div>
              <div><span>Priority Fee</span><span>{formatGwei(maxPriorityFeePerGas || 0n)} Gwei</span></div>
            </>
          ) : (
            <div><span>Gas Price</span><span>{formatGwei(gasPrice)} Gwei</span></div>
          )}
        </div>
      </details>
    </div>
  );
}

function formatGwei(wei: bigint): string {
  return (Number(wei) / 1e9).toFixed(2);
}
```

## Gas Estimation Hook

```typescript
import { BrowserProvider, parseEther } from 'ethers';

interface GasEstimate {
  gasLimit: bigint;
  gasPrice: bigint;
  maxFeePerGas: bigint | null;
  maxPriorityFeePerGas: bigint | null;
  estimatedCostWei: bigint;
  isLoading: boolean;
  error: string | null;
}

function useGasEstimate(provider: any, tx: { to: string; value?: bigint; data?: string } | null) {
  const [estimate, setEstimate] = useState<GasEstimate>({
    gasLimit: 0n, gasPrice: 0n, maxFeePerGas: null,
    maxPriorityFeePerGas: null, estimatedCostWei: 0n,
    isLoading: false, error: null,
  });

  useEffect(() => {
    if (!provider || !tx?.to) return;

    let cancelled = false;
    const fetchEstimate = async () => {
      setEstimate(s => ({ ...s, isLoading: true, error: null }));
      try {
        const ethersProvider = new BrowserProvider(provider);
        const [feeData, gasLimit] = await Promise.all([
          ethersProvider.getFeeData(),
          ethersProvider.estimateGas(tx),
        ]);

        if (cancelled) return;

        const effectiveGasPrice = feeData.maxFeePerGas || feeData.gasPrice || 0n;
        setEstimate({
          gasLimit,
          gasPrice: feeData.gasPrice || 0n,
          maxFeePerGas: feeData.maxFeePerGas,
          maxPriorityFeePerGas: feeData.maxPriorityFeePerGas,
          estimatedCostWei: gasLimit * effectiveGasPrice,
          isLoading: false,
          error: null,
        });
      } catch (err: any) {
        if (!cancelled) {
          setEstimate(s => ({ ...s, isLoading: false, error: err.message }));
        }
      }
    };

    const debounce = setTimeout(fetchEstimate, 500);
    return () => { cancelled = true; clearTimeout(debounce); };
  }, [provider, tx?.to, tx?.value?.toString(), tx?.data]);

  return estimate;
}
```

## Fee Tier Selector (EVM)

Let users choose speed vs cost:

```tsx
type FeeTier = 'slow' | 'standard' | 'fast';

interface FeeTierOption {
  tier: FeeTier;
  label: string;
  maxFeePerGas: bigint;
  maxPriorityFeePerGas: bigint;
  estimatedTime: string;
}

function useFeeTiers(provider: any): FeeTierOption[] {
  const [tiers, setTiers] = useState<FeeTierOption[]>([]);

  useEffect(() => {
    if (!provider) return;
    const fetch = async () => {
      const ethersProvider = new BrowserProvider(provider);
      const feeData = await ethersProvider.getFeeData();
      const baseFee = feeData.maxFeePerGas || feeData.gasPrice || 0n;

      setTiers([
        {
          tier: 'slow',
          label: 'Slow',
          maxFeePerGas: baseFee,
          maxPriorityFeePerGas: baseFee / 10n,
          estimatedTime: '~5 min',
        },
        {
          tier: 'standard',
          label: 'Standard',
          maxFeePerGas: baseFee * 3n / 2n,
          maxPriorityFeePerGas: baseFee / 5n,
          estimatedTime: '~30 sec',
        },
        {
          tier: 'fast',
          label: 'Fast',
          maxFeePerGas: baseFee * 2n,
          maxPriorityFeePerGas: baseFee / 2n,
          estimatedTime: '~15 sec',
        },
      ]);
    };
    fetch();
  }, [provider]);

  return tiers;
}

function FeeTierSelector({ tiers, selected, onSelect }: {
  tiers: FeeTierOption[];
  selected: FeeTier;
  onSelect: (tier: FeeTier) => void;
}) {
  return (
    <div className="fee-tier-selector">
      {tiers.map(t => (
        <button
          key={t.tier}
          className={`fee-tier ${t.tier === selected ? 'selected' : ''}`}
          onClick={() => onSelect(t.tier)}
        >
          <span className="tier-label">{t.label}</span>
          <span className="tier-time">{t.estimatedTime}</span>
          <span className="tier-cost">{formatGwei(t.maxFeePerGas)} Gwei</span>
        </button>
      ))}
    </div>
  );
}
```

## Non-EVM Fee Handling

Not all chains have gas in the EVM sense:

| Chain | Fee Model | What to Show |
|-------|-----------|-------------|
| EVM | Gas × Gas Price | Gas estimate in Gwei + total in ETH/BNB |
| Solana | Fixed base fee (5000 lamports) + priority fee | "Network fee: ~0.000005 SOL" |
| Bitcoin | Fee rate × tx size (sats/vByte) | "Network fee: ~X sats (Y BTC)" |
| TON | Compute + storage + forwarding fees | "Network fee: ~0.01 TON" |
| Aptos | Gas units × gas price | "Gas fee: ~X APT" |
| Cosmos | Gas × gas price | "Fee: X uatom" |
| Tron | Bandwidth + Energy | "Fee: ~X TRX (or 0 if bandwidth available)" |
| Sui | Computation + storage | "Gas budget: X SUI" |

For non-EVM chains where fees are simple and predictable, show a static estimate. For EVM, show dynamic gas estimation.

## Best Practices

1. **Always show fee estimate before confirmation** — never surprise users with costs
2. **Use progressive disclosure** — show total cost by default, details on expand
3. **Debounce gas estimates** — don't call `estimateGas` on every keystroke
4. **Provide fee tiers for EVM** — Slow / Standard / Fast with time estimates
5. **Show fees in native token** — not Gwei; convert to ETH/BNB for readability
6. **Handle estimation failures gracefully** — show "Fee estimate unavailable" instead of crashing
7. **Non-EVM chains can use static estimates** — Solana's base fee is predictable, Bitcoin fees come from mempool APIs
