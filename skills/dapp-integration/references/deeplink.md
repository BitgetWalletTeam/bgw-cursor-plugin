# DeepLink Reference

Use Bitget Wallet DeepLinks (BKConnect) to open the wallet app from external applications, navigate to DApps, send transactions, and sign messages.

## URL Schemes

| Platform | URL Scheme |
|---|---|
| iOS | `bitkeep://bkconnect?{params}` |
| Android | `https://bkcode.vip?{params}` (Android only supports HTTPS scheme) |
| Universal | `https://bkcode.vip?{params}` |

## Common Parameters

### Request Parameters

| Name | Type | Required | Description |
|---|---|---|---|
| `action` | string | Yes | Action type |
| `actionID` | string | Yes | Unique action UUID |
| `version` | string | No | BKConnect version |
| `dappName` | string | No | DApp name |
| `dappIcon` | string | No | DApp icon URL |
| `redirectUrl` | string | No | Callback URL after action |

### Response Parameters

| Name | Type | Description |
|---|---|---|
| `status` | string | `0` = success, `1` = fail |
| `actionID` | string | Same as request |

## Actions

### Open DApp

Open a DApp URL inside Bitget Wallet's built-in browser.

- `action` = `dapp`

| Name | Type | Required | Description |
|---|---|---|---|
| `url` | string | Yes | DApp URL to open |

```typescript
function openDApp(url: string): void {
  const deepLink = `https://bkcode.vip?action=dapp&url=${encodeURIComponent(url)}`;
  window.open(deepLink);
}

// Example
openDApp('https://app.uniswap.org');
```

#### Switch Network in DApp

Append `_needChain` to the DApp URL:

```typescript
// Open DApp on BSC
openDApp('https://your-dapp.com?_needChain=bnb');

// Supported chain values: eth, bnb, ht (Heco), etc.
```

### Get Account

Get the user's wallet address for a specific chain.

- `action` = `getAccount`

| Name | Type | Required | Description |
|---|---|---|---|
| `chain` | string | Yes | Chain name (eth, btc, trx, etc.) |

**Response:** `address` - string

```typescript
function getAccountLink(chain: string): string {
  return `https://bkcode.vip?action=getAccount&chain=${chain}`;
}
```

### Send Transaction

Send a token transfer via the wallet.

- `action` = `send`

| Name | Type | Required | Description |
|---|---|---|---|
| `chain` | string | Yes | Chain name |
| `contract` | string | Yes | Token contract address (use `0x` for native token) |
| `to` | string | Yes | Recipient address |
| `amount` | string | Yes | Transfer amount |
| `memo` | string | No | Transaction memo/note |

**Response:** `hash` - string (transaction hash)

```typescript
function sendTransactionLink(params: {
  chain: string;
  contract: string;
  to: string;
  amount: string;
  memo?: string;
}): string {
  const queryParams = new URLSearchParams({
    action: 'send',
    chain: params.chain,
    contract: params.contract,
    to: params.to,
    amount: params.amount,
    ...(params.memo && { memo: params.memo }),
  });
  return `https://bkcode.vip?${queryParams.toString()}`;
}

// Example: Send 0.1 ETH
const link = sendTransactionLink({
  chain: 'eth',
  contract: '0x',
  to: '0xRecipientAddress...',
  amount: '0.1',
  memo: 'Payment',
});
```

### Add Token

Prompt the user to add a custom token to their wallet.

- `action` = `addAsset`

| Name | Type | Required | Description |
|---|---|---|---|
| `chain` | string | Yes | Chain name |
| `contract` | string | Yes | Token contract address |
| `symbol` | string | Yes | Token symbol |

```typescript
function addTokenLink(chain: string, contract: string, symbol: string): string {
  return `https://bkcode.vip?action=addAsset&chain=${chain}&contract=${contract}&symbol=${symbol}`;
}
```

### Sign Message

Request a message signature from the wallet.

- `action` = `sign`

| Name | Type | Required | Description |
|---|---|---|---|
| `chain` | string | Yes | Chain name |
| `signType` | string | Yes | Signature type |
| `msg` | string | Yes | Message to sign |

**Supported signType values:** `personal_sign`, `eth_signTypedData`, `eth_signTypedData_v3`, `eth_signTypedData_v4`

**Response:** `sign` - string (signature)

```typescript
function signMessageLink(
  chain: string,
  signType: string,
  msg: string
): string {
  return `https://bkcode.vip?action=sign&chain=${chain}&signType=${signType}&msg=${encodeURIComponent(msg)}`;
}

// Example: Personal sign
const link = signMessageLink('eth', 'personal_sign', 'Hello Bitget!');
```

## Platform-Specific Examples

### Web / H5

```typescript
function openBitgetWallet(action: string, params: Record<string, string>): void {
  const queryParams = new URLSearchParams({ action, ...params });
  const url = `https://bkcode.vip?${queryParams.toString()}`;
  window.location.href = url;
}
```

### iOS (Swift)

```swift
let url = "bitkeep://bkconnect?action=dapp&url=\(dappUrl)"
if let url = URL(string: url) {
    UIApplication.shared.open(url)
}
```

### Android (Kotlin)

```kotlin
val uri = Uri.Builder()
    .scheme("bitkeep")
    .authority("bkconnect")
    .appendQueryParameter("action", "dapp")
    .appendQueryParameter("url", dappUrl)
    .appendQueryParameter("version", "1")
    .build()

startActivity(Intent(Intent.ACTION_VIEW, uri))
```

### Flutter

```dart
final queryParameters = {
  'action': 'dapp',
  'url': dappUrl,
};

final scheme = Uri(scheme: 'bitkeep', queryParameters: queryParameters);
if (await canLaunchUrl(scheme)) {
  await launchUrl(scheme);
}
```

## App Not Installed — Fallback Logic

When the user doesn't have Bitget Wallet installed, the deep link silently fails. Use this pattern to detect and redirect to the download page:

```typescript
const DOWNLOAD_URL = 'https://web3.bitget.com/en/wallet-download';

function openOrInstall(deepLink: string): void {
  const timeout = setTimeout(() => {
    window.location.href = DOWNLOAD_URL;
  }, 2500);

  window.addEventListener('blur', () => clearTimeout(timeout), { once: true });
  window.location.href = deepLink;
}
```

## Handling Callback Responses

When the wallet completes an action, it redirects back to your `redirectUrl` with query parameters:

```typescript
function parseWalletCallback(): { success: boolean; data: Record<string, string> } {
  const params = new URLSearchParams(window.location.search);
  const status = params.get('status');
  const data: Record<string, string> = {};
  params.forEach((value, key) => { if (key !== 'status' && key !== 'actionID') data[key] = value; });
  return { success: status === '0', data };
}

// Usage: call on page load of your redirectUrl page
const result = parseWalletCallback();
if (result.success) {
  console.log('Transaction hash:', result.data.hash);
} else {
  console.log('Action failed or was cancelled');
}
```

## Error Handling

DeepLinks don't return errors directly. Handle errors by:

1. Using the fallback pattern above when the app isn't installed
2. Setting a `redirectUrl` parameter for the wallet to call back
3. Checking the `status` field in the redirect response (`0` = success, `1` = fail)

## Resources

- [DeepLink Documentation](https://web3.bitget.com/en/docs/reference/deeplink)
