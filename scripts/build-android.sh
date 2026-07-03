#!/usr/bin/env bash
set -euo pipefail

mkdir -p dist/android
tar -czf dist/android/ocp-android-logic-bundle.tgz apps/mobile packages/offline-core package.json

cat <<'EOF'
Android logic artifact created:
  dist/android/ocp-android-logic-bundle.tgz

Note: this repository currently ships shared logic bundles.
A full APK/AAB pipeline can be added once Android toolchain/CI signing is configured.
EOF
