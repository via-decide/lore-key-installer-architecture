# 09 — Security Model

## 1. Core Security Position

QR, NFC, and serial are physical signals only. They are observable, copyable, and insufficient for identity. Aporaksha authenticates the user, validates the physical signal, activates ownership, binds the device, issues leases, and provides identity assertions for reputation signing.

## 2. Assets

| Asset | Required Protection |
|---|---|
| User identity | Confidentiality, integrity, recovery. |
| Lore Key ownership | Integrity and auditability. |
| Device keys | Confidentiality and non-exportability where possible. |
| Offline leases | Authenticity and bounded validity. |
| Bundle manifests | Integrity and immutability. |
| IndexedDB local state | Confidentiality and tamper evidence. |
| Progress events | Integrity, ordering, idempotency. |
| Reputation events | Evidence integrity and non-repudiation. |
| Zayvora projections | Consent, scope, inspectability. |
| Admin controls | Strong authorization and audit. |

## 3. Threat Actors

- Casual cloner.
- Bundle pirate.
- Reverse engineer.
- Credential attacker.
- Local state tamperer.
- Reputation manipulator.
- Malicious or careless admin.

## 4. Threats and Mitigations

| Threat | Mitigation |
|---|---|
| QR cloning | Treat QR as signal only; Aporaksha authentication, device binding, rate limits, anomaly detection. |
| NFC cloning | Same as QR; secure element tier later for stronger proof. |
| Serial guessing | Hash lookup, rate limits, generic errors. |
| Replay attack | Nonces, signed device assertions, timestamp windows, idempotency keys. |
| Bundle tampering | `.viabundle.json` signature, artifact hashes, trusted signing keys. |
| Local event tampering | Canonical hashes, device signatures, server verification. |
| IndexedDB modification | Treat local state as untrusted for reputation; verify server-side. |
| Offline lease abuse | Bounded expiry, capability scoping, reconciliation. |
| Manual reputation fraud | Reputation from verified events only. |
| Zayvora privacy leak | Explicit permission, scope, source IDs, revocation. |
| Admin abuse | RBAC, MFA, dual approval for destructive actions, audit logs. |

## 5. STRIDE

| Component | Spoofing | Tampering | Repudiation | Info Disclosure | DoS | Elevation |
|---|---|---|---|---|---|---|
| Physical Signal | QR/NFC clone | Label replacement | Claim dispute | Serial exposure | Destroy key | None |
| Aporaksha | Token theft | Ownership mutation | Deny activation | Identity leak | Activation flood | Admin abuse |
| Device Binding | Fake device | Key replacement | Deny use | Device metadata leak | Binding flood | Capability misuse |
| Lease | Forged lease | Expiry edits | Deny issuance | Capability leak | Renewal flood | Offline bypass |
| Bundle | Fake publisher | Manifest edits | Deny release | Metadata leak | CDN flood | Install malicious artifact |
| IndexedDB | Fake local user | Event edits | Deny event | Progress leak | Quota exhaustion | Local bypass |
| Sync | Fake event | Payload mutation | Deny sync | Progress leak | Batch flood | Accept fake progress |
| Reputation | Fake claimant | Claim mutation | Deny publish | Private evidence leak | Verification flood | Unverified claim |
| Zayvora | Fake permission | Projection edits | Deny consent | Memory leak | Projection flood | Overscoped memory |

## 6. Risk Matrix

| Risk | Likelihood | Impact | Severity | Required Control |
|---|---:|---:|---:|---|
| Physical signal clone | High | High | Critical | Do not trust signal; require identity and device binding. |
| Bundle tampering | Medium | High | High | Signature and hash verification. |
| Local progress tamper | Medium | Medium | Medium | Server reconciliation before reputation. |
| Reputation fraud | Medium | High | High | Verified events only. |
| Zayvora oversharing | Medium | High | High | Permissioned scope and audit. |
| Admin compromise | Low | Critical | Critical | MFA, RBAC, dual approval. |
| Outbox replay | Low | Medium | Medium | Idempotent consumers. |

## 7. Security Requirements

- All write endpoints require request ID and idempotency key.
- All server state transitions are audited.
- Offline leases are signed by Aporaksha.
- Device assertions are signed by registered device private key.
- Bundles are immutable after publication.
- Reputation server signatures are issued only after evidence verification.
- Zayvora projection records must include permission version and source event IDs.
# Security Model and Threat Analysis

## 1. Security Objective

Lore Key must provide practical trust for physical-to-digital learning environment installation while preserving local-first usability. Security controls must prevent casual abuse, detect serious abuse, and avoid turning the artifact into a fragile DRM device that punishes legitimate learners.

