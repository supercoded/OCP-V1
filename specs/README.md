# OCP Specifications

Authoritative project documents for the Open Communication Platform.

## Source of Truth (priority order)

1. **Engineering standards** — [OCP_ENGINEERING_SPEC.md](OCP_ENGINEERING_SPEC.md), [ENGINEERING_PRINCIPLES.md](ENGINEERING_PRINCIPLES.md) (OCP-0003), [DESIGN_GOALS.md](DESIGN_GOALS.md) (OCP-0004)
2. **Protocol specifications** — [odp-spec.md](odp-spec.md), [onp-spec.md](onp-spec.md), [maps-spec.md](maps-spec.md) (OCP-0012)
3. **Architecture documents** — [build-plan-v2.md](build-plan-v2.md) (active), [build-plan.md](build-plan.md), [adr/](adr/)
4. **Product requirements** — [PROJECT_CHARTER.md](PROJECT_CHARTER.md) (OCP-0002), [PRODUCT_REQUIREMENTS_SPECIFICATION_V2.md](PRODUCT_REQUIREMENTS_SPECIFICATION_V2.md) (OCP-0005), [PROJECT_VISION.md](PROJECT_VISION.md)
5. **Implementation** — code in the repository

## Documents

| Document ID | File | Version | Status |
|-------------|------|---------|--------|
| — | [OCP_ENGINEERING_SPEC.md](OCP_ENGINEERING_SPEC.md) | 1.0.0 | Draft |
| OCP-0002 | [PROJECT_CHARTER.md](PROJECT_CHARTER.md) | 2.0.0-draft | Draft |
| OCP-0003 | [ENGINEERING_PRINCIPLES.md](ENGINEERING_PRINCIPLES.md) | 1.0.0 | Draft |
| OCP-0004 | [DESIGN_GOALS.md](DESIGN_GOALS.md) | 1.0.0 | Draft |
| OCP-0005 | [PRODUCT_REQUIREMENTS_SPECIFICATION_V2.md](PRODUCT_REQUIREMENTS_SPECIFICATION_V2.md) | 2.0.0-draft | Draft |
| — | [PROJECT_VISION.md](PROJECT_VISION.md) | 1.0.0 | Draft |
| — | [build-plan-v2.md](build-plan-v2.md) | 2.0 | Active |
| — | [build-plan.md](build-plan.md) | 1.0 | Superseded by v2 |
| — | [charter.md](charter.md) | — | Redirect → PROJECT_CHARTER.md (+ v2.1 scope addendum) |
| — | [prs.md](prs.md) | — | Redirect → PRODUCT_REQUIREMENTS_SPECIFICATION_V2.md (+ v2.1 scope addendum) |
| — | [odp-spec.md](odp-spec.md) | 1.0.0 | Draft |
| — | [onp-spec.md](onp-spec.md) | 1.0.0 | Draft |
| OCP-0012 | [maps-spec.md](maps-spec.md) | 1.0.0 | Draft |

## Design goals quick reference

| Goal | Summary |
|------|---------|
| DG-001 | Offline first |
| DG-002 | Hardware independence |
| DG-003 | Modular architecture |
| DG-004 | Extensibility |
| DG-005 | Performance (60 FPS, lazy loading) |
| DG-006 | Reliability (retry, structured errors) |
| DG-007 | Security |
| DG-008 | Maintainability |
| DG-009 | Testability |
| DG-010 | Developer experience |
