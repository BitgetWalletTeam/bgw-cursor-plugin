# Layout Reference

Standard DApp page structure, navigation, and responsive design patterns.

## Page Structure

Every DApp follows this layout hierarchy (modeled after Uniswap, Aave, OpenSea):

**Single-chain:**
```
┌─────────────────────────────────────────────────────────┐
│  Header: Logo | Nav | [Network] | WalletStatus          │
├─────────────────────────────────────────────────────────┤
```

**Multi-chain:**
```
┌─────────────────────────────────────────────────────────┐
│  Header: Logo | Nav | ChainFamilyTabs | WalletStatus    │
├───────────────────────────────┬─────────────────────────┤
│  [EVM SubChain Selector]      │  (only when EVM active) │
├───────────────────────────────┴─────────────────────────┤
```

**General:**
```
┌─────────────────────────────────────────────────────────┐
│  Header: Logo | Nav | ChainSelector | WalletStatus      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Main Content Area                                      │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Feature Card / Form                              │  │
│  │  (Transfer, Swap, Mint, Dashboard, etc.)          │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Secondary Content                                │  │
│  │  (TX History, Activity, Stats)                    │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  Footer: Links | Version                                │
└─────────────────────────────────────────────────────────┘
```

## Layout Component

```tsx
interface LayoutProps {
  children: React.ReactNode;
  wallet: {
    account: string | null;
    chainId: number | null;
    isConnected: boolean;
    isConnecting: boolean;
    connect: () => void;
    disconnect: () => void;
  };
  supportedChains: ChainConfig[];
  onSwitchChain: (chainId: number) => Promise<void>;
  title?: string;
  navItems?: { label: string; path: string; active?: boolean }[];
}

function Layout({ children, wallet, supportedChains, onSwitchChain, title, navItems }: LayoutProps) {
  const isSupported = wallet.chainId ? supportedChains.some(c => c.chainId === wallet.chainId) : true;

  return (
    <div className="dapp-layout">
      <header className="dapp-header">
        <div className="header-left">
          {title && <h1 className="app-title">{title}</h1>}
          {navItems && (
            <nav className="main-nav">
              {navItems.map(item => (
                <a key={item.path} href={item.path}
                   className={item.active ? 'nav-active' : ''}>
                  {item.label}
                </a>
              ))}
            </nav>
          )}
        </div>
        <div className="header-right">
          {wallet.isConnected && (
            <ChainSelector
              currentChainId={wallet.chainId}
              supportedChains={supportedChains}
              onSwitch={onSwitchChain}
            />
          )}
          <WalletStatus
            account={wallet.account}
            chainId={wallet.chainId}
            isConnected={wallet.isConnected}
            isConnecting={wallet.isConnecting}
            onConnect={wallet.connect}
            onDisconnect={wallet.disconnect}
          />
        </div>
      </header>

      {wallet.isConnected && !isSupported && wallet.chainId && (
        <UnsupportedChainBanner
          currentChainId={wallet.chainId}
          supportedChains={supportedChains}
          onSwitch={onSwitchChain}
        />
      )}

      <main className="dapp-main">
        {children}
      </main>

      <footer className="dapp-footer">
        <span>Powered by Web3</span>
      </footer>
    </div>
  );
}
```

## Multi-Page Navigation

For DApps with multiple features, use tabs or a sidebar:

```tsx
interface TabItem {
  id: string;
  label: string;
  icon?: string;
}

function TabNav({ tabs, activeTab, onSelect }: {
  tabs: TabItem[];
  activeTab: string;
  onSelect: (id: string) => void;
}) {
  return (
    <div className="tab-nav" role="tablist">
      {tabs.map(tab => (
        <button
          key={tab.id}
          role="tab"
          aria-selected={tab.id === activeTab}
          className={`tab-btn ${tab.id === activeTab ? 'tab-active' : ''}`}
          onClick={() => onSelect(tab.id)}
        >
          {tab.icon && <span className="tab-icon">{tab.icon}</span>}
          {tab.label}
        </button>
      ))}
    </div>
  );
}
```

## Responsive Design

DApps must work on desktop and mobile:

```css
/* Base layout */
.dapp-layout {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.dapp-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 24px;
  border-bottom: 1px solid var(--border-color, #e2e8f0);
  gap: 16px;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.dapp-main {
  flex: 1;
  max-width: 560px;
  width: 100%;
  margin: 40px auto;
  padding: 0 16px;
}

.dapp-footer {
  padding: 16px 24px;
  text-align: center;
  color: var(--text-muted, #94a3b8);
  font-size: 14px;
}

/* Responsive: mobile */
@media (max-width: 768px) {
  .dapp-header {
    flex-wrap: wrap;
    padding: 12px 16px;
  }

  .header-right {
    width: 100%;
    justify-content: space-between;
  }

  .dapp-main {
    margin: 16px auto;
    padding: 0 12px;
  }

  .main-nav {
    display: none; /* Use hamburger menu on mobile */
  }
}
```

## Card Component

The standard content wrapper:

```tsx
function Card({ title, children, className }: {
  title?: string;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div className={`card ${className || ''}`}>
      {title && <h2 className="card-title">{title}</h2>}
      {children}
    </div>
  );
}
```

```css
.card {
  background: var(--card-bg, #ffffff);
  border: 1px solid var(--border-color, #e2e8f0);
  border-radius: 16px;
  padding: 24px;
  margin-bottom: 16px;
}

.card-title {
  font-size: 18px;
  font-weight: 600;
  margin: 0 0 16px;
}
```

## Dark Mode Support

```css
:root {
  --bg: #ffffff;
  --card-bg: #ffffff;
  --text: #1a202c;
  --text-muted: #94a3b8;
  --border-color: #e2e8f0;
  --primary: #3b82f6;
  --error: #ef4444;
  --success: #10b981;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg: #0f172a;
    --card-bg: #1e293b;
    --text: #f1f5f9;
    --text-muted: #64748b;
    --border-color: #334155;
    --primary: #60a5fa;
    --error: #f87171;
    --success: #34d399;
  }
}

body {
  background: var(--bg);
  color: var(--text);
}
```

## Best Practices

1. **Header is non-negotiable** — always show wallet status and active chain in the header
2. **Show chain family prominently** — users must know if they're on EVM, Solana, Bitcoin, etc.
3. **Center the main content** — max-width 480-560px for forms (Uniswap pattern)
4. **Use cards** — group related functionality in rounded cards
5. **Support dark mode** — use CSS custom properties, respect system preference
6. **Responsive first** — test on mobile viewports
7. **Clear navigation** — if multi-page, use tabs or sidebar, not hidden menus
8. **Don't clutter** — show one primary action per page/card
9. **Provide tab structure** — separate Transfer / Sign / History into tabs
10. **Chain-family tabs for multi-chain** — put chain family tabs (EVM / Solana / Bitcoin / ...) at the top level, not buried in a dropdown
