# 01 — Product Requirements Document: Lore Key MVP

## 1. Product Definition

Lore Key is a physical-to-digital **Environment Installer**. The physical artifact is a physical signal that starts an activation workflow; it is not a content container, storage drive, DRM token, or trusted identity by itself.

The required value chain is:

```text
Physical Signal
→ Authenticated Identity
→ Ownership Activation
→ Device Binding
→ Offline Lease
→ Signed Bundle Resolution
→ Verified Environment Installation
→ Local State Creation
→ Event-Based Progress
→ Verified Reputation
→ Zayvora Memory Projection
```

## 2. Executive Summary

The MVP enables a learner to scan or tap a Lore Key, authenticate with Aporaksha, activate ownership, bind a device, receive an offline lease, resolve an immutable signed `.viabundle.json`, install a verified local learning environment, record progress as events, synchronize those events, publish reputation only from verified events, and optionally project approved context into Zayvora memory.

The MVP is implementation-ready for:

- Backend: Node.js/NestJS preferred; FastAPI acceptable if selected at project bootstrap.
- Database: PostgreSQL.
- Events: PostgreSQL `events` table and transactional outbox.
- Local runtime: IndexedDB first; SQLite is a later migration path.
- Mobile shell: Capacitor.
- Bundles: signed, immutable, versioned `.viabundle.json` manifests.
- Sync: client queue plus server reconciliation.

## 3. Problem Statement

Learners receive physical kits, courses, credentials, and educational tools, but digital learning platforms remain fragmented, cloud-dependent, and weakly connected to long-term learner-owned state. Current systems often treat content access as the product, causing piracy risk, stateless learning, weak recovery, and unverified reputation.

Lore Key solves this by turning a physical signal into a secure installation and identity flow while keeping learning state local-first and reputation evidence-based.

## 4. Current Problems

| Problem | Product Impact | Required MVP Response |
|---|---|---|
| Content piracy | Physical media and downloadable archives are copied. | The Lore Key never stores content; bundles are signed and resolved by entitlement. |
| Stateless learning | Progress is trapped in tools or lost offline. | Progress is append-only events stored locally and reconciled with the server. |
| No ownership of learning history | Learners cannot carry trustworthy records. | Local state is learner-owned and exportable; server verifies only eligible evidence. |
| Fragmented learning tools | Study, exam prep, projects, reputation, and memory are disconnected. | One runtime contract connects StudyOS, PrepOS, SkillHex, ViaDecide, and Zayvora. |
| Offline exclusion | Learners lose access when connectivity is poor. | Valid activation issues a signed offline lease enforced locally. |

## 5. Proposed Solution

### 5.1 Product Flow

```text
User scans QR/NFC/serial
        │
        v
Aporaksha authenticates user and validates physical signal
        │
        v
Aporaksha activates ownership and binds device
        │
        v
Aporaksha issues signed offline lease
        │
        v
Bundle Resolver returns signed immutable bundle manifest
        │
        v
Installer verifies manifest and artifacts
        │
        v
Capacitor runtime creates local IndexedDB state
        │
        v
Apps append signed local progress events
        │
        v
Sync reconciles events with PostgreSQL
        │
        v
ViaDecide publishes reputation from verified events
        │
        v
Zayvora receives permissioned memory projection
```

### 5.2 Product Boundaries

In scope for MVP:

- QR, NFC, and serial physical signal intake.
- Aporaksha identity, ownership, lease, and device binding.
- Signed bundle resolution and installation.
- IndexedDB local runtime.
- Event-based progress capture and sync.
- Reputation from verified events.
- Zayvora projection by explicit permission.

Out of scope for MVP:

- Secure element as mandatory hardware.
- Fully decentralized identity.
- Content marketplace.
- Proctored high-stakes certification.
- SQLite local runtime implementation.
- Zayvora autonomous memory sharing without explicit consent.

## 6. Personas

| Persona | Job | MVP Need |
|---|---|---|
| STEM Student | Install course environment and study offline. | StudyOS bundle, progress events, offline lease. |
| Competitive Exam Aspirant | Practice consistently and track readiness. | PrepOS bundle, attempt events, weak-area analytics. |
| Maker | Build projects and preserve evidence. | SkillHex bundle, artifact events, portfolio evidence. |
| Embedded Engineer | Install reproducible toolchain/lab environment. | Signed dependencies, device-specific install checks. |
| Lifelong Learner | Preserve learning context over time. | Exportable local state and permissioned Zayvora projection. |

## 7. Functional Requirements

