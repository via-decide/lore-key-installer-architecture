# Aporaksha Identity Service Specification

## 1. Purpose

Aporaksha is the identity, key validation, lease, device binding, and trust authority for Lore Key. It converts physical possession evidence into digital authorization while preserving offline-first behavior through signed leases.

## 2. Responsibilities

| Responsibility | Description |
|---|---|
| Key registration | Register manufactured Lore Keys and hardware tiers. |
| Key activation | Claim a key and bind it to a user/device. |
| Key validation | Validate key status, entitlement capability, and device assertion. |
| Lease issuance | Issue signed offline authorization leases. |
| Lease renewal | Renew leases after online validation. |
| Device binding | Register, limit, suspend, or replace trusted devices. |
| Offline authorization | Encode capabilities that local runtime can enforce. |
| Reputation signing | Sign identity-level statements used by reputation service. |
| Recovery | Authorize device replacement and state restore. |

## 3. Trust Boundaries

```text
[Physical Key]
  QR/NFC/Secure Challenge
       │ untrusted observable payload
       v
[Installer]
  device key + local state
       │ signed request over TLS
       v
[API Gateway]
  rate limit + auth + WAF
       │ trusted service call
       v
[Aporaksha]
  identity authority
       │ writes
       v
[PostgreSQL + Audit Log]
```

## 4. Key Registration

### 4.1 Inputs

| Input | Required | Description |
|---|---:|---|
| `serial` | Yes | Unique printed serial. |
| `publicCodeHash` | Yes | Hash of QR activation code. |
| `nfcUidHash` | No | Hash of NFC identifier. |
| `secureElementPublicKey` | Tier-dependent | Public key for challenge-response. |
| `manufacturingBatch` | Yes | Batch identifier. |
| `hardwareTier` | Yes | Assurance tier. |
| `distributionChannel` | No | School, retail, kit, internal. |

### 4.2 Registration Rules

- Raw activation codes are never stored server-side after generation.
- Batch import must be idempotent by serial.
- Duplicate serials fail the batch unless explicitly marked as replacement correction.
- Registered keys start as `UNCLAIMED`.
- Every batch import creates an audit event with row counts and actor.

### 4.3 State Diagram

```text
BATCH_UPLOADED -> VALIDATED -> REGISTERED -> AVAILABLE
        |             |            |
        +-------------+------------+-> FAILED
```

## 5. Key Activation

### 5.1 Activation Inputs

- Physical proof: QR code, NFC UID/hash, or secure-element challenge response.
- User profile: email or recovery key, display name, region, consent versions.
- Device assertion: device ID, platform, public key, installer version.
- Idempotency key and request ID.

### 5.2 Activation Algorithm

```text
1. Validate request schema.
2. Rate-limit by IP, serial fingerprint, and device fingerprint.
3. Hash submitted public code and lookup key.
4. Verify key is not suspended/revoked/deleted.
5. Verify secure challenge if hardware tier requires it.
6. Create or resolve user identity.
7. Verify required consents.
8. Enforce claim policy.
9. Create device binding.
10. Transition key to CLAIMED or ACTIVE.
11. Issue access token and offline lease.
12. Write audit log.
13. Return activation response.
```

### 5.3 Activation State Diagram

```text
START
  │
  v
PROOF_RECEIVED -> PROOF_VERIFIED -> USER_BOUND -> DEVICE_BOUND -> LEASE_ISSUED -> COMPLETE
       |                |              |              |               |
       +----------------+--------------+--------------+---------------+-> FAILED
```

### 5.4 Failure Handling

| Failure | Response | Audit Severity |
|---|---|---|
| Invalid proof | `401 INVALID_KEY_PROOF` | WARN after threshold. |
| Revoked key | `403 KEY_REVOKED` | HIGH. |
| Already claimed | `409 KEY_ALREADY_CLAIMED` | INFO/WARN. |
| Device limit exceeded | `403 DEVICE_LIMIT_EXCEEDED` | INFO. |
| Consent missing | `422 CONSENT_REQUIRED` | INFO. |
| Nonce replay | `401 REPLAY_DETECTED` | HIGH. |

## 6. Key Validation

### 6.1 Validation Inputs

- `userId`
- `loreKeyId`
- `deviceId`
- signed device assertion
- requested capabilities
- optional current lease ID

### 6.2 Validation Output

- Key status.
- User lifecycle status.
- Device binding status.
- Granted capabilities.
- Lease or renewal decision.
- Required next action.

### 6.3 Validation Rules

- Revoked keys grant no protected capabilities.
- Suspended keys may allow `SYNC_ONLY` or `READ_LOCAL` based on policy.
- Device assertion must verify against registered public key.
- Requested capabilities are intersected with entitlement policy.
- Validation returns least privilege; absence of explicit grant means deny.

## 7. Lease Issuance

### 7.1 Lease Contract

