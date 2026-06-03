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
# Codex Execution Plan

## 1. Purpose

This plan orders implementation work so a future Codex agent can build the Lore Key platform without additional clarification. It maps phases to inputs, outputs, files, dependencies, definitions of done, and testing requirements. The plan assumes the monorepo structure defined in `12_REPOSITORY_STRUCTURE.md`.

## 2. Global Execution Rules

1. Implement shared types before services that consume them.
2. Implement database migrations before repository code.
3. Implement contract tests before endpoint implementations where possible.
4. Keep lifecycle enums consistent across SQL, shared types, APIs, and docs.
5. Every write API requires idempotency, audit logging, and correlation IDs.
6. Every local event must be canonicalized, hashed, and signed before sync.
7. Never store raw activation codes or private signing keys in repositories or fixtures.
8. Do not implement reputation publication before progress evidence verification exists.

## 3. Phase 1: Database

### Inputs

- `05_DATABASE_SCHEMA.sql`
- `11_DOMAIN_MODEL.md`
- `13_LOCAL_FIRST_ARCHITECTURE.md`

### Outputs

- PostgreSQL migrations for server tables.
- SQLite migrations for local runtime tables.
- Seed fixtures for development only.
- Repository interfaces for core aggregates.

### Files

```text
/apps/aporaksha/migrations/0001_identity.sql
/apps/bundle-resolver/migrations/0001_bundles.sql
/apps/environment-service/migrations/0001_environment.sql
/apps/reputation-service/migrations/0001_reputation.sql
/packages/local-store/migrations/0001_local_runtime.sql
/packages/shared-types/src/domain.ts
/packages/shared-types/src/lifecycle.ts
/tests/fixtures/db/*.json
```

### Dependencies

- PostgreSQL 15+.
- SQLite with encryption plan selected.
- UUID generation library.
- Migration runner chosen.

### Definition of Done

- All lifecycle enums exist in SQL and shared types.
- Migrations apply from empty database.
- Migrations roll back in development.
- Server schema has primary keys, foreign keys, indexes, soft-delete columns, and audit logs.
- Local SQLite schema supports identity context, leases, installs, local events, sync queue, achievements, and diagnostics.
- Seed data creates a valid unclaimed key, active key, revoked key, user, bundle, and install fixture.

### Testing Requirements

- Migration apply test.
- Migration rollback test where supported.
- Constraint tests for duplicate serial, duplicate event, invalid lifecycle transitions where enforced.
- Fixture load test.
- SQLite encryption/open test.

## 4. Phase 2: Identity Service

### Inputs

- `04_API_SPEC.md`
- `15_APORAKSHA_SPEC.md`
- `09_SECURITY_MODEL.md`

### Outputs

- Aporaksha service with activation, validation, lease renewal, device binding, recovery start, and admin registration.
- Audit logging implementation.
- Device assertion verification.
- Lease signing and verification test vectors.

### Files

```text
/apps/aporaksha/src/routes/activate.*
/apps/aporaksha/src/routes/validate.*
/apps/aporaksha/src/routes/leases.*
/apps/aporaksha/src/routes/devices.*
/apps/aporaksha/src/routes/recovery.*
/apps/aporaksha/src/routes/admin-keys.*
/apps/aporaksha/src/domain/*.ts
/apps/aporaksha/src/policies/*.ts
/apps/aporaksha/src/repositories/*.ts
/packages/auth/src/device-assertion.*
/packages/auth/src/tokens.*
/packages/crypto/src/signatures.*
/tests/contract/aporaksha/*.test.*
/tests/security/replay-activation.test.*
```

### Dependencies

- Phase 1 database.
- Crypto package.
- Auth package.
- Telemetry package.

### Definition of Done

- `POST /activate` handles QR/NFC/secure challenge envelopes according to tier.
- `POST /validate` returns least-privilege capabilities.
- Lease issuance creates signed offline lease.
- Lease renewal validates key, user, device, and entitlement state.
- Device binding limit is enforced.
- Admin key registration supports dry run and commit.
- Revoked and suspended key behavior matches policy.
- All failures are structured and audited.

