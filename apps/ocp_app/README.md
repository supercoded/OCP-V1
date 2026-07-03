# ocp_app

OCP Flutter app — messaging, maps sonar, and Meshtastic device pairing.

## Install on hardware (Android / iOS)

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (3.24+).
2. From the repo root, fetch dependencies:

```bash
cd apps/ocp_app
flutter pub get
```

3. Connect a phone with USB debugging (Android) or a paired iOS device.
4. Build and run:

```bash
flutter run
```

On first launch, grant **Bluetooth** (and **Location** on Android 11 and below when prompted). The Devices tab scans for Meshtastic boards advertising the official GATT service (RAK4631, LilyGo T-Beam, etc.).

### Flow

1. **Devices** → *Scan for Meshtastic devices*
2. Tap **Pair** on your board (connects over BLE, runs Meshtastic config sync)
3. **Messaging** → send text (forwarded as Meshtastic `TEXT_MESSAGE_APP`)
4. **Maps** → sonar view shows mesh positions from `POSITION_APP`

### Desktop / CI (mock demo)

On Linux, macOS, and Windows the app uses an in-process mock transport — same UI, no radio required. Unit tests run with `flutter test`.

## Development

```bash
# From repo root
melos run analyze
melos run test
cd apps/ocp_app && flutter test
cd packages/ocp_transport_ble && flutter test
```
