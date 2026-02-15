# Contributing to AI Usage Monitor

Thank you for your interest in contributing to the AI Usage Monitor plasmoid. This document covers how to set up the project for development, coding standards, and the contribution workflow.

## Development Setup

### Prerequisites

Fedora 43 KDE (or any distro with KDE Plasma 6):

```bash
sudo dnf install cmake extra-cmake-modules gcc-c++ \
    qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtbase-sql \
    libplasma-devel kf6-kwallet-devel kf6-ki18n-devel kf6-knotifications-devel
```

### Building

```bash
git clone https://github.com/loofitheboss/plasma-ai-usage-monitor.git
cd plasma-ai-usage-monitor
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug
make -j$(nproc)
```

### Installing for Testing

```bash
# Install the C++ QML plugin to the system path
sudo cmake --install build

# Or use the install script
./install.sh
```

### Testing Changes

After modifying QML files, restart Plasma Shell to pick up changes:

```bash
plasmashell --replace &
```

To test in a standalone window (without adding to panel):

```bash
plasmawindowed com.github.loofi.aiusagemonitor
```

## Project Structure

- **`package/`** — The plasmoid package (QML UI, metadata, config schema). Changes here are pure QML/JS and don't require a recompile, but do require `plasmashell --replace`.
- **`plugin/`** — C++ QML plugin providing backend classes. Changes here require a full rebuild and reinstall.

### Key Classes

| Class | File | Purpose |
|-------|------|---------|
| `SecretsManager` | `plugin/secretsmanager.{h,cpp}` | KWallet wrapper for API key storage |
| `ProviderBackend` | `plugin/providerbackend.{h,cpp}` | Abstract base for all providers (token usage, rate limits, cost, budget, errors, proxy support) |
| `OpenAIProvider` | `plugin/openaiprovider.{h,cpp}` | OpenAI usage/costs/rate-limit integration |
| `AnthropicProvider` | `plugin/anthropicprovider.{h,cpp}` | Anthropic rate-limit header parsing |
| `GoogleProvider` | `plugin/googleprovider.{h,cpp}` | Google Gemini connectivity + static limits |
| `MistralProvider` | `plugin/mistralprovider.{h,cpp}` | Mistral AI chat/rate-limit integration |
| `DeepSeekProvider` | `plugin/deepseekprovider.{h,cpp}` | DeepSeek chat/rate-limit integration |
| `GroqProvider` | `plugin/groqprovider.{h,cpp}` | Groq chat/rate-limit integration |
| `XAIProvider` | `plugin/xaiprovider.{h,cpp}` | xAI/Grok chat/rate-limit integration |
| `UsageDatabase` | `plugin/usagedatabase.{h,cpp}` | SQLite persistence for usage history, CSV/JSON export |

### QML Components

| Component | Purpose |
|-----------|---------|
| `main.qml` | Root PlasmoidItem — instantiates 7 backends, timers, notifications, database |
| `CompactRepresentation.qml` | Panel icon with 3 display modes (icon/cost/count) |
| `FullRepresentation.qml` | Popup with status bar, Live/History tabs, export buttons |
| `ProviderCard.qml` | Provider stats card with budget bars and error details |
| `CostSummaryCard.qml` | Aggregate cost breakdown across all providers |
| `UsageChart.qml` | Canvas line/area chart (cost/tokens/requests/rateLimit) |
| `TrendSummary.qml` | Summary stats grid for a time range |
| `configGeneral.qml` | General settings + per-provider refresh intervals |
| `configProviders.qml` | Provider enable/key/model/proxy settings (7 providers) |
| `configAlerts.qml` | Thresholds, notification types, per-provider toggles, cooldown, DND |
| `configBudget.qml` | Per-provider daily/monthly budgets |
| `configHistory.qml` | History enable/retention/prune settings |

## Coding Standards

### C++

- C++20 standard
- Follow existing naming conventions: `camelCase` for methods and variables, `PascalCase` for class names
- Use `Q_EMIT` instead of bare `emit`
- Use `QStringLiteral()` for string literals
- All Q_PROPERTYs must have NOTIFY signals
- New providers should inherit from `ProviderBackend` and implement the pure virtual `refresh()` method
- Use `effectiveBaseUrl(BASE_URL)` instead of hardcoded base URLs to support custom proxy URLs
- Budget values are managed through the base class — call `setDailyCost()` / `setMonthlyCost()` in your `refresh()` implementation

### QML

- Plasma 6 APIs only (`import org.kde.plasma.plasmoid`, `import org.kde.kirigami as Kirigami`)
- Config pages must use `KCM.SimpleKCM` as root element (from `org.kde.kcmutils`)
- Use `Kirigami.Units` and `Kirigami.Theme` for sizing and colors — no hardcoded pixel values or colors
- Child components access root PlasmoidItem properties via the `root` id (dynamic scoping)
- Budget config values are stored as integers in cents (e.g., 1050 = $10.50) — convert with `/ 100.0` when passing to C++ backends

### Config Conventions

- Budget entries in `main.xml` use `type="Int"` storing **cents** (not dollars)
- DND hours in `main.xml` use `type="Int"` with -1 meaning disabled and 0-23 for hours
- Config pages use explicit `property int` (not `property alias`) when the UI value differs from the stored config value

## Adding a New Provider

1. Create `plugin/newprovider.h` and `plugin/newprovider.cpp` inheriting from `ProviderBackend`
2. Implement `refresh()` to call the provider's API and update properties
3. Use `effectiveBaseUrl(BASE_URL)` for the API URL to support custom proxy URLs
4. Call `setDailyCost()` / `setMonthlyCost()` if the provider supports cost tracking
5. Register the type in `plugin/aiusageplugin.cpp`
6. Add the provider to `plugin/qmldir`
7. Add source files to `plugin/CMakeLists.txt`
8. Add config entries in `package/contents/config/main.xml` (enable, model, customBaseUrl, budget, notifications, refresh interval)
9. Add UI elements in `configProviders.qml`, `configBudget.qml`, `configAlerts.qml`, and `configGeneral.qml`
10. Instantiate the backend in `main.qml` with budget conversion (`/ 100.0`) and notification handlers
11. Add a `ProviderCard` in `FullRepresentation.qml`

## Contribution Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes and test locally
4. Ensure the project builds cleanly with no warnings (`-DCMAKE_BUILD_TYPE=Debug`)
5. Commit with clear, descriptive messages
6. Push to your fork and open a Pull Request

## Reporting Issues

Open an issue at [github.com/loofitheboss/plasma-ai-usage-monitor/issues](https://github.com/loofitheboss/plasma-ai-usage-monitor/issues) with:

- Your Plasma version (`plasmashell --version`)
- Your distro and version
- Steps to reproduce
- Any relevant error output from `journalctl --user -u plasma-plasmashell -f`

## License

By contributing, you agree that your contributions will be licensed under the GPL-3.0-or-later license.
