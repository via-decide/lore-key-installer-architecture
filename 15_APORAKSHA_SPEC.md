# 15 — Aporaksha Specification

## 1. Authority

Aporaksha is the source of truth for identity, ownership activation, device binding, offline leases, and identity assertions used by reputation signing.

## 2. Physical Signal Policy

QR, NFC, and serial are accepted only as `PhysicalSignal` inputs. They cannot authenticate a user and cannot authorize install by themselves.

## 3. Responsibilities

- Register key batches.
- Validate physical signal hashes.
- Authenticate or create users.
- Activate ownership.
- Bind devices.
- Issue and renew signed offline leases.
- Suspend/revoke keys, ownerships, and devices.
- Issue short-lived identity assertions for reputation.
- Audit all state changes and security failures.

## 4. Activation Algorithm

```text
1. Validate request schema.
2. Rate-limit by signal hash, IP, and device fingerprint.
3. Hash submitted public signal and find LoreKey.
4. Authenticate or create User.
5. Verify consent versions.
6. Reject revoked/suspended keys.
7. Create active Ownership if key is unowned.
8. Create DeviceBinding from public key.
9. Issue signed OfflineLease.
10. Insert audit log and outbox event.
11. Return tokens, ownership, device binding, lease.
```

## 5. Lease Contract

Lease fields: `lease_id`, `user_id`, `lore_key_id`, `ownership_id`, `device_id`, `capabilities`, `issued_at`, `expires_at`, `signature`.

Capabilities:

- `INSTALL_BUNDLE`
- `RUN_ENVIRONMENT`
- `RECORD_PROGRESS`
- `QUEUE_SYNC`
- `CREATE_REPUTATION_DRAFT`
- `REQUEST_ZAYVORA_PROJECTION`
- `SYNC_ONLY`

## 6. Device Binding

A device binding contains a stable `device_id`, platform, public key, status, and trust tier. Protected requests include a signed device assertion. Device private keys remain on device.

## 7. State Diagrams

```text
PhysicalSignalReceived -> SignalValidated -> UserAuthenticated -> OwnershipActivated
-> DeviceBound -> LeaseIssued -> ActivationComplete
```

```text
LeaseActive -> LeaseWarning -> LeaseExpired -> RenewalRequired -> LeaseRenewed
```

## 8. Offline Authorization

The local runtime verifies the Aporaksha lease signature and expiry. It grants only capabilities listed in the lease. Missing capability means deny.

## 9. Reputation Signing

Aporaksha issues a short-lived identity assertion. Reputation Service separately verifies evidence events and signs reputation. Aporaksha does not verify learning achievement by itself.

## 10. Threat Controls

| Threat | Control |
|---|---|
| Signal clone | Identity auth, ownership uniqueness, device binding. |
| Replay | Nonce, timestamp, idempotency, assertion signature. |
| Lease forgery | Ed25519 signature and trust store. |
| Device theft | device removal, lease expiry, recovery flow. |
| Admin abuse | RBAC, MFA, audit, dual approval for batch revocation. |

## 11. Required APIs

- `POST /v1/aporaksha/activate`
- `POST /v1/aporaksha/validate`
- `POST /v1/aporaksha/leases/renew`
- `POST /v1/aporaksha/reputation/assertion`
- `POST /v1/aporaksha/admin/keys/register`
- `POST /v1/aporaksha/admin/keys/suspend`
- `POST /v1/aporaksha/admin/keys/revoke`
