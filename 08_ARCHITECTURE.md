# 08 — Implementation Architecture

## 1. Architecture Invariant

Lore Key is an Environment Installer. The physical key provides only a physical signal. Identity, ownership, activation, leases, device binding, and reputation signing are controlled by Aporaksha.

```text
Physical Signal -> Aporaksha -> Bundle Resolver -> Installer Runtime -> Local Apps -> Sync -> Reputation -> Zayvora
```

## 2. MVP Stack

| Layer | Choice |
|---|---|
| Backend | Node.js/NestJS preferred; FastAPI acceptable at bootstrap. |
| Database | PostgreSQL 15+. |
| Eventing | PostgreSQL `events` table and transactional outbox. |
| Local runtime | Capacitor shell with IndexedDB. |
| Future local runtime | SQLite after MVP. |
| Bundle format | Signed `.viabundle.json`. |
| Sync | Client queue plus server reconciliation. |
| Deployment | Containerized services behind API gateway. |

## 3. Service Architecture

```text
              ┌────────────────────┐
              │ API Gateway / WAF   │
              └─────────┬──────────┘
                        │
 ┌──────────────────────┼──────────────────────┐
 v                      v                      v
Aporaksha        Bundle Resolver       Environment/Sync Service
 │                      │                      │
 └──────────────┬───────┴──────────────┬───────┘
                v                      v
          PostgreSQL             Object Storage/CDN
                │
                v
        Transactional Outbox
                │
                v
 Reputation Service ───── Zayvora Projection Service
```

## 4. Client Architecture

```text
Capacitor Shell
├── Key Signal Reader
├── Aporaksha Client
├── Bundle Client
├── Bundle Verifier
├── Install Engine
├── IndexedDB Local Store
├── Runtime SDK
├── Sync Client
├── ViaDecide UI
└── Zayvora Permission UI
```

## 5. Logical Components

| Component | Contract |
|---|---|
| Aporaksha | Source of truth for identity, ownership, activation, leases, device binding, reputation assertions. |
| Bundle Resolver | Entitlement and immutable signed bundle resolution. |
| Installer Runtime | Verifies bundles, installs environments, creates local state. |
| Local Runtime SDK | Capability checks, event append, progress read, reputation drafts, projection permission. |
| Environment Service | Sync reconciliation and progress materialization. |
| Reputation Service | Accepts reputation only from verified events. |
| Zayvora | Receives permissioned memory/context projections only. |

## 6. Data Architecture

Server domains:

- Identity: users, lore_keys, ownerships, devices, activations, leases.
- Bundle: bundles, bundle_versions.
- Environment: environments, installs.
- Events: events, outbox_events.
- Learning: progress, achievements.
- Reputation: reputation_events.
- Memory: zayvora_projections.
- Audit: audit_logs.

Client IndexedDB stores:

- identity context.
- offline leases.
- bundle cache index.
- installs.
- local events.
- sync queue.
- materialized progress.
- achievements.
- reputation drafts.
- Zayvora permissions and projections.

## 7. Security Architecture

Trust boundaries:

```text
Physical key boundary: QR/NFC/serial are observable and cloneable.
Device boundary: IndexedDB and Capacitor runtime are semi-trusted.
Network boundary: all requests over TLS with signed device assertions.
Server boundary: Aporaksha and PostgreSQL are authoritative.
Public boundary: reputation exposes only consented verified claims.
```

Controls:

- Treat physical signals as untrusted.
- Require Aporaksha authentication for ownership.
- Bind devices using public keys.
- Sign offline leases.
- Verify bundle signatures and hashes.
- Hash and sign progress events.
- Use server reconciliation before verified reputation.
- Require permission for Zayvora projections.

## 8. Deployment Architecture

```text
Containers:
- aporaksha-api
- bundle-resolver-api
- environment-sync-api
- reputation-api
- zayvora-projection-api
- outbox-worker
- admin-api

Shared:
- PostgreSQL
- object storage/CDN
- secret manager
- observability stack
```

