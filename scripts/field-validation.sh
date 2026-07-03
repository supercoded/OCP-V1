#!/usr/bin/env bash
set -euo pipefail

mkdir -p dist/validation

cat > dist/validation/field-validation-checklist.txt <<'EOF'
OCP Offline Field Validation Checklist

1) Device discovery
   - [ ] Radio discovered over BLE
   - [ ] Radio discovered over USB/Serial
   - [ ] Radio discovered over TCP (if available)

2) Offline behavior
   - [ ] Internet disabled on host
   - [ ] Node/channel sync succeeds
   - [ ] Direct message send/receive works
   - [ ] Group channel send/receive works
   - [ ] App restart preserves message history

3) Reliability
   - [ ] Power-cycle radio and verify reconnect
   - [ ] Delayed ACK triggers retry and eventually settles
   - [ ] Delivery states transition queued -> sent -> acked/failed
EOF

echo "Generated field validation checklist at dist/validation/field-validation-checklist.txt"
