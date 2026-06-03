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