### Testing Requirements

- Activation success.
- Invalid proof rejection.
- Nonce replay rejection.
- Revoked key denial.
- Suspended key restricted capabilities.
- Device limit exceeded.
- Idempotency replay.
- Lease signature verification.
- Admin batch import duplicate serial handling.

## 5. Phase 3: Bundle Resolver

### Inputs

- `14_BUNDLE_SPECIFICATION.md`
- `04_API_SPEC.md`
- `12_REPOSITORY_STRUCTURE.md`

### Outputs

- Bundle manifest schema package.
- Bundle Resolver service.
- Bundle eligibility engine.
- Dependency resolver.
- Example bundles validated in tests.

### Files

```text
/apps/bundle-resolver/src/routes/resolve.*
/apps/bundle-resolver/src/routes/manifest.*
/apps/bundle-resolver/src/domain/bundle.*
/apps/bundle-resolver/src/policies/eligibility.*
/apps/bundle-resolver/src/services/dependency-resolver.*
/packages/bundle-spec/src/schema/viabundle.schema.json
/packages/bundle-spec/src/validate.*
/packages/bundle-spec/src/signature.*
/bundles/examples/*.viabundle.json
/bundles/chemistry/manifest.viabundle.json
/bundles/embedded-systems/manifest.viabundle.json
/bundles/tinyml/manifest.viabundle.json
/bundles/industry-4-0/manifest.viabundle.json
/tests/contract/bundles/*.test.*
```

### Dependencies

- Phase 1 database.
- Phase 2 identity validation or mocked identity context for tests.
- Bundle signing keys in secure development environment.

### Definition of Done

- `.viabundle` schema validates examples.
- Resolver returns only entitled bundles.
- Manifest signature and hash metadata are returned.
- Revoked bundle versions are blocked.
- Dependency cycles are detected.
- Resolver is cache-friendly and returns immutable manifest URLs.

### Testing Requirements

- Valid manifest schema test.
- Invalid manifest rejection.
- Eligibility allow/deny tests.
- Dependency resolution tests.
- Revoked version deny test.
- Signature verification test vectors.

## 6. Phase 4: Installer

### Inputs

- `13_LOCAL_FIRST_ARCHITECTURE.md`
- `16_INSTALLER_RUNTIME.md`
- `14_BUNDLE_SPECIFICATION.md`
- Phase 2 and Phase 3 service contracts.

### Outputs

- Desktop installer runtime.
- Local SQLite store.
- Key scanner abstraction.
- Bundle cache and verifier.
- Install engine with rollback.
- CLI commands for activation, install, validate, sync, repair, export.

### Files

```text
/apps/installer/src/key-scanner/*
/apps/installer/src/identity-client/*
/apps/installer/src/bundle-client/*
/apps/installer/src/cache/*
/apps/installer/src/install-engine/*
/apps/installer/src/runtime-config/*
/apps/installer/src/recovery/*
/apps/installer/src/cli/*
/packages/local-store/src/*
/packages/sdk/src/runtime.*
/tests/e2e/activation-install.test.*
/tests/offline-sync/local-lease.test.*
```

### Dependencies

- Phase 2 Aporaksha APIs.
- Phase 3 Bundle Resolver APIs.
- Local-store package.
- Bundle-spec package.
- Crypto package.

### Definition of Done

- Installer activates a fixture key.
- Installer validates an active key and stores signed lease.
- Installer resolves and verifies a fixture `.viabundle`.
- Installer downloads or loads fixture artifacts from local mirror.
- Installer creates checkpoints and can roll back failed installs.
- Local SDK exposes identity context and append event API.
- Offline mode works with active lease and restricts expired lease behavior.

### Testing Requirements

- QR payload parsing.
- Device key generation and assertion signing.
- Manifest schema/signature validation.
- Artifact hash mismatch handling.
- Interrupted download resume.
- Failed install rollback.
- Expired lease restriction.
- Local SQLite corruption recovery.

