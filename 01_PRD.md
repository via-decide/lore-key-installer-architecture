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
# Product Requirements Document: Lore Key Installer Architecture

## 1. Executive Summary

Lore Key is a physical-to-digital environment installation platform that converts a durable physical artifact into a trusted identity anchor for installing, unlocking, and synchronizing learning environments. The platform is designed around the philosophy:

```text
Physical Artifact → Identity → Environment Installation → Learning Applications → Reputation Layer → Memory Layer
```

The physical Lore Key is **not** a content container. It does not attempt to store courseware, videos, exams, firmware archives, or proprietary educational assets on the artifact itself. Instead, it acts as an **Environment Installer**: a possession-based activation object that anchors user identity, resolves entitled bundles, installs local-first learning applications, and connects verified learning activity to reputation and memory layers.

Lore Key addresses a structural gap in digital learning ecosystems: learners can access content, but they rarely own a portable, trustworthy, offline-capable record of their learning environment, progress, achievements, and reputation. Existing tools are fragmented across LMS portals, video platforms, exam-prep apps, local IDEs, embedded toolchains, and social credential systems. Lore Key proposes a unified installation and identity layer that makes the learner's device the primary operating environment while retaining optional cloud verification, sync, and reputation publishing.

This document defines the product requirements for the Lore Key platform, including user problems, target personas, functional and non-functional requirements, constraints, success metrics, risks, assumptions, MVP scope, and future scope.

## 2. Product Vision

Lore Key enables learners to begin with a physical artifact and end with a locally installed, identity-anchored learning environment that can operate offline, synchronize when connectivity returns, and publish verified reputation events. The long-term vision is a network of installable learning environments where learners can carry identity, entitlements, progress, achievements, project evidence, and reputation across applications without treating educational content as a disposable stream.

## 3. Problem Statement

Digital learning systems typically optimize for content delivery rather than durable learner ownership. A learner may buy courses, use practice tests, build projects, take notes, complete labs, and earn certificates, but the resulting identity and state are scattered across incompatible services. When network access is unavailable, the learning environment often degrades. When a platform shuts down or account access is lost, history may disappear. When learners want to prove capability, they often rely on weak screenshots, unverified certificates, or social claims.

Lore Key must solve the problem of installing and maintaining trustworthy, local-first learning environments anchored to a physical identity artifact without turning the artifact into a piratable content container.

## 4. Current Problems

### 4.1 Content Piracy

Educational content is routinely copied, shared, and redistributed outside intended licensing boundaries. Systems that ship content directly on removable media or unprotected archives create obvious extraction surfaces. Purely online DRM can reduce casual copying but often harms legitimate offline learners and creates single points of failure.

Lore Key must reduce incentives and opportunities for piracy by separating physical possession from content storage. The key activates entitlement and installation workflows; content bundles remain signed, versioned, encrypted where appropriate, and resolved through policy.

### 4.2 Stateless Learning

Many tools treat a session, course, or quiz as an isolated interaction. Learners often lose context across devices, offline intervals, toolchains, and learning products. Local practice, embedded experiments, project work, and decision logs may never become part of a coherent learner state.

Lore Key must make learning state explicit, portable, and synchronizable. The platform should record activation state, environment install state, bundle version state, progress state, achievement state, and reputation event state.

### 4.3 No Ownership of Learning History

Most learning records are held by the platform provider. Learners may not be able to export detailed progress, verify local activity, or carry evidence into adjacent products. Certificates without auditable event trails are weak evidence of capability.

Lore Key must provide a learner-owned local state store and an optional verified publishing pathway for reputation events. The learner should retain useful records even when offline, while the platform should maintain enough integrity to prevent reputation fraud.

### 4.4 Fragmented Learning Tools

Learners switch between LMS platforms, IDEs, flashcard systems, exam banks, embedded simulators, career tools, and project portfolios. Each product maintains separate identity, progress, and credentials.

Lore Key must act as an installation and identity substrate for multiple learning applications:

- StudyOS for structured learning and progress.
- PrepOS for competitive exam preparation.
- SkillHex for project-based skill development.
- ViaDecide for decision trails and reputation publishing.
- Zayvora for runtime memory and adaptive learning context.