```json
{
  "lease_id": "lease_01HX",
  "subject": {
    "user_id": "usr_01HX",
    "lore_key_id": "key_01HX",
    "device_id": "dev_01HX"
  },
  "capabilities": ["RUN_ENVIRONMENT", "RECORD_PROGRESS", "QUEUE_SYNC"],
  "constraints": {
    "max_offline_seconds": 2592000,
    "max_clock_drift_seconds": 900,
    "allowed_applications": ["StudyOS", "PrepOS"]
  },
  "issued_at": "2026-06-02T00:00:00Z",
  "expires_at": "2026-07-02T00:00:00Z",
  "issuer": "aporaksha",
  "signature": "base64url-ed25519-signature"
}
```

### 7.2 Lease Rules

- Default MVP lease: 30 days unless bundle policy is stricter.
- Lease capabilities are bundle and device scoped.
- Lease signatures are verified locally before use.
- Leases are not bearer tokens for server APIs; they are offline authorization artifacts.
- Lease revocation takes effect at next online validation unless a short lease is used.

## 8. Lease Renewal

```text
ACTIVE_LEASE -> RENEWAL_REQUESTED -> VALIDATED -> RENEWED
       |                 |              |
       |                 +--------------+-> DENIED
       +-> EXPIRED -> VALIDATION_REQUIRED
```

Renewal rules:

- Renewal requires online validation.
- Renewal may be denied if key is suspended, revoked, device is unbound, or entitlement changed.
- Sync may proceed even if renewal is denied, unless abuse policy blocks ingestion.

## 9. Device Binding

### 9.1 Device Binding Record

| Field | Description |
|---|---|
| `deviceId` | Stable generated ID. |
| `devicePublicKey` | Ed25519 public key. |
| `platform` | OS and architecture. |
| `firstSeenAt` | First activation timestamp. |
| `lastSeenAt` | Last validation timestamp. |
| `status` | `ACTIVE`, `SUSPENDED`, `REMOVED`, `LOST`. |
| `trustTier` | Derived from hardware tier, OS key storage, risk signals. |

### 9.2 Binding Rules

- A user/key may have a configurable maximum number of active devices.
- Device private key must never leave the device.
- Device removal requires user confirmation or support/admin action.
- Lost devices are not physically deleted; they are marked inactive for audit.

## 10. Offline Authorization

Aporaksha grants offline authorization through signed leases. Local runtime enforces leases without contacting Aporaksha.

```text
Aporaksha signs lease -> Installer stores lease -> Runtime verifies signature
       -> Apps request capability -> Runtime allows/denies locally
```

Deny-by-default capability checks:

- `RUN_ENVIRONMENT`
- `INSTALL_BUNDLE`
- `RECORD_PROTECTED_PROGRESS`
- `QUEUE_REPUTATION`
- `EXPORT_DATA`
- `ADMINISTER_DEVICE`

## 11. Reputation Signing

Aporaksha does not replace the Reputation Service. It signs identity assertions that bind a reputation event to a validated user/key/device context.

### 11.1 Signed Assertion

```json
{
  "assertion_type": "IDENTITY_CONTEXT_FOR_REPUTATION",
  "user_id": "usr_01HX",
  "lore_key_id": "key_01HX",
  "device_id": "dev_01HX",
  "trust_tier": "QR_NFC_STANDARD",
  "issued_at": "2026-06-02T00:00:00Z",
  "expires_at": "2026-06-02T00:15:00Z",
  "signature": "base64url..."
}
```

Rules:

- Assertion TTL is short, default 15 minutes.
- Assertion does not prove achievement validity; it proves identity context.
- Reputation Service verifies achievement evidence separately.

## 12. Threat Model

| Threat | Mitigation |
|---|---|
| QR cloning | Device binding, rate limits, low-assurance classification, support dispute process. |
| NFC cloning | UID hash, anomaly detection, secure element tier. |
| Replay | Nonces, timestamp windows, device signatures, replay cache. |
| Device theft | OS keychain, local encryption, device removal, lease expiry. |
| Admin misuse | RBAC, MFA, dual approval for revocation batches, immutable audit. |
| Lease forgery | Ed25519 signatures and trusted key rotation. |
| Recovery takeover | Physical key proof plus step-up verification. |

## 13. Service Interfaces

| Endpoint | Purpose |
|---|---|
| `POST /v1/aporaksha/admin/keys/register` | Batch key registration. |
| `POST /v1/aporaksha/activate` | Claim and activate key. |
| `POST /v1/aporaksha/validate` | Validate key/user/device/capabilities. |
| `POST /v1/aporaksha/leases/renew` | Renew offline lease. |
| `POST /v1/aporaksha/devices/remove` | Remove or mark device lost. |
| `POST /v1/aporaksha/recovery/start` | Start recovery. |
| `POST /v1/aporaksha/reputation/assertion` | Issue identity context assertion. |

## 14. Definition of Done for Aporaksha MVP

- Activation, validation, lease issuance, renewal, and device binding implemented.
- All write endpoints require idempotency keys.
- All write and security-failure paths write audit logs.
- Revoked/suspended keys are enforced in validation.
- Replay tests pass.
- Lease signature verification test vectors exist for installer.
- Admin key registration supports dry-run validation.
