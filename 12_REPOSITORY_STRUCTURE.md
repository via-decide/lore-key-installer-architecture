# Repository Structure

## 1. Purpose

This document defines the target monorepo layout for building Lore Key. A future implementation agent must use this structure unless a migration record explicitly changes it. The repository separates deployable apps, shared packages, documentation, hardware assets, bundles, scripts, and tests while keeping contracts versioned in one place.

## 2. Monorepo Tree

```text
/lore-key-installer-architecture
├── apps
│   ├── aporaksha
│   ├── bundle-resolver
│   ├── environment-service
│   ├── reputation-service
│   ├── installer
│   ├── studyos
│   ├── prepos
│   ├── skillhex
│   ├── viadecide
│   ├── zayvora
│   └── admin-console
├── packages
│   ├── auth
│   ├── events
│   ├── sdk
│   ├── shared-types
│   ├── bundle-spec
│   ├── local-store
│   ├── crypto
│   ├── telemetry
│   └── ui
├── docs
│   ├── architecture
│   ├── api
│   ├── operations
│   ├── security
│   └── decisions
├── hardware
│   ├── lore-key
│   ├── dock
│   ├── nfc
│   ├── qr
│   ├── enclosures
│   ├── manufacturing
│   └── variants
├── bundles
│   ├── schemas
│   ├── examples
│   ├── chemistry
│   ├── embedded-systems
│   ├── tinyml
│   └── industry-4-0
├── scripts
│   ├── dev
│   ├── db
│   ├── bundles
│   ├── hardware
│   ├── release
│   └── security
├── tests
│   ├── contract
│   ├── integration
│   ├── e2e
│   ├── security
│   ├── offline-sync
│   └── fixtures
└── infra
    ├── docker
    ├── terraform
    ├── kubernetes
    └── observability
```

## 3. Top-Level Directories

| Directory | Purpose | Ownership |
|---|---|---|
| `/apps` | Deployable services and runnable client applications. | Application teams. |
| `/packages` | Shared libraries consumed by apps. | Platform team. |
| `/docs` | Maintained architecture, API, operations, and decision records. | Architecture and technical writing. |
| `/hardware` | Physical artifact, dock, NFC, QR, enclosure, and manufacturing assets. | Hardware/operations. |
| `/bundles` | Bundle schemas, examples, manifests, and reference module definitions. | Bundle platform and content teams. |
| `/scripts` | Automation scripts for dev, database, bundle signing, manufacturing, release, and security. | DevEx/platform. |
| `/tests` | Cross-app tests that validate contracts and end-to-end workflows. | QA and engineering. |
| `/infra` | Local and cloud infrastructure definitions. | DevOps/SRE. |

## 4. `/apps` Directory

### 4.1 `/apps/aporaksha`

Aporaksha Identity Service.

```text
/apps/aporaksha
├── src
│   ├── routes
│   ├── domain
│   ├── services
│   ├── repositories
│   ├── policies
│   └── workers
├── migrations
├── tests
└── README.md
```

Responsibilities:

- Key registration.
- Key activation and validation.
- Lease issuance and renewal.
- Device binding.
- Offline authorization.
- Recovery authorization.
- Reputation signing delegation where identity signatures are required.

### 4.2 `/apps/bundle-resolver`

Service that maps identity and entitlements to signed `.viabundle` manifests.

Responsibilities:

- Bundle catalog API.
- Eligibility evaluation.
- Dependency resolution.
- Manifest URL and signature return.
- Revocation and rollback policy.

### 4.3 `/apps/environment-service`

Server-side service for environment state, install telemetry, sync ingestion, and materialized progress.

Responsibilities:

- Environment lifecycle state.
- Sync batch ingestion.
- Progress materialization.
- Conflict resolution.
- Lease telemetry and expiry enforcement.

### 4.4 `/apps/reputation-service`

Service for achievements, reputation events, trust scores, badge issuance, and public/private verification.

Responsibilities:

- Evidence validation.
- Reputation event acceptance/rejection.
- Server signatures.
- Badge issuance.
- Fraud scoring.
- Verification endpoint.

### 4.5 `/apps/installer`

Desktop/runtime installer.

Responsibilities:

- Lore Key scan/tap flow.
- Activation and validation API calls.
- Bundle resolution.
- Download, cache, signature verification, and install.
- Local SQLite database.
- Sync queue.
- Rollback and recovery.

### 4.6 Learning Applications

| Directory | Purpose |
|---|---|
| `/apps/studyos` | Structured learning app with lesson progress and notes. |
| `/apps/prepos` | Competitive exam preparation app with attempts and analytics. |
| `/apps/skillhex` | Project/skill app with build evidence and portfolio artifacts. |
| `/apps/viadecide` | Decision and reputation UI for publishing claims. |
| `/apps/zayvora` | Local memory runtime and adaptive context layer. |

### 4.7 `/apps/admin-console`

Administrative web application for operations.

Responsibilities:

- Manufacturing batch imports.
- Key search, suspension, revocation, and replacement.
- Bundle release visibility.
- Audit log review.
- Support recovery workflow.

## 5. `/packages` Directory

