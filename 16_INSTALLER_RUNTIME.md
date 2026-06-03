# 16 — Installer Runtime

## 1. Runtime Goal

The installer runtime converts a validated Lore Key ownership into a verified local environment. It runs inside the Capacitor shell for MVP and uses IndexedDB as local state.

## 2. Flow

```text
Physical Signal -> Aporaksha Validation -> Bundle Resolution -> Manifest Verification
-> Artifact Verification -> Environment Installation -> IndexedDB State Creation
-> Runtime SDK Enabled -> Offline Operation
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
