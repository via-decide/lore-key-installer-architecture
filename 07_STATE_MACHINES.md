# 07 — State Machines

## 1. Lore Key Ownership Lifecycle

```text
REGISTERED -> UNCLAIMED -> OWNED -> ACTIVE -> SUSPENDED -> ACTIVE
      |           |          |        |           |
      +-----------+----------+--------+-----------+-> REVOKED
```

| State | Meaning | Allowed Next States |
|---|---|---|
| REGISTERED | Manufactured key exists in Aporaksha. | UNCLAIMED, REVOKED |
| UNCLAIMED | Available for ownership activation. | OWNED, REVOKED |
| OWNED | User ownership exists but capabilities may not be fully active. | ACTIVE, SUSPENDED, REVOKED |
| ACTIVE | Key can issue leases and install capabilities. | SUSPENDED, REVOKED |
| SUSPENDED | Temporarily restricted. | ACTIVE, REVOKED |
| REVOKED | Permanently invalid for new protected capabilities. | none |

Guards:

- QR/NFC/serial can only move a key forward after Aporaksha authentication.
- `REVOKED` is terminal.
- `SUSPENDED` requires reason and actor.

## 2. Device Binding Lifecycle

```text
REQUESTED -> ACTIVE -> SUSPENDED -> ACTIVE
      |         |          |
      |         +----------+-> REMOVED
      +---------------------> REJECTED
```

Guards:

- Device must provide public key.
- Device assertion must validate for protected actions.
- Removed devices cannot renew leases.

## 3. Offline Lease Lifecycle

```text
ISSUED -> ACTIVE -> WARNING -> EXPIRED
   |         |          |
   |         +----------+-> REVOKED
   +---------------------> SUPERSEDED
```

Actions:

- `ISSUED`: store signed lease in IndexedDB.
- `WARNING`: notify user before expiry.
- `EXPIRED`: block protected features but preserve local data and sync existing events.
- `SUPERSEDED`: old lease remains auditable; new lease becomes active.

## 4. Bundle Lifecycle

```text
DRAFT -> SIGNED -> PUBLISHED -> DEPRECATED -> REVOKED
             |          |
             +----------+-> REVOKED
```

Guards:

- `PUBLISHED` requires valid schema, signature, and immutable artifact hashes.
- `REVOKED` versions cannot be newly installed.
- `DEPRECATED` versions may continue running by policy but should update.

## 5. Install Lifecycle

```text
PLANNED -> DOWNLOADING -> VERIFYING -> INSTALLING -> CONFIGURING -> ACTIVE
   |           |             |             |              |
   +-----------+-------------+-------------+--------------+-> FAILED -> ROLLED_BACK
```

Actions:

- `PLANNED`: preflight disk, platform, lease, dependencies.
- `VERIFYING`: validate manifest signature and artifact hashes.
- `CONFIGURING`: create IndexedDB environment records.
- `FAILED`: preserve diagnostics.
- `ROLLED_BACK`: restore previous runtime state without deleting user data.

## 6. Environment Lifecycle

```text
LOCKED -> AUTHENTICATING -> INSTALLING -> ACTIVE -> OFFLINE -> EXPIRED
   ^             |              |          |        |           |
   +-------------+--------------+----------+--------+-----------+
```

Rules:

- `ACTIVE` requires valid install and lease.
- `OFFLINE` requires valid unexpired lease.
- `EXPIRED` cannot delete notes, exports, or pending events.
- Revocation at online validation returns to `LOCKED` or `SYNC_ONLY` by policy.

## 7. Event Lifecycle

```text
LOCAL_CREATED -> QUEUED -> SUBMITTED -> ACCEPTED -> MATERIALIZED
       |           |          |          |
       |           |          +----------+-> REJECTED
       |           +---------------------> CONFLICTED -> ACCEPTED
       +---------------------------------> DISCARDED_INVALID_LOCAL
```

Guards:

- Local events must pass schema before queueing.
- Submitted events must pass signature and hash verification.
- Materialization requires accepted status.

## 8. Reputation Lifecycle

```text
DRAFT -> CONSENTED -> PENDING_VERIFICATION -> ACCEPTED -> PUBLISHED
   |          |              |                 |
   +----------+--------------+-----------------+-> REJECTED
                                      |
                                      +-> REVOKED or SUPERSEDED
```

Rules:

- Drafts may be manual, but verified reputation must be event-backed.
- Consent is required before submission.
- Accepted reputation requires server signature.

## 9. Zayvora Projection Lifecycle

```text
REQUESTED -> PERMISSION_GRANTED -> CREATED -> INSPECTED -> CORRECTED
       |              |              |            |
       +--------------+--------------+------------+-> REVOKED
```

Rules:

- No projection without permission.
- Projection records source events and scope.
- Correction creates supersession, not silent mutation.
