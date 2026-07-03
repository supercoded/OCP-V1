# ODP Protocol Specification

**Document ID:** OCP-0010
**Version:** 1.0.0
**Status:** Draft

## Overview

Open Device Protocol (ODP) — wire format between OCP application and a device.

## Frame Format

```
| Magic (2) | Version (1) | Type (1) | Seq (4) | Length (2) | Payload (N) | CRC32 (4) |
```

- **Magic:** `0x4F 0x44` ("OD")
- **Version:** Protocol version (currently `1`)
- **Type:** Message type byte
- **Seq:** Sequence number (uint32 LE) for replay protection
- **Length:** Payload length (uint16 LE)
- **Payload:** Type-specific bytes
- **CRC32:** IEEE CRC32 over header+payload (excluding CRC field)

## Message Types

| Type | Name | Direction |
|------|------|-----------|
| 0x01 | HELLO | App → Device |
| 0x02 | HELLO_ACK | Device → App |
| 0x03 | CAPABILITY_REQ | App → Device |
| 0x04 | CAPABILITY_RSP | Device → App |
| 0x10 | DATA | Bidirectional |
| 0xFF | ERROR | Bidirectional |

## Handshake

1. App sends HELLO with supported protocol versions `[1]`
2. Device responds HELLO_ACK with selected version
3. App sends CAPABILITY_REQ
4. Device responds CAPABILITY_RSP with capability list

## Timeouts

- Handshake timeout: 5 seconds
- Response timeout: 3 seconds per message

## Error Codes

| Code | Meaning |
|------|---------|
| 0x01 | Version mismatch |
| 0x02 | Invalid frame |
| 0x03 | Timeout |
