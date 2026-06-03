# 10 — MVP Roadmap

## 1. Roadmap Objective

Build a working Lore Key MVP that preserves the invariant: physical signal becomes authenticated ownership, device binding, offline lease, signed bundle install, local state, event progress, verified reputation, and permissioned Zayvora projection.

## 2. Phase Plan

| Phase | Duration | Outcome |
|---|---:|---|
| 0 Architecture Freeze | 2 weeks | Final implementation specs and contracts. |
| 1 Database and Types | 3 weeks | PostgreSQL schema, shared enums, migrations. |
| 2 Aporaksha | 5 weeks | Activation, ownership, device binding, leases. |
| 3 Bundle Resolver | 4 weeks | Signed `.viabundle.json` resolution. |
| 4 Capacitor Installer Runtime | 6 weeks | IndexedDB local runtime and verified install. |
| 5 Progress and Sync | 5 weeks | Event queue, reconciliation, materialization. |
| 6 ViaDecide Reputation | 4 weeks | Verified event-backed reputation. |
| 7 Zayvora Projection | 3 weeks | Permissioned memory projection contract. |
| 8 Pilot Release | 4 weeks | Hardening, QA, launch, support workflows. |

## 3. Phase 0 — Architecture Freeze

Objectives:

- Freeze documents 01-20 as MVP contract.
- Select backend stack: NestJS unless project lead chooses FastAPI before Phase 1.
- Freeze event envelope, lease contract, and `.viabundle.json` schema.

Deliverables:

- Architecture review approval.
- Security review approval.
- Implementation repository structure.

Success metrics:

- No unresolved architecture ambiguity remains.
- All implementation agents can map files to phases.

## 4. Phase 1 — Database and Types

Objectives:

- Implement PostgreSQL migrations.
- Implement shared lifecycle enums and DTOs.
- Implement event and outbox tables.

Deliverables:

- Migration set.
- Seed fixtures.
- Shared type package.

Dependencies:

- Phase 0 approval.

Success metrics:

- Migrations apply from empty DB.
- Constraints reject duplicate serials and duplicate events.

## 5. Phase 2 — Aporaksha

Objectives:

- Implement identity, ownership activation, device binding, lease issuance, lease renewal, admin key controls.

Deliverables:

- Activation API.
- Validation API.
- Lease API.
- Admin registration/suspend/revoke.
- Audit logging.

Risks:

- Treating physical signal as identity. This is forbidden.

Success metrics:

- Revoked keys never receive protected capabilities.
- Lease test vectors validate in client runtime.

## 6. Phase 3 — Bundle Resolver

Objectives:

- Implement immutable signed bundle resolution.
- Validate `.viabundle.json` schema and signature.

Deliverables:

- Bundle Resolver API.
- Bundle schema validator.
- StudyOS example bundle.

Success metrics:

- Tampered manifest rejected.
- Revoked bundle not returned.

## 7. Phase 4 — Capacitor Installer Runtime

Objectives:

- Implement physical signal intake, Aporaksha client, bundle verification, installation, IndexedDB local store, and runtime SDK.

Deliverables:

- Capacitor shell.
- IndexedDB schema.
- Install engine.
- Offline lease enforcement.

Success metrics:

- Activated user installs StudyOS bundle and runs offline.
- Failed install rolls back without deleting local data.

## 8. Phase 5 — Progress and Sync

Objectives:

- Implement event-based progress and reconciliation.

Deliverables:

- Runtime event SDK.
- Sync API.
- Server materializers.
- Client retry/backpressure.

Success metrics:

- Duplicate events are idempotent.
- Offline events sync after 7 days.

## 9. Phase 6 — ViaDecide Reputation

Objectives:

- Generate reputation from verified events only.

Deliverables:

- Reputation drafts.
- Consent UI.
- Evidence verification.
- Server-signed reputation events.

Success metrics:

- Manual claims cannot become verified.
- Public verification shows current status and no private data.

## 10. Phase 7 — Zayvora Projection

Objectives:

- Implement permissioned memory/context projection.

Deliverables:

- Projection API.
- Permission records.
- Inspect and revoke flow.

Success metrics:

- Projection requires explicit permission.
- Projection includes source event IDs and scope.

## 11. Phase 8 — Pilot Release

Objectives:

- Launch controlled pilot.

Deliverables:

- Registered key batch.
- Signed installer.
- Signed StudyOS bundle.
- Runbooks.
- Observability dashboards.
- Support recovery workflow.

Success metrics:

- >= 90% activation completion.
- >= 85% install success.
- >= 95% sync success after offline period.
- 100% tampered bundles rejected in pilot QA.
