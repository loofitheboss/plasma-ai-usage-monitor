# AI Usage Monitor — KDE Plasma 6 Widget

A native KDE Plasma 6 plasmoid that monitors AI API token usage, rate limits, and costs across multiple providers. Sits in your panel as a compact icon with a colored status badge and expands into a detailed popup with per-provider stats, usage history charts, and budget tracking.

**Supported providers:** OpenAI, Anthropic (Claude), Google Gemini, Mistral AI, DeepSeek, Groq, xAI (Grok)

## Features

- **Real-time monitoring** — Periodic background polling with configurable refresh interval (default 5 min) and manual refresh per provider
- **7 AI providers** — OpenAI, Anthropic, Google Gemini, Mistral AI, DeepSeek, Groq, xAI/Grok
- **Token usage tracking** — Input/output tokens used, requests made, quota/tier limits
- **Cost tracking** — Dollar spending with daily and monthly cost breakdowns
- **Budget management** — Per-provider daily/monthly budgets with configurable warning thresholds and notifications when budgets are exceeded
- **Usage history** — SQLite-backed persistence with configurable retention (7-365 days, default 90)
- **Interactive charts** — Canvas-based line/area charts showing cost, tokens, requests, and rate limit trends over 24h/7d/30d
- **Trend summaries** — Total cost, average daily cost, peak usage, and snapshot counts per time range
- **Rate limit visualization** — Progress bars with color-coded thresholds (green/yellow/red)
- **KDE notifications** — Desktop alerts for rate limit warnings, API errors, budget exceeded, provider disconnect/reconnect
- **Notification controls** — Per-provider toggles, cooldown period, Do Not Disturb schedule
- **Secure key storage** — API keys stored in KWallet, never written to config files on disk
- **Panel display modes** — Compact icon shows green/yellow/red status badge, or current cost, or active provider count
- **Proxy support** — Custom base URLs per provider for API proxies/gateways
- **Data export** — CSV and JSON export of usage history
- **Per-provider configuration** — Enable/disable providers independently, select models, set refresh intervals, configure budgets

## What Each Provider Reports

| Metric | OpenAI | Anthropic | Google | Mistral | DeepSeek | Groq | xAI |
|--------|--------|-----------|--------|---------|----------|------|-----|
| Token usage (in/out) | Yes | No | No | Yes | Yes | Yes | Yes |
| Rate limits remaining | Yes | Yes | No* | Yes | Yes | Yes | Yes |
| Cost / spending | Yes | No | No | Yes | Yes | Yes | Yes |
| Request count | Yes | Yes | No | Yes | Yes | Yes | Yes |
| Connection status | Yes | Yes | Yes | Yes | Yes | Yes | Yes |

*\* Google Gemini displays known free-tier limits from documentation (static).*

- **OpenAI** has the richest data: real usage from `/organization/usage/completions`, dollar costs from `/organization/costs`, and rate limits from response headers. Requires an **Admin API key**.
- **Anthropic** has no usage/billing API. The widget pings `/v1/messages/count_tokens` (lightweight, no token cost) and reads the `anthropic-ratelimit-*` response headers for rate limit data.
- **Google Gemini** has no usage API and no rate limit headers. The widget verifies connectivity via `countTokens` and displays known free-tier limits from documentation.
- **Mistral AI** queries `/v1/chat/completions` and reads rate limit headers. Supports cost estimation.
- **DeepSeek** queries `/chat/completions` and reads rate limit headers. Supports cost tracking.
- **Groq** queries `/openai/v1/chat/completions` and reads rate limit headers. Supports cost tracking.
- **xAI / Grok** queries `/v1/chat/completions` and reads rate limit headers. Supports cost tracking.

## Screenshots

*Screenshots coming soon — the widget is functional and can be added to any Plasma 6 panel or desktop.*

## Requirements

- **KDE Plasma 6** (Plasma 6.0+)
- **Qt 6** (Core, Qml, Quick, Network, Sql)
- **KDE Frameworks 6** (KWallet, KNotifications, KI18n)
- **Fedora 43 KDE** (tested) — should work on any distro with Plasma 6

### Build Dependencies (Fedora)

```
cmake
extra-cmake-modules
gcc-c++
qt6-qtbase-devel
qt6-qtdeclarative-devel
qt6-qtbase-sql
libplasma-devel
kf6-kwallet-devel
kf6-ki18n-devel
kf6-knotifications-devel
```

## Installation

### Quick Install (Fedora)

The included `install.sh` script checks dependencies, builds, and installs everything:

