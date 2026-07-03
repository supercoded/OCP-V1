# PROJECT_CHARTER.md

**Document ID:** OCP-0002
**Version:** 2.0.0-draft

# Executive Summary

The Open Communication Platform (OCP) is an offline-first, modular communication platform designed to unify multiple hardware transports behind a consistent application architecture.

# Mission
Build a secure, extensible communication platform that remains functional without cloud infrastructure.

# Objectives
- Deliver a single Flutter codebase.
- Support BLE, USB, Serial, TCP/IP, LoRa.
- Provide plugin and device SDKs.
- Preserve user ownership of data.

# Scope
## In Scope
- Mobile application
- OCP Core
- ODP / ONP
- Local storage
- Plugin framework
- Simulator
## Out of Scope (v1)
- Mandatory cloud services
- Proprietary hardware lock-in

# Stakeholders
- End users
- Developers
- Hardware vendors
- Open-source contributors

# Governance
Architecture changes require review and updates to engineering specifications before implementation.

# Success Criteria
- Offline messaging
- Modular transports
- Cross-platform support
- >90% unit coverage goal for core modules
- Stable public APIs

# Risks
- Scope growth
- Protocol complexity
- Cross-platform differences

# Deliverables
- Flutter application
- Firmware
- Documentation
- SDK
- Test suite