## 9. Scaling Limits and Mitigations

| Limit | Mitigation |
|---|---|
| Activation spikes | Rate limits, queueable audit/outbox, horizontal API scaling. |
| Bundle download load | CDN, immutable caching, local mirrors. |
| Sync bursts after offline periods | Batch ingestion, backpressure, idempotency. |
| Reputation verification cost | Async verification, fraud rules, evidence indexes. |
| IndexedDB quota | Bundle artifacts outside DB cache where platform allows; DB stores metadata/events. |

## 10. Failure Points

| Failure | Behavior |
|---|---|
| Aporaksha unavailable | Existing valid leases continue; new activations blocked. |
| Bundle Resolver unavailable | Cached verified manifests can be reused by policy; new resolves blocked. |
| CDN unavailable | Retry mirror; install does not proceed without verified artifacts. |
| IndexedDB failure | Runtime enters recovery/export diagnostics mode. |
| Outbox worker failure | Domain transactions remain committed; outbox retries later. |
# Lore Key System Architecture

## 1. Architecture Intent

Lore Key is a physical-to-digital environment installation platform. The physical artifact anchors identity and initiates installation workflows; it is not a content container. The system is local-first, offline-capable, state-driven, and identity-anchored.

```text
Physical Artifact → Identity → Environment Installation → Learning Applications → Reputation Layer → Memory Layer
```

## 2. Business Architecture

### 2.1 Business Capabilities

| Capability | Description | Primary Owner |
|---|---|---|
| Physical key manufacturing | Produce serialized QR/NFC/secure-element artifacts and 3D printable enclosures. | Operations |
| Key identity activation | Bind artifact possession to learner identity. | Aporaksha |
| Entitlement resolution | Determine eligible bundles by user, key, cohort, region, and app. | Bundle Resolver |
| Local environment installation | Install signed learning environments on learner devices. | Installer Platform |
| Learning activity capture | Record progress, attempts, projects, and achievements. | Learning Apps |
| Reputation publishing | Publish verified claims with user consent. | ViaDecide |
| Memory continuity | Maintain local-first long-term learning context. | Zayvora |
| Administration | Manage batches, keys, revocations, support, and audit. | Platform Ops |

### 2.2 Value Chain

```text
Manufacture Key
      │
      v
Distribute Artifact
      │
      v
Activate Identity
      │
      v
Resolve Entitlement
      │
      v
Install Environment
      │
      v
Capture Learning State
      │
      v
Publish Reputation
      │
      v
Build Memory and Retention
```

## 3. Product Architecture

```text
┌──────────────────────────────────────────────────────────────────┐
│                           Lore Key                               │
│         physical artifact: QR / NFC / serial / secure challenge   │
└───────────────────────────────┬──────────────────────────────────┘
                                │
                                v
┌──────────────────────────────────────────────────────────────────┐
│ Aporaksha Identity Service                                        │
│ activation, validation, device binding, leases, recovery           │
└───────────────────────────────┬──────────────────────────────────┘
                                │
                                v
┌──────────────────────────────────────────────────────────────────┐
│ Bundle Resolver                                                   │
│ entitlement rules, signed manifests, versions, rollback policy     │
└───────────────────────────────┬──────────────────────────────────┘
                                │
                                v
┌──────────────────────────────────────────────────────────────────┐
│ Local Environment Installer                                       │
│ download, verify, install, configure, local state, sync queue       │
└───────┬──────────────┬──────────────┬──────────────┬──────────────┘
        │              │              │              │
        v              v              v              v
┌────────────┐   ┌────────────┐  ┌────────────┐ ┌────────────┐ ┌────────────┐
│ StudyOS    │   │ PrepOS     │  │ SkillHex   │ │ ViaDecide  │ │ Zayvora    │
│ learning   │   │ exam prep  │  │ projects   │ │ reputation │ │ memory     │
└────────────┘   └────────────┘  └────────────┘ └────────────┘ └────────────┘
```

