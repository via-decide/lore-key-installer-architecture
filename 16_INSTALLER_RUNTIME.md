# 16 — Installer Runtime

## 1. Runtime Goal

The installer runtime converts a validated Lore Key ownership into a verified local environment. It runs inside the Capacitor shell for MVP and uses IndexedDB as local state.

## 2. Flow

```text
Physical Signal -> Aporaksha Validation -> Bundle Resolution -> Manifest Verification
-> Artifact Verification -> Environment Installation -> IndexedDB State Creation
-> Runtime SDK Enabled -> Offline Operation
# Installer Runtime Specification

## 1. Purpose

The Installer Runtime is the local execution engine that turns a physical Lore Key into a configured learning environment. It performs key validation, bundle resolution, artifact download, cryptographic verification, installation, runtime configuration, offline enforcement, updates, rollback, and recovery.

## 2. Runtime Flow

```text
Lore Key
  │ scan/tap/challenge
  v
Validation
  │ Aporaksha activation or validation
  v
Bundle Resolution
  │ Bundle Resolver returns signed .viabundle
  v
Environment Installation
  │ download -> verify -> install -> configure
  v
Runtime Configuration
  │ local SQLite -> leases -> SDK -> apps
  v
Active Local Environment
```

## 3. Components

| Component | Responsibility |
|---|---|
| Signal Reader | QR/NFC/serial capture. |
| Aporaksha Client | activate, validate, renew leases. |
| Device Key Manager | generate and use device keypair. |
| Bundle Client | resolve and download manifests. |
| Bundle Verifier | schema, signature, hash checks. |
| Install Engine | plan, checkpoint, install, rollback. |
| IndexedDB Store | local identity, leases, events, progress. |
| Runtime SDK | app capability checks and event append. |
| Sync Client | batch queue submission and reconciliation. |
| Recovery Manager | repair, export, restore, rollback. |

## 4. Install State Machine

```text
IDLE -> SCANNING -> VALIDATING -> RESOLVING -> VERIFYING -> INSTALLING -> CONFIGURING -> ACTIVE
  |        |            |            |            |             |
  +--------+------------+------------+------------+-------------+-> FAILED -> ROLLED_BACK
```

## 5. Rollback Rules

- Create checkpoint before modifying runtime config.
- Never delete user events, notes, exports, or progress.
- Roll back app/module files and config only.
- Preserve diagnostics.
- Mark install `ROLLED_BACK` locally and sync telemetry later.

## 6. Offline Mode

The runtime allows offline operation if a valid lease grants capabilities. It blocks protected actions after expiry, but read/export and sync existing queue remain available.

## 7. Update Mechanism

Update metadata is signed. Installer update, bundle update, trust-store update, and policy update each require signature verification. Failed updates roll back to previous verified version.

## 8. Runtime SDK Interface

```text
getIdentityContext()
getLeaseStatus()
requireCapability(capability)
appendEvent(eventInput)
readProgress(query)
createReputationDraft(achievementId)
requestZayvoraProjection(scope)
syncNow()
exportLocalState()
```

## 9. Failure Handling

| Failure | Behavior |
|---|---|
| Aporaksha unavailable | Use existing valid lease or block activation. |
| Invalid manifest | Stop install and audit. |
| Artifact mismatch | Quarantine and retry alternate source. |
| IndexedDB failure | Enter recovery diagnostics mode. |
| Lease expired | Restrict protected capabilities. |
| Key Scanner | QR, NFC, serial, secure challenge input. |
| Identity Client | Calls Aporaksha activation/validation/lease APIs. |
| Device Binding Agent | Creates and signs device assertions. |
| Bundle Resolver Client | Requests eligible manifests. |
| Bundle Cache | Stores verified manifests and artifacts. |
| Verification Engine | Validates schemas, signatures, hashes, and dependency graph. |
| Installation Planner | Computes install steps and prerequisites. |
| Execution Engine | Runs install operations with checkpoints. |
| Runtime Configurator | Writes environment config and capabilities. |
| Local Store | SQLite encrypted state. |
| Sync Agent | Submits offline events. |
| Recovery Manager | Restores from checkpoints, snapshots, or server state. |
| Update Manager | Applies installer and bundle updates safely. |

## 4. Installation State Machine

```text
IDLE
  │ user starts
  v
SCANNING_KEY -> VALIDATING -> RESOLVING_BUNDLE -> PLANNING
      |             |              |                |
      +-------------+--------------+----------------+-> FAILED
                                                    |
                                                    v
DOWNLOADING -> VERIFYING -> INSTALLING -> CONFIGURING -> ACTIVE
     |             |            |             |
     +-------------+------------+-------------+-> ROLLING_BACK -> RECOVERABLE_FAILED
```

## 5. Detailed Execution Flow

### 5.1 Key Intake

1. User scans QR, taps NFC, enters serial, or performs secure challenge.
2. Scanner normalizes payload into `KeyProof`.
3. Installer stores no raw activation secret after request construction.
4. Device Binding Agent ensures a device keypair exists.

### 5.2 Validation

1. If no identity context exists, call activation.
2. If identity exists, call validation.
3. Verify server response and lease signature.
4. Store lease in encrypted SQLite.
5. Transition environment to `AUTHENTICATING` then `LOCKED`, `INSTALLING`, or `ACTIVE` based on result.

### 5.3 Bundle Resolution

1. Send application, platform, current versions, and capabilities to Bundle Resolver.
2. Receive manifest URL, hash, signature, and policy.
3. Download manifest.
4. Validate JSON Schema.
5. Verify manifest hash and publisher signature.
6. Build dependency graph.
7. Fail if dependencies are unresolved or cyclic.

### 5.4 Installation Planning

Plan must include:

- Required disk space.
- Required OS permissions.
- Artifact download set.
- Installation directories.
- Rollback checkpoints.
- Runtime configuration writes.
- App registration steps.
- Post-install validation commands.

### 5.5 Artifact Download and Verification

```text
manifest artifacts
    │
    v
