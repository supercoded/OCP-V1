#!/usr/bin/env bash
# Run the RuView Wi-Fi DensePose simulator in Docker.
# This provides simulated CSI/presence data on ws://localhost:3001/ws/sensing
# without requiring ESP32 hardware.

set -euo pipefail

HOST=${RUVIEW_HOST:-localhost}
HTTP_PORT=${RUVIEW_HTTP_PORT:-3000}
WS_PORT=${RUVIEW_WS_PORT:-3001}

echo "Starting RuView simulator on http://${HOST}:${HTTP_PORT} and ws://${HOST}:${WS_PORT}/ws/sensing"

docker run --rm -it \
  --name ruview-sim \
  -p "${HTTP_PORT}:3000" \
  -p "${WS_PORT}:3001" \
  -e RUVIEW_ALLOW_UNAUTHENTICATED=1 \
  ruvnet/wifi-densepose:latest
