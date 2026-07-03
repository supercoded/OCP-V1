# OCP-V1

Open Communication Platform — an offline-first, modular communication platform for secure, reliable communication across multiple physical transports.

## Monorepo structure

```
apps/ocp_app/              # Flutter application (workspaces UI)
packages/
  ocp_core/                # Repositories + services (business logic)
  ocp_storage/             # Isar schemas and database facade
  ocp_odp/                 # ODP codec and connection state machine
  ocp_onp/                 # ONP network layer
  ocp_transport/           # BLE, USB, mock transport abstractions
  ocp_bridge_meshtastic/   # Meshtastic → ODP bridge
  ocp_plugin_api/          # Plugin SDK contracts
  ocp_plugin_example/      # Example plugin
tools/
  mock_device/             # ODP simulator
  benchmark/               # Performance harness
specs/                     # Authoritative project documents
```

## Getting started

```bash
# Install Flutter stable and Melos
dart pub global activate melos

# Bootstrap workspace packages
dart pub get
melos bootstrap

# Run tests
melos run test
cd apps/ocp_app && flutter test
```

## Specifications

Project authority and requirements live in [`specs/`](specs/):

- [OCP Engineering Specification](specs/OCP_ENGINEERING_SPEC.md) — architecture and engineering standards
- [Engineering Principles](specs/ENGINEERING_PRINCIPLES.md) (OCP-0003) — normative design principles
- [Design Goals](specs/DESIGN_GOALS.md) (OCP-0004) — measurable design goals and review criteria
- [Project Charter](specs/PROJECT_CHARTER.md) (OCP-0002) — governance, scope, and success criteria
- [Product Requirements](specs/PRODUCT_REQUIREMENTS_SPECIFICATION_V2.md) (OCP-0005) — functional and non-functional requirements
- [Project Vision](specs/PROJECT_VISION.md) — mission, scope, and success criteria
- [Build Plan v2](specs/build-plan-v2.md) — active plan: adds offline maps, sonar node view, and the MVP vertical slice
- [Build Plan v1](specs/build-plan.md) — original monorepo structure and phased build order (superseded by v2)

See [specs/README.md](specs/README.md) for the full document index and source-of-truth priority order.

## License

MIT — see [LICENSE](LICENSE).
