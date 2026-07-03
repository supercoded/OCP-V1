# Offline Messaging MVP Scope

The MVP is intentionally constrained to the core offline communication loop.

## Included

- Device connection over BLE, USB/Serial, and TCP (adapter-based interface)
- PhoneAPI-style handshake/config sync flow
- Direct and channel message receive/send pipeline
- Delivery states: queued, sent, acked, failed
- Local persistence for nodes, channels, messages, and outbox
- Automatic retry of queued outbound messages
- Downloadable build artifacts for Android/desktop internal testing
- Field validation checklist and logging capture workflow

## Excluded from MVP

- Cloud account system or cloud relay dependencies
- Rich media attachments
- Plugin marketplace
- Production signing/notarization automation