## 7. Phase 5: Progress Tracking

### Inputs

- `11_DOMAIN_MODEL.md`
- `13_LOCAL_FIRST_ARCHITECTURE.md`
- `19_SYSTEM_SEQUENCE_DIAGRAMS.md`

### Outputs

- Canonical progress event schemas.
- Local progress materializer.
- Server sync ingestion materializer for progress.
- StudyOS and PrepOS basic progress integrations.
- Achievement derivation foundation.

### Files

```text
/packages/events/src/progress-events.*
/packages/events/src/canonical-json.*
/packages/sdk/src/progress.*
/apps/environment-service/src/routes/sync.*
/apps/environment-service/src/materializers/progress.*
/apps/studyos/src/runtime-integration/*
/apps/prepos/src/runtime-integration/*
/tests/contract/events/progress.test.*
/tests/integration/sync-progress.test.*
```

### Dependencies

- Phase 4 local SDK and local store.
- Environment Service database migrations.
- Device signature verification from auth package.

### Definition of Done

- Apps can append progress events locally.
- Local materialized progress updates immediately.
- Sync queue submits signed events.
- Environment Service accepts valid events idempotently.
- Duplicate event submission returns existing state.
- Rejected events keep rejection reason.
- Basic achievement derivation can consume accepted progress.

### Testing Requirements

- Canonical JSON hash stability.
- Event signature validation.
- Duplicate event idempotency.
- Offline queue to online sync.
- Conflict resolution for duplicate lesson completion.
- Rejection for event after expired lease where policy requires active lease.

## 8. Phase 6: ViaDecide

### Inputs

- `17_VIADECIDE_REPUTATION_MODEL.md`
- `15_APORAKSHA_SPEC.md`
- Phase 5 progress and achievement outputs.

### Outputs

- Reputation Service evidence verification.
- ViaDecide reputation draft and consent UI/API.
- Badge model and trust score computation.
- Public/private verification endpoint.
- Anti-fraud rules v1.

### Files

```text
/apps/reputation-service/src/routes/events.*
/apps/reputation-service/src/routes/verify.*
/apps/reputation-service/src/domain/reputation-event.*
/apps/reputation-service/src/services/evidence-verifier.*
/apps/reputation-service/src/services/trust-score.*
/apps/reputation-service/src/services/badge-engine.*
/apps/reputation-service/src/services/fraud-rules.*
/apps/viadecide/src/reputation-drafts/*
/apps/viadecide/src/consent/*
/packages/events/src/reputation-events.*
/tests/contract/reputation/*.test.*
/tests/security/reputation-fraud.test.*
```

### Dependencies

- Accepted progress and achievements.
- Aporaksha identity context assertion.
- Reputation database migrations.

### Definition of Done

- User can preview reputation claim fields before consent.
- Reputation Service verifies evidence references.
- Server signs accepted reputation events.
- Rejected claims return actionable reasons.
- Trust scores are explainable by dimensions.
- Badge issuance is deterministic from policy.
- Public verification does not expose private evidence.

### Testing Requirements

- Consent required test.
- Missing evidence rejection.
- Invalid local signature rejection.
- Accepted badge event signing.
- Revoked achievement blocks reputation.
- Fraud rule high-risk hold.
- Public verification privacy test.

## 9. Phase 7: Offline Sync

### Inputs

- `13_LOCAL_FIRST_ARCHITECTURE.md`
- `06_EVENT_FLOWS.md`
- Phase 5 event schemas.

### Outputs

- Hardened sync batch protocol.
- Conflict resolver framework.
- Lease window enforcement.
- Backpressure and retry handling.
- Local conflict review UI hooks.
- Sync observability.

### Files

```text
/apps/environment-service/src/routes/sync.*
/apps/environment-service/src/services/conflict-resolver.*
/apps/environment-service/src/services/lease-window-policy.*
/apps/environment-service/src/workers/sync-batch-worker.*
/apps/installer/src/sync-agent/*
/packages/sdk/src/sync-status.*
/packages/events/src/sync-events.*
/tests/offline-sync/*.test.*
/tests/integration/sync-batches.test.*
```

