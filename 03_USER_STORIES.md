# 03 — User Stories and Acceptance Criteria

## 1. Epics

| Epic | Definition |
|---|---|
| E1 Physical Signal Intake | QR, NFC, and serial are captured as untrusted physical signals. |
| E2 Aporaksha Identity | User authentication, ownership activation, device binding, and leases are controlled by Aporaksha. |
| E3 Bundle Resolution | Entitled signed immutable `.viabundle.json` manifests are resolved. |
| E4 Verified Installation | Installer verifies bundles and creates a local environment. |
| E5 Local Runtime | Capacitor runtime stores IndexedDB state and works offline under lease. |
| E6 Progress Events | Apps record progress as canonical signed events. |
| E7 Sync Reconciliation | Client queue syncs to server with idempotency and conflicts. |
| E8 Verified Reputation | ViaDecide publishes only from verified events. |
| E9 Zayvora Projection | User-permitted memory projections are created from verified/local context. |
| E10 Administration and Recovery | Admins register/revoke keys and users recover devices safely. |

## 2. User Stories

1. As a learner, I want to scan a QR code so that I can start activation from a physical signal.
2. As a learner, I want to tap NFC so that activation is easier on supported devices.
3. As a learner, I want to enter a serial manually so that damaged QR/NFC does not block me.
4. As a security engineer, I want QR/NFC/serial treated as untrusted signals so that clones do not become identity.
5. As a learner, I want to authenticate through Aporaksha so that ownership is tied to my account.
6. As a learner, I want to activate ownership so that the Lore Key becomes mine.
7. As a learner, I want my device bound so that offline access is secure.
8. As a learner, I want an offline lease so that I can learn without internet.
9. As a learner, I want lease expiry visible so that I know when to reconnect.
10. As a learner, I want to resolve my eligible bundle so that the correct environment installs.
11. As a learner, I want bundles verified before install so that tampered content is rejected.
12. As a learner, I want install progress and diagnostics so that failures are understandable.
13. As a learner, I want rollback on failed install so that my device is not left broken.
14. As a learner, I want local IndexedDB state so that progress is saved offline.
15. As a StudyOS learner, I want lessons to append progress events so that progress is durable.
16. As a PrepOS learner, I want exam attempts saved as events so that analytics are reconstructable.
17. As a SkillHex learner, I want project evidence events so that work can become reputation.
18. As a learner, I want sync to retry safely so that duplicate submissions do not corrupt state.
19. As a learner, I want conflict outcomes explained so that sync is understandable.
20. As a learner, I want reputation drafts generated from verified events so that claims are trustworthy.
21. As a learner, I want to approve reputation publication so that private data is not exposed.
22. As a verifier, I want signed reputation events so that I can verify current status.
23. As a learner, I want Zayvora projection permission prompts so that memory sharing is controlled.
24. As a learner, I want to inspect projected memory so that I can correct context.
25. As an admin, I want to register key batches so that manufactured keys are traceable.
26. As an admin, I want to suspend a key so that suspected abuse is contained.
27. As an admin, I want to revoke a key so that compromised keys stop receiving capabilities.
28. As a support agent, I want audit logs so that activation issues can be diagnosed.
29. As a learner, I want recovery on a new device so that device loss does not destroy progress.
30. As a security engineer, I want replayed activation requests rejected so that captured traffic cannot be reused.
31. As a bundle publisher, I want immutable versions so that installed environments are reproducible.
32. As a bundle publisher, I want dependencies declared so that installs are deterministic.
33. As an installer, I want local mirror support for signed artifacts so that classrooms can install on low bandwidth.
34. As a learner, I want expired leases to preserve my notes so that expiry does not delete data.
35. As an app developer, I want a runtime SDK so that apps use the same event and capability contract.
36. As a product leader, I want metrics by activation and install step so that pilot failures are visible.
37. As a privacy reviewer, I want Zayvora projections scoped so that only permitted data flows.
38. As a reputation reviewer, I want manual claims blocked from verified status so that reputation is evidence-backed.
39. As a DevOps engineer, I want transactional outbox events so that integrations are reliable.
40. As a QA engineer, I want deterministic fixtures so that activation, install, sync, and reputation can be tested.

## 3. Acceptance Criteria

### AC1 Physical Signal Intake

- Given a QR/NFC/serial payload, when the installer reads it, then it creates a `PhysicalSignal` envelope.
- Given a physical signal, when activation is attempted, then Aporaksha validates it before ownership changes.
- Given a copied signal, when identity/device checks fail or risk is high, then activation is denied or held.

### AC2 Ownership Activation

- Given an unclaimed key and authenticated user, when activation succeeds, then ownership is recorded in Aporaksha.
- Given an already owned key, when another user attempts activation, then Aporaksha returns `409` unless transfer is approved.
- Given a revoked key, when activation is attempted, then no ownership, device binding, or lease is issued.

### AC3 Device Binding

- Given successful activation, when the device public key is submitted, then the device binding becomes active.
- Given an unbound device, when it requests protected capabilities, then validation is denied.
- Given the device limit is reached, when a new binding is requested, then recovery or removal is required.

### AC4 Offline Lease

- Given a valid activation, when Aporaksha issues a lease, then the lease is signed and scoped to user, key, device, capabilities, and expiry.
- Given an unexpired lease, when offline, then the runtime allows lease-scoped capabilities.
- Given an expired lease, when offline, then protected features are blocked while local read/export remains available.

### AC5 Bundle Resolution

- Given valid entitlement, when Bundle Resolver is called, then it returns a signed immutable `.viabundle.json` reference.
- Given no entitlement, when resolution is requested, then it returns `403`.
- Given a revoked bundle version, when resolution is requested, then it is not returned for new install.

### AC6 Verified Installation

- Given a manifest, when schema, signature, and hash pass, then artifacts may download.
- Given an artifact hash mismatch, when verification runs, then installation stops and artifact is quarantined.
- Given install failure after checkpoint, when rollback runs, then user data is preserved.

### AC7 Local State

- Given the runtime starts, when a valid lease exists, then identity, install, progress, sync, and memory state are read from IndexedDB.
- Given IndexedDB is unavailable, when the app starts, then recovery diagnostics are shown.
- Given user exports data, when export completes, then local event history is included.

### AC8 Progress Events

- Given an app records progress, when it calls the SDK, then a canonical event is hashed, signed, stored, and queued.
- Given duplicate event IDs, when synced, then the server returns the existing accepted result.
- Given invalid schema, when appended, then the event is rejected before sync.

### AC9 Sync Reconciliation

- Given pending events, when network returns, then the client submits a stable batch.
- Given partial rejection, when the response returns, then accepted events are marked accepted and rejected events retain reason.
- Given a conflict, when deterministic resolution applies, then conflict metadata is stored.

### AC10 Verified Reputation

- Given a reputation draft, when evidence is not verified, then it cannot become a verified reputation event.
- Given verified evidence and consent, when ViaDecide publishes, then Reputation Service signs the event.
- Given revoked evidence, when verification is requested, then the reputation status reflects revocation.

### AC11 Zayvora Projection

- Given a user grants projection permission, when eligible context exists, then Zayvora receives scoped memory records.
- Given no permission, when projection is requested, then no data is sent.
- Given a user correction, when saved, then corrected memory supersedes prior projection without deleting provenance.

### AC12 Administration

- Given a manufacturing batch, when imported, then duplicate serials are rejected and audit is written.
- Given suspicious abuse, when an admin suspends a key, then validation returns restricted capabilities.
- Given confirmed compromise, when an admin revokes a key, then new leases and installs are denied.