| Package | Purpose | Must Not Contain |
|---|---|---|
| `/packages/auth` | Token validation, device assertions, RBAC helpers. | Service-specific database writes. |
| `/packages/events` | Canonical event names, schemas, serializers, validators. | App-specific business logic. |
| `/packages/sdk` | Local runtime SDK used by learning apps. | UI framework assumptions. |
| `/packages/shared-types` | Type definitions for APIs, domain enums, DTOs. | Runtime side effects. |
| `/packages/bundle-spec` | `.viabundle` parser, JSON Schema, signature validators. | Private signing keys. |
| `/packages/local-store` | SQLite schema, migrations, encrypted storage helpers. | Cloud-only logic. |
| `/packages/crypto` | Hashing, signatures, key derivation wrappers. | Custom cryptographic algorithms. |
| `/packages/telemetry` | Structured logging, metrics, traces, correlation IDs. | Sensitive raw payload logging. |
| `/packages/ui` | Shared UI components for installer/admin/apps. | Domain secrets or API credentials. |

## 6. `/docs` Directory

Generated architecture files may initially remain at repository root for review visibility. During implementation, root documents should be mirrored or moved into `/docs/architecture` with stable links.

```text
/docs
├── architecture       # PRD, architecture, state machines, execution architecture
├── api                # OpenAPI files and endpoint examples
├── operations         # Runbooks, release checklists, support procedures
├── security           # Threat models, key management, incident response
└── decisions          # ADRs named ADR-0001-title.md
```

Rules:

- Every breaking architecture decision requires an ADR.
- API docs must match contract tests.
- Security docs must be reviewed before public launch.

## 7. `/hardware` Directory

```text
/hardware
├── lore-key           # Artifact CAD, dimensions, assembly drawings
├── dock               # Optional dock electrical/mechanical assets
├── nfc                # NFC tag layout, encoding scripts, QA fixtures
├── qr                 # QR payload templates and print QA specs
├── enclosures         # 3D-printable STL/STEP source
├── manufacturing      # Batch CSV formats, supplier specs, QA checklists
└── variants           # Embedded Systems, TinyML, Maker variant notes
```

Rules:

- CAD source files must include units.
- Manufacturing exports must include revision identifiers.
- NFC and QR scripts must never output raw server secrets into committed fixtures.

## 8. `/bundles` Directory

```text
/bundles
├── schemas            # JSON Schema for .viabundle
├── examples           # Minimal valid and invalid examples
├── chemistry          # Chemistry learning bundle manifests
├── embedded-systems   # Embedded systems bundle manifests
├── tinyml             # TinyML bundle manifests
└── industry-4-0       # Industry 4.0 bundle manifests
```

Rules:

- Bundle artifacts are not committed if large or licensed; commit manifests and test fixtures only.
- Example manifests must validate against `/bundles/schemas/viabundle.schema.json`.
- Every bundle directory includes `README.md`, `manifest.viabundle.json`, and `signing-notes.md`.

## 9. `/scripts` Directory

| Directory | Examples |
|---|---|
| `/scripts/dev` | Bootstrap local services, seed data, run watchers. |
| `/scripts/db` | Migrate, rollback, seed, reset local DB. |
| `/scripts/bundles` | Validate manifest, sign manifest, compute hashes, build local mirror. |
| `/scripts/hardware` | Generate QR batches, encode NFC payloads, QA scan reports. |
| `/scripts/release` | Version, changelog, package installer, publish manifests. |
| `/scripts/security` | Rotate keys, verify signatures, run dependency scans. |

Rules:

- Scripts must be deterministic and documented with `--help`.
- Scripts that produce secrets must write to ignored paths only.
- Release scripts must fail closed on unsigned bundles.

## 10. `/tests` Directory

| Directory | Purpose |
|---|---|
| `/tests/contract` | API and event schema contract tests. |
| `/tests/integration` | Multi-service tests with test database and object storage. |
| `/tests/e2e` | Full activation-to-install-to-sync workflows. |
| `/tests/security` | Replay, tamper, auth, and privilege tests. |
| `/tests/offline-sync` | Lease expiry, conflict resolution, and queue recovery tests. |
| `/tests/fixtures` | Safe fixture keys, manifests, and events. |

Rules:

- Contract tests are the source of truth for public interfaces.
- Security fixtures must be fake and clearly labeled.
- Offline tests must simulate clock drift, network loss, duplicate events, and corrupted local state.

## 11. Implementation Conventions

- Use workspace-level dependency management.
- Keep generated API clients in `/packages/sdk/generated`.
- Define canonical enums once in `/packages/shared-types`.
- Define canonical event schemas in `/packages/events` and reuse them in services and tests.
- No application may define a private variant of a lifecycle enum without an ADR.
- Shared packages must not depend on deployable apps.
- Apps may depend on packages, never on other apps directly.

## 12. Dependency Direction

```text
apps/* ───────────────┐
                      v
packages/sdk ──> packages/events ──> packages/shared-types
      │                    │                 │
      v                    v                 v
packages/auth       packages/crypto    packages/telemetry
      │
      v
packages/local-store
```

Forbidden dependencies:

- `/packages/*` importing from `/apps/*`.
- `/hardware/*` importing service code.
- `/docs/*` used as runtime configuration.
- `/bundles/examples` depending on production secrets.
