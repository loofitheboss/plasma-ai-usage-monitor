Name:           plasma-ai-usage-monitor
Version:        2.2.0
Release:        1%{?dist}
Summary:        KDE Plasma 6 widget to monitor AI API token usage, rate limits, and costs
License:        GPL-3.0-or-later
URL:            https://github.com/loofitheboss/plasma-ai-usage-monitor
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  cmake >= 3.16
BuildRequires:  extra-cmake-modules
BuildRequires:  gcc-c++
BuildRequires:  qt6-qtbase-devel
BuildRequires:  qt6-qtdeclarative-devel
BuildRequires:  libplasma-devel
BuildRequires:  kf6-kwallet-devel
BuildRequires:  kf6-ki18n-devel
BuildRequires:  kf6-knotifications-devel

Requires:       plasma-workspace >= 6.0
Requires:       kf6-kwallet
Requires:       kf6-kirigami
Requires:       kf6-kcmutils
Requires:       qt6-qtbase-sql

%description
A native KDE Plasma 6 plasmoid that monitors AI API token usage,
rate limits, costs, and budgets across multiple providers including
OpenAI, Anthropic (Claude), Google (Gemini), Mistral AI, DeepSeek,
Groq, and xAI (Grok).

Features:
- Real-time rate limit monitoring for all providers
- Usage and cost tracking with historical trends
- Token-based cost estimation (~30 models with pricing tables)
- Budget management with daily/monthly limits
- SQLite-based usage history with chart visualization
- Secure API key storage via KDE Wallet
- Configurable alerts with KDE notifications
- Per-provider refresh intervals and notification controls
- Collapsible provider cards with accessibility support
- Data export (CSV/JSON)
- Panel icon with status badge indicator
- HTTPS security warnings for custom base URLs

%prep
%autosetup

%build
%cmake
%cmake_build

%install
%cmake_install

%files
%{_datadir}/plasma/plasmoids/com.github.loofi.aiusagemonitor/
%{_libdir}/qt6/qml/com/github/loofi/aiusagemonitor/
%{_datadir}/knotifications6/plasma_applet_com.github.loofi.aiusagemonitor.notifyrc

%changelog
* Sun Feb 15 2026 Loofi <loofi@github.com> - 2.2.0-1
- Add subscription tool tracking for Claude Code, Codex CLI, and GitHub Copilot
- Add SubscriptionToolBackend abstract base class with rolling time windows
- Add ClaudeCodeMonitor with 5h session + weekly dual limits (Pro/Max5x/Max20x)
- Add CodexCliMonitor with 5h window (Plus/Pro/Business plans)
- Add CopilotMonitor with monthly limits + optional GitHub API org metrics
- Add SubscriptionToolCard.qml with progress bars and time-until-reset
- Add configSubscriptions.qml with per-tool plan/limit/notification settings
- Add subscription_tool_usage table to SQLite database
- Fix token accumulation bug in OpenAICompatibleProvider (session-level tracking)
- Fix estimatedMonthlyCost returning 0 for non-OpenAI providers
- Fix budget notifications not firing from direct cost setters
- Add DeepSeek account balance display in ProviderCard
- Add Google Gemini free/paid tier selector with tier-aware rate limits

* Sat Feb 15 2026 Loofi <loofi@github.com> - 2.1.0-1
- Add OpenAICompatibleProvider base class, dedup Mistral/Groq/xAI/DeepSeek
- Add token-based cost estimation with per-model pricing (~30 models)
- Add per-provider refresh timers (individual timers per provider)
- Add collapsible provider cards with animated transitions
- Add HTTPS security warnings on custom base URL fields
- Add ClipboardHelper C++ class for data export
- Add accessibility annotations (ProviderCard, CostSummaryCard, CompactRepresentation)
- Data-driven provider cards via Repeater (eliminates hardcoded cards)
- Deduplicate provider arrays (single allProviders source of truth)
- Enable cost/usage display for Anthropic and Google providers
- Fix version mismatch (CMakeLists 1.0.0 to 2.0.0)
- Fix xAI default model (grok-3-mini to grok-3)
- Fix token tracking for Mistral/Groq/xAI providers
- Fix DeepSeek cost display (separate balance from cost)
- Fix OpenAI monthly cost tracking (new billing API endpoint)

* Sun Feb 15 2026 Loofi <loofi@github.com> - 2.0.0-1
- Add Mistral AI, DeepSeek, Groq, and xAI/Grok providers
- Add SQLite-based usage history with chart visualization
- Add budget management with daily/monthly limits per provider
- Add per-provider refresh intervals and notification controls
- Add data export (CSV/JSON) and trend analysis
- Add custom base URL support for all providers (proxy support)
- Fix compact display mode rendering (cost/count modes)
- Fix rate limit remaining=0 edge case in OpenAI provider
- Remove dead parseRateLimitHeaders() method

* Sun Feb 15 2026 Loofi <loofi@github.com> - 1.0.0-1
- Initial release
- Support for OpenAI, Anthropic, and Google Gemini providers
- KWallet integration for secure API key storage
- KDE notifications for rate limit warnings