for each artifact:
    download to tmp
    verify size
    verify sha256
    optional decrypt
    move to content-addressed cache
```

Rules:

- Never execute downloaded artifacts before verification.
- Hash mismatch quarantines temporary file.
- Downloads are resumable by byte ranges or chunk manifests.
- Local mirrors are allowed only for signed immutable artifacts.

### 5.6 Runtime Configuration

The installer writes:

- Environment record.
- Bundle install record.
- Offline lease record.
- App capabilities.
- Local SDK configuration.
- Sync queue configuration.
- App launch entries.

## 6. Failure Handling

| Failure | Detection | Action |
|---|---|---|
| Invalid key proof | Aporaksha response | Show activation error; do not install. |
| Suspended/revoked key | Validation response | Enter locked or sync-only mode. |
| Manifest invalid | Schema/signature check | Block install and audit. |
| Artifact corrupt | Hash mismatch | Retry alternate mirror; quarantine file. |
| Dependency missing | Planner | Show prerequisite instructions. |
| Disk insufficient | Planner/preflight | Abort before modification. |
| Install script failure | Exit code/checkpoint | Roll back to last safe checkpoint. |
| SQLite unavailable | Startup/open failure | Enter recovery mode. |
| Lease expired | Runtime capability check | Restrict protected features. |

## 7. Rollback

### 7.1 Rollback Invariants

- Never delete learner-created data.
- Never roll back to an unsigned or unverified version.
- Always record rollback reason and phase.
- Preserve diagnostic logs and install checkpoints.

### 7.2 Rollback Phases

```text
CREATE_CHECKPOINT -> STOP_APP -> RESTORE_FILES -> RESTORE_CONFIG -> VERIFY -> MARK_ROLLED_BACK
          |             |              |              |
          +-------------+--------------+--------------+-> ROLLBACK_FAILED
```

### 7.3 Rollback Strategy by Install Strategy

| Install Strategy | Rollback |
|---|---|
| `copy` | Restore prior file tree snapshot. |
| `extract` | Remove extracted files listed in manifest; restore previous version. |
| `scripted` | Run signed rollback script with restricted permissions. |
| `container` | Switch image tag/digest back to prior verified digest. |
| `runtime-module` | Disable module and restore previous config. |

## 8. Recovery

### 8.1 Recovery Modes

| Mode | Trigger | Behavior |
|---|---|---|
| Local snapshot recovery | Failed update or corruption | Restore last good SQLite snapshot and config. |
| Server state recovery | Device replacement | Validate key, bind device, pull accepted state. |
| Import recovery | User has export | Verify signed export and replay events. |
| Support recovery | Automated proof insufficient | Generate support package and require admin approval. |

### 8.2 Recovery Flow

```text
Recovery requested
    │
    v
Classify failure
    │
    ├── install failure -> rollback
    ├── local db corruption -> snapshot restore
    ├── new device -> Aporaksha recovery
    └── suspicious state -> support escalation
```

## 9. Offline Mode

Offline mode begins when network validation is unavailable but a valid lease exists.

Allowed:

- Launch installed environments.
- Read local content and notes.
- Record lease-authorized progress.
- Queue sync events.
- Queue reputation drafts.

Denied or restricted:

- New protected installs without cached entitlement.
- Reputation publication to public network.
- Lease renewal.
- Device binding changes.
- High-stakes exam attempts after lease expiry.

## 10. Update Mechanism

### 10.1 Update Types

| Update | Scope | Required Validation |
|---|---|---|
| Installer update | Runtime binary | Code signature and updater signature. |
| Bundle update | Learning content/modules | `.viabundle` signature and compatibility. |
| App update | StudyOS/PrepOS/etc. | App signature and state migration. |
| Trust store update | Signing keys/revocations | Signature by root update key. |
| Policy update | Lease or entitlement policy | Aporaksha validation. |

### 10.2 Update Flow

```text
Check update -> Download metadata -> Verify signature -> Preflight -> Snapshot
      -> Apply update -> Verify postconditions -> Mark active
      -> if failure: rollback and report
```

### 10.3 Migration Rules

- Migrations are versioned and idempotent.
- Local database migration runs after snapshot creation.
- Failed migration restores snapshot.
- Major bundle migrations require user confirmation if rollback may be limited.

## 11. Installer Interfaces

### 11.1 Local Runtime SDK

```ts
interface LoreKeyRuntime {
  getIdentityContext(): IdentityContext;
  requireCapability(capability: Capability): CapabilityDecision;
  appendEvent(event: LocalEventInput): Promise<AppendEventResult>;
  getProgress(query: ProgressQuery): Promise<ProgressResult>;
  requestReputationDraft(input: ReputationDraftInput): Promise<ReputationDraft>;
  getLeaseStatus(): LeaseStatus;
}
```

### 11.2 Installer CLI

```text
lorekey scan
lorekey activate --serial LK-2026-000001
lorekey install --app StudyOS --bundle chemistry-foundations
lorekey validate
lorekey sync
lorekey repair
lorekey export --output learner-export.lkexport
```

## 12. Testing Requirements

- Activation happy path and revoked key denial.
- Manifest signature failure blocks install.
- Artifact hash mismatch quarantine.
- Interrupted download resume.
- Rollback preserves user data.
- Offline 30-day lease behavior.
- Expired lease restricted mode.
- SQLite corruption recovery mode.
- Duplicate sync event idempotency.
- Update failure rollback.