```bash
git clone https://github.com/loofitheboss/plasma-ai-usage-monitor.git
cd plasma-ai-usage-monitor
chmod +x install.sh
./install.sh
```

### Manual Build

```bash
# Install build dependencies (Fedora)
sudo dnf install cmake extra-cmake-modules gcc-c++ \
    qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtbase-sql \
    libplasma-devel kf6-kwallet-devel kf6-ki18n-devel kf6-knotifications-devel

# Build
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)

# Install (requires sudo for system QML plugin path)
sudo cmake --install .
```

### After Installation

1. Right-click your desktop or panel
2. Select **Add Widgets...**
3. Search for **AI Usage Monitor**
4. Drag it to your panel or desktop
5. Right-click the widget > **Configure** to add your API keys

To test without adding to a panel:
```bash
plasmawindowed com.github.loofi.aiusagemonitor
```

If the widget doesn't appear after installation:
```bash
plasmashell --replace &
```

## Configuration

Right-click the widget and select **Configure** to access five settings tabs:

### General

- **Refresh interval** — How often to poll APIs (30s to 30min, default 5min)
- **Compact display mode** — What to show in the panel: icon only, current cost, or active provider count
- **Per-provider refresh intervals** — Override the global interval for specific providers

### Providers

Each provider has:
- **Enable/disable** toggle
- **API key** field — Keys are stored in KWallet. Use the eye icon to show/hide, and the clear button to remove a key.
- **Model selector** — Choose which model to query (e.g., `gpt-4o`, `claude-sonnet-4-20250514`, `gemini-2.0-flash`, `mistral-large-latest`, `deepseek-chat`, `llama-3.3-70b-versatile`, `grok-3`)
- **Custom base URL** — Optional proxy/gateway URL override
- **Project ID** (OpenAI only) — Optional, to filter usage to a specific project

### Alerts

- **Master toggle** — Enable/disable all alerts
- **Warning threshold** — Percentage of rate limit to trigger a yellow warning (default 80%)
- **Critical threshold** — Percentage to trigger a red critical alert (default 95%)
- **Notification types** — Toggle API error, budget warning, provider disconnect, and provider reconnect notifications independently
- **Per-provider toggles** — Enable/disable notifications for specific providers
- **Cooldown** — Minimum minutes between repeated notifications (1-60, default 15)
- **Do Not Disturb** — Schedule a time window to suppress all notifications

### Budget

- **Per-provider daily and monthly budgets** — Set spending limits in dollars (e.g., $10.50/day, $100.00/month)
- **Warning percentage** — Trigger a warning at this percentage of budget (default 80%)

### History

- **Enable/disable** usage history recording
- **Retention period** — How long to keep data (7-365 days, default 90)
- **Database size** display
- **Prune** button to manually clean old data

## Architecture

```
plasma-ai-usage-monitor/
├── CMakeLists.txt                  # Root build system
├── install.sh                      # Build & install script
├── plasma-ai-usage-monitor.spec    # RPM packaging spec
├── plasma_applet_...notifyrc       # KDE notification events
├── package/                        # Plasmoid package (QML + metadata)
│   ├── metadata.json               # Plasma 6 plugin metadata
│   └── contents/
│       ├── config/
│       │   ├── config.qml          # Config tab definitions (5 tabs)
│       │   └── main.xml            # KConfigXT schema
│       └── ui/
│           ├── main.qml            # Root PlasmoidItem (7 providers, timers, notifications)
│           ├── CompactRepresentation.qml  # Panel icon (3 display modes)
│           ├── FullRepresentation.qml     # Popup with Live/History tabs
│           ├── ProviderCard.qml           # Provider stats card with budget bars
│           ├── CostSummaryCard.qml        # Aggregate cost breakdown
│           ├── UsageChart.qml             # Canvas line/area chart
│           ├── TrendSummary.qml           # Summary stats grid
│           ├── configGeneral.qml
│           ├── configProviders.qml
│           ├── configAlerts.qml
│           ├── configBudget.qml
│           └── configHistory.qml
└── plugin/                         # C++ QML plugin
    ├── CMakeLists.txt
    ├── qmldir                      # QML module registration
    ├── aiusageplugin.{h,cpp}       # QQmlExtensionPlugin (9 types)
    ├── secretsmanager.{h,cpp}      # KWallet wrapper
    ├── providerbackend.{h,cpp}     # Abstract base class
    ├── openaiprovider.{h,cpp}      # OpenAI API integration
    ├── anthropicprovider.{h,cpp}   # Anthropic API integration
    ├── googleprovider.{h,cpp}      # Google Gemini integration
    ├── mistralprovider.{h,cpp}     # Mistral AI integration
    ├── deepseekprovider.{h,cpp}    # DeepSeek integration
    ├── groqprovider.{h,cpp}        # Groq integration
    ├── xaiprovider.{h,cpp}         # xAI/Grok integration
    └── usagedatabase.{h,cpp}       # SQLite usage history persistence
```

