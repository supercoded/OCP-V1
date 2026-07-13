# OCP-V1 Flutter App

This is the Flutter front‑end for the Operational Comms Platform (OCP‑V1). It provides a dark submarine‑style UI with sonar visualisation, messaging, network monitoring and device control.

## Getting started

1. **Install Flutter** – Follow the official instructions at https://flutter.dev.
2. **Fetch dependencies** – Run `flutter pub get` inside `apps/ocp_app`.
3. **Run** – `flutter run` to launch on a connected device or emulator.

## Building releases

- Android: `flutter build apk --release`
- Linux:   `flutter build linux --release`
- Windows: `flutter build windows --release`
- macOS:   `flutter build macos --release`

## Architecture overview

- **Theme** – `packages/ocp_flutter_core` provides a shared dark theme.
- **State** – Providers (`connection_provider`, `sonar_provider`, …) expose app state via the `provider` package.
- **UI** – The main scaffold (`ocp_scaffold.dart`) hosts a sidebar navigation and a content area driven by an `IndexedStack`.
- **Sonar** – Custom `SonarPPI` painter renders a radar‑like display with animated sweep.

---

*Generated scaffold – do not edit manually unless you know what you are doing.*