| ID | Requirement | Priority | Acceptance Rule |
|---|---|---:|---|
| FR-001 | Accept QR/NFC/serial as physical signals. | P0 | Signals are never treated as trusted identity without Aporaksha validation. |
| FR-002 | Authenticate user through Aporaksha. | P0 | Activation cannot complete without an authenticated identity. |
| FR-003 | Activate ownership of a Lore Key. | P0 | A key can have one active owner unless an admin transfer occurs. |
| FR-004 | Bind activated ownership to a device. | P0 | Device public key is registered and used for signed assertions. |
| FR-005 | Issue signed offline lease. | P0 | Lease includes user, key, device, capabilities, expiry, and Aporaksha signature. |
| FR-006 | Resolve signed immutable bundles. | P0 | Bundle Resolver returns only entitled `.viabundle.json` versions. |
| FR-007 | Verify bundle manifest and artifacts. | P0 | Installer fails closed on invalid signature or hash. |
| FR-008 | Create local runtime state in IndexedDB. | P0 | Identity context, lease, installs, event queue, and progress are stored locally. |
| FR-009 | Capture progress as events. | P0 | Apps append canonical events through runtime SDK. |
| FR-010 | Sync local queue with server reconciliation. | P0 | Duplicate events are idempotent and conflicts are deterministic. |
| FR-011 | Generate reputation from verified events only. | P0 | Manual claims cannot become verified reputation. |
| FR-012 | Project Zayvora memory only with permission. | P1 | User grants scope before projection is created or shared. |
| FR-013 | Support recovery. | P1 | Device replacement requires Aporaksha verification and does not delete local exports. |
| FR-014 | Provide admin key controls. | P1 | Admin can register, suspend, revoke, and audit keys. |

## 8. Non-Functional Requirements

| Category | Requirement | MVP Target |
|---|---|---|
| Availability | Local runtime works offline after valid activation. | 30-day default lease. |
| Security | Physical signal is low-trust input. | Aporaksha validation required. |
| Integrity | Bundle signatures and hashes are mandatory. | 100% verified before install. |
| Privacy | Zayvora receives only permissioned projections. | Consent record required. |
| Scalability | Activation spikes from classroom cohorts. | 10,000 activations/hour in load test. |
| Reliability | Sync is idempotent. | Stable event IDs and outbox processing. |
| Portability | Mobile shell supports web runtime. | Capacitor with IndexedDB. |
| Observability | All write flows are traceable. | Request ID, correlation ID, audit record. |

## 9. Constraints

- QR/NFC/serial are physical signals only.
- Aporaksha is source of truth for identity, ownership, activation, lease, and reputation signing assertions.
- Local app runtime must continue offline after valid activation.
- Bundles are signed, versioned, immutable, and installable.
- Progress is event-based.
- Reputation is generated from verified events, not manual claims.
- Zayvora memory projection requires user permission.
- IndexedDB is the MVP local store; SQLite is a future migration.

## 10. Success Metrics

| Metric | MVP Success Threshold |
|---|---:|
| Activation completion rate | >= 90% |
| Median activation time | <= 3 minutes |
| Successful verified install rate | >= 85% |
| Offline sessions completed under lease | >= 30% of pilot sessions |
| Sync success after offline period | >= 95% |
| Tampered bundle rejection | 100% in security tests |
| Verified reputation event correctness | 100% event-backed in audit sample |
| Zayvora projection consent compliance | 100% projections linked to permission record |

## 11. Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| QR/NFC cloning | Unauthorized activation attempts. | Treat as signal only, require identity and device binding, rate-limit, audit. |
| Bundle extraction | Content piracy. | Signed manifests, artifact hashes, optional encryption, watermarking later. |
| Offline abuse | Shared devices or stale leases. | Bounded leases, reconciliation, fraud scoring. |
| Local state tampering | Fake progress. | Canonical event hashes, device signatures, server verification. |
| Reputation fraud | Trust collapse. | Reputation only from verified events and evidence policy. |
| Memory privacy | User trust loss. | Zayvora projection requires explicit permission and inspectable records. |

## 12. MVP Scope

MVP ships one deployable architecture with:

- Aporaksha service.
- Bundle Resolver service.
- Environment/Sync service.
- Reputation service for verified events.
- Capacitor installer/runtime shell.
- IndexedDB local state.
- StudyOS first bundle.
- ViaDecide reputation draft and publishing flow.
- Zayvora projection interface.
- PostgreSQL schema and transactional outbox.

## 13. Future Scope

- SQLite runtime for desktop/offline-heavy installs.
- Secure element hardware tier.
- Peer classroom bundle mirrors.
- Embedded Systems, TinyML, and Maker hardware variants.
- Advanced Zayvora adaptive runtime.
- Public bundle marketplace.