## 4. Logical Architecture

### 4.1 Component Model

```text
Client Device
┌────────────────────────────────────────────────────────────┐
│ Installer Shell                                            │
│ ├─ Key Scanner                                             │
│ ├─ Device Binding Agent                                    │
│ ├─ Bundle Download Manager                                 │
│ ├─ Signature and Hash Verifier                             │
│ ├─ Environment Supervisor                                  │
│ ├─ Local State Store                                       │
│ └─ Sync Queue                                              │
│                                                            │
│ Learning Apps                                              │
│ ├─ StudyOS                                                 │
│ ├─ PrepOS                                                  │
│ ├─ SkillHex                                                │
│ ├─ ViaDecide                                               │
│ └─ Zayvora                                                 │
└────────────────────────────────────────────────────────────┘

Cloud / Hosted Services
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│ Aporaksha Identity  │  │ Bundle Resolver     │  │ Environment Service │
└─────────┬───────────┘  └─────────┬───────────┘  └─────────┬───────────┘
          │                        │                        │
          v                        v                        v
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│ PostgreSQL          │  │ Object Storage/CDN  │  │ Reputation Service  │
└─────────────────────┘  └─────────────────────┘  └─────────────────────┘
```

### 4.2 Key Logical Decisions

| Decision | Rationale |
|---|---|
| Physical key stores identity reference, not content. | Reduces content extraction and positions artifact as installer. |
| Local event store is authoritative for offline work until sync. | Enables learning continuity. |
| Server remains authority for activation, entitlement, and reputation verification. | Maintains trust and abuse controls. |
| Bundles are immutable and signed. | Supports integrity, caching, rollback, and forensics. |
| Reputation events are derived from evidence. | Prevents arbitrary claims from becoming trusted credentials. |

## 5. Physical Architecture

### 5.1 Physical Artifact

```text
┌────────────────────────────────────────────┐
│ 3D Printed Shell                           │
│ ┌────────────────────────────────────────┐ │
│ │ Printed Serial / QR                    │ │
│ └────────────────────────────────────────┘ │
│ ┌────────────────────────────────────────┐ │
│ │ Optional NFC Sticker / Chip            │ │
│ └────────────────────────────────────────┘ │
│ ┌────────────────────────────────────────┐ │
│ │ Optional Secure Element (future tier)  │ │
│ └────────────────────────────────────────┘ │
└────────────────────────────────────────────┘
```

### 5.2 Manufacturing Data

Each artifact must have:

- Human-readable serial.
- Public activation code or QR payload.
- Hashed server-side secret or public key.
- Manufacturing batch ID.
- Hardware tier.
- Packaging and distribution metadata.

## 6. Deployment Architecture

### 6.1 MVP Deployment

```text
Internet
   │
   v
API Gateway / WAF
   │
   ├── Aporaksha Identity Service ── PostgreSQL
   ├── Bundle Resolver Service ───── PostgreSQL
   ├── Environment Service ───────── PostgreSQL
   ├── Reputation Service ────────── PostgreSQL
   └── Admin Service ─────────────── PostgreSQL

Object Storage + CDN
   │
   └── signed manifests and artifacts

Observability
   ├── metrics
   ├── logs
   └── traces
```

### 6.2 Deployment Requirements

- All services behind API gateway with TLS termination and WAF rules.
- PostgreSQL with point-in-time recovery.
- Object storage with immutable bundle artifacts.
- CDN configured for signed immutable manifests and artifacts.
- Secrets managed through a dedicated secret manager.
- Separate environments for development, staging, and production.

## 7. Data Architecture

### 7.1 Data Domains

| Domain | Primary Tables | Owner |
|---|---|---|
| Identity | `users`, `lore_keys`, `activations` | Aporaksha |
| Bundles | `bundles`, `bundle_versions` | Bundle Resolver |
| Environment | `environment_installs`, `sync_queue` | Environment Service |
| Learning State | `user_progress`, `achievements` | Learning Apps |
| Reputation | `reputation_events` | Reputation Service |
| Audit | `audit_logs` | Platform Security |

