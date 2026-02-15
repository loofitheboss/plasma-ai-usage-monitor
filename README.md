# AI Usage Monitor — KDE Plasma 6 Widget

A native KDE Plasma 6 plasmoid that monitors AI API token usage, rate limits, and costs across multiple providers. Sits in your panel as a compact icon with a colored status badge and expands into a detailed popup with per-provider stats.

**Supported providers:** OpenAI, Anthropic (Claude), Google Gemini

## Features

- **Real-time monitoring** — Periodic background polling with configurable refresh interval (default 5 min) and manual refresh
- **Token usage tracking** — Input/output tokens used, requests made, quota/tier limits
- **Cost tracking** — Dollar spending for OpenAI (the only provider with a billing API)
- **Rate limit visualization** — Progress bars with color-coded thresholds (green/yellow/red)
- **KDE notifications** — Desktop alerts when rate limits hit warning (80%) or critical (95%) thresholds
- **Secure key storage** — API keys stored in KWallet, never written to config files on disk
- **Panel status badge** — Compact icon shows green/yellow/red dot based on worst-case provider status
- **Per-provider configuration** — Enable/disable providers independently, select models, set project IDs

## What Each Provider Reports

| Metric | OpenAI | Anthropic | Google Gemini |
|--------|--------|-----------|---------------|
| Token usage (in/out) | Yes (real) | No | No |
| Rate limits remaining | Yes (headers) | Yes (headers) | No (static known limits) |
| Cost / spending | Yes (billing API) | No | No |
| Request count | Yes | Yes (from headers) | No |
| Connection status | Yes | Yes | Yes |

- **OpenAI** has the richest data: real usage from `/organization/usage/completions`, dollar costs from `/organization/costs`, and rate limits from response headers. Requires an **Admin API key**.
- **Anthropic** has no usage/billing API. The widget pings `/v1/messages/count_tokens` (lightweight, no token cost) and reads the `anthropic-ratelimit-*` response headers for rate limit data.
- **Google Gemini** has no usage API and no rate limit headers. The widget verifies connectivity via `countTokens` and displays known free-tier limits from documentation (e.g., Gemini Flash: 15 RPM / 1M TPM).

## Screenshots

*Screenshots coming soon — the widget is functional and can be added to any Plasma 6 panel or desktop.*

## Requirements

- **KDE Plasma 6** (Plasma 6.0+)
- **Qt 6** (Core, Qml, Quick, Network)
- **KDE Frameworks 6** (KWallet, KNotifications, KI18n)
- **Fedora 43 KDE** (tested) — should work on any distro with Plasma 6

### Build Dependencies (Fedora)

```
cmake
extra-cmake-modules
gcc-c++
qt6-qtbase-devel
qt6-qtdeclarative-devel
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
    qt6-qtbase-devel qt6-qtdeclarative-devel libplasma-devel \
    kf6-kwallet-devel kf6-ki18n-devel kf6-knotifications-devel

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

Right-click the widget and select **Configure** to access three settings tabs:

### General

- **Refresh interval** — How often to poll APIs (30s to 30min, default 5min)
- **Compact display mode** — What to show in the panel: icon only, current cost, or token count

### Providers

Each provider has:
- **Enable/disable** toggle
- **API key** field — Keys are stored in KWallet. Use the eye icon to show/hide, and the clear button to remove a key.
- **Model selector** — Choose which model to query (e.g., `gpt-4o`, `claude-sonnet-4-20250514`, `gemini-2.0-flash`)
- **Project ID** (OpenAI only) — Optional, to filter usage to a specific project

### Alerts

- **Master toggle** — Enable/disable all alerts
- **Warning threshold** — Percentage of rate limit to trigger a yellow warning (default 80%)
- **Critical threshold** — Percentage to trigger a red critical alert (default 95%)
- **Error notifications** — Toggle desktop notifications on API errors

## Architecture

```
plasma-ai-usage-monitor/
├── CMakeLists.txt                  # Root build system
├── install.sh                      # Build & install script
├── plasma-ai-usage-monitor.spec    # RPM packaging spec
├── package/                        # Plasmoid package (QML + metadata)
│   ├── metadata.json               # Plasma 6 plugin metadata
│   └── contents/
│       ├── config/
│       │   ├── config.qml          # Config tab definitions
│       │   └── main.xml            # KConfigXT schema (12 entries)
│       └── ui/
│           ├── main.qml            # Root PlasmoidItem
│           ├── CompactRepresentation.qml
│           ├── FullRepresentation.qml
│           ├── ProviderCard.qml    # Reusable provider stats card
│           ├── configGeneral.qml
│           ├── configProviders.qml
│           └── configAlerts.qml
└── plugin/                         # C++ QML plugin
    ├── CMakeLists.txt
    ├── qmldir                      # QML module registration
    ├── aiusageplugin.{h,cpp}       # QQmlExtensionPlugin
    ├── secretsmanager.{h,cpp}      # KWallet wrapper
    ├── providerbackend.{h,cpp}     # Abstract base class
    ├── openaiprovider.{h,cpp}      # OpenAI API integration
    ├── anthropicprovider.{h,cpp}   # Anthropic API integration
    └── googleprovider.{h,cpp}      # Google Gemini integration
```

### C++ Plugin

The QML plugin (`com.github.loofi.aiusagemonitor`) provides:

- **`SecretsManager`** — Wraps KWallet for secure API key storage. Uses wallet folder `"ai-usage-monitor"` with async open and a pending operations queue.
- **`ProviderBackend`** (abstract) — Base class with 16 Q_PROPERTYs (connected, loading, error, tokensUsed, tokensLimit, requestsUsed, requestsLimit, rateLimitRemaining, rateLimitTotal, costTotal, resetTime, etc.) and 5 signals.
- **`OpenAIProvider`** — Queries `GET /organization/usage/completions` and `GET /organization/costs`. Costs API returns cents (divided by 100). Reads `x-ratelimit-*` response headers.
- **`AnthropicProvider`** — Pings `POST /v1/messages/count_tokens`. Reads 12+ `anthropic-ratelimit-*` headers for request/token/input-token limits.
- **`GoogleProvider`** — Pings `POST /v1beta/models/{model}:countTokens`. Applies static known free-tier limits (Flash: 15 RPM/1M TPM, Pro: 2 RPM/32K TPM).

### QML Frontend

- **`main.qml`** — Instantiates C++ backends, manages the refresh timer, handles KWallet lifecycle, fires KDE notifications via `Notification` (KF6 type from `org.kde.notification`)
- **`CompactRepresentation.qml`** — Panel icon with a colored status badge reflecting worst-case provider status
- **`FullRepresentation.qml`** — Popup with header, refresh/settings buttons, and scrollable list of ProviderCard components
- **`ProviderCard.qml`** — Card showing connection status, token usage grid, cost display, and rate limit progress bars with color coding and reset countdown

## API Key Requirements

### OpenAI

You need an **Admin API key** (not a regular one) to access the usage and costs endpoints. Create one at [platform.openai.com/api-keys](https://platform.openai.com/api-keys) with the "Admin" role.

### Anthropic

A standard API key from [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys). The widget uses a lightweight `count_tokens` call that consumes no tokens.

### Google Gemini

A standard API key from [aistudio.google.com/apikey](https://aistudio.google.com/apikey). The widget only verifies connectivity and displays known tier limits.

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

## License

GPL-3.0-or-later. See [LICENSE](LICENSE) for the full text.

## Author

**Loofi** — [github.com/loofitheboss](https://github.com/loofitheboss)