## 2. Assets

| Asset | Security Need |
|---|---|
| Physical Lore Key identifiers | Integrity and anti-cloning controls. |
| User identity | Confidentiality, integrity, recoverability. |
| Device binding private keys | Confidentiality and non-exportability where possible. |
| Bundle manifests | Integrity and authenticity. |
| Bundle artifacts | Integrity, optional confidentiality, license control. |
| Local progress database | Confidentiality, integrity, availability. |
| Achievement evidence | Integrity and privacy. |
| Reputation events | Integrity, non-repudiation, revocation. |
| Admin credentials | Strong confidentiality and authorization. |
| Audit logs | Integrity and retention. |

## 3. Trust Boundaries

```text
Physical Artifact Boundary
  QR/NFC/secure element can be observed, copied, lost, or tampered with.

User Device Boundary
  Local filesystem, OS keychain, local database, installer, and apps are semi-trusted.

Network Boundary
  Requests may be intercepted, delayed, replayed, or blocked.

Cloud Service Boundary
  Aporaksha, Bundle Resolver, Environment Service, Reputation Service, and databases are trusted components.

Public Reputation Boundary
  External viewers can verify shared claims but must not receive private evidence by default.
```

## 4. Attack Surface

- QR code scan payload.
- NFC UID or NDEF payload.
- Secure challenge endpoint.
- Activation API.
- Validation API.
- Bundle manifest and artifact download path.
- Local installer update path.
- Local database files.
- Sync ingestion endpoint.
- Reputation publishing endpoint.
- Admin console and batch import tooling.
- Recovery workflows.

## 5. Threat Actors

### 5.1 Casual Cloner

Copies a QR code or photographs a key to activate or share access.

### 5.2 Bundle Pirate

Attempts to extract, redistribute, or modify bundles and learning assets.

### 5.3 Reverse Engineer

Inspects the installer, local databases, manifests, or application binaries to bypass controls.

### 5.4 Credential Attacker

Uses phishing, stuffing, token theft, or malware to compromise user or admin accounts.

### 5.5 Reputation Manipulator

Attempts to create fake progress, achievements, or reputation events.

## 6. Threat Analysis

### 6.1 NFC Cloning

| Dimension | Analysis |
|---|---|
| Threat | Static NFC identifiers can be copied to another tag. |
| Impact | Unauthorized activation or sharing. |
| Likelihood | Medium for NFC sticker tier; lower for secure element tier. |
| Mitigations | Hash UID server-side, device binding, anomaly detection, secure-element challenge for high-assurance tier, rate limits. |
| Residual Risk | Static NFC cannot provide strong proof alone. |

### 6.2 QR Cloning

| Dimension | Analysis |
|---|---|
| Threat | QR payload can be photographed or duplicated. |
| Impact | First claimant may steal activation. |
| Likelihood | High. |
| Mitigations | Treat QR as low-assurance, require account verification, device binding, packaging tamper evidence, support dispute workflow, optional receipt/cohort validation. |
| Residual Risk | QR-only keys are unsuitable for high-stakes credentials without secondary proof. |

### 6.3 Bundle Extraction

| Dimension | Analysis |
|---|---|
| Threat | User extracts local artifacts and redistributes content. |
| Impact | Content piracy and license leakage. |
| Likelihood | Medium. |
| Mitigations | Do not store content on key, signed bundles, optional encryption, watermarking, license policy, local entitlement checks, legal controls, minimal secrets in client. |
| Residual Risk | Any locally executable content can be copied by determined attackers. |

### 6.4 Replay Attacks

| Dimension | Analysis |
|---|---|
| Threat | Captured activation or validation requests are replayed. |
| Impact | Unauthorized validation or duplicate activation. |
| Likelihood | Medium. |
| Mitigations | Nonces, timestamp windows, signed device assertions, idempotency keys, TLS, replay cache. |
| Residual Risk | Compromised devices may still submit valid signed requests. |

### 6.5 Local Database Tampering

| Dimension | Analysis |
|---|---|
| Threat | User modifies progress, lease, achievements, or sync queue. |
| Impact | Fraudulent progress or offline bypass. |
| Likelihood | Medium. |
| Mitigations | Encrypt sensitive data, sign local events, hash chains, monotonic counters, server verification, reputation evidence validation. |
| Residual Risk | Local state cannot be fully trusted for high-stakes claims. |

### 6.6 Reputation Fraud

| Dimension | Analysis |
|---|---|
| Threat | Attacker fabricates achievements or evidence. |
| Impact | Trust degradation. |
| Likelihood | Medium. |
| Mitigations | Evidence-linked events, device signatures, server-side progress correlation, anomaly detection, revocation, reviewer workflows for high-value claims. |
| Residual Risk | Social and project claims require review beyond cryptographic signals. |