## 5. Proposed Solution: Lore Key as Environment Installer

Lore Key consists of a physical artifact, a local installer, identity services, bundle resolution services, environment runtimes, sync services, and reputation services.

### 5.1 Core Concept

```text
             ┌─────────────────────┐
             │ Physical Lore Key    │
             │ NFC / QR / Serial    │
             └──────────┬──────────┘
                        │ possession proof
                        v
             ┌─────────────────────┐
             │ Aporaksha Identity  │
             │ activation/validate │
             └──────────┬──────────┘
                        │ entitlement token
                        v
             ┌─────────────────────┐
             │ Bundle Resolver     │
             │ signed manifests    │
             └──────────┬──────────┘
                        │ bundle plan
                        v
┌──────────────────────────────────────────────────┐
│ Local Environment Installer                       │
│ install, verify, configure, run, sync             │
└───────┬─────────┬──────────┬──────────┬──────────┘
        │         │          │          │
        v         v          v          v
     StudyOS    PrepOS    SkillHex   ViaDecide   Zayvora
```

### 5.2 Product Principles

1. **Physical artifact as identity anchor:** The artifact establishes a real-world possession event that starts identity creation or validation.
2. **Environment over content:** The primary output is an installed, configured learning environment, not files copied from a key.
3. **Local-first state:** Learners can continue working without continuous connectivity.
4. **Signed and auditable transitions:** State transitions and bundles are verified by signatures, hashes, leases, and audit trails.
5. **Reputation with provenance:** Published achievements must be derived from verifiable events, not arbitrary self-attestation.
6. **Low-cost manufacturability:** The artifact must be inexpensive, robust, and compatible with 3D printed enclosures.

## 6. User Personas

### 6.1 STEM Student

A university or high-school STEM learner who needs structured lessons, labs, notes, progress tracking, and offline availability. They value continuity across semesters and devices.

**Needs**

- Install course-aligned environments quickly.
- Work offline in hostels, classrooms, buses, or low-connectivity homes.
- Preserve progress and lab evidence.
- Recover state after device loss.

### 6.2 Competitive Exam Aspirant

A learner preparing for standardized or competitive exams. They need disciplined practice, analytics, revision schedules, simulated tests, and credible progress reports.

**Needs**

- Install PrepOS bundles for exam tracks.
- Use question banks offline.
- Track attempts, weak topics, streaks, and readiness.
- Publish verified milestones without leaking private performance details.

### 6.3 Maker

A self-directed builder who learns through projects involving electronics, robotics, 3D printing, or software. They need project templates, toolchains, instructions, and portfolio evidence.

**Needs**

- Install project environments and dependencies.
- Preserve build logs and artifacts.
- Link physical builds to digital progress.
- Publish proof of completed projects.

### 6.4 Embedded Engineer

A professional or advanced learner working with boards, firmware, debugging tools, and constrained environments. They require reliable local toolchains and offline documentation.

**Needs**

- Install reproducible embedded development environments.
- Validate firmware examples and board support packages.
- Track skill progression and lab completion.
- Maintain secure local credentials and device bindings.

### 6.5 Lifelong Learner

A learner exploring multiple domains over years. They value continuity, memory, recommendations, and personal ownership of learning history.

**Needs**

- Carry identity and history across learning products.
- Resume old topics.
- Maintain a long-term learning memory layer.
- Selectively share achievements and reputation.

## 7. Functional Requirements

