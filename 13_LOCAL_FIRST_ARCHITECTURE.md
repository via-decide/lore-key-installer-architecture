# 13 — Local-First Architecture

## 1. Local-First Contract

After valid activation, the Capacitor runtime works offline under a signed Aporaksha lease. IndexedDB is the MVP local store. SQLite is a later migration and must preserve the same event contracts.

## 2. Runtime Diagram

```text
Capacitor Shell
├── Physical Signal Reader
├── Aporaksha Client
├── Bundle Verifier
├── Install Engine
├── IndexedDB Store
│   ├── identity_context
│   ├── offline_leases
│   ├── installs
│   ├── local_events
│   ├── sync_queue
│   ├── progress
│   ├── achievements
│   ├── reputation_drafts
│   └── zayvora_permissions
└── Sync Client
```

## 3. Bundle Cache

The cache stores verified manifest metadata and artifact references. Large artifacts are stored using platform-supported file/cache APIs when available; IndexedDB stores metadata, hashes, and install checkpoints.

Rules:

- Cache by SHA-256 hash.
- Manifest usable only after signature verification.
- Revoked versions cannot be newly installed.
- Cache eviction never deletes user-created data or event history.

## 4. IndexedDB Schema

| Store | Key | Purpose |
|---|---|---|
| `identity_context` | `userId` | User/key/device IDs and active capabilities. |
| `offline_leases` | `leaseId` | Signed Aporaksha leases. |
| `bundle_cache` | `bundleCode@version` | Manifest metadata and hashes. |
| `installs` | `installId` | Install lifecycle and checkpoints. |
| `local_events` | `eventId` | Append-only local event log. |
| `sync_queue` | `eventId` | Pending server reconciliation. |
| `progress` | `application:subjectRef` | Local materialized progress. |
| `achievements` | `achievementId` | Derived milestones. |
| `reputation_drafts` | `draftId` | Consent-pending reputation drafts. |
| `zayvora_permissions` | `permissionId` | Projection consent and scopes. |

## 5. Sync Queue Flow

```text
App calls SDK
  -> event schema validation
  -> canonical JSON
  -> event hash
  -> device signature
  -> local_events insert
  -> sync_queue insert
  -> local materialization
  -> batch submit when online
  -> server reconciliation
```

## 6. Conflict Resolution

| Conflict | Resolver |
|---|---|
| Duplicate event | Return existing accepted state. |
| Lesson completion from two devices | Preserve both events; materialize complete. |
| Competing exam attempt slot | Preserve attempts; active result selected by event time and policy. |
| Event after lease expiry | Reject protected progress or mark low-trust by policy. |
| Missing dependency | Hold event until dependency arrives or reject with reason. |

## 7. Offline Lease Behavior

```text
ACTIVE lease -> OFFLINE runtime -> WARNING at T-72h -> EXPIRED restricted mode
```

Allowed with active lease:

- Run installed environments.
- Record progress events.
- Queue sync.
- Create reputation drafts.

Allowed after expiry:

- View local notes and prior progress.
- Export local data.
- Sync existing queued events.

Blocked after expiry:

- New protected progress.
- New installs.
- Reputation publication.
- Zayvora projection submission.

## 8. Recovery

```text
Startup failure -> classify
  -> IndexedDB inaccessible: recovery diagnostics
  -> corrupt local events: preserve export and request server state
  -> device replacement: Aporaksha recovery + state restore
  -> failed install: rollback checkpoint
```

Recovery must not accept unsigned imports, bypass revoked key checks, or publish reputation until evidence is verified.