### 7.2 Data Flow

```text
Activation Data ──> Identity State ──> Entitlement Rules ──> Bundle Manifests
       │                    │                    │                   │
       v                    v                    v                   v
   Audit Logs        Device Binding       Environment Install    Local State
       │                                                         │
       v                                                         v
Security Review <──── Sync Events <──── Learning Progress <──── Apps
       │                                                         │
       v                                                         v
Reputation Verification <──── Achievements <──── Evidence Hashes
```

## 8. Security Architecture

### 8.1 Trust Boundaries

```text
[Physical World]
      │ key possession proof
      v
[User Device] ───── signed assertions ───── [API Gateway]
      │                                      │
      │ local encrypted state                v
      │                              [Trusted Services]
      │                                      │
      v                                      v
[Local Apps]                         [Databases / CDN]
```

### 8.2 Security Controls

| Control | Purpose |
|---|---|
| Signed bundle manifests | Prevent tampered installs. |
| Artifact hash verification | Detect corrupted or modified downloads. |
| Device binding | Reduce key sharing and replay. |
| Offline leases | Permit offline use with bounded risk. |
| Idempotency keys | Prevent duplicate writes during retries. |
| Audit logs | Enable incident response and abuse analysis. |
| Reputation evidence verification | Prevent arbitrary claim publishing. |

## 9. Integration Architecture

### 9.1 Application Integration Contract

Every learning application integrates with the local runtime through:

- Identity context API.
- Entitlement and lease API.
- Local event append API.
- Progress materialization API.
- Achievement declaration API.
- Reputation publishing intent API.
- Memory read/write API for Zayvora-compatible records.

### 9.2 Integration Diagram

```text
StudyOS ─┐
PrepOS ──┤
SkillHex ├── Local Runtime SDK ── Local Event Store ── Sync Client ── Environment Service
ViaDecide┤             │
Zayvora ─┘             └── Identity Context ────────── Aporaksha
```

## 10. Bottlenecks

| Bottleneck | Cause | Mitigation |
|---|---|---|
| Activation launch spikes | Cohorts activate simultaneously. | Queue writes, autoscale, pre-register batches, backoff clients. |
| Bundle downloads | Large artifacts and low bandwidth. | CDN, local mirrors, chunking, compression, resumable downloads. |
| Sync bursts | Offline cohorts reconnect together. | Batch ingestion, server backpressure, idempotent events. |
| Reputation verification | Evidence review and fraud scoring. | Async processing, narrow claim types, automated evidence hashes. |
| Local installer support | Device diversity. | Diagnostics, supported platforms matrix, telemetry, rollback. |

## 11. Scaling Limits

- QR-only keys have low cryptographic assurance and must not be used for high-stakes credentials without secondary controls.
- PostgreSQL can support MVP scale but may need read replicas, partitioning, or event streaming as sync volumes grow.
- Local-first sync requires careful conflict resolution; naive last-write-wins will fail for complex learning state.
- Bundle CDN scale is straightforward, but publisher signing and release governance become bottlenecks.
- Reputation graph trust declines if event acceptance rules are too broad.

## 12. Failure Points

| Failure Point | Impact | Resilience Strategy |
|---|---|---|
| Aporaksha outage | New activation and lease renewal blocked. | Existing offline leases continue; status page; retry. |
| Bundle Resolver outage | New installs blocked. | Cache recent manifests; local mirrors. |
| CDN outage | Downloads fail. | Alternate mirrors and classroom cache. |
| Local state corruption | Progress at risk. | Snapshots, export, sync restore. |
| Signing key compromise | Bundle trust compromised. | Key rotation, revocation, transparency log. |
| Admin credential compromise | Key abuse and revocation risk. | RBAC, MFA, approval workflow, audit monitoring. |