| ID | Requirement | Priority | Rationale |
|---|---|---:|---|
| FR-001 | Activate a Lore Key using physical artifact data such as NFC UID, QR code, serial, or signed chip challenge. | P0 | Establishes possession-based identity anchor. |
| FR-002 | Create or bind a learner identity during activation. | P0 | Required for entitlement, progress, and recovery. |
| FR-003 | Validate Lore Key status before installation. | P0 | Prevents revoked, suspended, or cloned keys from installing environments. |
| FR-004 | Resolve entitled environment bundles based on key, user, region, cohort, and application. | P0 | Supports environment installation without storing content on the key. |
| FR-005 | Download, verify, and install signed bundles. | P0 | Ensures integrity and provenance. |
| FR-006 | Support offline installation from pre-cached or locally mirrored signed bundles. | P1 | Enables low-connectivity deployments. |
| FR-007 | Maintain local state for identity, activation, progress, achievements, and sync queue. | P0 | Enables local-first operation. |
| FR-008 | Provide offline lease validation for installed environments. | P0 | Balances offline use with entitlement control. |
| FR-009 | Capture user progress events from StudyOS, PrepOS, SkillHex, ViaDecide, and Zayvora. | P0 | Creates coherent learning state. |
| FR-010 | Publish reputation events with signatures and evidence references. | P1 | Supports trustworthy reputation layer. |
| FR-011 | Synchronize local events with cloud services when connectivity is available. | P0 | Reconciles offline state. |
| FR-012 | Resolve conflicts using deterministic state rules. | P1 | Prevents data corruption across devices. |
| FR-013 | Support device binding and device replacement workflows. | P0 | Reduces sharing abuse while supporting recovery. |
| FR-014 | Provide administrative tools for key manufacturing batches and revocation. | P1 | Required for operations and security. |
| FR-015 | Provide audit logs for activation, validation, bundle resolution, reputation publishing, and admin actions. | P0 | Required for trust and incident response. |
| FR-016 | Support soft deletion for user-controlled account closure and compliance workflows. | P1 | Required for privacy and operational safety. |
| FR-017 | Provide bundle versioning and rollback rules. | P1 | Supports stable installs and incident mitigation. |
| FR-018 | Expose REST APIs for activation, validation, bundle resolution, state, reputation, and sync. | P0 | Enables integration across products. |
| FR-019 | Verify bundle manifests against trusted publisher keys. | P0 | Prevents malicious or tampered bundles. |
| FR-020 | Export learner-owned progress and achievement records. | P2 | Supports data portability. |

## 8. Non-Functional Requirements

| Category | Requirement | Target |
|---|---|---|
| Availability | Core local environment remains usable offline. | 30-day offline lease for MVP; configurable by bundle policy. |
| Latency | Online activation completes quickly under normal network conditions. | p95 under 5 seconds excluding user input. |
| Integrity | Signed bundle verification must be mandatory. | 100% of installed bundles verified before activation. |
| Security | Activation tokens and leases must be non-replayable. | Nonce-bound challenge and expiry. |
| Privacy | Local state must minimize sensitive data and support encryption at rest. | Encrypt local identity and sync queue secrets. |
| Scalability | Identity service must support education cohort launches. | 10,000 activations/hour target for v1 cloud architecture. |
| Reliability | Sync must be idempotent. | Duplicate event submissions produce same final state. |
| Maintainability | Services must expose versioned APIs and migration paths. | `/v1` APIs for MVP; backward-compatible minor changes. |
| Observability | Server-side events must be traceable. | Correlation ID required for all write APIs. |
| Portability | Installer must support common learner devices. | Windows, macOS, Linux prioritized; Android later. |
| Manufacturability | Physical artifact must be low cost. | Target BOM under USD $2 for QR/NFC version excluding packaging. |
| Accessibility | Learning apps must support accessibility baseline. | Keyboard navigation, readable contrast, exportable text. |

## 9. Constraints

### 9.1 Local-First

The user device is the primary execution and state environment. Cloud services validate, sync, resolve, and publish, but must not be required for every learning action.

### 9.2 Offline Capable

The platform must support offline learning after activation and installation. Offline behavior must be explicit through leases, sync queues, conflict rules, and reputation publication delays.

### 9.3 Physical Activation

The physical artifact must be involved in initial activation and selected recovery or revalidation workflows. Activation can use QR, NFC, serial, or a stronger secure element challenge depending on hardware tier.

### 9.4 Low-Cost Manufacturing

The MVP should support inexpensive manufacturing using printed QR labels, low-cost NFC stickers, and serialized 3D printed enclosures. Higher-security editions may add secure elements.

### 9.5 3D Printable

The enclosure must be designed for accessible fabrication. Product requirements should avoid shapes, tolerances, or materials that make low-volume production impractical.

## 10. Success Metrics

