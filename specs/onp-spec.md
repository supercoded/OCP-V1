# ONP Protocol Specification

**Document ID:** OCP-0011
**Version:** 1.0.0
**Status:** Draft

## Overview

Open Network Protocol (ONP) — device-to-device routing and peer metadata.

## Frame Format

Uses ODP DATA frames with ONP payload:

```
| RouteType (1) | HopCount (1) | OriginId (16) | Payload (N) |
```

## Route Types

| Type | Name |
|------|------|
| 0x01 | PEER_ANNOUNCE |
| 0x02 | PEER_HEARD |
| 0x03 | ROUTE_STATS |

## PEER_HEARD

Reports last-heard timestamp and link quality (0-100).

## Routing

- Max hop count: 7
- Duplicate suppression via origin ID + sequence
