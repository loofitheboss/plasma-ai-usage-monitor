# Contributing to AI Usage Monitor

Thank you for your interest in contributing to the AI Usage Monitor plasmoid. This document covers how to set up the project for development, coding standards, and the contribution workflow.

## Development Setup

### Prerequisites

Fedora 43 KDE (or any distro with KDE Plasma 6):

```bash
sudo dnf install cmake extra-cmake-modules gcc-c++ \
    qt6-qtbase-devel qt6-qtdeclarative-devel libplasma-devel \
    kf6-kwallet-devel kf6-ki18n-devel kf6-knotifications-devel
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
| `ProviderBackend` | `plugin/providerbackend.{h,cpp}` | Abstract base for all providers |
| `OpenAIProvider` | `plugin/openaiprovider.{h,cpp}` | OpenAI usage/costs/rate-limit integration |
| `AnthropicProvider` | `plugin/anthropicprovider.{h,cpp}` | Anthropic rate-limit header parsing |
| `GoogleProvider` | `plugin/googleprovider.{h,cpp}` | Google Gemini connectivity + static limits |

## Coding Standards

### C++

- C++20 standard
- Follow existing naming conventions: `camelCase` for methods and variables, `PascalCase` for class names
- Use `Q_EMIT` instead of bare `emit`
- Use `QStringLiteral()` for string literals
- All Q_PROPERTYs must have NOTIFY signals
- New providers should inherit from `ProviderBackend` and implement the pure virtual `refresh()` method

### QML

- Plasma 6 APIs only (`import org.kde.plasma.plasmoid`, `import org.kde.kirigami as Kirigami`)
- Config pages must use `KCM.SimpleKCM` as root element (from `org.kde.kcmutils`)
- Use `Kirigami.Units` and `Kirigami.Theme` for sizing and colors — no hardcoded pixel values or colors
- Child components access root PlasmoidItem properties via the `root` id (dynamic scoping)

## Adding a New Provider

1. Create `plugin/newprovider.h` and `plugin/newprovider.cpp` inheriting from `ProviderBackend`
2. Implement `refresh()` to call the provider's API and update properties
3. Register the type in `plugin/aiusageplugin.cpp`
4. Add the provider to `plugin/qmldir`
5. Add config entries in `package/contents/config/main.xml`
6. Add UI elements in `configProviders.qml`
7. Instantiate the backend in `main.qml` and add a `ProviderCard` in `FullRepresentation.qml`

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
