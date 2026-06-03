# 20 — Codex Execution Plan

## 1. Execution Contract

This repository is now an implementation-ready architecture repo. Do not generate application code until a build task explicitly requests it. Future Codex agents must implement in the order below.

## 2. Phase 1 — Database

Inputs: `05_DATABASE_SCHEMA.sql`, `11_DOMAIN_MODEL.md`.

Outputs:

- `/db/migrations` PostgreSQL migration files.
- `/db/seeds` safe fixtures.
- `packages/shared-types` lifecycle enums.

Files:

- `db/migrations/0001_core.sql`
- `db/seeds/dev-fixtures.sql`
- `packages/shared-types/src/lifecycle.ts`
- `packages/shared-types/src/domain.ts`

Dependencies: PostgreSQL 15+, migration runner.

Definition of Done:

- Migrations apply from empty DB.
- Duplicate serial and event constraints work.
- Events and outbox tables exist.

Testing:

- Migration apply test.
- Constraint test.
- Seed load test.

## 3. Phase 2 — Identity Service

Inputs: `04_API_SPEC.md`, `15_APORAKSHA_SPEC.md`, `09_SECURITY_MODEL.md`.

Outputs:

- Aporaksha activation, validation, leases, device binding, admin key controls.

Files:

- `apps/aporaksha-api/src/activate/*`
- `apps/aporaksha-api/src/validate/*`
- `apps/aporaksha-api/src/leases/*`
- `apps/aporaksha-api/src/devices/*`
- `apps/aporaksha-api/src/admin/*`
- `packages/auth/src/*`
- `packages/crypto/src/*`

Dependencies: Phase 1.

Definition of Done:

- Physical signal is never trusted as identity.
- Ownership activation requires authenticated user.
- Device binding uses public key.
- Lease signatures validate with test vectors.
- Revoked keys receive no protected capabilities.

Testing:

- Activation success.
- Invalid signal rejection.
- Replay rejection.
- Revoked key denial.
- Device limit test.

## 4. Phase 3 — Bundle Resolver

Inputs: `14_BUNDLE_SPECIFICATION.md`, `04_API_SPEC.md`.

Outputs:

- Bundle schema validator.
- Resolver endpoint.
- Signed StudyOS example bundle.

Files:

- `packages/bundle-spec/src/*`
- `bundles/schemas/viabundle.schema.json`
- `apps/bundle-resolver-api/src/*`
- `bundles/studyos-foundations/manifest.viabundle.json`

Dependencies: Phase 1, Phase 2 validation contract.

Definition of Done:

- Valid manifests pass schema.
- Invalid or tampered manifests fail.
- Resolver returns only entitled published immutable versions.

Testing:

- Schema tests.
- Signature tests.
- Eligibility tests.
- Revoked bundle denial.

## 5. Phase 4 — Installer

Inputs: `13_LOCAL_FIRST_ARCHITECTURE.md`, `16_INSTALLER_RUNTIME.md`.

Outputs:

- Capacitor installer shell.
- IndexedDB local runtime.
- Bundle verification and install engine.
- Runtime SDK.

Files:

- `apps/installer-shell/src/*`
- `packages/local-runtime/src/indexeddb/*`
- `packages/sdk/src/*`

Dependencies: Phases 2 and 3.

Definition of Done:

- Scan QR/NFC/serial.
- Activate and store lease in IndexedDB.
- Resolve and verify bundle.
- Create local environment state.
- Run offline under valid lease.
- Roll back failed install without deleting user data.

Testing:

- Scan parsing.
- Lease enforcement.
- Manifest/artifact tamper rejection.
- IndexedDB state creation.
- Rollback test.

## 6. Phase 5 — Progress Tracking

Inputs: `06_EVENT_FLOWS.md`, `11_DOMAIN_MODEL.md`, `13_LOCAL_FIRST_ARCHITECTURE.md`.

Outputs:

- Canonical event schemas.
- SDK `appendEvent`.
- Sync API reconciliation.
- Progress materializers.

Files:

- `packages/events/src/*`
- `apps/environment-sync-api/src/sync/*`
- `apps/environment-sync-api/src/materializers/*`
- `apps/studyos/src/runtime-integration/*`

Dependencies: Phase 4.

Definition of Done:

- Progress is event-based.
- Client queue retries idempotently.
- Server materializes accepted events.
- Conflicts are deterministic.

Testing:

- Canonical hash stability.
- Duplicate event idempotency.
- Offline sync after reconnect.
- Conflict resolver tests.

## 7. Phase 6 — ViaDecide

Inputs: `17_VIADECIDE_REPUTATION_MODEL.md`, Phase 5 events.

Outputs:

- Reputation drafts.
- Consent flow.
- Evidence verification.
- Signed reputation events.

Files:

- `apps/viadecide/src/*`
- `apps/reputation-api/src/*`

Dependencies: Phase 5 and Aporaksha assertions.

Definition of Done:

- Manual claims cannot become verified.
- Evidence events must be accepted.
- Server signs accepted reputation.
- Public verification hides private data.

Testing:

- Missing evidence rejection.
- Consent required.
- Revoked evidence revokes claim.
- Signature verification.

## 8. Phase 7 — Offline Sync and Zayvora

Inputs: `13_LOCAL_FIRST_ARCHITECTURE.md`, `19_SYSTEM_SEQUENCE_DIAGRAMS.md`.

Outputs:

- Hardened sync retry/backpressure.
- Zayvora permissioned projection API.

Files:

- `apps/environment-sync-api/src/reconciliation/*`
- `apps/zayvora-projection-api/src/*`
- `packages/local-runtime/src/sync/*`

Dependencies: Phase 5.

Definition of Done:

- Lease expiry rules enforced.
- Backpressure respected.
- Projection requires permission and source events.
- Projection can be inspected and revoked.

Testing:

- 30-day lease expiry.
- Partial batch accept/reject.
- Projection without permission denied.
- Projection source event verification.

## 9. Phase 8 — MVP Release

Inputs: all prior phases and `10_MVP_ROADMAP.md`.

Outputs:

- Pilot-ready system.
- Signed installer shell.
- Registered key batch.
- Signed StudyOS bundle.
- Runbooks and support workflows.

Files:

- `infra/*`
- `scripts/release/*`
- `scripts/hardware/*`
- `docs/operations/*`

Definition of Done:

- End-to-end activation to reputation works.
- Offline learning and sync work.
- Tampered bundle rejected.
- Revoked key denied.
- Zayvora projection requires permission.

Testing:

- Full E2E happy path.
- Revoked key path.
- Tampered bundle path.
- Offline sync path.
- Reputation verification path.
- Recovery path.

## 10. Non-Negotiable Gates

- No physical signal is trusted as identity.
- No unsigned bundle installs.
- No progress exists without an event.
- No verified reputation exists without accepted evidence events.
- No Zayvora projection exists without permission.
- No write API lacks audit and idempotency.
- No rollback deletes learner-created data.
