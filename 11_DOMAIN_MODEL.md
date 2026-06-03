# 11 — Domain Model

## 1. Domain Rule

The Lore Key artifact is not an identity. It is a physical signal that Aporaksha validates during authenticated ownership activation.

## 2. UML-Style Model

```mermaid
classDiagram
  User "1" --> "0..*" Ownership
  LoreKey "1" --> "0..1" Ownership
  Ownership "1" --> "0..*" DeviceBinding
  DeviceBinding "1" --> "0..*" OfflineLease
  Bundle "1" --> "0..*" BundleVersion
  BundleVersion "1" --> "0..*" Install
  Environment "1" --> "0..*" Install
  Install "1" --> "0..*" ProgressEvent
  ProgressEvent "0..*" --> "0..*" Achievement
  Achievement "0..*" --> "0..*" ReputationEvent
  ProgressEvent "0..*" --> "0..*" ZayvoraProjection

  class User { UUID id; email; displayName; region; status }
  class LoreKey { UUID id; serial; signalHashes; hardwareTier; status }
  class Ownership { UUID id; userId; loreKeyId; status; activatedAt }
  class DeviceBinding { UUID id; deviceId; publicKey; platform; status }
  class OfflineLease { UUID id; capabilities; expiresAt; signature }
  class Bundle { code; title; publisherId; status }
  class BundleVersion { version; manifestSha256; signature; immutable }
  class Environment { name; status; localStateVector }
  class Install { status; checkpoint; manifestSha256 }
  class ProgressEvent { eventId; eventType; payload; hash; signature }
  class Achievement { code; evidenceHash; status }
  class ReputationEvent { claimType; evidenceEvents; serverSignature; status }
  class ZayvoraProjection { scope; sourceEvents; permissionVersion; status }
```

## 3. Entities

### User

Purpose: authenticated learner or operator.

Attributes: `id`, `email`, `displayName`, `region`, `status`, `consentVersions`, `recoveryPublicKey`, timestamps, `deletedAt`.

Relationships: owns Ownership records; owns events, progress, achievements, reputation, and projections.

Lifecycle: `NEW -> ACTIVATED -> ENGAGED -> CONTRIBUTOR -> ALUMNI`; `SUSPENDED` restricts capabilities.

Validation: email or recovery key required; current consent required before activation; soft-deleted users cannot activate.

Constraints: user controls local history exports; server audit remains pseudonymized when required.

### LoreKey

Purpose: manufactured artifact record and physical signal reference.

Attributes: `id`, `serial`, `publicCodeHash`, `nfcUidHash`, `secureElementPublicKey`, `hardwareTier`, `manufacturingBatch`, `status`.

Relationships: has zero or one active Ownership.

Lifecycle: `REGISTERED -> UNCLAIMED -> OWNED -> ACTIVE -> SUSPENDED -> REVOKED`.

Validation: serial unique; raw activation codes never stored; secure element tier requires public key.

Constraints: QR/NFC/serial are signals only; revoked is terminal.

### Ownership

Purpose: binding between authenticated User and LoreKey.

Attributes: `id`, `userId`, `loreKeyId`, `status`, `activatedAt`, `reason`.

Relationships: one User, one LoreKey, many DeviceBindings.

Lifecycle: `PENDING -> ACTIVE -> SUSPENDED -> ACTIVE` or `REVOKED`.

Validation: one active ownership per key; activation requires Aporaksha validation.

Constraints: transfer requires admin or recovery workflow.

### DeviceBinding

Purpose: binds ownership to device public key.

Attributes: `id`, `deviceId`, `platform`, `publicKey`, `trustTier`, `status`, timestamps.

Relationships: belongs to Ownership; issues OfflineLeases.

Lifecycle: `REQUESTED -> ACTIVE -> SUSPENDED/REMOVED/LOST`.

Validation: public key required; signed assertions required; device limit enforced.

Constraints: device private key never leaves device.

### OfflineLease

Purpose: signed local authorization for offline runtime.

Attributes: `id`, `userId`, `ownershipId`, `deviceId`, `capabilities`, `issuedAt`, `expiresAt`, `signature`, `status`.

Relationships: belongs to DeviceBinding; referenced by events.

Lifecycle: `ACTIVE -> EXPIRED`, `ACTIVE -> SUPERSEDED`, `ACTIVE -> REVOKED`.

