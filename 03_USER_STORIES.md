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
# User Stories, Acceptance Criteria, and Epics

## 1. Epic Definitions

### Epic 1: Physical Identity Activation

Enable learners to claim a physical Lore Key and bind it to a learner identity through QR, NFC, serial, or secure challenge workflows.

### Epic 2: Aporaksha Identity and Validation

Provide identity, key status, entitlement, validation, lease, and recovery services that applications can trust.

### Epic 3: Environment Installation

Install verified learning environments locally using signed manifests, resumable downloads, dependency checks, and deterministic state transitions.

### Epic 4: Offline Learning Runtime

Allow users to continue learning offline within explicit lease and sync boundaries while preserving local progress.

### Epic 5: Progress and Achievement Tracking

Capture structured learning events, progress states, achievements, and evidence references across StudyOS, PrepOS, SkillHex, ViaDecide, and Zayvora.

### Epic 6: Reputation Publishing

Publish consented, verifiable reputation events derived from trusted progress and achievement records.

### Epic 7: Bundle Management

Manage bundle catalogs, versions, signatures, eligibility rules, installation policies, and rollback controls.

### Epic 8: Administration and Operations

Support manufacturing batches, key issuance, suspension, revocation, audit review, support workflows, and incident response.

### Epic 9: Security and Abuse Prevention

Protect against cloning, replay, bundle extraction, local tampering, credential attacks, and reputation manipulation.

### Epic 10: Recovery and Portability

Support device replacement, account recovery, state export, sync reconciliation, and lawful deletion.

## 2. User Stories

1. As a STEM Student, I want to scan my Lore Key so that I can activate my learning environment without manually creating multiple accounts.
2. As a Competitive Exam Aspirant, I want my Lore Key to install the correct PrepOS bundle so that I can start practice immediately.
3. As a Maker, I want the installer to configure project tools so that I can build instead of troubleshooting setup.
4. As an Embedded Engineer, I want board-specific bundles to install locally so that I can work offline in a lab.
5. As a Lifelong Learner, I want my learning identity to persist across products so that my history remains coherent.
6. As a learner, I want activation to validate the key status so that stolen or revoked keys cannot be used.
7. As a learner, I want offline access after installation so that unreliable internet does not stop learning.
8. As a learner, I want to see offline lease expiry clearly so that I know when revalidation is required.
9. As a learner, I want progress to be saved locally so that connectivity failures do not lose work.
10. As a learner, I want local progress to sync automatically so that my cloud state catches up when online.
11. As a learner, I want duplicate sync events to be ignored safely so that retries do not corrupt progress.
12. As a learner, I want achievements to include evidence references so that they are credible.
13. As a learner, I want to approve reputation publishing so that private learning data is not exposed.
14. As a learner, I want to export my progress so that I can keep my learning history.
15. As a learner, I want to recover access on a new device so that device loss does not end my learning.
16. As a parent or sponsor, I want to verify that a key was activated so that I know the learner can start.
17. As a teacher, I want cohort keys to map to course bundles so that setup is consistent.
18. As an administrator, I want to register manufacturing batches so that every physical key is traceable.
19. As an administrator, I want to suspend a key so that suspected abuse can be investigated.
20. As an administrator, I want to revoke a key so that confirmed compromised artifacts cannot validate.
21. As a support agent, I want audit logs so that I can diagnose activation failures.
22. As a security analyst, I want activation attempts rate-limited so that credential attacks are slowed.
23. As a bundle publisher, I want to sign bundle manifests so that installers can verify authenticity.
24. As a bundle publisher, I want versioned bundles so that fixes can be shipped without breaking prior installs.
25. As a learner, I want the installer to resume downloads so that network interruptions do not restart installation.
26. As a learner, I want the installer to verify hashes so that corrupted bundles are rejected.
27. As a learner, I want installation errors explained clearly so that I can fix device issues.
28. As a learner, I want StudyOS progress tracked by topic so that I know what remains.
29. As an exam aspirant, I want PrepOS attempts tracked by exam section so that I can target revision.
30. As a maker, I want SkillHex to capture project evidence so that completed work is provable.
31. As a ViaDecide user, I want decision trails linked to achievements so that reputation has context.
32. As a Zayvora user, I want memory records to be inspectable so that I can correct inaccurate context.
33. As a privacy-conscious learner, I want local data encrypted so that device theft does not expose records.
34. As a learner, I want to unbind an old device so that I can manage authorized devices.
35. As a support agent, I want recovery flows to require strong verification so that attackers cannot steal accounts.
36. As a learner, I want my key status visible so that I understand whether it is active, suspended, or revoked.
37. As an administrator, I want bundle eligibility rules so that cohorts receive correct content.
38. As an operations lead, I want metrics for activation failures so that manufacturing or software defects are detected.
39. As a security analyst, I want replayed activation tokens rejected so that captured traffic cannot be reused.
40. As a learner, I want clear warnings before lease expiry so that I can sync in time.
41. As a teacher, I want offline classroom installation from a local mirror so that limited bandwidth does not block a cohort.
42. As a learner, I want reputation events queued offline so that achievements can publish later.
43. As a reputation verifier, I want signatures on events so that I can validate provenance.
44. As a learner, I want the installer to avoid storing content on the physical key so that losing the key does not leak course assets.
45. As an embedded engineer, I want toolchain versions pinned so that labs are reproducible.
46. As a developer, I want API versioning so that clients can evolve safely.
47. As an administrator, I want soft delete controls so that user deletion does not destroy audit integrity.
48. As a learner, I want conflict resolution explained so that sync results are understandable.
49. As a product leader, I want adoption metrics by cohort so that product-market fit can be measured.
50. As an investor, I want the architecture to support additional learning apps so that the platform can scale beyond one product.

