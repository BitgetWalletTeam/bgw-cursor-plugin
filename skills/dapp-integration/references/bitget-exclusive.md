# Bitget Exclusive APIs Reference

Launch Bitget Wallet's built-in Swap page directly from your DApp. Works in both Chrome Extension and Bitget Wallet App browser.

## Open Swap

Open the Bitget Wallet Swap page, optionally pre-filling a trading pair.

```typescript
interface SwapCoin {
  chain: string;      // chain identifier
  address?: string;   // token contract address
  symbol?: string;    // token symbol
}

interface SwapQuery {
  fromCoin?: SwapCoin;
  toCoin?: SwapCoin;
}

async function openSwap(query?: SwapQuery): Promise<void> {
  if (typeof window.bitkeep?.navigateTo === 'function') {
    await window.bitkeep.navigateTo('swap', query);
  } else {
    window.open('https://web3.bitget.com/en/swap');
  }
}

// Open swap page
await openSwap();

// Open swap with pre-selected tokens
await openSwap({
  fromCoin: { chain: 'eth', symbol: 'ETH' },
  toCoin: { chain: 'eth', address: '0xdAC17F958D2ee523a2206206994597C13D831ec7', symbol: 'USDT' },
});
```

> **Detection note:** `window.bitkeep.navigateTo` is an own property bound in the constructor — directly callable. Do **NOT** use `caniuse('bit_navigateTo')` for detection: `caniuse` is a class prototype method (non-enumerable) that is not available on the `window.bitkeep` proxy. Always fall back to `window.open(...)` when `navigateTo` is unavailable.

## Error Handling

```typescript
async function openSwapSafe(query?: SwapQuery): Promise<void> {
  try {
    if (typeof window.bitkeep?.navigateTo === 'function') {
      await window.bitkeep.navigateTo('swap', query);
    } else {
      window.open('https://web3.bitget.com/en/swap');
    }
  } catch (error: any) {
    console.error('Swap open failed:', error.message);
    window.open('https://web3.bitget.com/en/swap');
  }
}
```

## Complete Example

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Bitget Wallet — Open Swap Demo</title>
  <style>
    body { font-family: sans-serif; max-width: 640px; margin: 40px auto; padding: 0 20px; }
    button { margin: 8px 4px; padding: 8px 16px; cursor: pointer; }
    pre { background: #f4f4f4; padding: 12px; border-radius: 4px; overflow-x: auto; }
  </style>
</head>
<body>
  <h1>Bitget Wallet — Open Swap</h1>
  <button id="swapBtn">Open Swap</button>
  <pre id="output"></pre>

  <script>
    const outputEl = document.getElementById('output');
    const swapBtn = document.getElementById('swapBtn');

    function log(msg) { outputEl.textContent += msg + '\n'; }

    swapBtn.onclick = async () => {
      if (typeof window.bitkeep?.navigateTo === 'function') {
        try {
          await window.bitkeep.navigateTo('swap');
          log('Swap page opened');
        } catch (err) {
          log('Error: ' + err.message);
          window.open('https://web3.bitget.com/en/swap');
        }
      } else {
        window.open('https://web3.bitget.com/en/swap');
        log('Opened web swap fallback');
      }
    };
  </script>
</body>
</html>
```
