# Detection and Setup Reference

Detect Bitget Wallet, handle installation prompts, and determine the runtime environment.

## Prerequisites

No additional packages required for basic detection. For EIP-6963 multi-wallet discovery, no extra dependencies are needed — it uses browser-native `CustomEvent`.

## Provider Namespace

All Bitget Wallet providers live under `window.bitkeep`:

```typescript
interface BitkeepProviders {
  ethereum: EIP1193Provider;   // EVM chains
  solana: SolanaProvider;      // Solana
  unisat: UnisatProvider;      // Bitcoin
  ton: TonProvider;            // TON
  aptos: AptosProvider;        // Aptos
  keplr: KeplrProvider;        // Cosmos
  tronWeb: TronWebProvider;    // Tron (TronWeb instance)
  tronLink: TronLinkProvider;  // Tron (TronLink compat)
  suiWallet: SuiProvider;      // Sui
}

```

## Basic Detection

### Check if Bitget Wallet is Installed

```typescript
function getBitgetProvider(chain: 'ethereum' | 'solana' | 'unisat' | 'ton' | 'aptos' | 'keplr' | 'tronWeb' | 'suiWallet'): any | null {
  if (typeof window === 'undefined') return null;

  const provider = window.bitkeep?.[chain];
  if (!provider) {
    return null;
  }
  return provider;
}

function redirectToInstall(): void {
  const downloadUrl = 'https://web3.bitget.com/en/wallet-download';
  window.open(downloadUrl, '_blank');
}
```

### Detect with Timeout (Recommended)

Providers may inject asynchronously. Wait for them with a timeout:

```typescript
function detectBitgetWallet(
  chain: string = 'ethereum',
  timeout: number = 3000
): Promise<any> {
  return new Promise((resolve, reject) => {
    if (window.bitkeep?.[chain]) {
      return resolve(window.bitkeep[chain]);
    }

    const timer = setTimeout(() => {
      reject(new Error('Bitget Wallet not detected. Please install it.'));
    }, timeout);

    window.addEventListener('bitkeep#initialized', () => {
      clearTimeout(timer);
      if (window.bitkeep?.[chain]) {
        resolve(window.bitkeep[chain]);
      } else {
        reject(new Error(`Bitget Wallet ${chain} provider not available.`));
      }
    }, { once: true });
  });
}
```

### Usage

```typescript
async function init(): Promise<void> {
  try {
    const provider = await detectBitgetWallet('ethereum');
    console.log('Bitget Wallet detected:', provider);
  } catch (error) {
    console.log('Not installed, redirecting...');
    redirectToInstall();
  }
}
```

## Environment Detection

### Chrome Extension vs App Built-in Browser

```typescript
interface BitgetEnvironment {
  isChromeExtension: boolean;
  isAppBrowser: boolean;
  isBitgetWallet: boolean;
}

function detectEnvironment(): BitgetEnvironment {
  const isChromeExtension = !!(window as any).isBitKeepChrome;
  const isBitgetWallet = !!window.bitkeep;
  const isAppBrowser = isBitgetWallet && !isChromeExtension;

  return { isChromeExtension, isAppBrowser, isBitgetWallet };
}
```

**Key differences:**

| Feature | Chrome Extension | App Browser |
|---|---|---|
| `window.isBitKeepChrome` | `true` | `undefined` |
| Provider injection timing | After page load (async) | Immediate (sync) |
| EIP-6963 support | Yes | No |
| Multiple wallets coexist | Yes | No (only Bitget) |

### Server-Side Rendering (SSR) Guard

```typescript
function isBrowser(): boolean {
  return typeof window !== 'undefined' && typeof document !== 'undefined';
}

function safeGetProvider(chain: string = 'ethereum'): any | null {
  if (!isBrowser()) return null;
  return window.bitkeep?.[chain] ?? null;
}
```

## EIP-6963: Multi-Wallet Discovery

EIP-6963 allows DApps to discover all installed wallets without namespace conflicts. Bitget Wallet announces itself via this protocol.

### Bitget Wallet EIP-6963 Info

```typescript
const BITGET_WALLET_INFO = {
  uuid: crypto.randomUUID(),
  name: 'Bitget Wallet',
  icon: 'data:image/svg+xml;base64,...', // Bitget Wallet icon
  rdns: 'com.bitget.web3',
};
```

### Discovering Wallets via EIP-6963

```typescript
interface EIP6963ProviderInfo {
  uuid: string;
  name: string;
  icon: string;
  rdns: string;
}

interface EIP6963ProviderDetail {
  info: EIP6963ProviderInfo;
  provider: any;
}

interface EIP6963AnnounceProviderEvent extends CustomEvent {
  detail: EIP6963ProviderDetail;
}

const discoveredWallets: EIP6963ProviderDetail[] = [];

function discoverWallets(): EIP6963ProviderDetail[] {
  window.addEventListener(
    'eip6963:announceProvider',
    (event: Event) => {
      const e = event as EIP6963AnnounceProviderEvent;
      discoveredWallets.push(e.detail);
    }
  );

  window.dispatchEvent(new Event('eip6963:requestProvider'));

  return discoveredWallets;
}
```

