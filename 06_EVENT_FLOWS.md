# Event-Driven Architecture Flows

## 1. Event Architecture Overview

Lore Key uses state-driven workflows coordinated through durable events. Online services process activation, validation, bundle resolution, reputation, and sync events. Local applications also produce signed events that are queued offline and reconciled later.

```text
Local Installer / Apps
        │
        │ signed local events
        v
Local Event Store ───── offline queue ─────┐
        │                                  │
        │ online API calls                 │ sync when connected
        v                                  v
Aporaksha Identity ── Bundle Resolver ── Environment Service ── Reputation Service
        │                  │                    │                    │
        v                  v                    v                    v
   Audit Logs        Bundle Manifests      Progress State       Reputation Graph
```

## 2. Event Naming Standards

| Event | Producer | Primary Consumer |
|---|---|---|
| `KeyProofSubmitted` | Installer | Aporaksha Identity Service |
| `LoreKeyClaimed` | Aporaksha | Bundle Resolver, Audit |
| `LoreKeyActivated` | Aporaksha | Environment Service |
| `BundleResolved` | Bundle Resolver | Installer, Audit |
| `BundleVerified` | Installer | Environment Service |
| `EnvironmentInstallStarted` | Installer | Local State, Audit Sync |
| `EnvironmentInstalled` | Installer | Environment Service |
| `ProgressRecorded` | Learning App | Local State, Sync Service |
| `AchievementAwarded` | Learning App | Reputation Service |
| `ReputationPublishRequested` | ViaDecide | Reputation Service |
| `OfflineSyncQueued` | Local Runtime | Sync Service |
| `OfflineSyncAccepted` | Environment Service | Local Runtime |
| `RecoveryRequested` | Installer / Support | Aporaksha |

## 3. Key Activation Flow

### Trigger

A learner scans or taps a physical Lore Key and submits identity and device information.

### Diagram

```text
Learner       Installer       Aporaksha        Audit Log       Bundle Resolver
  │              │                │                │                  │
  │ scan key     │                │                │                  │
  ├─────────────>│                │                │                  │
  │              │ KeyProofSubmitted              │                  │
  │              ├───────────────>│                │                  │
  │              │                │ verify proof   │                  │
  │              │                │ check status   │                  │
  │              │                │ bind device    │                  │
  │              │                │ LoreKeyClaimed │                  │
  │              │                ├───────────────>│                  │
  │              │                │ LoreKeyActivated                 │
  │              │                ├─────────────────────────────────>│
  │              │ activation token / lease       │                  │
  │              │<───────────────┤                │                  │
  │ next action  │                │                │                  │
  │<─────────────┤                │                │                  │
```

### Events

1. `KeyProofSubmitted`
2. `ActivationValidationStarted`
3. `LoreKeyClaimed`
4. `DeviceBound`
5. `LoreKeyActivated`
6. `ActivationAuditRecorded`

### Consumers

- Aporaksha validates key proof and writes activation state.
- Audit Log records all state transitions.
- Bundle Resolver warms eligibility cache for the activated user.
- Environment Service prepares initial local environment state.

### Failure States

| Failure | Handling |
|---|---|
| Invalid public code | Return generic invalid proof error; rate limit. |
| Replayed nonce | Reject with `401`; write security audit event. |
| Already claimed key | Return `409` unless same idempotency key. |
| Suspended key | Return `403`; preserve support path. |
| Database write failure | Retry transaction with idempotency key; do not double-bind. |

### Retry Logic

- Client retries with the same idempotency key for network failures.
- Server deduplicates activation by idempotency key and key/device pair.
- Nonce challenges must be regenerated after expiry.

### Recovery Logic

- If activation succeeded but client did not receive the response, the client calls state lookup with the same identity proof.
- If device binding was partially written, reconciliation verifies activation and binding tables.
- Support recovery requires physical key possession or stronger identity proof.

## 4. Environment Installation Flow

### Trigger

An activated user requests installation of StudyOS, PrepOS, SkillHex, ViaDecide, or Zayvora.

### Diagram

