# Token Approval Reference

Standard patterns for managing ERC-20 token approvals in DApps — the approve-before-transfer flow, allowance display, and security best practices.

> **Why this matters:** Over $1B in user losses in 2024-2025 came from token approval exploits. Infinite approvals let compromised contracts drain all tokens. DApps MUST handle approvals correctly.

## The Approve-Before-Transfer Pattern

ERC-20 tokens require a two-step flow: the user first approves a spender contract, then the contract calls `transferFrom`. This is NOT needed for native token transfers (ETH, BNB, etc.).

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Check        │────→│ Approve      │────→│ Transfer     │
│ Allowance    │     │ (if needed)  │     │ (transferFrom)│
└─────────────┘     └─────────────┘     └─────────────┘
       ↓                                       ↓
  Already enough?                         Done ✓
  Skip approve ───────────────────────────→
```

## Approval Hook

```typescript
import { BrowserProvider, Contract, MaxUint256, parseUnits, formatUnits } from 'ethers';

const ERC20_ABI = [
  'function allowance(address owner, address spender) view returns (uint256)',
  'function approve(address spender, uint256 amount) returns (bool)',
  'function decimals() view returns (uint8)',
  'function symbol() view returns (string)',
];

interface ApprovalState {
  allowance: bigint;
  isApproving: boolean;
  needsApproval: boolean;
  error: string | null;
}

function useTokenApproval(
  provider: any,
  tokenAddress: string,
  spenderAddress: string,
  account: string | null,
  requiredAmount: bigint,
) {
  const [state, setState] = useState<ApprovalState>({
    allowance: 0n,
    isApproving: false,
    needsApproval: true,
    error: null,
  });

  const checkAllowance = useCallback(async () => {
    if (!provider || !account || !tokenAddress || !spenderAddress) return;
    try {
      const ethersProvider = new BrowserProvider(provider);
      const contract = new Contract(tokenAddress, ERC20_ABI, ethersProvider);
      const current: bigint = await contract.allowance(account, spenderAddress);
      setState(s => ({
        ...s,
        allowance: current,
        needsApproval: current < requiredAmount,
      }));
    } catch {
      setState(s => ({ ...s, error: 'Failed to check allowance' }));
    }
  }, [provider, account, tokenAddress, spenderAddress, requiredAmount]);

  const approve = useCallback(async (amount?: bigint) => {
    if (!provider || !account) return;
    setState(s => ({ ...s, isApproving: true, error: null }));
    try {
      const ethersProvider = new BrowserProvider(provider);
      const signer = await ethersProvider.getSigner();
      const contract = new Contract(tokenAddress, ERC20_ABI, signer);

      // Use exact amount by default — NEVER infinite unless user explicitly opts in
      const approveAmount = amount || requiredAmount;
      const tx = await contract.approve(spenderAddress, approveAmount);
      await tx.wait();

      setState(s => ({
        ...s,
        allowance: approveAmount,
        needsApproval: false,
        isApproving: false,
      }));
    } catch (err: any) {
      setState(s => ({
        ...s,
        isApproving: false,
        error: getUserFriendlyError(err),
      }));
    }
  }, [provider, account, tokenAddress, spenderAddress, requiredAmount]);

  useEffect(() => { checkAllowance(); }, [checkAllowance]);

  return { ...state, approve, checkAllowance };
}
```

## Approval UI Component

Show the approval step clearly before the action button:

```tsx
interface ApprovalButtonProps {
  needsApproval: boolean;
  isApproving: boolean;
  onApprove: () => void;
  onAction: () => void;
  actionLabel: string;
  tokenSymbol: string;
  disabled?: boolean;
}

function ApprovalButton({
  needsApproval, isApproving, onApprove, onAction, actionLabel, tokenSymbol, disabled,
}: ApprovalButtonProps) {
  if (needsApproval) {
    return (
      <div className="approval-flow">
        <div className="approval-step">
          <span className="step-indicator">Step 1 of 2</span>
          <p>Approve {tokenSymbol} spending</p>
        </div>
        <button onClick={onApprove} disabled={isApproving || disabled}>
          {isApproving ? 'Approving...' : `Approve ${tokenSymbol}`}
        </button>
      </div>
    );
  }

  return (
    <button onClick={onAction} disabled={disabled}>
      {actionLabel}
    </button>
  );
}
```

## Allowance Display

Show current approvals so users know what's authorized:

```tsx
function AllowanceDisplay({ allowance, decimals, symbol, spenderName }: {
  allowance: bigint;
  decimals: number;
  symbol: string;
  spenderName: string;
}) {
  const isUnlimited = allowance >= MaxUint256 / 2n;
  const formatted = isUnlimited ? 'Unlimited' : formatUnits(allowance, decimals);

  return (
    <div className={`allowance-display ${isUnlimited ? 'warning' : ''}`}>
      <span>Approved for {spenderName}: </span>
      <span className="allowance-amount">
        {formatted} {symbol}
        {isUnlimited && <span className="warning-badge">⚠ Unlimited</span>}
      </span>
    </div>
  );
}
```

## Approval Amount Strategy

```typescript
enum ApprovalStrategy {
  EXACT = 'exact',         // Approve only what's needed — safest
  PADDED = 'padded',       // Approve 1.1x — avoids re-approval for price drift
  UNLIMITED = 'unlimited', // MaxUint256 — convenient but risky
}

function getApprovalAmount(
  required: bigint,
  strategy: ApprovalStrategy = ApprovalStrategy.EXACT,
): bigint {
  switch (strategy) {
    case ApprovalStrategy.EXACT:
      return required;
    case ApprovalStrategy.PADDED:
      return required + required / 10n; // +10%
    case ApprovalStrategy.UNLIMITED:
      return MaxUint256;
  }
}
```

## Security Rules

1. **Default to exact amounts** — never use `MaxUint256` unless the user explicitly chooses "Unlimited"
2. **Show what they're approving** — display the token, amount, and spender contract clearly
3. **Warn on unlimited** — if user chooses unlimited, show a warning explaining the risk
4. **Check before approve** — always check existing allowance first; skip if already sufficient
5. **Handle the approve-to-zero race** — some tokens (USDT) require setting allowance to 0 before changing it
6. **Show 2-step flow** — "Step 1: Approve" → "Step 2: Transfer" so users understand why there are two popups
7. **Support Permit2 when available** — for modern DeFi, prefer signature-based approvals over on-chain approve

## Best Practices

1. **Always check allowance before showing approve button** — don't force unnecessary approvals
2. **Default to exact-amount approvals** — safest for users
3. **Display current allowance** — users should see what's already approved
4. **Show approval status in transaction history** — "Approved 100 USDC for Uniswap"
5. **Consider Permit/Permit2** — gasless approvals via EIP-2612 when the token supports it
