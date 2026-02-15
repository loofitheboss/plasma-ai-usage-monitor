Name:           plasma-ai-usage-monitor
Version:        1.0.0
Release:        1%{?dist}
Summary:        KDE Plasma 6 widget to monitor AI API token usage and rate limits
License:        GPL-3.0-or-later
URL:            https://github.com/loofi/plasma-ai-usage-monitor
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

%description
A native KDE Plasma 6 plasmoid that monitors AI API token usage,
rate limits, and costs across multiple providers including OpenAI,
Anthropic (Claude), and Google (Gemini).

Features:
- Real-time rate limit monitoring for all providers
- Usage and cost tracking for OpenAI
- Secure API key storage via KDE Wallet
- Configurable alerts with KDE notifications
- Panel icon with status badge indicator

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
* Sun Feb 15 2026 Loofi <loofi@github.com> - 1.0.0-1
- Initial release
- Support for OpenAI, Anthropic, and Google Gemini providers
- KWallet integration for secure API key storage
- KDE notifications for rate limit warnings
