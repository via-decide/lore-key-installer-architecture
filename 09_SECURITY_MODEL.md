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
