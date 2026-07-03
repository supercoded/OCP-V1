# Platform Execution Order

This repository implements the platform sequence from the approved offline-first plan:

1. Android + Desktop MVP (primary delivery)
2. iOS/macOS parity (second wave)

## Why this order

- Android and desktop both support direct BLE/USB/TCP integrations with fewer platform constraints.
- The same shared protocol/storage logic can be hardened in those targets before Apple-specific integration.
- This keeps the first deliverable focused on fully offline radio messaging rather than store/submission complexity.