### Dependencies

- Phase 4 installer sync agent.
- Phase 5 progress events.
- Phase 2 lease validation.

### Definition of Done

- Sync batches are idempotent by batch ID and event ID.
- Server accepts partial batches where safe.
- Conflicts return structured metadata.
- Backpressure uses `Retry-After` and client respects it.
- Lease expiry rules are enforced consistently.
- Offline 7-day and 30-day scenarios pass.

### Testing Requirements

- Duplicate batch retry.
- Out-of-order event dependencies.
- Clock rollback signal.
- Expired lease protected event rejection.
- Partial accept/reject batch.
- Conflict resolver deterministic output.
- Server backpressure retry behavior.

## 10. Phase 8: MVP Release

### Inputs

- Phases 1-7 outputs.
- `10_MVP_ROADMAP.md`
- `18_HARDWARE_ARCHITECTURE.md`
- Security model and operations docs.

### Outputs

- Production-ready MVP for pilot.
- Signed installer release.
- Registered physical key pilot batch.
- Signed StudyOS bundle.
- Admin support workflows.
- Launch runbooks and rollback plan.

### Files

```text
/infra/terraform/*
/infra/kubernetes/*
/infra/observability/*
/scripts/release/*
/scripts/hardware/generate-qr-batch.*
/scripts/hardware/qa-scan-report.*
/scripts/security/rotate-signing-keys.*
/docs/operations/mvp-launch-runbook.md
/docs/security/incident-response.md
/apps/admin-console/src/*
```

### Dependencies

- All prior phases.
- Production infrastructure.
- Key manufacturing batch.
- Signing key custody process.
- Support team readiness.

### Definition of Done

- Pilot batch registered and QA scanned.
- Production services deployed with observability.
- Installer signed and downloadable.
- StudyOS bundle signed and resolvable.
- Activation-to-install-to-offline-sync E2E passes in staging and production smoke test.
- Admin can suspend/revoke key and view audit logs.
- Recovery workflow documented and tested.
- Security launch review approved.

### Testing Requirements

- Full E2E happy path.
- Full E2E revoked key path.
- Offline lease pilot test.
- Bundle tamper test.
- Admin revocation test.
- Recovery test on new device.
- Load test for activation spike.
- Security replay and signature tests.
- Observability alert test.

## 11. Implementation Order Checklist

```text
[ ] Create monorepo structure.
[ ] Add shared lifecycle and domain types.
[ ] Add PostgreSQL migrations.
[ ] Add SQLite migrations.
[ ] Implement crypto helpers and test vectors.
[ ] Implement Aporaksha activation.
[ ] Implement Aporaksha validation and leases.
[ ] Implement admin key registration.
[ ] Implement bundle schema validator.
[ ] Implement Bundle Resolver.
[ ] Implement installer local store.
[ ] Implement installer activation/validation client.
[ ] Implement bundle download/cache/verify.
[ ] Implement install engine and rollback.
[ ] Implement local runtime SDK append event.
[ ] Implement Environment Service sync ingestion.
[ ] Integrate StudyOS progress.
[ ] Integrate PrepOS progress.
[ ] Implement achievement derivation.
[ ] Implement ViaDecide consent and drafts.
[ ] Implement Reputation Service verification and signing.
[ ] Harden offline sync and conflicts.
[ ] Add admin console operational workflows.
[ ] Build release scripts and signed installer.
[ ] Run staging pilot tests.
[ ] Release MVP pilot.
```

## 12. Non-Negotiable Acceptance Gates

- No unsigned bundle can install.
- No revoked key can receive new protected capabilities.
- No private reputation data can publish without explicit consent.
- No write API can lack audit logging.
- No sync event can materialize without schema validation and idempotency.
- No rollback can delete learner-created progress.
- No production key batch can be imported without QA and audit.
