# OCP-V1

Open Communication Platform — an offline-first, modular communication platform for secure, reliable communication across multiple physical transports.

## Specifications

Project authority and requirements live in [`specs/`](specs/):

- [OCP Engineering Specification](specs/OCP_ENGINEERING_SPEC.md) — architecture and engineering standards
- [Engineering Principles](specs/ENGINEERING_PRINCIPLES.md) (OCP-0003) — normative design principles
- [Design Goals](specs/DESIGN_GOALS.md) (OCP-0004) — measurable design goals and review criteria
- [Project Charter](specs/PROJECT_CHARTER.md) (OCP-0002) — governance, scope, and success criteria
- [Product Requirements](specs/PRODUCT_REQUIREMENTS_SPECIFICATION_V2.md) (OCP-0005) — functional and non-functional requirements
- [Project Vision](specs/PROJECT_VISION.md) — mission, scope, and success criteria
- [Build Plan](specs/build-plan.md) — monorepo structure and phased build order

See [specs/README.md](specs/README.md) for the full document index and source-of-truth priority order.

## Offline App Implementation Scaffold

This repository now includes a first-pass implementation scaffold for the offline-first downloadable app:

- Shared core: [`packages/offline-core`](packages/offline-core)
  - Transport adapters (BLE/Serial/TCP)
  - PhoneAPI-style protocol client (handshake, NodeDB/channel sync, ACK/retry)
  - Offline JSON storage with encrypted channel keys at rest
- App shells:
  - [`apps/desktop`](apps/desktop)
  - [`apps/mobile`](apps/mobile)
- Build and validation scripts:
  - `scripts/build-desktop.sh`
  - `scripts/build-android.sh`
  - `scripts/field-validation.sh`
- Plan decision records:
  - [`docs/offline-app/target-order.md`](docs/offline-app/target-order.md)
  - [`docs/offline-app/mvp-scope.md`](docs/offline-app/mvp-scope.md)

### Quick start

```bash
npm test
npm run build:desktop
npm run build:android
npm run validate:field
```

## License

MIT — see [LICENSE](LICENSE).