Validation: Aporaksha signature required; capability scope explicit.

Constraints: expired leases preserve local data but block protected features.

### Bundle

Purpose: product-level installable environment family.

Attributes: `bundleCode`, `title`, `primaryApplication`, `publisherId`, `eligibilityRules`, `status`.

Relationships: has BundleVersions.

Lifecycle: `DRAFT -> SIGNED -> PUBLISHED -> DEPRECATED/REVOKED`.

Validation: published versions must be immutable and signed.

Constraints: bundle content is never stored on LoreKey.

### BundleVersion

Purpose: immutable signed `.viabundle.json` release.

Attributes: `version`, `channel`, `manifestUrl`, `manifestSha256`, `signature`, `signingKeyId`, status.

Relationships: installed by Installs.

Lifecycle: `SIGNED -> PUBLISHED -> DEPRECATED/REVOKED`.

Validation: semver required; hash and signature required.

Constraints: a published version cannot be mutated; create a new version instead.

### Environment

Purpose: local runtime context for StudyOS, PrepOS, SkillHex, ViaDecide, or Zayvora.

Attributes: `name`, `status`, `capabilities`, `localStateVector`.

Relationships: has Installs and events.

Lifecycle: `LOCKED -> AUTHENTICATING -> INSTALLING -> ACTIVE -> OFFLINE -> EXPIRED`.

Validation: active environment requires verified install and valid lease.

Constraints: environment expiry never deletes user data.

### Install

Purpose: installation instance of BundleVersion into Environment.

Attributes: `id`, `status`, `manifestSha256`, `checkpoint`, `installPathHash`, `failureReason`.

Relationships: belongs to User, DeviceBinding, Environment, BundleVersion.

Lifecycle: `PLANNED -> DOWNLOADING -> VERIFYING -> INSTALLING -> CONFIGURING -> ACTIVE`; failure path `FAILED -> ROLLED_BACK`.

Validation: cannot become active without signature/hash verification.

Constraints: rollback preserves local user-created data.

### ProgressEvent

Purpose: canonical event proving learning activity.

Attributes: `eventId`, `eventType`, `application`, `aggregate`, `payload`, `eventHash`, `signature`, `leaseId`, `status`.

Relationships: materializes Progress and can contribute to Achievement.

Lifecycle: `LOCAL_CREATED -> QUEUED -> SUBMITTED -> ACCEPTED/REJECTED/CONFLICTED -> MATERIALIZED`.

Validation: schema, hash, signature, idempotency, lease window.

Constraints: progress is event-based; direct manual progress mutation is not authoritative.

### Achievement

Purpose: derived milestone from accepted events.

Attributes: `achievementCode`, `title`, `evidenceEventIds`, `evidenceHash`, `status`.

Relationships: may produce ReputationEvents.

Lifecycle: `PENDING -> AWARDED -> REVOKED/SUPERSEDED`.

Validation: evidence events must be accepted.

Constraints: achievements are private until reputation consent.

### ReputationEvent

Purpose: signed claim generated from verified evidence.

Attributes: `reputationEventId`, `claimType`, `claim`, `evidenceEventIds`, `serverSignature`, `status`, `consentVersion`.

Relationships: references Achievement and events.

Lifecycle: `DRAFT -> PENDING_VERIFICATION -> ACCEPTED/PUBLISHED` or `REJECTED/REVOKED`.

Validation: verified events and consent required.

Constraints: manual claims cannot become verified reputation.

### SyncEvent

Purpose: client queue item submitted for server reconciliation.

Attributes: `syncBatchId`, `eventId`, `status`, `attempts`, `conflictDetails`, `rejectionReason`.

Relationships: wraps ProgressEvent envelope.

Lifecycle: `PENDING -> PROCESSING -> ACCEPTED/REJECTED/CONFLICTED`.

Validation: stable IDs and idempotent server response.

Constraints: rejected events remain diagnosable.

### ZayvoraProjection

Purpose: permissioned memory/context projection.

Attributes: `projectionId`, `scope`, `sourceEventIds`, `permissionVersion`, `projectionPayload`, `status`.

Relationships: references User and source events.

Lifecycle: `REQUESTED -> CREATED -> INSPECTED -> CORRECTED/REVOKED`.

Validation: explicit permission and source events required.

Constraints: projection is scoped, inspectable, and revocable.
