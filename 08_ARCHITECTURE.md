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
