# 12 — Repository Structure

## 1. Target Monorepo

```text
/lore-key-installer-architecture
├── apps
│   ├── aporaksha-api
│   ├── bundle-resolver-api
│   ├── environment-sync-api
│   ├── reputation-api
│   ├── zayvora-projection-api
│   ├── installer-shell
│   ├── studyos
│   ├── prepos
│   ├── skillhex
│   ├── viadecide
│   └── admin-console
├── packages
│   ├── shared-types
│   ├── auth
│   ├── crypto
│   ├── events
│   ├── bundle-spec
│   ├── local-runtime
│   ├── sdk
│   ├── ui
│   └── telemetry
├── db
│   ├── migrations
│   └── seeds
├── bundles
│   ├── schemas
│   ├── examples
│   └── studyos-foundations
├── hardware
│   ├── lore-key
│   ├── dock
│   ├── qr
│   ├── nfc
│   └── manufacturing
├── docs
│   ├── architecture
│   ├── api
│   ├── operations
│   ├── security
│   └── decisions
├── scripts
│   ├── db
│   ├── bundles
│   ├── hardware
│   ├── release
│   └── security
├── tests
│   ├── contract
│   ├── integration
│   ├── e2e
│   ├── offline-sync
│   └── security
└── infra
    ├── docker
    ├── terraform
    └── observability
```

## 2. Apps

| App | Build Responsibility |
|---|---|
| `aporaksha-api` | Identity, ownership, device binding, offline leases, reputation assertions. |
| `bundle-resolver-api` | Entitlement and signed `.viabundle.json` resolution. |
| `environment-sync-api` | Installs, sync batches, progress materialization, outbox writes. |
| `reputation-api` | Evidence verification, badges, trust scores, signed reputation events. |
| `zayvora-projection-api` | Permissioned memory/context projection. |
| `installer-shell` | Capacitor shell, physical signal reader, IndexedDB, installer runtime. |
| `studyos` | Structured learning modules and progress event producer. |
| `prepos` | Exam prep attempts and analytics event producer. |
| `skillhex` | Project workflows, evidence capture, skill event producer. |
| `viadecide` | Reputation draft, consent, and publishing UI. |
| `admin-console` | Batch registration, support, suspension, revocation, audit review. |

## 3. Packages

| Package | Contents |
|---|---|
| `shared-types` | Domain enums, API DTOs, lifecycle types. |
| `auth` | JWT validation, device assertions, RBAC helpers. |
| `crypto` | Ed25519, SHA-256, canonical JSON wrappers; no custom algorithms. |
| `events` | Event envelope schemas, event names, validators, canonicalization. |
| `bundle-spec` | `.viabundle.json` schema, parser, signature verifier. |
| `local-runtime` | IndexedDB schema, migrations, lease enforcement, sync queue. |
| `sdk` | Runtime API used by StudyOS, PrepOS, SkillHex, ViaDecide, Zayvora. |
| `ui` | Shared UI components for Capacitor/admin/app shells. |
| `telemetry` | Correlation IDs, structured logs, metrics helpers. |

## 4. Database Directory

`/db/migrations` contains PostgreSQL migrations generated from `05_DATABASE_SCHEMA.sql`. `/db/seeds` contains safe development fixtures only. No real activation codes or signing keys are committed.

## 5. Bundles Directory

- `/bundles/schemas/viabundle.schema.json` mirrors `14_BUNDLE_SPECIFICATION.md`.
- `/bundles/examples` contains valid and invalid fixtures.
- Bundle artifacts are stored in object storage, not committed, except tiny test fixtures.

## 6. Hardware Directory

Stores CAD references, QR/NFC payload specs, manufacturing QA checklists, and batch formats. Hardware scripts never commit raw private secrets.

## 7. Tests

| Test Type | Required Coverage |
|---|---|
| Contract | APIs, events, `.viabundle.json`. |
| Integration | DB migrations, activation, bundle resolve, sync, reputation. |
| E2E | Scan-to-install-to-progress-to-reputation. |
| Offline Sync | lease expiry, retries, conflicts, IndexedDB recovery. |
| Security | replay, tampering, revoked key, invalid signatures. |

## 8. Dependency Direction

```text
apps/* -> packages/* -> shared-types
packages/* must not import apps/*
hardware/docs/scripts must not contain runtime secrets
```

Every lifecycle enum is defined in `packages/shared-types` and imported by apps. Every event schema is defined in `packages/events` and reused by local and server code.
