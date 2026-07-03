#!/usr/bin/env bash
set -euo pipefail

mkdir -p dist/desktop

node apps/desktop/src/main.js
tar -czf dist/desktop/ocp-desktop-offline.tgz apps/desktop packages/offline-core package.json

cat <<'EOF'
Desktop artifact created:
  dist/desktop/ocp-desktop-offline.tgz

This is a downloadable internal-test bundle.
EOF
