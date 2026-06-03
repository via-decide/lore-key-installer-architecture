# System Sequence Diagrams

## 1. Activation

```mermaid
sequenceDiagram
  actor Learner
  participant Installer
  participant Key as Lore Key
  participant Aporaksha
  participant DB as Identity DB
  participant Audit

  Learner->>Installer: Start activation
  Installer->>Key: Scan QR / read NFC / challenge
  Key-->>Installer: Key proof payload
  Installer->>Installer: Generate device keypair if missing
  Installer->>Aporaksha: POST /activate(keyProof, user, device)
  Aporaksha->>Aporaksha: Validate schema, nonce, rate limits
  Aporaksha->>DB: Lookup key by hashed proof
  DB-->>Aporaksha: Key status UNCLAIMED/CLAIMED
  Aporaksha->>DB: Create user, activation, device binding
  Aporaksha->>DB: Transition key CLAIMED/ACTIVE
  Aporaksha->>Audit: Record activation
  Aporaksha-->>Installer: Tokens, lease, next actions
  Installer->>Installer: Store identity context and lease
  Installer-->>Learner: Activation complete
```

## 2. Installation

```mermaid
sequenceDiagram
  actor Learner
  participant Installer
  participant Aporaksha
  participant Resolver as Bundle Resolver
  participant CDN
  participant LocalDB as Local SQLite
  participant App as Learning Environment

  Learner->>Installer: Install StudyOS bundle
  Installer->>Aporaksha: POST /validate(device assertion, capabilities)
  Aporaksha-->>Installer: Valid lease and capabilities
  Installer->>Resolver: GET /bundles/resolve(application, platform)
  Resolver-->>Installer: Manifest URL, hash, signature, policy
  Installer->>CDN: Download .viabundle manifest
  CDN-->>Installer: Manifest
  Installer->>Installer: Validate schema and signature
  Installer->>CDN: Download artifacts
  CDN-->>Installer: Artifacts
  Installer->>Installer: Verify artifact hashes
  Installer->>LocalDB: Create install checkpoint
  Installer->>Installer: Execute install plan
  Installer->>LocalDB: Register environment ACTIVE
  Installer->>App: Launch/configure runtime
  App-->>Learner: Environment ready
```

## 3. Progress Tracking

```mermaid
sequenceDiagram
  actor Learner
  participant App as StudyOS/PrepOS/SkillHex
  participant SDK as Local Runtime SDK
  participant LocalDB as Local SQLite
  participant Sync as Sync Agent
  participant EnvSvc as Environment Service

  Learner->>App: Complete lesson / attempt / project step
  App->>SDK: appendEvent(progress payload)
  SDK->>SDK: Canonicalize, hash, sign event
  SDK->>LocalDB: Insert local_events row
  SDK->>LocalDB: Update local materialized progress
  SDK->>LocalDB: Insert sync_queue row
  SDK-->>App: Event accepted locally
  App-->>Learner: Progress updated
  Sync->>LocalDB: Read pending events
  Sync->>EnvSvc: POST /environments/sync(batch)
  EnvSvc->>EnvSvc: Verify signatures, dedupe, resolve
  EnvSvc-->>Sync: Accepted/rejected/conflicted events
  Sync->>LocalDB: Update sync statuses and state vector
```

## 4. Reputation Publishing

```mermaid
sequenceDiagram
  actor Learner
  participant App as SkillHex/StudyOS
  participant ViaDecide
  participant LocalDB as Local SQLite
  participant Aporaksha
  participant RepSvc as Reputation Service
  participant Verifier

  App->>LocalDB: Achievement awarded with evidence refs
  Learner->>ViaDecide: Review reputation draft
  ViaDecide->>Learner: Show fields, evidence summary, privacy scope
  Learner->>ViaDecide: Consent to publish/share
  ViaDecide->>Aporaksha: Request identity context assertion
  Aporaksha-->>ViaDecide: Signed identity assertion
  ViaDecide->>LocalDB: Read achievement and evidence hashes
  ViaDecide->>RepSvc: POST /reputation/events(claim, evidence, signatures)
  RepSvc->>RepSvc: Verify consent, identity, evidence, fraud signals
  alt Accepted
    RepSvc-->>ViaDecide: Accepted event, server signature, optional URL
    ViaDecide->>LocalDB: Mark reputation accepted
    ViaDecide-->>Learner: Reputation published/shared
    Verifier->>RepSvc: Verify public/shared event
    RepSvc-->>Verifier: Current signed status
  else Rejected
    RepSvc-->>ViaDecide: Rejection reason
    ViaDecide->>LocalDB: Mark rejected with reason
    ViaDecide-->>Learner: Show remediation
  end
```

## 5. Offline Sync

```mermaid
sequenceDiagram
  actor Learner
  participant App
  participant SDK
  participant LocalDB as Local SQLite
  participant Sync
  participant Aporaksha
  participant EnvSvc as Environment Service

  Learner->>App: Learn while offline
  App->>SDK: appendEvent()
  SDK->>LocalDB: Store signed local event
  SDK->>LocalDB: Queue sync event
  App-->>Learner: Local progress visible

  Note over Sync: Network returns later
  Sync->>Aporaksha: Validate/renew lease if possible
  Aporaksha-->>Sync: Lease renewed or sync-only allowed
  Sync->>LocalDB: Build batch from pending queue
  Sync->>EnvSvc: POST /environments/sync(syncBatchId, events)
  EnvSvc->>EnvSvc: Verify event hashes and signatures
  EnvSvc->>EnvSvc: Check lease windows and dependencies
  EnvSvc->>EnvSvc: Resolve conflicts deterministically
  EnvSvc-->>Sync: accepted, rejected, conflicts, state vector
  Sync->>LocalDB: Mark accepted/rejected/conflicted
  Sync->>LocalDB: Update local state vector
  Sync-->>Learner: Sync complete or conflicts require review
```

## 6. Recovery

```mermaid
sequenceDiagram
  actor Learner
  participant Installer
  participant Key as Lore Key
  participant Aporaksha
  participant Support
  participant EnvSvc as Environment Service
  participant LocalDB as Local SQLite

  Learner->>Installer: Start recovery on new/corrupted device
  Installer->>Key: Scan/tap physical key
  Key-->>Installer: Key proof
  Installer->>Aporaksha: POST /recovery/start(key proof, user proof, new device key)
  Aporaksha->>Aporaksha: Validate key, user, risk, device limits
  alt Automated approval
    Aporaksha-->>Installer: Recovery approved, device binding, lease
  else Support required
    Aporaksha->>Support: Create recovery review case
    Support->>Aporaksha: Approve or deny
    Aporaksha-->>Installer: Decision
  end
  alt Approved
    Installer->>EnvSvc: Request accepted server state
    EnvSvc-->>Installer: Environment, progress, achievements
    Installer->>LocalDB: Restore encrypted local state
    Installer->>Installer: Install required bundles if missing
    Installer-->>Learner: Recovery complete
  else Denied
    Installer-->>Learner: Recovery denied with support path
  end
```