## 3. Acceptance Criteria Sets

### AC-01: Key Activation

- Given an unclaimed valid Lore Key, when the learner scans it and completes identity setup, then the key state becomes `CLAIMED` and an activation record is created.
- Given a revoked key, when activation is attempted, then the API returns `403` and no activation is created.
- Given a repeated activation request with the same idempotency key, when retried, then the same activation result is returned.

### AC-02: Validation

- Given an active key and bound device, when validation is requested, then the response includes key status, lease expiry, and eligible bundle references.
- Given a suspended key, when validation is requested, then the response denies new installs but preserves local read-only state.
- Given an invalid signature, when validation is requested, then the response is `401`.

### AC-03: Bundle Resolution

- Given valid entitlement, when the client requests a bundle, then the service returns a signed manifest with version and hash metadata.
- Given no entitlement, when a bundle is requested, then the service returns `403`.
- Given a deprecated bundle version, when the request allows upgrade, then the latest compatible version is returned.

### AC-04: Installation

- Given a signed manifest, when all artifact hashes verify, then installation may proceed.
- Given a hash mismatch, when verification runs, then installation stops and an audit event is recorded.
- Given an interrupted download, when restarted, then the installer resumes from verified chunks.

### AC-05: Offline Usage

- Given an active unexpired lease, when the device is offline, then the environment remains usable.
- Given an expired lease, when the device is offline, then protected features are locked and recovery guidance is displayed.
- Given offline progress events, when the user works, then events are appended to the sync queue.

### AC-06: Sync

- Given queued events, when connectivity returns, then events are uploaded in order with idempotency keys.
- Given duplicate event IDs, when sync occurs, then the server returns the existing accepted state.
- Given conflicting progress, when sync resolves, then deterministic rules are applied and conflict metadata is stored.

### AC-07: Reputation Publishing

- Given an eligible achievement, when the learner consents, then a signed reputation event is created.
- Given insufficient evidence, when publishing is attempted, then the event is rejected with an actionable error.
- Given a revoked achievement, when verification occurs, then reputation status reflects revocation.

### AC-08: Device Binding

- Given first activation on a device, when validation succeeds, then the device binding is created.
- Given the device limit is exceeded, when another device validates, then the user must remove a device or request support.
- Given a device is unbound, when it validates again, then reauthorization is required.

### AC-09: Administration

- Given a batch file, when an admin imports keys, then all serials are registered with batch metadata.
- Given suspicious activity, when an admin suspends a key, then future validations reflect `SUSPENDED`.
- Given revocation, when the key is validated, then installs are denied and an audit event is written.

### AC-10: Security Logging

- Given any write API call, when processed, then a correlation ID is stored in audit logs.
- Given failed authentication, when repeated, then rate limiting applies.
- Given an integrity failure, when detected, then severity and artifact identifiers are logged.

### AC-11: Recovery

- Given verified account ownership and physical key possession, when device recovery is requested, then a new device can be bound.
- Given no physical key and weak identity proof, when recovery is requested, then the system denies automated recovery.
- Given recovery success, when sync completes, then previous state is restored according to policy.

### AC-12: Local Encryption

- Given local state exists, when stored, then sensitive fields are encrypted at rest.
- Given the OS keychain is unavailable, when encryption setup runs, then the installer fails closed or uses an approved fallback.
- Given corrupted local state, when opening the app, then recovery mode starts.

### AC-13: Progress Tracking

- Given lesson completion, when recorded, then user progress updates locally.
- Given repeated completion events, when processed, then progress remains idempotent.
- Given rollback or reset, when requested, then the original event history remains auditable.

### AC-14: Bundle Versioning

- Given a compatible update, when resolved, then the installer offers upgrade.
- Given an incompatible major version, when resolved, then migration requirements are shown.
- Given a compromised version, when revoked, then future installs are blocked.

### AC-15: Offline Reputation Queue

- Given an achievement offline, when the user consents to publish, then a pending reputation event is queued.
- Given the queue syncs later, when the server validates evidence, then the event publishes.
- Given evidence fails validation, when synced, then the event remains rejected with reason.

### AC-16: Privacy

- Given a reputation event preview, when displayed, then all shared fields are visible before consent.
- Given private notes exist, when publishing reputation, then notes are not included unless explicitly selected.
- Given data export, when requested, then user-owned records are exported in documented format.

### AC-17: Installer Diagnostics

- Given a failed prerequisite check, when installation starts, then the installer displays the missing dependency and fix path.
- Given insufficient disk space, when installing, then no partial active environment is created.
- Given a permissions failure, when installing, then the installer offers user-level alternative paths where possible.

### AC-18: Audit Integrity

- Given audit logs are written, when users are soft-deleted, then audit references remain pseudonymized rather than removed.
- Given admin actions, when performed, then actor identity and reason are required.
- Given log export, when requested by authorized admin, then records include timestamps, correlation IDs, and action types.

### AC-19: Zayvora Memory

- Given progress events, when memory updates, then derived memory records cite source event IDs.
- Given a user correction, when saved, then the correction supersedes but does not silently erase provenance.
- Given memory sharing, when enabled, then only selected summaries leave the device.

### AC-20: API Versioning

- Given an API change, when backward-compatible, then it remains under `/v1` with additive fields.
- Given a breaking change, when introduced, then it is published under a new version.
- Given deprecated fields, when used, then clients receive deprecation warnings before removal.
