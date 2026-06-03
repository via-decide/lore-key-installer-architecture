# Local-First Architecture

## 1. Purpose

Lore Key must continue to deliver value when connectivity is poor, intermittent, censored, expensive, or absent. Local-first does not mean cloudless. It means the learner's device is the primary execution environment and cloud services provide validation, entitlement, synchronization, reputation verification, and recovery when available.

## 2. Local-First Principles

1. Learning actions are recorded locally before network submission.
2. Installed environments can run under bounded offline leases.
3. Bundle artifacts are cached after signature and hash verification.
4. Sync is idempotent, resumable, and conflict-aware.
5. Reputation publication waits for verification and user consent.
6. Recovery preserves learner-owned progress whenever possible.

## 3. Local Runtime Components

```text
┌──────────────────────────────────────────────────────────────┐
│ Local Device                                                  │
│                                                              │
│ ┌───────────────┐      ┌────────────────────┐                │
│ │ Key Scanner   │─────>│ Identity Context   │                │
│ └───────────────┘      └─────────┬──────────┘                │
│                                  │                           │
│ ┌───────────────┐      ┌─────────v──────────┐                │
│ │ Bundle Cache  │<────>│ Installer Engine   │                │
│ └──────┬────────┘      └─────────┬──────────┘                │
│        │                         │                           │
│ ┌──────v────────┐      ┌─────────v──────────┐                │
│ │ SQLite Store  │<────>│ Local Runtime SDK  │<── Learning Apps│
│ └──────┬────────┘      └─────────┬──────────┘                │
│        │                         │                           │
│ ┌──────v────────┐      ┌─────────v──────────┐                │
│ │ Sync Queue    │─────>│ Sync Client        │───── Network    │
│ └───────────────┘      └────────────────────┘                │
└──────────────────────────────────────────────────────────────┘
```

## 4. Bundle Cache

### 4.1 Purpose

The Bundle Cache stores verified manifests, downloaded artifacts, installation checkpoints, and local mirror metadata. It reduces bandwidth, supports offline installation from pre-cached artifacts, and enables rollback.

### 4.2 Cache Layout

```text
~/.lorekey/cache
├── manifests
│   └── {bundleCode}/{version}/manifest.viabundle.json
├── artifacts
│   └── sha256/{first-two-bytes}/{artifact-hash}.blob
├── signatures
│   └── {keyId}.sig
├── checkpoints
│   └── {installId}.json
└── mirrors
    └── classroom-mirror-index.json
```

### 4.3 Cache Rules

- Cache entries are addressed by content hash, not mutable filenames.
- A manifest is usable only if its signature chain is trusted.
- Artifacts are promoted from `tmp` to `artifacts` only after hash verification.
- Revoked manifests are retained for forensics but blocked for new installs.
- Cache eviction never deletes installed user data or SQLite records.

## 5. SQLite Storage

### 5.1 Purpose

SQLite is the local source of truth for offline runtime state. It stores identity context, leases, installed environments, progress events, sync queue entries, achievements, memory records, and diagnostics.

### 5.2 Local Tables

| Table | Purpose |
|---|---|
| `identity_context` | User ID, key ID, device ID, current capabilities. |
| `device_keys` | References to OS keychain-held private keys and public keys. |
| `offline_leases` | Issued leases, expiry, capabilities, server signatures. |
| `bundle_cache_index` | Verified manifests and artifact hashes. |
| `environment_installs` | Local install lifecycle and checkpoints. |
| `local_events` | Append-only event log from apps. |
| `progress_materialized` | Query-optimized local progress state. |
| `achievements` | Local achievements awaiting or after sync. |
| `sync_queue` | Pending, accepted, rejected, and conflicted events. |
| `memory_records` | Zayvora local memory with provenance. |
| `diagnostics` | Installer/runtime logs safe for support export. |

### 5.3 Encryption Rules

- SQLite file should be encrypted using SQLCipher or platform-equivalent encryption.
- Device private keys must be stored in the OS keychain, TPM, Secure Enclave, or equivalent where available.
- If platform secure storage is unavailable, the installer must warn the user and apply approved fallback encryption.
- Raw secrets, activation codes, and private signing keys must not be stored in plaintext.

## 6. Sync Queue

### 6.1 Event Flow

```text
Learning App
    │ append event
    v
Local Runtime SDK
    │ canonicalize + hash + sign
    v
local_events table
    │ materialize locally
    v
sync_queue table
    │ batch when online
    v
Environment Service
    │ verify + dedupe + resolve conflicts
    v
Server Materialized State
    │ response
    v
Local queue marks accepted/rejected/conflicted
```

### 6.2 Queue Entry Contract

| Field | Description |
|---|---|
| `eventId` | Deterministic UUID/ULID generated by client. |
| `eventType` | Canonical event type from `/packages/events`. |
| `application` | Source app. |
| `payload` | Canonically serialized event payload. |
| `eventHash` | SHA-256 hash of canonical payload plus envelope fields. |
| `signature` | Device key signature. |
| `dependencyEventIds` | Optional event dependencies. |
| `leaseId` | Offline lease under which event occurred. |
| `occurredAt` | Device timestamp. |
| `monotonicCounter` | Local sequence counter for tamper detection. |