### 6.7 Key Sharing

| Dimension | Analysis |
|---|---|
| Threat | Multiple learners share one physical key or identity. |
| Impact | Revenue loss, corrupted learning state, reputation ambiguity. |
| Likelihood | High in low-cost tiers. |
| Mitigations | Device limits, cohort policy, anomaly detection, lease renewal patterns, user education, support exceptions. |
| Residual Risk | Overly strict controls may harm families, classrooms, and device-poor learners. |

## 7. Mitigations

### 7.1 Signed Bundles

- Every manifest is signed by a trusted publisher key.
- Every artifact includes a SHA-256 hash in the manifest.
- Installer fails closed on invalid signatures or hash mismatches.
- Signing keys support rotation and revocation.

### 7.2 Device Binding

- Activation registers a device public key.
- Validation requires signed assertions from the device key.
- Device replacement requires physical key possession or recovery proof.
- Device limits are policy-driven by product and cohort.

### 7.3 Offline Lease Windows

- Offline leases permit local use for bounded durations.
- Lease metadata includes issue time, expiry, capabilities, and device binding.
- Clock rollback detection reduces trust and requires online validation.
- Expired leases lock protected features but preserve local data.

### 7.4 Audit Trails

- All activation, validation, bundle resolution, sync, reputation, and admin writes are audited.
- Security failures are audited even when no business state changes.
- Audit logs are append-only and retained according to policy.
- User deletion pseudonymizes audit references rather than erasing security history.

### 7.5 Reputation Verification

- Reputation events must cite achievements or progress evidence.
- Local event signatures and server materialized progress are checked.
- High-value claims can require human or mentor review.
- Accepted events can be revoked through explicit revocation records.

## 8. STRIDE Analysis

| Component | Spoofing | Tampering | Repudiation | Information Disclosure | Denial of Service | Elevation of Privilege |
|---|---|---|---|---|---|---|
| Physical Key | Clone QR/NFC | Replace labels | Claim not mine | Serial leakage | Destroy/lost key | N/A |
| Installer | Fake client | Modify binaries | Deny local actions | Local data leakage | Crash install | Bypass checks |
| Aporaksha | Token theft | State mutation | Dispute activation | Identity leakage | Activation flood | Admin abuse |
| Bundle Resolver | Fake entitlement | Manifest tamper | Deny release | Bundle metadata leakage | Download spike | Publisher key abuse |
| Local State | Device spoofing | Progress edits | Deny event creation | Notes/progress leak | DB corruption | Lease bypass |
| Sync Service | Device spoofing | Event mutation | Deny submission | Progress leakage | Batch flood | Accept fake events |
| Reputation Service | Fake claimant | Claim mutation | Deny publication | Private evidence leak | Verification flood | Publish unverified claims |
| Admin Console | Admin impersonation | Batch edits | Deny actions | Full data exposure | Lock operations | Unauthorized revocation |

## 9. Risk Matrix

| Risk | Likelihood | Impact | Severity | Primary Mitigation |
|---|---:|---:|---:|---|
| QR cloning before activation | High | High | Critical | Device binding, dispute workflow, secure packaging. |
| Bundle artifact piracy | Medium | High | High | Signed bundles, optional encryption, watermarking. |
| Admin account compromise | Medium | Critical | Critical | MFA, RBAC, approval workflows, audit monitoring. |
| Local progress tampering | Medium | Medium | Medium | Signed local events and server verification. |
| Reputation fraud | Medium | High | High | Evidence correlation, review, revocation. |
| Sync endpoint flooding | Medium | Medium | Medium | Rate limits, backpressure, batching. |
| Signing key compromise | Low | Critical | High | HSM/secret manager, rotation, revocation. |
| Offline lease abuse | Medium | Medium | Medium | Lease windows and anomaly detection. |
| Device loss | High | Medium | High | Recovery flow and local encryption. |

## 10. Security Requirements by Assurance Tier

| Tier | Artifact | Intended Use | Required Controls |
|---|---|---|---|
| Tier 0 | Printed QR | Low-cost kits, non-high-stakes learning | Device binding, rate limits, low-assurance reputation. |
| Tier 1 | QR + NFC | Standard learning environments | All Tier 0 plus NFC hash and anomaly checks. |
| Tier 2 | Secure element | Higher-value credentials and professional kits | Challenge-response, stronger recovery, stricter device policy. |
| Tier 3 | Secure element + supervised issuance | High-stakes cohorts | Identity verification, proctored issuance, enhanced audit. |
