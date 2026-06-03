# 06 — Event Flows

## 1. Event Architecture

Lore Key uses PostgreSQL-backed domain events plus a transactional outbox. Client apps use an IndexedDB queue. Server services reconcile client events, materialize progress, and publish outbox records for downstream processing.

```text
Capacitor App Runtime
  IndexedDB local_events + sync_queue
        │
        v
Sync API
        │ transaction
        v
PostgreSQL events table ──> materializers ──> progress / achievements
        │
        v
transactional outbox ──> workers ──> reputation / notifications / projections
```

## 2. Canonical Event Envelope

```json
{
  "event_id": "evt_01",
  "event_type": "PROGRESS_RECORDED",
  "aggregate_type": "Progress",
  "aggregate_id": "StudyOS:lesson-1",
  "application": "StudyOS",
  "occurred_at": "2026-06-03T00:00:00Z",
  "lease_id": "lease_01",
  "payload": {},
  "event_hash": "sha256:...",
  "signature": "base64url"
}
```

## 3. Activation Flow

```text
Trigger: user scans QR/NFC/serial.

Installer -> Aporaksha: PhysicalSignalSubmitted
Aporaksha -> DB: OwnershipActivated
Aporaksha -> DB: DeviceBound
Aporaksha -> DB: OfflineLeaseIssued
Aporaksha -> Outbox: ActivationCompleted
Installer -> IndexedDB: IdentityContextCreated
```

Failure states:

| Failure | Event/Record | Retry |
|---|---|---|
| Invalid signal | audit `ActivationRejected` | User may retry with rate limit. |
| Already owned | audit `OwnershipConflict` | Requires transfer/recovery. |
| Revoked key | audit `RevokedKeyAttempt` | No retry without admin. |
| Device limit | audit `DeviceLimitExceeded` | Remove/recover device. |

## 4. Bundle Resolution Flow

```text
Trigger: activated user requests environment install.

Installer -> Aporaksha: CapabilityValidationRequested
Aporaksha -> Installer: LeaseValidated
Installer -> Bundle Resolver: BundleResolutionRequested
Bundle Resolver -> DB: BundleEligibilityEvaluated
Bundle Resolver -> Outbox: BundleResolved
Installer -> IndexedDB: BundleManifestCached
```

Rules:

- Resolver returns immutable published versions only.
- Bundle signatures are verified by installer before artifact download.
- Revoked bundles produce `BundleResolutionDenied`.

## 5. Environment Installation Flow

```text
Trigger: signed bundle manifest is resolved.

Installer: InstallPlanned
Installer: BundleArtifactDownloadStarted
Installer: BundleArtifactVerified
Installer: EnvironmentInstallStarted
Installer: EnvironmentConfigured
Installer -> Environment Service: InstallTelemetrySubmitted
Environment Service -> DB: EnvironmentInstallRecorded
Environment Service -> Outbox: EnvironmentInstalled
Installer -> IndexedDB: LocalStateCreated
```

Failure and recovery:

| Failure | Handling |
|---|---|
| Signature invalid | Stop install, audit, quarantine manifest. |
| Hash mismatch | Stop install, quarantine artifact, retry alternate source. |
| Install step failure | Roll back from checkpoint. |
| Runtime config failure | Restore previous config and enter recovery. |

## 6. Progress Flow

```text
Trigger: learning app records progress.

App -> Runtime SDK: ProgressRecordRequested
Runtime SDK -> IndexedDB: LocalEventAppended
Runtime SDK -> IndexedDB: LocalProgressMaterialized
Runtime SDK -> IndexedDB: SyncEventQueued
Sync Client -> Sync API: SyncBatchSubmitted
Sync API -> DB: EventAccepted
Sync API -> DB: ProgressMaterialized
Sync API -> Outbox: ProgressRecorded
```

Rules:

- Progress is never written directly as trusted server state without an event.
- Duplicate `event_id` returns existing result.
- Invalid lease windows can lower trust or reject protected progress.

## 7. Reputation Flow

```text
Trigger: user approves ViaDecide reputation draft.

ViaDecide -> Aporaksha: IdentityAssertionRequested
Aporaksha -> ViaDecide: IdentityAssertionIssued
ViaDecide -> Reputation Service: ReputationPublishRequested
Reputation Service -> DB: EvidenceEventsVerified
Reputation Service -> DB: ReputationEventAccepted
Reputation Service -> Outbox: ReputationPublished
```

Rules:

- Manual claims cannot become verified reputation.
- Evidence events must be accepted server events.
- Revoked evidence revokes or supersedes dependent reputation.

## 8. Zayvora Projection Flow

```text
Trigger: user grants Zayvora permission.

Runtime/ViaDecide -> Zayvora API: ProjectionRequested
Zayvora API -> DB: PermissionVerified
Zayvora API -> DB: SourceEventsResolved
Zayvora API -> DB: MemoryProjectionCreated
Zayvora API -> Outbox: ZayvoraProjectionCreated
```

Rules:

- Projection requires permission scope.
- Projection stores source event IDs and policy version.
- Correction creates a superseding projection.

## 9. Sync Retry Logic

- Client retries batches with same `sync_batch_id`.
- Server deduplicates by `(user_id, application, event_id)`.
- Server accepts partial batches when safe.
- `Retry-After` is mandatory for backpressure.
- Conflicts return machine-readable resolution metadata.

## 10. Transactional Outbox Rules

- Any domain state transition that must notify another process writes outbox in the same transaction.
- Outbox workers mark `PUBLISHED` only after successful delivery.
- Failed deliveries increment attempts and schedule `next_attempt_at`.
- Outbox payloads must not contain private data unnecessary for consumers.