| Metric | MVP Target | Strategic Target |
|---|---:|---:|
| Activation completion rate | >= 90% | >= 97% |
| Median activation time | <= 3 minutes | <= 60 seconds |
| Successful install rate | >= 85% | >= 95% |
| Offline learning sessions completed | >= 30% of sessions | >= 50% in low-connectivity cohorts |
| Sync success after offline period | >= 95% | >= 99% |
| Bundle verification failures detected | 100% detection of modified test bundles | Continuous integrity monitoring |
| Support tickets per 100 activations | <= 8 | <= 3 |
| Reputation event acceptance rate | >= 90% legitimate events accepted | >= 98% |
| Key clone abuse rate | Measured baseline | < 1% confirmed fraudulent activations |
| 30-day learner retention | >= 35% | >= 55% |

## 11. Risks

| Risk | Impact | Likelihood | Mitigation |
|---|---|---:|---|
| QR-only keys are easily copied. | High | High | Treat QR tier as low-assurance; add device binding, server validation, rate limits, and upgrade path to NFC/secure element. |
| Offline mode can be abused for sharing. | Medium | Medium | Offline lease windows, sync reconciliation, reputation verification, anomaly detection. |
| Bundle extraction may expose content. | High | Medium | Signed manifests, optional encryption, watermarking, policy-based bundle composition, legal and operational controls. |
| Installer complexity harms onboarding. | High | Medium | Progressive install UI, robust diagnostics, resumable downloads, clear recovery. |
| Fragmented apps produce inconsistent state. | Medium | Medium | Shared event schema, state machine definitions, SDKs, contract tests. |
| Manufacturing quality variations cause activation failures. | Medium | Medium | Batch QA, redundant identifiers, printed fallback code, admin replacement flow. |
| Reputation layer creates privacy concerns. | High | Medium | User consent, selective disclosure, privacy-preserving evidence references. |
| Cloud dependency during first activation blocks offline-first promise. | Medium | Medium | Support pre-authorized cohort activation files and offline activation vouchers in future phases. |

## 12. Assumptions

1. Learners have access to at least one compatible device capable of running the installer.
2. Initial activation usually has intermittent internet access, even if ongoing usage is offline.
3. Low-cost QR/NFC keys are acceptable for MVP assurance levels if paired with device binding and anomaly detection.
4. Learning applications can integrate with a shared local event and state SDK.
5. Bundle publishers can produce signed manifests and versioned artifacts.
6. Users will tolerate periodic revalidation if offline lease behavior is transparent.
7. Reputation events can be delayed until sync without breaking core learning workflows.
8. Physical artifacts create emotional and behavioral value beyond pure security.

## 13. MVP Scope

### 13.1 Included

- Physical Lore Key prototype using serialized QR and optional NFC tag.
- Aporaksha Identity Service with activation, validation, and state endpoints.
- Bundle Resolver Service with signed manifest resolution.
- Desktop installer for one primary OS and documented portability path.
- StudyOS integration with progress tracking.
- Local encrypted state store and sync queue.
- Basic reputation event publishing through ViaDecide.
- Admin tooling for batch registration, suspension, revocation, and audit review.
- Offline lease policy for installed environments.
- PostgreSQL backend schema and migration baseline.
- Security controls for signed bundles, replay prevention, audit trails, and rate limits.

### 13.2 Excluded

- Secure element hardware requirement for all keys.
- Full mobile runtime.
- Marketplace for third-party bundle publishers.
- Fully decentralized identity.
- Zero-knowledge reputation proofs.
- Advanced adaptive AI memory layer beyond initial Zayvora runtime interfaces.
- High-stakes proctoring or regulated certification.

## 14. Future Scope

- Secure element challenge-response Lore Key edition.
- Offline activation vouchers for schools and remote cohorts.
- Peer-to-peer signed bundle distribution within classrooms.
- Marketplace for environment bundles.
- Advanced reputation graph with verified project evidence.
- Learner-owned encrypted memory vault.
- Multi-device sync with stronger conflict-free replicated data types.
- Hardware board pairing for embedded learning kits.
- Institution dashboards with privacy-preserving analytics.
- Public achievement verification pages and signed credential exports.
- 3D printable enclosure library with regional manufacturing instructions.