### C++ Plugin

The QML plugin (`com.github.loofi.aiusagemonitor`) provides:

- **`SecretsManager`** — Wraps KWallet for secure API key storage. Uses wallet folder `"ai-usage-monitor"` with async open and a pending operations queue.
- **`ProviderBackend`** (abstract) — Base class with properties for token usage, rate limits, cost tracking, budget management, error tracking, and custom base URL support. Includes signals for quota warnings, budget exceeded, provider disconnect/reconnect.
- **`OpenAIProvider`** — Queries `GET /organization/usage/completions` and `GET /organization/costs`. Reads `x-ratelimit-*` response headers.
- **`AnthropicProvider`** — Pings `POST /v1/messages/count_tokens`. Reads `anthropic-ratelimit-*` headers.
- **`GoogleProvider`** — Pings `POST /v1beta/models/{model}:countTokens`. Applies static known free-tier limits.
- **`MistralProvider`** — Queries `/v1/chat/completions`. Reads rate limit headers and tracks cost.
- **`DeepSeekProvider`** — Queries `/chat/completions`. Reads rate limit headers and tracks cost.
- **`GroqProvider`** — Queries `/openai/v1/chat/completions`. Reads rate limit headers and tracks cost.
- **`XAIProvider`** — Queries `/v1/chat/completions`. Reads rate limit headers and tracks cost.
- **`UsageDatabase`** — SQLite persistence with WAL mode, configurable retention, auto-pruning, and CSV/JSON export.

### QML Frontend

- **`main.qml`** — Instantiates 7 C++ backends, manages refresh timers, handles KWallet lifecycle, fires KDE notifications with cooldown and DND support, records snapshots to UsageDatabase
- **`CompactRepresentation.qml`** — Panel icon with 3 display modes (icon with status badge, cost display, provider count) and smooth animations
- **`FullRepresentation.qml`** — Popup with status summary bar, tabbed Live/History view, provider cards, cost summary, chart, trend summary, and export buttons
- **`ProviderCard.qml`** — Card showing connection status, token usage, cost, rate limit bars, budget progress bars, error badges with expandable details, relative time display, and animations

## API Key Requirements

### OpenAI

You need an **Admin API key** (not a regular one) to access the usage and costs endpoints. Create one at [platform.openai.com/api-keys](https://platform.openai.com/api-keys) with the "Admin" role.

### Anthropic

A standard API key from [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys). The widget uses a lightweight `count_tokens` call that consumes no tokens.

### Google Gemini

A standard API key from [aistudio.google.com/apikey](https://aistudio.google.com/apikey). The widget only verifies connectivity and displays known tier limits.

### Mistral AI

A standard API key from [console.mistral.ai/api-keys](https://console.mistral.ai/api-keys).

### DeepSeek

A standard API key from [platform.deepseek.com/api_keys](https://platform.deepseek.com/api_keys).

### Groq

A standard API key from [console.groq.com/keys](https://console.groq.com/keys).

### xAI / Grok

A standard API key from [console.x.ai](https://console.x.ai).

## RPM Packaging

An RPM spec file is included for Fedora/RHEL packaging:

```bash
rpmbuild -ba plasma-ai-usage-monitor.spec
```

## Troubleshooting

**Widget doesn't appear after install:**
```bash
plasmashell --replace &
```

**QML plugin not found:**
The C++ plugin must be installed to the system QML path (`/usr/lib64/qt6/qml/` on Fedora). The `install.sh` script and CMake handle this automatically with `sudo`.

**KWallet not opening:**
Make sure KWallet is enabled in System Settings > KDE Wallet. The widget requires KWallet to store API keys securely.

**OpenAI returns 403:**
The usage/costs endpoints require an Admin API key. Regular API keys will get a 403 Forbidden response.

**Usage history not recording:**
Check that the History tab is enabled in configuration. Data is stored in `~/.local/share/plasma-ai-usage-monitor/usage_history.db`.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE) for the full text.

## Author

**Loofi** — [github.com/loofitheboss](https://github.com/loofitheboss)