```text
Installer       Aporaksha       Bundle Resolver       CDN/Mirror       Local Runtime
   │                │                 │                   │                 │
   │ validate       │                 │                   │                 │
   ├───────────────>│                 │                   │                 │
   │ lease/status   │                 │                   │                 │
   │<───────────────┤                 │                   │                 │
   │ resolve bundle │                 │                   │                 │
   ├─────────────────────────────────>│                   │                 │
   │ manifest URL + signature         │                   │                 │
   │<─────────────────────────────────┤                   │                 │
   │ download artifacts                                   │                 │
   ├─────────────────────────────────────────────────────>│                 │
   │ artifacts                                            │                 │
   │<─────────────────────────────────────────────────────┤                 │
   │ verify hashes/signature                              │                 │
   │ install/configure                                                      │
   ├───────────────────────────────────────────────────────────────────────>│
   │ EnvironmentInstalled                                                   │
   └───────────────────────────────────────────────────────────────────────>│
```

### Events

- `BundleResolveRequested`
- `BundleResolved`
- `BundleDownloadStarted`
- `BundleArtifactDownloaded`
- `BundleVerified`
- `EnvironmentInstallStarted`
- `EnvironmentInstalled`
- `EnvironmentInstallFailed`

### Consumers

- Installer consumes manifests and artifacts.
- Environment Service consumes install completion and failure telemetry.
- Audit Log consumes integrity failures.
- Local Runtime consumes installation state for app launch.

### Failure States

| Failure | Retry | Recovery |
|---|---|---|
| Manifest signature invalid | No retry until manifest changes | Block install; report security incident. |
| Artifact hash mismatch | Retry download from alternate mirror | Quarantine artifact and audit. |
| Disk space insufficient | No automatic retry | Clear partial files and show requirements. |
| Dependency missing | Retry after user fixes | Provide diagnostics and fallback. |
| Lease expired before install | Revalidate | Request online validation. |

### Retry Logic

- Downloads use chunk-level verification and resumable ranges.
- Manifest failures are not retried blindly because they may indicate tampering.
- Installation steps use checkpointed phases: `downloaded`, `verified`, `unpacked`, `configured`, `registered`.

### Recovery Logic

- Partial installations remain `INSTALLING` until cleanup or resume.
- Verified artifacts can be reused after transient failures.
- Failed installs never transition to `ACTIVE`.

## 5. Reputation Publishing Flow

### Trigger

A learner completes an eligible achievement and consents to publish a reputation event through ViaDecide.

### Diagram

```text
Learning App      Local State      ViaDecide       Reputation Service      Verifier
    │                 │               │                    │                 │
    │ AchievementAwarded              │                    │                 │
    ├────────────────>│               │                    │                 │
    │                 │ publish request                    │                 │
    │                 ├──────────────>│                    │                 │
    │                 │               │ signed claim       │                 │
    │                 │               ├───────────────────>│                 │
    │                 │               │                    │ verify evidence │
    │                 │               │                    │ sign accepted   │
    │                 │               │ accepted/rejected  │                 │
    │                 │               │<───────────────────┤                 │
    │                 │ update state  │                    │                 │
    │                 │<──────────────┤                    │                 │
    │                 │               │ public proof if allowed             │
    │                 │               │────────────────────────────────────>│
```

### Events

- `AchievementAwarded`
- `ReputationPublishRequested`
- `EvidenceVerificationStarted`
- `ReputationEventAccepted`
- `ReputationEventRejected`
- `ReputationEventRevoked`

### Consumers

- Reputation Service verifies evidence and signs accepted events.
- ViaDecide updates publication state.
- Audit Log records rejected and revoked events.
- External verifiers consume public or shared proofs.

### Failure States

| Failure | Handling |
|---|---|
| Missing consent | Do not publish; keep achievement private. |
| Evidence hash unknown | Reject with `422`; request sync first. |
| Local signature invalid | Reject and audit as security event. |
| Reputation service unavailable | Queue event locally. |
| Privacy policy mismatch | Block until user reviews updated consent. |

### Retry Logic

- Pending publication events use exponential backoff.
- Duplicate `event_id` returns existing event state.
- Rejections caused by missing synced evidence can retry after sync.

### Recovery Logic

- Users can withdraw public visibility, but signed audit history remains internally.
- Incorrect achievements are superseded by revocation events.
- Evidence corrections create new reputation events rather than mutating accepted claims silently.