### Finding Bitget Wallet from Discovered Wallets

```typescript
function findBitgetWallet(wallets: EIP6963ProviderDetail[]): EIP6963ProviderDetail | undefined {
  return wallets.find(w => w.info.rdns === 'com.bitget.web3');
}

async function connectViaBitget(): Promise<string[]> {
  const wallets = discoverWallets();

  await new Promise(resolve => setTimeout(resolve, 500));

  const bitget = findBitgetWallet(wallets);
  if (!bitget) {
    throw new Error('Bitget Wallet not found via EIP-6963');
  }

  const accounts: string[] = await bitget.provider.request({
    method: 'eth_requestAccounts',
  });

  return accounts;
}
```

## Compatibility Flags

Bitget Wallet sets compatibility flags so DApps built for other wallets work seamlessly:

| Provider | Flags Set | Purpose |
|---|---|---|
| `ethereum` | `isMetaMask: true`, `isBitKeep: true` | MetaMask-compatible DApps |
| `solana` | `isPhantom: true`, `isBitKeep: true` | Phantom-compatible DApps |
| `unisat` | `isBitKeep: true` | UniSat-compatible DApps |
| `ton` | `isOpenMask: true`, `isTonkeeper: true`, `isBitgetWallet: true` | Multi-wallet compat |
| `aptos` | (none — uses AIP-62 standard) | Petra-compatible |
| `keplr` | Keplr protocol compliance | Keplr-compatible DApps |

### Identifying Bitget Wallet Specifically

```typescript
function isBitgetWalletEVM(): boolean {
  const provider = window.bitkeep?.ethereum;
  return !!provider?.isBitKeep;
}

function isBitgetWalletSolana(): boolean {
  const provider = window.bitkeep?.solana;
  return !!provider?.isBitKeep;
}
```

## Error Handling

```typescript
interface DetectionError {
  code: string;
  message: string;
}

function handleDetectionError(error: DetectionError): void {
  if (error.message.includes('not detected') || error.message.includes('not installed')) {
    const shouldRedirect = confirm(
      'Bitget Wallet is not installed. Would you like to install it?'
    );
    if (shouldRedirect) {
      window.open('https://web3.bitget.com/en/wallet-download', '_blank');
    }
  }
}
```

## Complete Example

A full HTML page that detects Bitget Wallet, supports EIP-6963, and falls back gracefully:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Bitget Wallet Detection</title>
</head>
<body>
  <h1>Bitget Wallet Detection Demo</h1>
  <div id="status">Detecting wallet...</div>
  <button id="connectBtn" style="display:none">Connect Wallet</button>
  <button id="installBtn" style="display:none">Install Bitget Wallet</button>

  <script>
    const statusEl = document.getElementById('status');
    const connectBtn = document.getElementById('connectBtn');
    const installBtn = document.getElementById('installBtn');

    // Method 1: Direct detection
    function detectDirect() {
      return window.bitkeep?.ethereum ?? null;
    }

    // Method 2: EIP-6963
    let eip6963Provider = null;
    window.addEventListener('eip6963:announceProvider', (event) => {
      if (event.detail.info.rdns === 'com.bitget.web3') {
        eip6963Provider = event.detail.provider;
        onWalletFound(eip6963Provider, 'EIP-6963');
      }
    });
    window.dispatchEvent(new Event('eip6963:requestProvider'));

    // Fallback to direct detection after timeout
    setTimeout(() => {
      if (!eip6963Provider) {
        const direct = detectDirect();
        if (direct) {
          onWalletFound(direct, 'Direct');
        } else {
          onWalletNotFound();
        }
      }
    }, 1000);

    function onWalletFound(provider, method) {
      statusEl.textContent = `Bitget Wallet detected via ${method}`;
      connectBtn.style.display = 'inline-block';

      connectBtn.onclick = async () => {
        try {
          const accounts = await provider.request({
            method: 'eth_requestAccounts',
          });
          statusEl.textContent = `Connected: ${accounts[0]}`;
        } catch (err) {
          if (err.code === 4001) {
            statusEl.textContent = 'Connection rejected by user.';
          } else {
            statusEl.textContent = `Error: ${err.message}`;
          }
        }
      };
    }

    function onWalletNotFound() {
      statusEl.textContent = 'Bitget Wallet not detected.';
      installBtn.style.display = 'inline-block';
      installBtn.onclick = () => {
        window.open('https://web3.bitget.com/en/wallet-download', '_blank');
      };
    }
  </script>
</body>
</html>
```