### 6.3 Submission Rules

- Submit batches in monotonic counter order when possible.
- Preserve dependencies within a batch.
- Use stable `syncBatchId` for retries.
- Treat `ACCEPTED` response as final.
- Keep `REJECTED` entries locally with reason for support.
- Do not publish reputation from unsynced progress unless policy marks it low-trust/local-only.

## 7. Conflict Resolution

### 7.1 Conflict Classes

| Conflict | Example | Resolution |
|---|---|---|
| Duplicate event | Retry after timeout | Idempotent accept existing result. |
| Concurrent progress | Same lesson completed on two devices | Max completion, preserve both events. |
| Score conflict | Two exam attempts for same slot | Preserve attempts separately; materialize latest submitted attempt if slot-bound. |
| Achievement conflict | Local achievement derived from rejected progress | Mark achievement pending/rejected until evidence resolves. |
| Lease conflict | Event occurred after offline lease expiry | Accept only non-protected local notes; reject protected progress/reputation evidence. |
| Clock drift | Device time jumps backwards | Use monotonic counter, mark trust lowered, request online validation. |

### 7.2 Resolver Pipeline

```text
Incoming Sync Batch
        │
        v
Schema Validation
        │
        v
Signature Verification
        │
        v
Idempotency Check
        │
        v
Dependency Check
        │
        v
Lease Window Check
        │
        v
Domain Resolver
        │
        ├── accept
        ├── reject
        └── conflict
```

### 7.3 Deterministic Rules

- Completion progress uses highest verified completion percentage.
- Attempts are append-only unless the event is an explicit correction.
- Achievements are derived from accepted evidence only.
- Memory records can be superseded but retain source provenance.
- User-visible conflict messages must identify the affected app, subject, and resolution.

## 8. Offline Leases

### 8.1 Purpose

Offline leases authorize protected local behavior for bounded periods without requiring continuous connectivity.

### 8.2 Lease Contents

```json
{
  "lease_id": "lease_01HX",
  "user_id": "usr_01HX",
  "lore_key_id": "key_01HX",
  "device_id": "dev_01HX",
  "capabilities": ["RUN_STUDYOS", "RECORD_PROGRESS", "QUEUE_REPUTATION"],
  "issued_at": "2026-06-02T00:00:00Z",
  "expires_at": "2026-07-02T00:00:00Z",
  "max_clock_drift_seconds": 900,
  "server_signature": "base64url..."
}
```

### 8.3 Lease State Diagram

```text
ISSUED -> ACTIVE -> WARNING -> EXPIRED -> RENEWAL_REQUIRED
   |         |          |          |
   |         |          |          +-> SYNC_ONLY
   |         |          +-> RENEWED
   |         +-> REVOKED_ONLINE
   +-> INVALID_SIGNATURE
```

### 8.4 Lease Enforcement

| Capability | Active Lease | Expired Lease |
|---|---|---|
| Open app shell | Allowed | Allowed. |
| View local notes | Allowed | Allowed. |
| Record protected progress | Allowed | Blocked or marked untrusted by policy. |
| Take offline exam | Allowed | Blocked. |
| Publish reputation | Queued only | Blocked. |
| Sync existing events | Allowed | Allowed. |
| Renew lease | Online only | Online only. |

## 9. Environment Expiry

```text
ACTIVE
  │ network lost
  v
OFFLINE
  │ lease T-72h
  v
EXPIRY_WARNING
  │ lease expired
  v
EXPIRED
  │ online validation succeeds
  v
ACTIVE
```

Expiry rules:

- Warning starts at policy-defined threshold, default 72 hours before expiry.
- Expiry must never delete local user data.
- Expired environments enter restricted mode.
- Sync remains available after expiry to prevent data loss.
- New installs require online validation if lease expired.

## 10. Recovery Flow

### 10.1 Local Corruption Recovery

```text
App startup
   │
   v
Open encrypted SQLite
   │ success
   v
Normal runtime
   │ failure
   v
Recovery mode
   │
   ├── restore from last local snapshot
   ├── import user export
   ├── sync from server accepted state
   └── create support diagnostics package
```

### 10.2 Device Replacement Recovery

```text
New Device -> Scan Lore Key -> Aporaksha Recovery Check
      │              │                 │
      │              │ valid proof      v
      │              └────────────> Device Binding Created
      │                                  │
      v                                  v
Install Runtime <---------------- State Restore
      │
      v
Sync accepted server state + optional local export replay
```

### 10.3 Recovery Constraints

- Recovery must not bypass key status checks.
- Recovery must not accept unsigned local event imports.
- Reputation publishing remains disabled until recovered state is verified.
- A lost key plus weak account proof requires support escalation.

## 11. Offline Test Matrix

| Scenario | Expected Result |
|---|---|
| 7 days offline, active lease | Progress queues and syncs. |
| 31 days offline, 30-day lease | Environment enters expired restricted mode. |
| Duplicate sync batch | Server returns existing accepted state. |
| Corrupted artifact cache | Artifact is redownloaded or install blocked. |
| Corrupted SQLite | Recovery mode starts; no destructive auto-repair. |
| Clock rollback | Trust lowered and validation requested. |
| Server rejects one event in batch | Accepted events removed from pending; rejected event retained with reason. |