## 6. Offline Sync Flow

### Trigger

The local runtime detects connectivity after offline learning events have accumulated.

### Diagram

```text
Local App       Local Event Store       Sync Client       Environment Service       State Store
   │                   │                    │                    │                    │
   │ ProgressRecorded  │                    │                    │                    │
   ├──────────────────>│                    │                    │                    │
   │                   │ OfflineSyncQueued  │                    │                    │
   │                   ├───────────────────>│                    │                    │
   │                   │                    │ sync batch         │                    │
   │                   │                    ├───────────────────>│                    │
   │                   │                    │                    │ verify signatures  │
   │                   │                    │                    │ apply idempotently │
   │                   │                    │                    ├───────────────────>│
   │                   │                    │ accepted/conflicts │                    │
   │                   │                    │<───────────────────┤                    │
   │                   │ mark accepted      │                    │                    │
   │                   │<───────────────────┤                    │                    │
```

### Events

- `ProgressRecorded`
- `OfflineSyncQueued`
- `SyncBatchSubmitted`
- `SyncEventAccepted`
- `SyncEventRejected`
- `SyncConflictDetected`
- `OfflineSyncAccepted`

### Consumers

- Local Sync Client batches and submits events.
- Environment Service validates signatures and applies state transitions.
- Progress State Store materializes accepted progress.
- Reputation Service consumes newly accepted achievement evidence.

### Failure States

| Failure | Handling |
|---|---|
| Expired token | Refresh token or require reactivation. |
| Expired offline lease | Sync allowed; new offline lease requires validation. |
| Invalid event signature | Reject event; keep local copy for diagnostics. |
| Conflict with newer server state | Apply deterministic merge or return conflict metadata. |
| Server backpressure | Client slows submission using `Retry-After`. |

### Retry Logic

- Batches are retried with stable batch IDs.
- Events are idempotent by `(user_id, application, event_id)`.
- Exponential backoff with jitter is required.

### Recovery Logic

- If sync partially succeeds, accepted events are removed from pending queue and rejected events remain with reasons.
- Conflict records are visible to the user if they change progress outcomes.
- Local state snapshots allow rollback to last accepted sync point.

## 7. Recovery Flow

### Trigger

A learner loses a device, corrupts local state, changes devices, or needs to rebind a Lore Key.

### Diagram

```text
Learner       Installer       Aporaksha       Support/Admin       Environment Service
  │              │                │                │                     │
  │ recovery req │                │                │                     │
  ├─────────────>│                │                │                     │
  │              │ RecoveryRequested              │                     │
  │              ├───────────────>│                │                     │
  │              │                │ check key/user │                     │
  │              │                │ needs support? │                     │
  │              │                ├───────────────>│                     │
  │              │                │ approve/deny   │                     │
  │              │                │<───────────────┤                     │
  │              │ new device binding             │                     │
  │              │<───────────────┤                │                     │
  │              │ restore state                                     │
  │              ├────────────────────────────────────────────────────>│
  │ environment restored                                             │
  │<─────────────┤                │                │                     │
```

### Events

- `RecoveryRequested`
- `RecoveryProofSubmitted`
- `RecoveryApproved`
- `RecoveryDenied`
- `DeviceBindingCreated`
- `StateRestoreRequested`
- `StateRestored`

### Consumers

- Aporaksha validates identity and key possession.
- Support/Admin reviews high-risk recoveries.
- Environment Service restores synced state.
- Audit Log records all decisions.

### Failure States

| Failure | Handling |
|---|---|
| No physical key proof | Require stronger account proof or support escalation. |
| Key revoked | Deny automated recovery. |
| Too many device bindings | Require user/admin device removal. |
| No synced backup | Restore only local export if available. |
| Suspicious recovery pattern | Step-up verification and temporary hold. |

### Retry Logic

- User can retry proof submission after correcting input.
- Support decisions are not retried automatically.
- State restore retries are idempotent by restore request ID.

### Recovery Logic

- Device recovery creates a new binding and can suspend the lost device.
- State restoration pulls last accepted server state and then replays valid local export events if supplied.
- Reputation records remain server-verifiable even if local state is lost.
