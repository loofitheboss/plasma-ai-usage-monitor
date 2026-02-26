# Flatpak Scaffold (Kickoff)

This directory contains a minimal Flatpak manifest scaffold for future distribution work.

Current scope:

- Establish canonical manifest location: `packaging/flatpak/com.github.loofi.aiusagemonitor.yaml`
- Keep CI validation lightweight (schema/presence checks only for now)
- Do not publish Flatpak artifacts yet

Local validation:

- `bash scripts/check_flatpak_scaffold.sh`

Future work can extend this scaffold with full plugin/runtime integration and reproducible Flatpak builds.
